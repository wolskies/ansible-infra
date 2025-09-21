#!/bin/bash
# Phase 2 macOS VM Testing - Remote Mac with Tart

set -e

echo "=== Phase 2 VM Testing - Remote macOS ==="
echo "Target: Mac at 207.254.38.250"
echo "VM: macOS Sonoma via Tart"
echo ""

# Check SSH connectivity to Mac
echo "Step 1: Checking connection to remote Mac..."
if ssh -o ConnectTimeout=5 ed@207.254.38.250 "echo 'Mac connected'" > /dev/null 2>&1; then
    echo "✅ Remote Mac is accessible"
else
    echo "❌ Cannot connect to remote Mac"
    exit 1
fi

# Initialize and apply Terraform
echo "Step 2: Creating macOS VM with Tart..."
cd terraform
tofu init
tofu apply -auto-approve

# Extract VM IP
VM_IP=$(tofu output -json | jq -r '.vm_status.value.vm_ip')
echo "VM IP: $VM_IP"

# Wait for VM to be ready
echo "Step 3: Waiting for VM to be fully ready..."
for i in {1..10}; do
    if ssh -o ConnectTimeout=5 \
           -o StrictHostKeyChecking=no \
           -o UserKnownHostsFile=/dev/null \
           -o ProxyCommand="ssh -W %h:%p ed@207.254.38.250" \
           admin@"$VM_IP" "echo 'VM ready'" 2>/dev/null; then
        echo "✅ VM is accessible via SSH"
        break
    fi
    echo "  Attempt $i/10 - waiting 30s..."
    sleep 30
done

cd ..

# Run Ansible playbook
echo "Step 4: Configuring VM with Ansible..."
ansible-playbook -i terraform/inventory.ini \
  --extra-vars "@test-scenarios/macos-test.yml" \
  ../../playbooks/configure_system.yml

# Run discovery
echo "Step 5: Running discovery playbook..."
ansible-playbook -i terraform/inventory.ini \
  ../../playbooks/discovery.yml

# Validate configuration
echo "Step 6: Validating configuration..."
ansible-playbook -i terraform/inventory.ini \
  ../../playbooks/validate_vm_configuration.yml

echo ""
echo "=== Phase 2 Testing Complete ==="
echo "To destroy VM, run: cd terraform && tofu destroy"
