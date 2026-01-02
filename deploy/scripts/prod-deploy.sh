#!/bin/bash
set -e

# Load environment
if [ -f .env.prod ]; then
    export $(grep -v '^#' .env.prod | xargs)
fi

echo "Starting Production Deployment..."

# Deploy with production compose
docker compose -f docker-compose.yml up -d

# Healthcheck
./deploy/scripts/healthcheck.sh

echo "Production Deployment completed."
