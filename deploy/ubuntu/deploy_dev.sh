#!/bin/bash
set -e
set -o pipefail

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

# Load environment variables properly
echo "Loading environment variables..." | tee -a "$LOG_FILE"

# Load .env.dev
if [ -f .env.dev ]; then
    set -a
    source .env.dev
    set +a
fi

# Generate mailcow.conf if it doesn't exist
if [ ! -f mailcow/mailcow.conf ]; then
    echo "⚠️  mailcow.conf not found, generating..." | tee -a "$LOG_FILE"
    
    # Save current directory
    ORIGINAL_DIR=$(pwd)
    
    # Run generate script from mailcow directory
    cd mailcow || { echo "ERROR: Cannot cd to mailcow/"; exit 1; }
    
    if [ -f generate_config.sh ]; then
        # Run with ./generate_config.sh instead of bash to preserve script context
        ./generate_config.sh || {
            cd "$ORIGINAL_DIR"
            echo "ERROR: generate_config.sh failed!" | tee -a "$LOG_FILE"
            exit 1
        }
        cd "$ORIGINAL_DIR"
        echo "✅ mailcow.conf generated" | tee -a "$LOG_FILE"
    else
        cd "$ORIGINAL_DIR"
        echo "ERROR: Cannot generate mailcow.conf - generate_config.sh not found!" | tee -a "$LOG_FILE"
        exit 1
    fi
fi

# Load mailcow.conf (using robust grep + export method)
if [ -f mailcow/mailcow.conf ]; then
    echo "Loading Mailcow configuration..." | tee -a "$LOG_FILE"
    
    # Extract only valid KEY=VALUE lines and export them
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ -z "$line" ]] && continue
        
        # Only process lines with KEY=VALUE format
        if [[ "$line" =~ ^[A-Z_][A-Z0-9_]*= ]]; then
            export "$line"
        fi
    done < mailcow/mailcow.conf
    
    echo "Loaded env vars from mailcow.conf" | tee -a "$LOG_FILE"
fi

# Verify critical variables are set
if [ -z "$DBNAME" ] || [ -z "$DBPASS" ] || [ -z "$REDISPASS" ]; then
    echo "ERROR: Critical environment variables not loaded!" | tee -a "$LOG_FILE"
    echo "DBNAME='$DBNAME', DBPASS='$DBPASS', REDISPASS='$REDISPASS'" | tee -a "$LOG_FILE"
    
    # Debug: show what's in mailcow.conf
    echo "=== Debugging mailcow.conf ===" | tee -a "$LOG_FILE"
    grep -E "^(DBNAME|DBPASS|REDISPASS)=" mailcow/mailcow.conf | tee -a "$LOG_FILE"
    
    exit 1
fi

# Deploy services
echo "Deploying dev services..." | tee -a "$LOG_FILE"

# Step 1: Stop all containers first to prevent directory recreation
echo "Stopping existing containers..." | tee -a "$LOG_FILE"
docker compose -f docker-compose.dev.yml down 2>&1 | tee -a "$LOG_FILE" || true

# Step 2: Clean up old Docker resources to prevent network conflicts
echo "Cleaning up old Docker networks and containers..." | tee -a "$LOG_FILE"

# Remove old project containers (all potential prefixes)
docker ps -a --filter "name=dxmtoffice-" -q | xargs -r docker rm -f 2>&1 | tee -a "$LOG_FILE" || true
docker ps -a --filter "name=dxmt-" -q | xargs -r docker rm -f 2>&1 | tee -a "$LOG_FILE" || true
docker ps -a --filter "name=mailcowdockerized-" -q | xargs -r docker rm -f 2>&1 | tee -a "$LOG_FILE" || true
docker ps -a --filter "name=mailcow-" -q | xargs -r docker rm -f 2>&1 | tee -a "$LOG_FILE" || true

# Remove old project networks  
docker network ls --filter "name=dxmtoffice_" -q | xargs -r docker network rm 2>&1 | tee -a "$LOG_FILE" || true
docker network ls --filter "name=mailcowdockerized_" -q | xargs -r docker network rm 2>&1 | tee -a "$LOG_FILE" || true
docker network ls --filter "name=mailcow-" -q | xargs -r docker network rm 2>&1 | tee -a "$LOG_FILE" || true

# Step 2.5: Handle host port conflicts (Port 53, 80, 443)
echo "Ensuring host ports 53, 80, 443 are free..." | tee -a "$LOG_FILE"

# Port 53 (Unbound)
if [ -f /etc/systemd/resolved.conf ] && grep -q "DNSStubListener=yes" /etc/systemd/resolved.conf 2>/dev/null; then
    echo "Disabling systemd-resolved DNSStubListener..." | tee -a "$LOG_FILE"
    sed -i 's/#DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf || true
    sed -i 's/DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf || true
    systemctl restart systemd-resolved || true
fi

# Port 80/443 (NPM)
if command -v lsof >/dev/null; then
    if lsof -Pi :80,443 -sTCP:LISTEN -t >/dev/null ; then
        echo "Found host processes on port 80/443. Stopping them..." | tee -a "$LOG_FILE"
        systemctl stop nginx apache2 2>/dev/null || true
        # Kill if still there
        fuser -k 80/tcp 443/tcp 2>/dev/null || true
    fi
fi

# Step 3: Aggressive cleanup of Docker-created directories
echo "Cleaning Docker file artifacts..." | tee -a "$LOG_FILE"
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

# Step 4: Now start containers (restore already ran earlier)
docker compose -f docker-compose.dev.yml up -d --build 2>&1 | tee -a "$LOG_FILE"

# Healthcheck
./deploy/scripts/healthcheck.sh 2>&1 | tee -a "$LOG_FILE" || {
    echo "❌ Healthcheck FAILED. Gathering diagnostics..." | tee -a "$LOG_FILE"
    
    echo "=== Current Docker Networks ===" | tee -a "$LOG_FILE"
    docker network ls --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}" | tee -a "$LOG_FILE"
    
    echo "=== Network Subnets ===" | tee -a "$LOG_FILE"
    docker network ls -q | xargs docker network inspect --format '{{.Name}}: {{range .IPAM.Config}}{{.Subnet}}{{end}}' | tee -a "$LOG_FILE"
    
    echo "=== Container Status ===" | tee -a "$LOG_FILE"
    docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | tee -a "$LOG_FILE"

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
