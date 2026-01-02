#!/bin/bash
set -e

TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
LOG_FILE="deploy/logs/dev/deploy-$TIMESTAMP.log"

# Ensure log directories exist
mkdir -p deploy/logs/dev

# Git Identity Fix (for VPS deployments)
if [ -z "$(git config user.email)" ]; then
    echo "Configuring temporary git identity..."
    git config user.email "admin@feelmagic.store"
    git config user.name "DXMT Admin"
fi

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
# Log Management: Push to history branch (Optional)
if [ "${GIT_PUSH_LOG:-true}" = "true" ]; then
    echo "Archiving log to history branch..." | tee -a "$LOG_FILE"
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    
    # Try to checkout or creating branch
    if git checkout -B logs/dev-deploy-history; then
        cp "$LOG_FILE" deploy/logs/dev/latest-summary.log
        git add -f deploy/logs/dev/
        git commit -m "chore(log): dev deploy log $TIMESTAMP"
        
        # Non-blocking push
        if git push origin logs/dev-deploy-history --force; then
            echo "✅ Logs pushed to GitHub." | tee -a "$LOG_FILE"
        else
            echo "⚠️  Git push failed (Permission/Auth). Skipping log archive." | tee -a "$LOG_FILE"
        fi
        
        # Return to previous branch
        git checkout $CURRENT_BRANCH
    else
        echo "⚠️  Failed to switch git branch. Skipping log archive." | tee -a "$LOG_FILE"
    fi
else
    echo "Skipping log push (GIT_PUSH_LOG is disabled)." | tee -a "$LOG_FILE"
fi

echo "Dev Deployment completed successfully." | tee -a "$LOG_FILE"
