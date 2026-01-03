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
    ufw allow 80/tcp || true
    ufw allow 443/tcp || true
    ufw allow 25/tcp || true
    ufw allow 465/tcp || true
    ufw allow 587/tcp || true
    ufw allow 110/tcp || true
    ufw allow 143/tcp || true
    ufw allow 993/tcp || true
    ufw allow 995/tcp || true
    ufw allow 4190/tcp || true
    ufw allow 53/tcp || true
    ufw allow 53/udp || true
    ufw allow 8080/tcp || true
    ufw allow 8081/tcp || true
    ufw allow 8082/tcp || true
    ufw allow 3000/tcp || true
fi

# 3. Clear Port 80/443
if command -v lsof >/dev/null && lsof -Pi :80,443 -sTCP:LISTEN -t >/dev/null; then
    echo "Clearing port 80/443..."
    systemctl stop nginx apache2 2>/dev/null || true
    fuser -k 80/tcp 443/tcp 2>/dev/null || true
fi

# Step 3: Start fresh
docker compose -f docker-compose.prod.yml up -d --build

# Healthcheck
./deploy/ubuntu/healthcheck.sh || {
    echo "Production Healthcheck FAILED. Triggering Rollback..."
    ./deploy/ubuntu/rollback.sh
    exit 1
}

echo "Production Deployment successful."
