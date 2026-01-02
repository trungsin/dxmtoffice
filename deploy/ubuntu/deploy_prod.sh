#!/bin/bash
# deploy_prod.sh - Production deployment for Ubuntu VPS
set -e

# Load environment
if [ -f .env.prod ]; then
    export $(grep -v '^#' .env.prod | xargs)
fi

echo "Starting Production Deployment..."

# Deploy with production compose
docker compose -f docker-compose.prod.yml up -d --build

# Healthcheck
./deploy/ubuntu/healthcheck.sh || {
    echo "Production Healthcheck FAILED. Triggering Rollback..."
    ./deploy/ubuntu/rollback.sh
    exit 1
}

echo "Production Deployment successful."
