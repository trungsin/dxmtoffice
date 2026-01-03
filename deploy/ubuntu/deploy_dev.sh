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

# Restore missing Mailcow configs (idempotent)
./deploy/scripts/restore_mailcow_config.sh | tee -a "$LOG_FILE"

# Load environment
if [ -f .env.dev ]; then
    export $(grep -v '^#' .env.dev | xargs)
fi

# Load Mailcow Environment
if [ -f mailcow/mailcow.conf ]; then
    echo "Loading Mailcow configuration..." | tee -a "$LOG_FILE"
    export $(grep -v '^#' mailcow/mailcow.conf | xargs)
fi

# Deploy services
echo "Deploying dev services..." | tee -a "$LOG_FILE"

# Step 1: Stop all containers first to prevent directory recreation
echo "Stopping existing containers..." | tee -a "$LOG_FILE"
docker compose -f docker-compose.dev.yml down 2>&1 | tee -a "$LOG_FILE" || true

# Step 2: Aggressive cleanup of Docker-created directories
echo "Cleaning Docker artifacts..." | tee -a "$LOG_FILE"
find mailcow/data/conf -type d -empty -delete 2>/dev/null || true

# Remove specific known problematic paths if they exist as directories
for path in \
    "mailcow/data/conf/unbound/unbound.conf" \
    "mailcow/data/conf/redis/redis-conf.sh" \
    "mailcow/data/conf/sogo/custom-favicon.ico" \
    "mailcow/data/conf/sogo/custom-fulllogo.svg" \
    "mailcow/data/conf/sogo/custom-fulllogo.png" \
    "mailcow/data/conf/sogo/custom-shortlogo.svg" \
    "mailcow/data/conf/sogo/custom-theme.js" \
    "mailcow/data/conf/sogo/custom-sogo.js"; do
    if [ -d "$path" ]; then
        echo "Removing bad directory: $path" | tee -a "$LOG_FILE"
        rm -rf "$path"
    fi
done

# Step 3: Re-run restore to ensure all files exist
./deploy/scripts/restore_mailcow_config.sh | tee -a "$LOG_FILE"

# Step 4: Now start containers
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
