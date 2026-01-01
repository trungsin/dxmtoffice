#!/bin/bash
set -e

TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
LOG_FILE="deployment/logs/dev/deploy-$TIMESTAMP.log"

echo "Starting Dev Deployment at $TIMESTAMP" | tee -a "$LOG_FILE"

# Load environment
if [ -f .env.dev ]; then
    export $(cat .env.dev | xargs)
fi

# Deploy infrastructure
echo "Deploying infrastructure..." | tee -a "$LOG_FILE"
docker compose -f infrastructure/nginx/docker-compose.yml up -d 2>&1 | tee -a "$LOG_FILE"
docker compose -f infrastructure/mailcow/docker-compose.yml up -d 2>&1 | tee -a "$LOG_FILE"
docker compose -f infrastructure/nextcloud/docker-compose.yml up -d 2>&1 | tee -a "$LOG_FILE"

# Healthcheck
./deployment/scripts/healthcheck.sh 2>&1 | tee -a "$LOG_FILE"

# Logging & Git push
if [ "$GIT_PUSH_LOG" = "true" ]; then
    echo "Pushing logs to git..." | tee -a "$LOG_FILE"
    cp "$LOG_FILE" deployment/logs/dev/system-summary.log
    git add deployment/logs/dev/
    git commit -m "chore(log): dev deploy log $TIMESTAMP"
    git push origin main
fi

echo "Dev Deployment completed." | tee -a "$LOG_FILE"
