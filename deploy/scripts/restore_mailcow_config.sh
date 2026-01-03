#!/bin/bash
set -e

echo "Restoring Mailcow configuration files..."

# Base directory
CONF_DIR="mailcow/data/conf"

# 1. Unbound
mkdir -p "$CONF_DIR/unbound"
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
  local-zone: "mail.feelmagic.store." static
  local-data: "mail.feelmagic.store. IN A 127.0.0.1"
EOF

# 2. Redis
mkdir -p "$CONF_DIR/redis"
cat > "$CONF_DIR/redis/redis-conf.sh" <<EOF
#!/bin/sh
echo "bind 0.0.0.0" > /data/redis.conf
echo "requirepass \$REDISPASS" >> /data/redis.conf
exec redis-server /data/redis.conf
EOF
chmod +x "$CONF_DIR/redis/redis-conf.sh"

# 3. MySQL
mkdir -p "$CONF_DIR/mysql"
# Empty config is fine, folder must exist

# 4. ClamAV
mkdir -p "$CONF_DIR/clamav"

# 5. Postfix
mkdir -p "$CONF_DIR/postfix"

# 6. Dovecot
mkdir -p "$CONF_DIR/dovecot"
mkdir -p "$CONF_DIR/dovecot/auth"

# 7. Nginx
mkdir -p "$CONF_DIR/nginx"

# 8. PHP-FPM
mkdir -p "$CONF_DIR/phpfpm"

echo "Configuration files restored."
