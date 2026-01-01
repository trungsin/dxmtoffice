#!/bin/bash
set -e

# Load environment
if [ -f .env.prod ]; then
    export $(cat .env.prod | xargs)
fi

echo "Starting Production Deployment..."

# Deploy with production compose
docker compose -f docker-compose.yml up -d

# Healthcheck
./deployment/scripts/healthcheck.sh

echo "Production Deployment completed."
