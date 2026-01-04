#!/bin/bash
# local_up.sh - Start infrastructure locally
set -e

echo "--- 1. Checking Dependencies ---"
if ! command -v docker &> /dev/null; then
    echo "Error: docker is not installed."
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "Error: Docker is not running. Please start Docker Desktop."
    exit 1
fi

echo "--- 2. Setting up Environment ---"
if [ ! -f ".env.dev" ]; then
    echo "Creating .env.dev from example..."
    cp .env.example .env.dev
fi

# Link to root if needed, but compose uses env_file usually. 
# Here we ensure current shell has access to some vars for compose interpretation if needed.
export $(grep -v '^#' .env.dev | xargs)

echo "--- 3. Resetting Local Infrastructure (Optional) ---"
# Uncomment if you want a fresh start locally every time
# docker compose -f docker-compose.dev.yml down -v --remove-orphans

echo "--- 4. Launching Local Services ---"
docker compose -f docker-compose.dev.yml up -d

echo ""
echo "=================================================="
echo "✅ LOCAL INFRASTRUCTURE IS STARTING"
echo "=================================================="
echo "1. Wait 1-2 minutes for all containers to stabilize."
echo "2. Access NPM Admin UI: http://localhost:81"
echo "3. (Requirement) Ensure your hosts file has the mappings from local/hosts_entries.txt"
echo "4. In NPM, Proxy Hosts will need to be configured manually for first-time setup."
echo "=================================================="
echo "To see diagnostic status run: ./deploy/ubuntu/healthcheck.sh"
echo "=================================================="
