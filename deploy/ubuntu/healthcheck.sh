#!/bin/bash
# healthcheck.sh - Unified Healthcheck with Diagnostics

echo "=========================================="
echo "      DXMT DEPLOYMENT HEALTHCHECK"
echo "=========================================="
date
echo ""

EXIT_CODE=0

# 1. Port Checks
echo "--- Checking Network Ports ---"
check_port() {
    local port=$1
    local name=$2
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null ; then
        echo "✅ $name ($port) is UP"
    else
        echo "❌ $name ($port) is DOWN"
        EXIT_CODE=1
    fi
}

check_port 80 "Nginx Proxy Manager"
check_port 81 "NPM Admin UI"
check_port 443 "SSL Gateway"
check_port 25 "Postfix (SMTP)"
check_port 587 "Submission (SMTP)"
check_port 143 "IMAP (Plain)"
check_port 993 "IMAP (Secure)"
check_port 465 "SMTP (SSL)"
check_port 995 "POP3 (Secure)"
check_port 8080 "Mailcow UI (Internal)"
check_port 8081 "Nextcloud (Internal)"
check_port 8082 "OnlyOffice (Internal)"
check_port 3000 "AI Service (Internal)"

echo ""

# 2. Container Status
echo "--- Container Status ---"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.State}}"
echo ""

# 3. Diagnostic Logs for Failed Containers
echo "--- Diagnostics for Unhealthy/Stopped Services ---"
FAILED_CONTAINERS=$(docker ps -a --filter "status=exited" --filter "status=dead" --filter "status=restarting" --format "{{.Names}}")

if [ -n "$FAILED_CONTAINERS" ]; then
    echo "⚠️ Detected non-running containers:"
    for container in $FAILED_CONTAINERS; do
        echo "------------------------------------------"
        echo "LOGS FOR: $container"
        docker logs --tail 30 "$container" 2>&1 | sed 's/^/  /'
        echo ""
        echo "INSPECT NETWORK FOR: $container"
        docker inspect "$container" --format '{{range .NetworkSettings.Networks}}{{.IPAddress}} ({{.NetworkID}}){{end}}' | sed 's/^/  /'
        echo "------------------------------------------"
    done
else
    echo "✅ All containers appear to be in expected states (running)."
fi

# 4. Shared Network Check
echo ""
echo "--- Infrastructure Network Check ---"
if docker network inspect infrastructure_default >/dev/null 2>&1; then
    echo "✅ infrastructure_default network exists."
    # Count members
    MEMBER_COUNT=$(docker network inspect infrastructure_default --format '{{len .Containers}}')
    echo "   Members: $MEMBER_COUNT containers"
else
    echo "❌ infrastructure_default network is MISSING!"
    EXIT_CODE=1
fi

echo ""
echo "=========================================="
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ HEALTHCHECK PASSED"
else
    echo "❌ HEALTHCHECK FAILED"
fi
echo "=========================================="

exit $EXIT_CODE
