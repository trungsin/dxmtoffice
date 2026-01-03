#!/bin/bash
# factory_reset.sh - Wipe everything and start from scratch
set -e

echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "!!!             FACTORY RESET WARNING          !!!"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "This will PERMANENTLY DELETE:"
echo "1. All Emails and Mailcow settings"
echo "2. All Nginx Proxy Manager (NPM) hosts and SSL certs"
echo "3. All Nextcloud files and databases"
echo "4. All Docker images, volumes, and networks"
echo ""
read -p "Are you absolutely sure you want to proceed? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

echo "--- 1. Stopping and Removing all Project Containers & Volumes ---"
# Using -v to remove named volumes
docker compose -f docker-compose.prod.yml down -v --remove-orphans || true
docker compose -f docker-compose.dev.yml down -v --remove-orphans || true

echo "--- 2. Deep Cleaning Docker (Images, Cache, Networks) ---"
docker system prune -af --volumes

echo "--- 3. Wiping Persistent Data Directories on Host ---"
# NPM
echo "Cleaning NPM data..."
sudo rm -rf infrastructure/nginx/data
sudo rm -rf infrastructure/nginx/mysql
sudo rm -rf infrastructure/nginx/letsencrypt

# Mailcow
echo "Cleaning Mailcow data..."
# We keep the directory structure but remove the content that causes "missing or empty" checks to trigger
sudo rm -rf mailcow/data/assets/*
sudo rm -rf mailcow/data/web/*
sudo rm -rf mailcow/data/conf/unbound/unbound.conf
sudo rm -rf mailcow/data/conf/redis/redis-conf.sh

# Office
echo "Cleaning Office data..."
sudo rm -rf office/nextcloud_data
sudo rm -rf office/postgres_data

echo ""
echo "=================================================="
echo "✅ FACTORY RESET COMPLETE"
echo "=================================================="
echo "Your VPS is now in a 100% clean state."
echo "To start fresh, run:"
echo "  ./deploy/ubuntu/deploy_prod.sh"
echo "=================================================="
