#!/bin/bash
# Quick script to update VM IPs after they're provisioned

echo "Enter the new IPs for your VMs (press enter to keep current):"

# Function to update IP in molecule.yml
update_ip() {
    local hostname=$1
    local current_ip=$2

    read -p "$hostname (current: $current_ip): " new_ip

    if [ ! -z "$new_ip" ]; then
        sed -i "s/ansible_host: $current_ip/ansible_host: $new_ip/" molecule.yml
        echo "  Updated $hostname to $new_ip"
    fi
}

# Update each VM
update_ip "ws-arch" "192.168.100.127"
update_ip "ws-ubuntu" "192.168.100.231"
update_ip "ws-macos" "207.254.38.250"
update_ip "sv-debian" "192.168.100.204"
update_ip "sv-ubuntu" "192.168.100.205"

echo ""
echo "IPs updated in molecule.yml"
echo "Run 'molecule test -s vm_test' to test against the VMs"
