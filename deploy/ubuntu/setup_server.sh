#!/bin/bash
# setup_server.sh - Server optimization and Swap configuration

set -e

# Check for Swap
if [[ $(swapon --show | wc -l) -eq 0 ]]; then
    echo "Creating 2GB swap file..."
    sudo fallocate -l 2G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
fi

# Kernel tuning
echo "Tuning kernel for performance..."
sudo tee -a /etc/sysctl.conf <<EOF
vm.swappiness=10
vm.vfs_cache_pressure=50
net.core.somaxconn=1024
EOF
sudo sysctl -p

# Firewall setup
echo "Configuring firewall (UFW)..."
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 25/tcp
sudo ufw allow 587/tcp
sudo ufw allow 993/tcp
sudo ufw --force enable

echo "Server setup and optimization complete."
