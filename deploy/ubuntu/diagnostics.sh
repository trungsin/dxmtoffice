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

echo "Note: If 'Local Connection' works but you can't access from outside,"
echo "      then your Cloud Provider (e.g. DigitalOcean) is blocking the ports."
echo ""
check_local() {
    local port=$1
    local name=$2
    echo -n "Checking Local $name ($port): "
    if curl -s -o /dev/null --connect-timeout 2 "http://localhost:$port" 2>/dev/null; then
        echo "✅ RESPONDING"
    elif curl -k -s -o /dev/null --connect-timeout 2 "https://localhost:$port" 2>/dev/null; then
        echo "✅ RESPONDING (HTTPS)"
    else
        echo "❌ REFUSED (Local test)"
    fi
}

check_local 80 "HTTP"
check_local 81 "NPM Admin"
check_local 443 "HTTPS"
check_local 8080 "Mailcow UI"
echo ""

echo "=========================================="
echo "      DIAGNOSTICS COMPLETE"
echo "=========================================="
