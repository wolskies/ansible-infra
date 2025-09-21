#!/bin/bash
# Phase III: Expanded Linux VM Testing
# Tests version compatibility across Linux distributions

set -e

# Set collection path since we're running from inside the collection structure
export ANSIBLE_COLLECTIONS_PATH="/home/ed/Projects/ansible/collections:/home/ed/.ansible/collections"

echo "=== Phase III: Expanded Linux VM Testing ==="
echo "Testing: Arch, Debian 12+13, Ubuntu 22+24"
echo "Focus: Version compatibility and edge cases"
echo ""

echo "Infrastructure:"
echo "  Local:  5 VMs (3 workstations + 2 servers) all on br0 bridge"
echo "  Static IPs: 192.168.100.61-65"
echo ""

# Initialize and apply Terraform
echo "Step 1: Creating VMs with OpenTofu..."
cd terraform
tofu init
tofu apply -auto-approve

# Wait for VMs to be ready
echo "Step 2: Waiting for VMs to boot..."
sleep 30  # Give VMs time to boot

echo "  All VMs using static IPs on br0 bridge:"
echo "    Workstations: 192.168.100.61-63"
echo "    Servers: 192.168.100.64-65"

# Verify connectivity
echo "Step 3: Verifying VM connectivity..."
MAX_ATTEMPTS=10
for attempt in $(seq 1 $MAX_ATTEMPTS); do
    echo "  Attempt $attempt/$MAX_ATTEMPTS..."

    if ansible all -i inventory.ini -m ping --one-line > /dev/null 2>&1; then
        echo "✅ All VMs are accessible"
        break
    fi

    if [ $attempt -eq $MAX_ATTEMPTS ]; then
        echo "❌ VMs not ready after $MAX_ATTEMPTS attempts"
        echo "Final inventory:"
        cat inventory.ini
        exit 1
    fi

    sleep 15
done

cd ..

# Show VM status
echo "Step 4: VM Status Check..."
ansible all -i terraform/inventory.ini -m setup -a "filter=ansible_distribution*" --one-line

# Run Ansible playbook with hierarchical configuration
echo "Step 5: Configuring systems with hierarchical Ansible..."
# Create proper group_vars structure for Ansible's native precedence
mkdir -p terraform/group_vars
cp test-scenarios/all.yml terraform/group_vars/all.yml
cp test-scenarios/workstations.yml terraform/group_vars/workstations.yml
cp test-scenarios/servers.yml terraform/group_vars/servers.yml

# Copy host_vars if they exist
if [ -d test-scenarios/host_vars ]; then
  cp -r test-scenarios/host_vars terraform/
fi

# Clean up any discovery output directories to prevent variable precedence conflicts
echo "  Cleaning discovery output directories..."
rm -rf terraform/host_vars/*/

# Run playbook once - Ansible handles precedence automatically
ansible-playbook -i terraform/inventory.ini \
  ../../playbooks/configure_system.yml

# Run validation (which includes discovery internally)
echo "Step 6: Running validation playbook (includes discovery)..."
# Use Phase III-specific validation that reads from group_vars/host_vars
ansible-playbook -i terraform/inventory.ini \
  validate-phase3.yml

echo ""
echo "=== Phase III Testing Complete ==="
echo "Results:"
echo "  - VMs: 5 (3 workstations + 2 servers)"
echo "  - Distros: Arch, Debian 12+13, Ubuntu 22+24"
echo "  - Hierarchical config: all.yml → group_vars → host_vars"
echo "  - Validation: Results saved to /tmp/validation_results_*.yml"
echo ""
echo "To destroy VMs, run: cd terraform && tofu destroy"
