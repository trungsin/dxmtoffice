#!/bin/bash
set -e

# Load environment
if [ -f .env.prod ]; then
    export $(cat .env.prod | xargs)
fi

echo "Starting Production Deployment..."

# Deploy with production compose
docker compose -f docker-compose.prod.yml up -d --build

# Healthcheck
./deploy/scripts/healthcheck.sh || {
    echo "Production Healthcheck FAILED. Triggering Rollback..."
    ./deploy/scripts/rollback.sh
    exit 1
}

echo "Production Deployment successful."
