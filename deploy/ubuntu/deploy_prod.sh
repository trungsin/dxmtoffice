#!/bin/bash
# deploy_prod.sh - Production deployment for Ubuntu VPS
set -e

# Load environment
if [ -f .env.prod ]; then
    export $(grep -v '^#' .env.prod | xargs)
fi

# Load Mailcow Environment
if [ -f mailcow/mailcow.conf ]; then
    echo "Loading Mailcow configuration..."
    export $(grep -v '^#' mailcow/mailcow.conf | xargs)
fi

# Ensure log directories exist
mkdir -p deploy/logs/prod

echo "Starting Production Deployment..."

# Restore missing Mailcow configs
./deploy/scripts/restore_mailcow_config.sh

# Deploy with production compose
docker compose -f docker-compose.prod.yml up -d --build

# Healthcheck
./deploy/ubuntu/healthcheck.sh || {
    echo "Production Healthcheck FAILED. Triggering Rollback..."
    ./deploy/ubuntu/rollback.sh
    exit 1
}

echo "Production Deployment successful."
