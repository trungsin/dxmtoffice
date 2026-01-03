#!/bin/bash
# diagnostics.sh - System-wide diagnostics for troubleshooting

echo "=========================================="
echo "      DXMT SYSTEM DIAGNOSTICS"
echo "=========================================="
date
echo ""

echo "--- 1. System Information ---"
uname -a
uptime
echo ""
echo "--- 2. Resource Usage ---"
echo "memory:"
free -h
echo ""
echo "disk:"
df -h /
echo ""
echo "docker stats (one-shot):"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
echo ""

echo "--- 3. Network & Firewall ---"
if command -v ufw >/dev/null; then
    sudo ufw status verbose
fi
echo ""
echo "Listening ports (TCP):"
sudo lsof -iTCP -sTCP:LISTEN -P -n
echo ""

echo "--- 4. Docker Infrastructure ---"
echo "Networks:"
docker network ls
echo ""
for net in $(docker network ls --format "{{.Name}}"); do
    echo "Network: $net"
    docker network inspect "$net" --format '  Subnet: {{range .IPAM.Config}}{{.Subnet}}{{end}}'
    docker network inspect "$net" --format '  Containers: {{range .Containers}}{{.Name}} ({{.IPv4Address}}), {{end}}'
    echo ""
done

echo "--- 5. Key Configuration Files (Metadata Only) ---"
ls -la .env.prod .env.dev mailcow/mailcow.conf docker-compose.prod.yml docker-compose.dev.yml
echo ""

echo "--- 6. Public IP & DNS ---"
echo "Public IP: $(curl -s https://ifconfig.me || echo 'unknown')"
echo "DNS (resolv.conf):"
cat /etc/resolv.conf
echo ""

echo "=========================================="
echo "      DIAGNOSTICS COMPLETE"
echo "=========================================="
