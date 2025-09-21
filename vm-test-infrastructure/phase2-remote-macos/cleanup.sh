#!/bin/bash
# Cleanup Phase 2 macOS VMs

echo "=== Phase 2 macOS VM Cleanup ==="

# Destroy via Terraform
if [ -d terraform ]; then
    cd terraform
    tofu destroy -auto-approve 2>/dev/null || true
    rm -f vm_ip.txt inventory.ini
    cd ..
fi

# Manual cleanup on remote Mac (in case Terraform cleanup fails)
ssh ed@207.254.38.250 "/opt/homebrew/bin/tart stop sonoma-ansible-test 2>/dev/null || true"
ssh ed@207.254.38.250 "/opt/homebrew/bin/tart delete sonoma-ansible-test 2>/dev/null || true"

echo "✅ macOS VMs cleaned up"
echo ""
echo "=== Cleanup Complete ===="
