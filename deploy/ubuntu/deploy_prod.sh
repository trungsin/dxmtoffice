#!/bin/bash
# deploy_prod.sh - Production deployment for Ubuntu VPS
set -e

# Load environment variables properly
echo "Loading environment variables..."

# Load .env.prod
if [ -f .env.prod ]; then
    set -a
    source .env.prod
    set +a
fi

# Load mailcow.conf (using robust grep + export method)
if [ -f mailcow/mailcow.conf ]; then
    echo "Loading Mailcow configuration..."
    while IFS= read -r line; do
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ -z "$line" ]] && continue
        if [[ "$line" =~ ^[A-Z_][A-Z0-9_]*= ]]; then
            export "$line"
        fi
    done < mailcow/mailcow.conf
fi

# Ensure log directories exist
mkdir -p deploy/logs/prod

echo "Starting Production Deployment..."

# Restore missing Mailcow configs
./deploy/scripts/restore_mailcow_config.sh

# Deploy services
echo "Deploying production services..."

# Step 1: Stop all containers
docker compose -f docker-compose.prod.yml down 2>/dev/null || true

# Step 2: Clean up old Docker resources
echo "Cleaning up Docker resources..."
docker ps -a --filter "name=dxmtoffice-" -q | xargs -r docker rm -f || true
docker ps -a --filter "name=mailcowdockerized-" -q | xargs -r docker rm -f || true

# Step 2.5: Handle host port conflicts (Port 53, 80, 443) and Firewall
echo "Ensuring host ports 53, 80, 443 are free and firewall is configured..."

# 1. Force DNS Fix
echo "Forcing host DNS to Google (8.8.8.8)..."
systemctl stop systemd-resolved 2>/dev/null || true
systemctl disable systemd-resolved 2>/dev/null || true
rm -f /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 1.1.1.1" >> /etc/resolv.conf

# 2. Open Firewall Ports (UFW)
if command -v ufw >/dev/null; then
    echo "Configuring UFW firewall..."
    ufw --force enable || true
    for port in 80 443 25 465 587 110 143 993 995 4190 53 8080 8081 8082 3000; do
        ufw allow "$port"/tcp || true
    done
    ufw allow 53/udp || true
fi

# 3. EXTREME Port Clearing (80, 443, 53)
echo "Killing any process or container on ports 80, 443, 53..."
for port in 80 443 53; do
    CONFLICT_CONTAINERS=$(docker ps -a --filter "publish=$port" -q)
    if [ -n "$CONFLICT_CONTAINERS" ]; then
        docker rm -f $CONFLICT_CONTAINERS || true
    fi
    if command -v ss >/dev/null; then
        PIDS=$(ss -tlpn "sport = :$port" | grep -oP 'pid=\K[0-9]+' | sort -u)
        [ -n "$PIDS" ] && echo "$PIDS" | xargs kill -9 2>/dev/null || true
    fi
    if command -v fuser >/dev/null; then
        fuser -k "$port"/tcp 2>/dev/null || true
        [ "$port" == "53" ] && fuser -k 53/udp 2>/dev/null || true
    fi
done
sleep 2

# Step 3: Start fresh
docker compose -f docker-compose.prod.yml up -d --build

# Healthcheck
./deploy/ubuntu/healthcheck.sh || {
    echo "Production Healthcheck FAILED. Triggering Rollback..."
    ./deploy/ubuntu/rollback.sh
    exit 1
}

echo "Production Deployment successful."
