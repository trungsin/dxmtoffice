#!/bin/bash
set -e

echo "Restoring Mailcow configuration files..."

# Base directory
CONF_DIR="mailcow/data/conf"

# Helper to ensure file destination is clean (Docker auto-creates dirs for missing files)
function cleanup_and_create() {
    local target="$1"
    local dir=$(dirname "$target")
    
    mkdir -p "$dir"
    
    # If target exists as a directory, it's a Docker artifact - remove it
    if [ -d "$target" ]; then
        echo "Removing incorrect directory at $target"
        rm -rf "$target"
    fi
}

# 0. Core Data Repair (Web/Assets)
if [ ! -d "$CONF_DIR/../web" ] || [ ! -d "$CONF_DIR/../assets" ]; then
    echo "⚠️  Missing core Mailcow data (web/assets). Attempting auto-repair..."
    TMP_DIR=$(mktemp -d)
    
    echo "Cloning core files from upstream..."
    git clone --depth 1 https://github.com/mailcow/mailcow-dockerized "$TMP_DIR"
    
    if [ ! -d "$CONF_DIR/../web" ]; then
        echo "Restoring data/web..."
        cp -r "$TMP_DIR/data/web" "$CONF_DIR/../"
    fi
    
    if [ ! -d "$CONF_DIR/../assets" ]; then
        echo "Restoring data/assets..."
        cp -r "$TMP_DIR/data/assets" "$CONF_DIR/../"
    fi
    
    rm -rf "$TMP_DIR"
    echo "✅ Core data restored."
fi

# 1. Unbound
cleanup_and_create "$CONF_DIR/unbound/unbound.conf"
cat > "$CONF_DIR/unbound/unbound.conf" <<EOF
server:
  verbosity: 1
  interface: 0.0.0.0
  port: 53
  do-ip4: yes
  do-udp: yes
  do-tcp: yes
  do-ip6: no
  access-control: 0.0.0.0/0 allow
  chroot: ""
  logfile: ""
  use-syslog: no
  hide-identity: yes
  hide-version: yes
EOF

# 2. Redis
cleanup_and_create "$CONF_DIR/redis/redis-conf.sh"
cat > "$CONF_DIR/redis/redis-conf.sh" <<EOF
#!/bin/sh
echo "bind 0.0.0.0" > /data/redis.conf
echo "requirepass \$REDISPASS" >> /data/redis.conf
exec redis-server /data/redis.conf
EOF
chmod +x "$CONF_DIR/redis/redis-conf.sh"

# 3. SOGo Assets (Prevent "not a directory" errors for these too)
SOGO_ASSETS=(
    "custom-favicon.ico"
    "custom-fulllogo.png"
    "custom-fulllogo.svg"
    "custom-shortlogo.svg"
    "custom-sogo.js"
    "custom-theme.js"
)
mkdir -p "$CONF_DIR/sogo"
for asset in "${SOGO_ASSETS[@]}"; do
    cleanup_and_create "$CONF_DIR/sogo/$asset"
    # Create empty touch file if not exists (git should rely on repo, but this is safety)
    if [ ! -f "$CONF_DIR/sogo/$asset" ]; then
        touch "$CONF_DIR/sogo/$asset"
    fi
done

# 4. MySQL
mkdir -p "$CONF_DIR/mysql"

# 5. ClamAV
mkdir -p "$CONF_DIR/clamav"

# 6. Postfix
mkdir -p "$CONF_DIR/postfix"

# 7. Dovecot
mkdir -p "$CONF_DIR/dovecot"
mkdir -p "$CONF_DIR/dovecot/auth"

# 8. Nginx
mkdir -p "$CONF_DIR/nginx"

# 9. PHP-FPM
mkdir -p "$CONF_DIR/phpfpm"

echo "Configuration files restored and cleaned."
