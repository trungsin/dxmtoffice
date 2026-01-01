#!/bin/bash
# dev-sanity-check.sh - Fast validation for Dev Environment

set -e

echo "--- DXMT Dev Sanity Check ---"

# 1. Check Env
if [ ! -f .env.dev ]; then
    echo "❌ .env.dev missing! Creating from example..."
    cp .env.example .env.dev
fi

# 2. Check Docker
if ! docker info &> /dev/null; then
    echo "❌ Docker not running!"
    exit 1
fi

# 3. Check AI Gateway (Local Test)
echo "Checking AI Gateway configuration..."
if grep -q "GEMINI_API_KEY=your" .env.dev; then
    echo "⚠️  Warning: Gemini API Key is still default. AI features will fail."
else
    echo "✅ AI Key appears configured."
fi

# 4. Check Container status (if running)
echo "Checking running services..."
SERVICES=("dxmt-ai-service" "nginx-proxy-manager" "mailcow-dockerized-nginx-mailcow-1")
for SVC in "${SERVICES[@]}"; do
    if docker ps | grep -q "$SVC"; then
        echo "✅ $SVC is running."
    else
        echo "⚠️  $SVC is NOT running."
    fi
done

echo "-----------------------------"
