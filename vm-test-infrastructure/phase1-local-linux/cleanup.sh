#!/bin/bash
# Phase I VM Testing Cleanup Script
# Destroys VMs and cleans up resources

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Phase I VM Cleanup ==="
echo ""

cd "${SCRIPT_DIR}/terraform"

# Check if terraform state exists
if [ -f "terraform.tfstate" ]; then
    echo "Destroying VMs and resources..."
    tofu destroy -auto-approve
    echo "✅ VMs destroyed"
else
    echo "No terraform state found, checking for orphaned VMs..."

    # Check for and destroy any orphaned VMs
    for vm in debian12-test ubuntu2204-test; do
        if sudo virsh list --all | grep -q "$vm"; then
            echo "Found orphaned VM: $vm"
            sudo virsh destroy "$vm" 2>/dev/null || true
            sudo virsh undefine "$vm" --remove-all-storage 2>/dev/null || true
            echo "✅ Cleaned up $vm"
        fi
    done

    # Clean up storage pool if it exists
    if sudo virsh pool-list --all | grep -q "ansible_test_pool"; then
        echo "Cleaning up storage pool..."
        sudo virsh pool-destroy ansible_test_pool 2>/dev/null || true
        sudo virsh pool-undefine ansible_test_pool 2>/dev/null || true
        echo "✅ Storage pool cleaned"
    fi
fi

# Clean up any leftover files
echo "Cleaning up temporary files..."
rm -f inventory.ini
rm -f /tmp/validation_results_*.yml
rm -rf terraform/host_vars/  # Remove discovery-generated host_vars

echo ""
echo "=== Cleanup Complete ==="
echo "You can now run ./run-test.sh again"
