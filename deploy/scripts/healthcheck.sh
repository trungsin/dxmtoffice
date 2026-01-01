#!/bin/bash

echo "Running Healthchecks..."

check_port() {
    local port=$1
    local name=$2
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null ; then
        echo "✅ $name ($port) is UP"
    else
        echo "❌ $name ($port) is DOWN"
    fi
}

check_port 80 "Nginx Proxy Manager"
check_port 443 "SSL Gateway"
check_port 25 "Postfix (SMTP)"
check_port 587 "Submission (SMTP)"
check_port 993 "IMAP (Secure)"
check_port 8080 "Mailcow UI (Internal)"
check_port 8081 "Nextcloud (Internal)"
check_port 8082 "OnlyOffice (Internal)"
