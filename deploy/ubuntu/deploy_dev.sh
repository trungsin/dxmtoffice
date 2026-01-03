#!/bin/bash
set -e
set -o pipefail

TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
LOG_FILE="deploy/logs/dev/deploy-$TIMESTAMP.log"

# Ensure log directories exist
mkdir -p deploy/logs/dev

# 1. Setup Logging Redirection
exec > >(tee -i "$LOG_FILE") 2>&1

echo "Starting Dev Deployment at $(date)"
echo "Log file: $LOG_FILE"
echo ""

# Function to run on error
on_error() {
    echo ""
    echo "❌ ERROR DETECTED! Running diagnostics..."
    chmod +x ./deploy/ubuntu/diagnostics.sh
    ./deploy/ubuntu/diagnostics.sh
    echo "❌ Deployment failed. Check the logs above."
    # Optional: could push logs here too
    exit 1
}

trap on_error ERR

# Git Identity Fix (for VPS deployments)
if [ -z "$(git config user.email)" ]; then
    echo "Configuring temporary git identity..."
    git config user.email "admin@feelmagic.store"
    git config user.name "DXMT Admin"
fi

echo "Starting Dev Deployment at $TIMESTAMP" | tee -a "$LOG_FILE"

# 1. Pre-flight check
./deploy/ubuntu/dev_sanity_check.sh | tee -a "$LOG_FILE"

# 2. Load Environment Variables (Needed for cleanup and restoration)
echo "Loading environment variables..." | tee -a "$LOG_FILE"

# Set Project Name explicitly to avoid project-prefixed network conflicts
export COMPOSE_PROJECT_NAME=mailcowdockerized

# Load .env.dev
if [ -f .env.dev ]; then
    set -a
    source .env.dev
    set +a
fi

# Load mailcow.conf
if [ -f mailcow/mailcow.conf ]; then
    echo "Loading Mailcow configuration..." | tee -a "$LOG_FILE"
    set -a
    source mailcow/mailcow.conf
    set +a
fi

# Verify critical variables are set
if [ -z "$DBNAME" ] || [ -z "$DBPASS" ] || [ -z "$REDISPASS" ]; then
    echo "ERROR: Critical environment variables not loaded!" | tee -a "$LOG_FILE"
    exit 1
fi

# 3. Cleanup and Conflict Resolution (CLEAN SLATE)
echo "Stopping existing containers..." | tee -a "$LOG_FILE"
docker compose -f docker-compose.dev.yml down 2>&1 | tee -a "$LOG_FILE" || true

echo "Cleaning up Docker resources (Aggressive)..." | tee -a "$LOG_FILE"
# Remove any container with known prefixes (including legacy and standalone ones)
for prefix in "dxmt-" "dxmtoffice-" "mailcowdockerized-" "mailcow-" "onemail-" "office-" "infrastructure-" "valentine-" "nginx-"; do
    docker ps -a --filter "name=$prefix" -q | xargs -r docker rm -f 2>&1 | tee -a "$LOG_FILE" || true
done

# Remove networks
for pref in "dxmtoffice_" "mailcowdockerized_" "mailcow-" "infrastructure_" "onemail_" "office_" "valentine_" "nginx_"; do
    docker network ls --filter "name=$pref" -q | xargs -r docker network rm 2>&1 | tee -a "$LOG_FILE" || true
done

docker network prune -f 2>&1 | tee -a "$LOG_FILE" || true

echo "Ensuring shared infrastructure network exists..." | tee -a "$LOG_FILE"
docker network rm infrastructure_default 2>/dev/null || true
docker network create --subnet 172.29.1.0/24 infrastructure_default | tee -a "$LOG_FILE"

# 4. Host-Level Environment Recovery (DNS/Ports/Firewall)
echo "Ensuring host environment is ready..." | tee -a "$LOG_FILE"

# 4.1 Force DNS Fix (Aggressive)
echo "Configuring host DNS (8.8.8.8)..." | tee -a "$LOG_FILE"
systemctl stop systemd-resolved 2>/dev/null || true
systemctl disable systemd-resolved 2>/dev/null || true
rm -f /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 1.1.1.1" >> /etc/resolv.conf

# 4.2 Configure Firewall (UFW)
if command -v ufw >/dev/null; then
    echo "Configuring UFW..." | tee -a "$LOG_FILE"
    ufw --force enable || true
    for port in 80 81 443 25 465 587 110 143 993 995 4190 53 8080 8081 8082 3000; do
        ufw allow "$port"/tcp >/dev/null || true
    done
    ufw allow 53/udp >/dev/null || true
fi

# 4.3 Force Port Clearing (Standard + Mail Ports)
echo "Killing any process on ports 80, 443, 53, 25, 465, 587, 143, 993, 995, 8080-8082, 3000..." | tee -a "$LOG_FILE"
for port in 80 443 53 25 465 587 143 993 995 8080 8081 8082 3000; do
    CONTAINERS=$(docker ps -a --filter "publish=$port" -q)
    if [ -n "$CONTAINERS" ]; then
        echo "Removing container using port $port: $CONTAINERS" | tee -a "$LOG_FILE"
        docker rm -f $CONTAINERS || true
    fi
    if command -v fuser >/dev/null; then
        fuser -k "$port"/tcp 2>/dev/null || true
        [ "$port" == "53" ] && fuser -k 53/udp 2>/dev/null || true
    fi
done
sleep 2

# 5. RESTORATION STEP (Must be after cleanup, right before startup)
# This prevents Docker from creating directories where files should be
echo "Cleaning file artifacts and PERFORMING RESTORATION..." | tee -a "$LOG_FILE"
# Force-remove specific problematic paths
for path in "mailcow/data/conf/unbound/unbound.conf" "mailcow/data/conf/redis/redis-conf.sh"; do
    if [ -e "$path" ]; then
        echo "Clearing $path to ensure correct restoration..." | tee -a "$LOG_FILE"
        rm -rf "$path"
    fi
done

# Now run the restoration script
./deploy/scripts/restore_mailcow_config.sh | tee -a "$LOG_FILE"

# 6. Start Services
echo "Deploying services fresh..." | tee -a "$LOG_FILE"
docker compose -f docker-compose.dev.yml up -d --build 2>&1 | tee -a "$LOG_FILE"

# 7. Healthcheck
echo "Verifying deployment..."
./deploy/ubuntu/healthcheck.sh || {
    echo "❌ Healthcheck FAILED. Running diagnostics..."
    chmod +x ./deploy/ubuntu/diagnostics.sh
    ./deploy/ubuntu/diagnostics.sh
    exit 1
}

# 8. Log Archive
# (Removing the heavy log archive push for now to avoid complexity during debug)

echo ""
echo "=========================================="
echo "✅ Dev Deployment finished successfully."
echo "=========================================="
