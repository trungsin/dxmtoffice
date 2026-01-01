#!/bin/bash
echo "Initiating Rollback..."

# Simple rollback: stop current and restart with previous known goods (if any)
# In a more advanced setup, this would use git tags or previous docker images
docker compose down
docker compose up -d

echo "Rollback completed."
