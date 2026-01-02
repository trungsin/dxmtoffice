#!/bin/bash
set -e

TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
LOG_FILE="deploy/logs/dev/deploy-$TIMESTAMP.log"

# Ensure log directories exist
mkdir -p deploy/logs/dev

echo "Starting Dev Deployment at $TIMESTAMP" | tee -a "$LOG_FILE"

# Pre-flight check
./deploy/ubuntu/dev_sanity_check.sh | tee -a "$LOG_FILE"

# Load environment
if [ -f .env.dev ]; then
    export $(grep -v '^#' .env.dev | xargs)
fi

# Deploy services
echo "Deploying dev services..." | tee -a "$LOG_FILE"
docker compose -f docker-compose.dev.yml up -d --build 2>&1 | tee -a "$LOG_FILE"

# Healthcheck
./deploy/scripts/healthcheck.sh 2>&1 | tee -a "$LOG_FILE" || {
    echo "Healthcheck FAILED. Reverting..." | tee -a "$LOG_FILE"
    ./deploy/scripts/rollback.sh
    exit 1
}

# Log Management: Push to history branch
echo "Archiving log to history branch..." | tee -a "$LOG_FILE"
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
git checkout -B logs/dev-deploy-history
cp "$LOG_FILE" deploy/logs/dev/latest-summary.log
git add deploy/logs/dev/
git commit -m "chore(log): dev deploy log $TIMESTAMP"
git push origin logs/dev-deploy-history --force
git checkout $CURRENT_BRANCH

echo "Dev Deployment completed successfully." | tee -a "$LOG_FILE"
