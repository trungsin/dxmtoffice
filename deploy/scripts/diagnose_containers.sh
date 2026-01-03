#!/bin/bash
# VPS Container Diagnostic Helper
# Usage: ./diagnose_containers.sh

echo "=== Checking Docker Container Status ==="
docker ps -a | grep -E "(mailcow|dxmt)"

echo -e "\n=== Checking Unbound Container Logs ==="
docker logs dxmtoffice-unbound-mailcow-1 --tail 50

echo -e "\n=== Checking Postfix Container Logs ==="
docker logs dxmtoffice-postfix-mailcow-1 --tail 50 2>&1 || echo "Postfix container not found or not started"

echo -e "\n=== Checking Nginx-Mailcow Container Logs ==="
docker logs dxmtoffice-nginx-mailcow-1 --tail 50 2>&1 || echo "Nginx-Mailcow container not found or not started"

echo -e "\n=== Checking Unbound Health Status ==="
docker inspect dxmtoffice-unbound-mailcow-1 --format='{{json .State.Health}}' 2>&1 || echo "Health check info not available"
