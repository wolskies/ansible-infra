#!/bin/bash
# Configure Arch Linux VM networking via systemd-networkd
# Args: $1=disk_path $2=ip_address $3=gateway

set -euo pipefail

DISK_PATH="$1"
IP_ADDRESS="$2"
GATEWAY="$3"

echo "Configuring network for Arch Linux at $DISK_PATH with IP $IP_ADDRESS"

# Use virt-customize to inject systemd-networkd configuration
sudo virt-customize -a "$DISK_PATH" \
  --write "/etc/systemd/network/20-wired.network:[Match]
Name=en*

[Network]
Address=$IP_ADDRESS/24
Gateway=$GATEWAY
DNS=192.168.100.1
DNS=8.8.8.8" \
  --run-command "systemctl enable systemd-networkd" \
  --run-command "systemctl enable systemd-resolved"

echo "Network configuration complete"
