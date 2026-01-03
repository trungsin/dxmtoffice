#!/bin/bash
set -e
set -o pipefail

TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
LOG_FILE="deploy/logs/dev/deploy-$TIMESTAMP.log"

# Ensure log directories exist
mkdir -p deploy/logs/dev

# Git Identity Fix (for VPS deployments)
if [ -z "$(git config user.email)" ]; then
    echo "Configuring temporary git identity..."
    git config user.email "admin@feelmagic.store"
    git config user.name "DXMT Admin"
fi

echo "Starting Dev Deployment at $TIMESTAMP" | tee -a "$LOG_FILE"

# 1. Pre-flight check
./deploy/ubuntu/dev_sanity_check.sh | tee -a "$LOG_FILE"

# 2. Restore missing Mailcow configs (idempotent)
./deploy/scripts/restore_mailcow_config.sh | tee -a "$LOG_FILE"

# 3. Load Environment Variables
echo "Loading environment variables..." | tee -a "$LOG_FILE"

# Load .env.dev
if [ -f .env.dev ]; then
    set -a
    source .env.dev
    set +a
fi

# Load mailcow.conf
if [ -f mailcow/mailcow.conf ]; then
    echo "Loading Mailcow configuration..." | tee -a "$LOG_FILE"
    while IFS= read -r line; do
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ -z "$line" ]] && continue
        if [[ "$line" =~ ^[A-Z_][A-Z0-9_]*= ]]; then
            export "$line"
        fi
    done < mailcow/mailcow.conf
fi

# Verify critical variables are set
if [ -z "$DBNAME" ] || [ -z "$DBPASS" ] || [ -z "$REDISPASS" ]; then
    echo "ERROR: Critical environment variables not loaded!" | tee -a "$LOG_FILE"
    exit 1
fi

# 4. Cleanup and Conflict Resolution
echo "Stopping existing containers..." | tee -a "$LOG_FILE"
docker compose -f docker-compose.dev.yml down 2>&1 | tee -a "$LOG_FILE" || true

echo "Cleaning up Docker resources..." | tee -a "$LOG_FILE"
# Remove any container with known prefixes or suffixes
for prefix in "dxmt-" "dxmtoffice-" "mailcowdockerized-" "mailcow-"; do
    docker ps -a --filter "name=$prefix" -q | xargs -r docker rm -f 2>&1 | tee -a "$LOG_FILE" || true
done

# Remove networks
for pref in "dxmtoffice_" "mailcowdockerized_" "mailcow-" "infrastructure_"; do
    docker network ls --filter "name=$pref" -q | xargs -r docker network rm 2>&1 | tee -a "$LOG_FILE" || true
done
docker network rm infrastructure_default 2>/dev/null || true

# 5. Host-Level Environment Recovery (DNS/Ports/Firewall)
echo "Ensuring host environment is ready..." | tee -a "$LOG_FILE"

# 5.1 Force DNS Fix (Aggressive)
echo "Configuring host DNS (8.8.8.8)..." | tee -a "$LOG_FILE"
systemctl stop systemd-resolved 2>/dev/null || true
systemctl disable systemd-resolved 2>/dev/null || true
rm -f /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 1.1.1.1" >> /etc/resolv.conf

# 5.2 Configure Firewall (UFW)
if command -v ufw >/dev/null; then
    echo "Configuring UFW..." | tee -a "$LOG_FILE"
    ufw --force enable || true
    for port in 80 443 25 465 587 110 143 993 995 4190 53 8080 8081 8082 3000; do
        ufw allow "$port"/tcp >/dev/null || true
    done
    ufw allow 53/udp >/dev/null || true
fi

# 5.3 Force Port Clearing (80, 443, 53, 8080, 8081, 8082, 3000)
echo "Killing any process on ports 80, 443, 53, 8080, 8081, 8082, 3000..." | tee -a "$LOG_FILE"
# First, find and kill containers publishing these ports (any project)
for port in 80 443 53 8080 8081 8082 3000; do
    CONTAINERS=$(docker ps -a --filter "publish=$port" -q)
    if [ -n "$CONTAINERS" ]; then
        echo "Removing container using port $port: $CONTAINERS" | tee -a "$LOG_FILE"
        docker rm -f $CONTAINERS || true
    fi
    # Use fuser as the primary host-process killer
    if command -v fuser >/dev/null; then
        fuser -k "$port"/tcp 2>/dev/null || true
        [ "$port" == "53" ] && fuser -k 53/udp 2>/dev/null || true
    fi
done
sleep 2

# 6. Final Data Cleanup
echo "Cleaning file artifacts..." | tee -a "$LOG_FILE"
find mailcow/data/conf -type d -empty -delete 2>/dev/null || true
for path in "mailcow/data/conf/unbound/unbound.conf" "mailcow/data/conf/redis/redis-conf.sh"; do
    [ -d "$path" ] && rm -rf "$path"
done

# 7. Start Services
echo "Deploying services fresh..." | tee -a "$LOG_FILE"
docker compose -f docker-compose.dev.yml up -d --build 2>&1 | tee -a "$LOG_FILE"

# 8. Healthcheck
echo "Verifying deployment..." | tee -a "$LOG_FILE"
./deploy/scripts/healthcheck.sh 2>&1 | tee -a "$LOG_FILE" || {
    echo "❌ Healthcheck FAILED. Gathering diagnostics..." | tee -a "$LOG_FILE"
    docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | tee -a "$LOG_FILE"
    exit 1
}

# 9. Log Archive
if [ "${GIT_PUSH_LOG:-true}" = "true" ]; then
    echo "Archiving logs..." | tee -a "$LOG_FILE"
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    if git checkout -B logs/dev-deploy-history; then
        cp "$LOG_FILE" deploy/logs/dev/latest-summary.log
        git add -f deploy/logs/dev/
        git commit -m "chore(log): dev deploy log $TIMESTAMP"
        git push origin logs/dev-deploy-history --force || true
        git checkout "$CURRENT_BRANCH"
    fi
fi

echo "Done. Deployment finished successfully." | tee -a "$LOG_FILE"
