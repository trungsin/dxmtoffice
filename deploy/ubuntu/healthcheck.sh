#!/bin/bash
# healthcheck.sh - Verify system health

echo "--- DXMT Healthcheck ---"

# Check Exposed Ports (Public)
EXPOSED_PORTS=(80 443 25 587 993 3000)
for PORT in "${EXPOSED_PORTS[@]}"; do
  if nc -z localhost $PORT 2>/dev/null; then
    echo "✅ Port $PORT (Public) is OPEN"
  else
    echo "❌ Port $PORT (Public) is CLOSED"
  fi
done

# Check Internal Dev Ports (Mapped for local testing)
INTERNAL_PORTS=(8080 8081 8082)
for PORT in "${INTERNAL_PORTS[@]}"; do
  if nc -z localhost $PORT 2>/dev/null; then
    echo "✅ Port $PORT (Internal) is UP"
  else
    echo "⚠️  Port $PORT (Internal) is DOWN (Check Nginx Proxy)"
  fi
done

# Check Container Health
SERVICES=("dxmt-ai-service" "nginx-proxy-manager" "mailcow-dockerized-nginx-mailcow-1")
for SVC in "${SERVICES[@]}"; do
  if docker ps | grep -q "$SVC"; then
    echo "✅ Service $SVC is RUNNING"
  else
    echo "❌ Service $SVC is NOT DETECTED"
  fi
done

echo "-----------------------"
