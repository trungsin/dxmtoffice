#!/bin/bash
# rollback.sh - Revert to previous stable state
echo "Initiating Rollback..."

# Simple rollback: stop current and restart with previous known goods
docker compose down
docker compose -f docker-compose.prod.yml up -d

echo "Rollback completed."
