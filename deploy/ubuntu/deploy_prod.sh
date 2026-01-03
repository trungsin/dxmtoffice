#!/bin/bash
# deploy_prod.sh - Production deployment for Ubuntu VPS
set -e
set -o pipefail

TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
LOG_FILE="deploy/logs/prod/deploy-$TIMESTAMP.log"

# Ensure log directories exist
mkdir -p deploy/logs/prod

# 1. Load Environment Variables (Needed for cleanup and restoration)
echo "Loading environment variables..." | tee -a "$LOG_FILE"

# Set Project Name explicitly to avoid project-prefixed network conflicts
export COMPOSE_PROJECT_NAME=mailcowdockerized

# Load .env.prod
if [ -f .env.prod ]; then
    set -a
    source .env.prod
    set +a
fi

# Load mailcow.conf
if [ -f mailcow/mailcow.conf ]; then
    echo "Loading Mailcow configuration..." | tee -a "$LOG_FILE"
    set -a
    source mailcow/mailcow.conf
    set +a
fi

echo "Starting Production Deployment..." | tee -a "$LOG_FILE"

# 2. Cleanup and Conflict Resolution (CLEAN SLATE)
echo "Stopping existing containers..." | tee -a "$LOG_FILE"
docker compose -f docker-compose.prod.yml down 2>/dev/null || true

echo "Cleaning up Docker resources..." | tee -a "$LOG_FILE"
for prefix in "dxmt-" "dxmtoffice-" "mailcowdockerized-" "mailcow-"; do
    docker ps -a --filter "name=$prefix" -q | xargs -r docker rm -f 2>&1 | tee -a "$LOG_FILE" || true
done
for pref in "dxmtoffice_" "mailcowdockerized_" "mailcow-" "infrastructure_"; do
    docker network ls --filter "name=$pref" -q | xargs -r docker network rm 2>&1 | tee -a "$LOG_FILE" || true
done
docker network rm infrastructure_default 2>/dev/null || true

# 3. Host-Level Environment Recovery (DNS/Ports/Firewall)
echo "Ensuring host environment is ready..." | tee -a "$LOG_FILE"

# 3.1 Force DNS Fix
echo "Configuring host DNS (8.8.8.8)..." | tee -a "$LOG_FILE"
systemctl stop systemd-resolved 2>/dev/null || true
systemctl disable systemd-resolved 2>/dev/null || true
rm -f /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 1.1.1.1" >> /etc/resolv.conf

# 3.2 Configure Firewall (UFW)
if command -v ufw >/dev/null; then
    echo "Configuring UFW..." | tee -a "$LOG_FILE"
    ufw --force enable || true
    for port in 80 81 443 25 465 587 110 143 993 995 4190 53 8080 8081 8082 3000; do
        ufw allow "$port"/tcp >/dev/null || true
    done
    ufw allow 53/udp >/dev/null || true
fi

# 3.3 EXTREME Port Clearing
echo "Killing any process on ports 80, 443, 53, 25, 465, 587, 143, 993, 995, 8080, 8081, 8082, 3000..." | tee -a "$LOG_FILE"
for port in 80 443 53 25 465 587 143 993 995 8080 8081 8082 3000; do
    CONTAINERS=$(docker ps -a --filter "publish=$port" -q)
    [ -n "$CONTAINERS" ] && docker rm -f $CONTAINERS || true
    if command -v fuser >/dev/null; then
        fuser -k "$port"/tcp 2>/dev/null || true
        [ "$port" == "53" ] && fuser -k 53/udp 2>/dev/null || true
    fi
done
sleep 2

# 4. RESTORATION STEP (Must be after cleanup, right before startup)
echo "Cleaning file artifacts and PERFORMING RESTORATION..." | tee -a "$LOG_FILE"
for path in "mailcow/data/conf/unbound/unbound.conf" "mailcow/data/conf/redis/redis-conf.sh"; do
    if [ -e "$path" ]; then
        echo "Clearing $path to ensure correct restoration..." | tee -a "$LOG_FILE"
        rm -rf "$path"
    fi
done

# Now run the restoration script
./deploy/scripts/restore_mailcow_config.sh | tee -a "$LOG_FILE"

# 5. Start fresh
echo "Deploying production services..." | tee -a "$LOG_FILE"
docker compose -f docker-compose.prod.yml up -d --build 2>&1 | tee -a "$LOG_FILE"

# 6. Healthcheck
./deploy/ubuntu/healthcheck.sh || {
    echo "Production Healthcheck FAILED. Triggering Rollback..." | tee -a "$LOG_FILE"
    ./deploy/scripts/rollback.sh
    exit 1
}

echo "Production Deployment successful." | tee -a "$LOG_FILE"
