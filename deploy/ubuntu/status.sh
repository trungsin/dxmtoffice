#!/bin/bash
# status.sh - Integrated status check

echo "--- DXMT Office Status ---"
echo "Uptime: $(uptime -p)"
echo "Docker Containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo "Firewall Status:"
sudo ufw status | grep -E "80|443|25"
echo ""
echo "Memory Usage:"
free -h
echo ""
./deploy/ubuntu/healthcheck.sh
echo "--------------------------"
