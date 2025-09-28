#!/bin/bash
# Final Release Testing - Cleanup Script
# Destroys all VMs and cleans up testing infrastructure

set -euo pipefail

# Configuration
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$TEST_DIR/terraform"

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
}

# Cleanup VMs with Terraform
cleanup_vms() {
    log "Cleaning up VMs with Terraform..."

    cd "$TERRAFORM_DIR"

    if [[ ! -f "terraform.tfstate" ]]; then
        warning "No OpenTofu state found. VMs may not exist."
        return 0
    fi

    # Show what will be destroyed
    log "Planning VM destruction..."
    if ! tofu plan -destroy -out=destroy.tfplan >/dev/null 2>&1; then
        warning "OpenTofu plan failed. Attempting direct destroy..."
        tofu destroy -auto-approve || warning "OpenTofu destroy had issues"
    else
        # Execute destruction
        log "Destroying VMs..."
        tofu apply destroy.tfplan || warning "Some VMs may not have been destroyed"
    fi

    # Clean up Terraform files
    if [[ -f "destroy.tfplan" ]]; then
        rm -f destroy.tfplan
    fi

    if [[ -f "tfplan" ]]; then
        rm -f tfplan
    fi

    if [[ -f "vm_output.json" ]]; then
        rm -f vm_output.json
    fi

    success "VM cleanup completed"

    cd "$TEST_DIR"
}

# Clean up generated files
cleanup_files() {
    log "Cleaning up generated files..."

    # Remove inventory files
    if [[ -d "inventory" ]]; then
        rm -rf inventory/
        log "Removed inventory directory"
    fi

    # Remove SSH config
    if [[ -f "ssh-config" ]]; then
        rm -f ssh-config
        log "Removed SSH config"
    fi

    # Archive validation results if they exist
    if [[ -d "validation/discovery-results" ]] && [[ -n "$(ls -A validation/discovery-results/ 2>/dev/null)" ]]; then
        local archive_name="test-results-$(date +%Y%m%d-%H%M%S).tar.gz"
        tar -czf "$archive_name" validation/ || warning "Failed to archive results"
        if [[ -f "$archive_name" ]]; then
            log "Archived validation results to: $archive_name"
        fi
    fi

    # Clean up validation working files
    if [[ -d "validation/discovery-results" ]]; then
        rm -rf validation/discovery-results/
        log "Cleaned discovery results"
    fi

    if [[ -d "validation/reports" ]]; then
        rm -rf validation/reports/
        log "Cleaned validation reports"
    fi

    success "File cleanup completed"
}

# Verify cleanup
verify_cleanup() {
    log "Verifying cleanup..."

    # Check for running VMs
    local vm_count=0
    if command -v virsh >/dev/null 2>&1; then
        vm_count=$(virsh list --name | grep -E "(ubuntu|debian|arch).*test" | wc -l || echo "0")
    fi

    if [[ $vm_count -gt 0 ]]; then
        warning "$vm_count test VMs may still be running"
        log "Check with: virsh list --all"
    else
        success "No test VMs found running"
    fi

    # Check for remaining files
    if [[ -f "inventory/hosts.ini" ]]; then
        warning "Inventory file still exists"
    fi

    if [[ -f "$TERRAFORM_DIR/terraform.tfstate" ]]; then
        local resources=$(grep -c '"instances"' "$TERRAFORM_DIR/terraform.tfstate" 2>/dev/null || echo "0")
        if [[ $resources -gt 0 ]]; then
            warning "OpenTofu state indicates $resources resources may still exist"
        fi
    fi
}

# Force cleanup for stuck resources
force_cleanup() {
    log "Performing force cleanup..."

    # Kill any VMs matching our naming pattern
    if command -v virsh >/dev/null 2>&1; then
        local test_vms=$(virsh list --name | grep -E "(ubuntu|debian|arch).*test" || true)
        if [[ -n "$test_vms" ]]; then
            while IFS= read -r vm; do
                log "Force destroying VM: $vm"
                virsh destroy "$vm" 2>/dev/null || true
                virsh undefine "$vm" --remove-all-storage 2>/dev/null || true
            done <<< "$test_vms"
        fi
    fi

    # Remove any remaining storage volumes
    if command -v virsh >/dev/null 2>&1; then
        local test_volumes=$(virsh vol-list default | grep -E "(ubuntu|debian|arch).*test" | awk '{print $1}' || true)
        if [[ -n "$test_volumes" ]]; then
            while IFS= read -r vol; do
                log "Removing volume: $vol"
                virsh vol-delete "$vol" default 2>/dev/null || true
            done <<< "$test_volumes"
        fi
    fi

    warning "Force cleanup completed - manual verification recommended"
}

# Main execution
main() {
    log "Starting cleanup of Final Release Testing infrastructure"
    echo

    case "${1:-}" in
        --force)
            log "Force cleanup mode enabled"
            force_cleanup
            ;;
        --help|-h)
            echo "Final Release Testing Cleanup"
            echo ""
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --help, -h     Show this help message"
            echo "  --force        Force cleanup of stuck resources"
            echo ""
            echo "This script will:"
            echo "1. Destroy all test VMs via OpenTofu"
            echo "2. Clean up generated configuration files"
            echo "3. Archive validation results"
            echo "4. Verify cleanup completion"
            exit 0
            ;;
        *)
            cleanup_vms
            cleanup_files
            verify_cleanup
            ;;
    esac

    echo
    success "Cleanup completed successfully!"
    log "All test VMs and generated files have been removed"
}

main "$@"
