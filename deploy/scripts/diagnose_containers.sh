#!/bin/bash
# VPS Container Diagnostic Helper
# Usage: ./diagnose_containers.sh

echo "=== Checking Docker Container Status ==="
docker ps -a | grep -E "(mailcow|dxmt|office)"

echo -e "\n=== Checking Unbound Container Logs ==="
UNBOUND=$(docker ps -a --filter "name=unbound-mailcow" --format "{{.Names}}" | head -n 1)
if [ -z "$UNBOUND" ]; then
    echo "Unbound container not found."
else
    docker logs "$UNBOUND" --tail 50
fi

echo -e "\n=== Checking Postfix Container Logs ==="
POSTFIX=$(docker ps -a --filter "name=postfix-mailcow" --format "{{.Names}}" | head -n 1)
if [ -z "$POSTFIX" ]; then
    echo "Postfix container not found."
else
    docker logs "$POSTFIX" --tail 50
fi

echo -e "\n=== Checking Nginx-Mailcow Container Logs ==="
NGINX=$(docker ps -a --filter "name=nginx-mailcow" --format "{{.Names}}" | head -n 1)
if [ -z "$NGINX" ]; then
    echo "Nginx-Mailcow container not found."
else
    docker logs "$NGINX" --tail 50
fi

echo -e "\n=== Checking Unbound Health Status ==="
if [ -n "$UNBOUND" ]; then
    docker inspect "$UNBOUND" --format='{{json .State.Health}}' 2>&1 || echo "Health check info not available"
fi
