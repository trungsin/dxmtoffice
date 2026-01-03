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

# Step 2.5: Handle host port conflicts (Port 53, 80, 443)
if [ -f /etc/systemd/resolved.conf ] && grep -q "DNSStubListener=yes" /etc/systemd/resolved.conf; then
    echo "Disabling systemd-resolved DNSStubListener..."
    sed -i 's/DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf || true
    systemctl restart systemd-resolved || true
fi

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
