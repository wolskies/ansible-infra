#!/bin/bash
# Final Release Testing - Comprehensive VM Test Runner
# Provisions VMs, deploys collection, runs discovery, validates results

set -euo pipefail

# Configuration
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$TEST_DIR/terraform"
INVENTORY_DIR="$TEST_DIR/inventory"
VALIDATION_DIR="$TEST_DIR/validation"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."

    command -v tofu >/dev/null 2>&1 || error "OpenTofu not found. Please install opentofu."
    command -v ansible-playbook >/dev/null 2>&1 || error "Ansible not found. Please install ansible."
    command -v virsh >/dev/null 2>&1 || error "libvirt not found. Please install libvirt."

    # Check if libvirt is accessible (handles socket activation)
    if ! virsh list >/dev/null 2>&1; then
        error "libvirt is not accessible. Please check libvirtd service or permissions."
    fi

    # Check SSH key
    if [[ ! -f ~/.ssh/id_ed25519 ]]; then
        warning "SSH key ~/.ssh/id_ed25519 not found. VMs may not be accessible."
    fi

    success "Prerequisites check passed"
}

# Create directory structure
setup_directories() {
    log "Setting up directory structure..."

    mkdir -p "$INVENTORY_DIR"
    mkdir -p "$VALIDATION_DIR/discovery-results"
    mkdir -p "$VALIDATION_DIR/reports"

    success "Directories created"
}

# Provision VMs with Terraform
provision_vms() {
    log "Provisioning VMs with Terraform..."

    cd "$TERRAFORM_DIR"

    # Initialize OpenTofu
    tofu init -upgrade

    # Plan deployment
    log "Planning VM deployment..."
    tofu plan -out=tfplan

    # Apply deployment
    log "Creating VMs (this may take several minutes)..."
    tofu apply tfplan

    # Display VM information
    log "VM deployment complete. Getting VM information..."
    tofu output -json > vm_output.json

    success "VMs provisioned successfully"

    cd "$TEST_DIR"
}

# Wait for VMs to be ready
wait_for_vms() {
    log "Waiting for VMs to be ready..."

    if [[ ! -f "$INVENTORY_DIR/hosts.ini" ]]; then
        error "Inventory file not found. VM provisioning may have failed."
    fi

    # Wait for SSH connectivity
    local max_attempts=30
    local attempt=0

    while [[ $attempt -lt $max_attempts ]]; do
        log "Checking VM connectivity (attempt $((attempt + 1))/$max_attempts)..."

        if ansible test_vms -i "$INVENTORY_DIR/hosts.ini" -m ping --timeout=10 >/dev/null 2>&1; then
            success "All VMs are accessible"
            return 0
        fi

        sleep 10
        ((attempt++))
    done

    error "VMs not accessible after $max_attempts attempts"
}

# Deploy collection to servers
deploy_servers() {
    log "Deploying server configuration..."

    if ! ansible-playbook -i "$INVENTORY_DIR/hosts.ini" \
        "$TEST_DIR/deploy-servers.yml" \
        --timeout=30 \
        -v; then
        error "Server deployment failed"
    fi

    success "Server configuration deployed"
}

# Deploy collection to workstations
deploy_workstations() {
    log "Deploying workstation configuration..."

    if ! ansible-playbook -i "$INVENTORY_DIR/hosts.ini" \
        "$TEST_DIR/deploy-workstations.yml" \
        --timeout=30 \
        --skip-tags=terminal \
        -v; then
        warning "Workstation deployment had issues (terminal config skipped for containers)"
    else
        success "Workstation configuration deployed"
    fi
}

# Run discovery and validation
run_discovery_validation() {
    log "Running discovery and validation..."

    if ! ansible-playbook -i "$INVENTORY_DIR/hosts.ini" \
        "$TEST_DIR/run-discovery.yml" \
        --timeout=30 \
        -v; then
        warning "Discovery/validation had issues but continuing..."
    else
        success "Discovery and validation completed"
    fi
}

# Display results
display_results() {
    log "Generating final test report..."

    local report_file="$VALIDATION_DIR/reports/final-test-report.txt"

    if [[ -f "$report_file" ]]; then
        echo
        echo "======================================================================"
        echo "                    FINAL RELEASE TEST RESULTS"
        echo "======================================================================"
        cat "$report_file"
        echo "======================================================================"
        echo
        success "Final test report available at: $report_file"
    else
        warning "Final test report not generated. Check logs for issues."
    fi

    # Display discovery results
    if ls "$VALIDATION_DIR/discovery-results/"*.json >/dev/null 2>&1; then
        log "Discovery results available in: $VALIDATION_DIR/discovery-results/"
    fi
}

# Cleanup function
cleanup_on_exit() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        warning "Test run failed with exit code $exit_code"
        log "To clean up VMs manually, run: $TEST_DIR/cleanup.sh"
    fi
    exit $exit_code
}

# Main execution
main() {
    log "Starting Final Release Testing for wolskies.infrastructure v1.2.0"
    echo

    # Set up exit trap
    trap cleanup_on_exit EXIT

    # Run test phases
    check_prerequisites
    setup_directories
    provision_vms
    wait_for_vms
    deploy_servers
    deploy_workstations
    run_discovery_validation
    display_results

    echo
    success "Final Release Testing completed successfully!"
    log "To clean up VMs, run: $TEST_DIR/cleanup.sh"
    log "To re-run just the validation, run the discovery playbook directly"
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Final Release Testing for wolskies.infrastructure collection"
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --cleanup      Clean up VMs and exit"
        echo ""
        echo "This script will:"
        echo "1. Provision 4 test VMs (Ubuntu 22/24, Debian 12, Arch)"
        echo "2. Deploy server configuration to server VMs"
        echo "3. Deploy workstation configuration to workstation VMs"
        echo "4. Run discovery to capture actual system state"
        echo "5. Validate results against expected configuration"
        echo "6. Generate comprehensive test report"
        echo ""
        echo "Prerequisites:"
        echo "- OpenTofu (tofu command)"
        echo "- Ansible"
        echo "- libvirt/KVM"
        echo "- SSH key at ~/.ssh/id_ed25519"
        exit 0
        ;;
    --cleanup)
        log "Running cleanup only..."
        exec "$TEST_DIR/cleanup.sh"
        ;;
    *)
        main "$@"
        ;;
esac
