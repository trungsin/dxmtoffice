#!/bin/bash
# healthcheck.sh - Verify system health

echo "--- DXMT Healthcheck ---"

# Check Ports
PORTS=(80 443 25 587 993 3000)
for PORT in "${PORTS[@]}"; do
  if nc -z localhost $PORT 2>/dev/null; then
    echo "✅ Port $PORT is OPEN"
  else
    echo "❌ Port $PORT is CLOSED"
  fi
done

# Check Services
SERVICES=("dxmt-ai-service" "nginx-proxy-manager")
for SVC in "${SERVICES[@]}"; do
  if docker ps | grep -q "$SVC"; then
    echo "✅ Service $SVC is RUNNING"
  else
    echo "❌ Service $SVC is DOWN"
  fi
done

echo "-----------------------"
