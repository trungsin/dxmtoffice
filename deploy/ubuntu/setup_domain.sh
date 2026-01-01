#!/bin/bash
# setup_domain.sh - Domain and SSL configuration

set -e

# Load environment
if [ -f .env.prod ]; then
    export $(grep -v '^#' .env.prod | xargs)
elif [ -f .env.dev ]; then
    export $(grep -v '^#' .env.dev | xargs)
fi

DOMAIN=${DOMAIN:-feelmagic.store}
EMAIL=${ADMIN_EMAIL:-admin@$DOMAIN}

echo "Requesting SSL for $DOMAIN and subdomains..."

# Use certbot for domains
sudo certbot certonly --standalone \
    -d $DOMAIN \
    -d mail.$DOMAIN \
    -d office.$DOMAIN \
    -d ai.$DOMAIN \
    -d api.$DOMAIN \
    --non-interactive --agree-tos -m $EMAIL

echo "SSL certificates configured. Remember to restart Nginx."
