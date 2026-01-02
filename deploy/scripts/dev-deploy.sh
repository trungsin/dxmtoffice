#!/bin/bash
set -e

TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
LOG_FILE="deploy/logs/dev/deploy-$TIMESTAMP.log"

echo "Starting Dev Deployment at $TIMESTAMP" | tee -a "$LOG_FILE"

# Load environment
if [ -f .env.dev ]; then
    export $(grep -v '^#' .env.dev | xargs)
fi

# Deploy infrastructure
echo "Deploying infrastructure..." | tee -a "$LOG_FILE"
{
    docker compose -f infrastructure/nginx/docker-compose.yml up -d
    docker compose -f infrastructure/mailcow/docker-compose.yml up -d
    docker compose -f infrastructure/nextcloud/docker-compose.yml up -d
} 2>&1 | tee -a "$LOG_FILE" || {
    echo "Deployment FAILED. Capturing error context..." | tee -a "$LOG_FILE"
    echo "# Latest Deployment Error ($TIMESTAMP)" > deploy/logs/ai-context/latest-error.md
    tail -n 20 "$LOG_FILE" >> deploy/logs/ai-context/latest-error.md
    exit 1
}

# Healthcheck
./deploy/scripts/healthcheck.sh 2>&1 | tee -a "$LOG_FILE" || {
    echo "Healthcheck FAILED. Capturing error context..." | tee -a "$LOG_FILE"
    echo "# Latest Healthcheck Error ($TIMESTAMP)" > deploy/logs/ai-context/latest-error.md
    ./deploy/scripts/healthcheck.sh >> deploy/logs/ai-context/latest-error.md
    exit 1
}

# Logging & Git push
if [ "$GIT_PUSH_LOG" = "true" ]; then
    echo "Pushing logs to git..." | tee -a "$LOG_FILE"
    cp "$LOG_FILE" deploy/logs/dev/system-summary.log
    git add deploy/logs/
    git commit -m "chore(log): dev deploy log $TIMESTAMP"
    git push origin main
fi

echo "Dev Deployment completed." | tee -a "$LOG_FILE"
