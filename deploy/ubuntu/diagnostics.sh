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
sudo lsof -iTCP -sTCP:LISTEN -P -n | grep -E ":80|:443|:81|:22"
echo ""
echo "Netstat/SS check for 443:"
if command -v ss >/dev/null; then ss -tlnp | grep :443; elif command -v netstat >/dev/null; then netstat -tlnp | grep :443; fi
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

echo "--- 4.1 Docker Port Mappings (Focus: NPM) ---"
docker ps --filter "name=app" --format "table {{.Names}}\t{{.Ports}}"
echo ""

echo "--- 5. Key Configuration Files (Metadata Only) ---"
ls -la .env.prod .env.dev mailcow/mailcow.conf docker-compose.prod.yml docker-compose.dev.yml
echo ""

echo "--- 6. Public IP & DNS ---"
echo "Public IP: $(curl -s https://ifconfig.me || echo 'unknown')"
echo "DNS (resolv.conf):"
cat /etc/resolv.conf
echo ""

echo "--- 7. Cloud Firewall Detection Hints ---"
echo "Note: If 443 is UP in 'Listening ports' but TIMEOUT from outside,"
echo "      you MUST open it in your VPS provider's control panel."
echo "Diagnostic check (External connection test to 443):"
timeout 2 bash -c 'cat < /dev/tcp/127.0.0.1/443' && echo "✅ Local 443 is reachable" || echo "❌ Local 443 connection REFUSED"
echo ""

echo "=========================================="
echo "      DIAGNOSTICS COMPLETE"
echo "=========================================="
