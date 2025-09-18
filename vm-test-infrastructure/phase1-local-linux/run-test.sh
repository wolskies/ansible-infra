#!/bin/bash
# Phase I VM Testing Script
# Tests Debian 12 and Ubuntu 22.04 with features not available in containers

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

echo "=== Phase I VM Testing - Local Linux ==="
echo "Testing: Debian 12, Ubuntu 22.04"
echo "Features: hostname, locale, timezone, hardening, firewall"
echo ""

# Check prerequisites
command -v tofu >/dev/null 2>&1 || { echo "OpenTofu (tofu) is required but not installed. Aborting." >&2; exit 1; }
command -v ansible-playbook >/dev/null 2>&1 || { echo "Ansible is required but not installed. Aborting." >&2; exit 1; }
command -v virsh >/dev/null 2>&1 || { echo "libvirt (virsh) is required but not installed. Aborting." >&2; exit 1; }

cd "${SCRIPT_DIR}/terraform"

# Initialize OpenTofu
echo "Step 1: Initializing OpenTofu..."
tofu init

# Create VMs
echo "Step 2: Creating VMs with OpenTofu..."
tofu apply -auto-approve

# Wait for VMs to be ready
echo "Step 3: Waiting for VMs to be ready..."
echo "  Waiting for cloud-init to complete and SSH to start..."
sleep 90

# Test connectivity with retries
echo "Step 4: Testing VM connectivity..."
for i in {1..5}; do
    echo "  Attempt $i/5..."
    if ansible all -i inventory.ini -m ping; then
        echo "✅ All VMs responding"
        break
    else
        if [ $i -lt 5 ]; then
            echo "  Some VMs not ready, waiting 30s..."
            sleep 30
        else
            echo "❌ VMs not responding after 5 attempts"
            echo "  Check VM status: sudo virsh list --all"
            exit 1
        fi
    fi
done

# Run configure_system playbook
echo "Step 5: Running configure_system playbook..."
ansible-playbook -i inventory.ini \
  "${PROJECT_ROOT}/playbooks/configure_system.yml" \
  --extra-vars "@${SCRIPT_DIR}/test-scenarios/confidence-test.yml"

# Run validation
echo "Step 6: Running validation playbook..."
ansible-playbook -i inventory.ini \
  "${PROJECT_ROOT}/playbooks/validate_vm_configuration.yml" \
  --extra-vars "test_scenario_file=${SCRIPT_DIR}/test-scenarios/confidence-test.yml"

echo ""
echo "=== Phase I Testing Complete ==="
echo "Validation results saved to /tmp/validation_results_*.yml"
echo ""
echo "To destroy VMs, run: cd terraform && tofu destroy"
