# Phase III VM Testing Implementation Plan

## Overview
VM testing complements our container-based CI by testing on bare metal/VMs with full OS capabilities that containers can't provide.

## Test Objectives

### Primary Goals
1. **Multi-OS coverage beyond CI** - Test Debian 12, Ubuntu 22.04 (CI only tests Ubuntu 24.04 and Arch)
2. **Container limitations** - Test features currently skipped: hostname, locale, timezone, system hardening
3. **End-to-end validation** - Run configure_system → discovery → validate output matches input

### Additional Capabilities (from container limitations)
- System-level configs: hostname changes, locale/timezone, system hardening, hosts file updates
- Service/daemon testing: SSH hardening, systemd services, firewall rules, cron jobs

## OS Coverage Matrix

| OS | Versions | Host | Special Requirements |
|---|---|---|---|
| Debian | 12 (bookworm), 13 (trixie) | libvirt | Debian 12 needs pre-installed rustup |
| Ubuntu | 22.04 (jammy), 24.04 (noble) | libvirt | - |
| Arch Linux | latest | libvirt | - |
| macOS | latest | macOS host | Separate Terraform provider |

**Design Philosophy**: Collection expects users to handle OS-specific prerequisites. We test that it works when prerequisites are met, not that it resolves all dependencies.

## Test Implementation Phases

### Phase I: Local Linux VMs (Foundation)
**Goal**: Validate older Debian/Ubuntu versions locally, establish VM testing foundation
- **Scope**: Debian 12, Ubuntu 22.04 on local libvirt
- **Purpose**: Close CI coverage gaps, validate VM testing approach
- **Infrastructure**: Local libvirt host
- Essentially mimics CI but with real VMs and older OS versions

### Phase II: Remote macOS Integration
**Goal**: Add remote VM capability, test macOS
- **Scope**: macOS latest on remote host
- **Purpose**: Validate macOS support, demonstrate remote VM management
- **Infrastructure**: Remote macOS host with appropriate virtualization
- Proves the collection works across different architectures

### Phase III: Comprehensive Validation
**Goal**: Full end-to-end testing across local and remote infrastructure
- **Scope**: All supported OS versions across multiple hosts
- **Purpose**: Complete validation using discovery as verification
- **Process**:
  1. Create robust host_vars/group_vars configuration
  2. Run configure_system to apply configuration
  3. Run discovery to scan configured system
  4. Validate discovery output matches input vars

## Variable Comparison Strategy (Graduation Test)

### Comparison Rules
- **Structural equivalence**: All configured items must be present
- **Allow extras**: Discovered vars can have MORE than configured (e.g., system packages)
- **Fail on missing**: Any MISSING configured items = test failure
- **Ignore dynamic values**: UIDs, timestamps, generated IDs

### Validation Examples
```yaml
# Input (host_vars)
packages:
  - git
  - neovim

# Discovery output (PASS - has required + extras)
packages:
  - git
  - neovim
  - base-system-package

# Discovery output (FAIL - missing required)
packages:
  - git
  # neovim missing!
```

## Infrastructure Architecture

### Directory Structure (Phased Approach)
```
vm-test-infrastructure/
├── phase1-local-linux/         # Phase I: Local Linux VMs
│   ├── terraform/
│   │   ├── main.tf            # Libvirt VM definitions
│   │   ├── variables.tf       # Debian 12, Ubuntu 22.04
│   │   ├── outputs.tf         # Dynamic inventory
│   │   └── cloud-init/
│   │       └── user-data.yml  # SSH keys, prerequisites
│   └── test-scenarios/
│       └── confidence-test.yml
├── phase2-remote-macos/        # Phase II: Remote macOS
│   ├── terraform/
│   │   ├── main.tf            # Remote provider config
│   │   └── variables.tf
│   └── test-scenarios/
│       └── macos-test.yml
└── phase3-comprehensive/       # Phase III: Full test suite
    ├── terraform/
    │   ├── local/             # Local libvirt resources
    │   └── remote/            # Remote resources
    └── test-scenarios/
        ├── group_vars/
        └── host_vars/
```

### Infrastructure Tools

#### IaC Tool: OpenTofu
- **Choice**: OpenTofu over Terraform
- **Rationale**: Open source (MPL 2.0), no licensing concerns, community-driven
- **Compatibility**: Drop-in replacement for Terraform code

#### Virtualization Platforms
- **Linux**: libvirt/KVM on local host
- **macOS**: Tart (uses Apple Virtualization.framework)
  - Native performance on Apple Silicon (M4)
  - Excellent CLI automation
  - Open source and free

#### Configuration Details
- **Networking**:
  - Linux: Bridged (br0) for direct SSH
  - macOS: Tart's default networking with port forwarding
- **Images**: Upstream cloud images (pristine state)
- **Cloud-init**: Minimal - SSH key + OS-specific prerequisites

## Validation Playbook Design

```yaml
# playbooks/validate_vm_configuration.yml
- name: Validate VM Configuration
  hosts: all
  tasks:
    1. Load original input vars (host_vars/group_vars)
    2. Run discovery role
    3. Compare discovered vs input:
       - Check all required items present
       - Generate diff report
       - Track missing/extra items
    4. Fail if any required items missing
    5. Generate summary report
```

## Testing Workflow

```bash
# Phase I: Local Linux Foundation Test
cd vm-test-infrastructure/phase1-local-linux/terraform
tofu init
tofu apply -auto-approve
cd ..
ansible-playbook -i terraform/inventory.ini \
  ../../playbooks/configure_system.yml \
  --extra-vars "@test-scenarios/confidence-test.yml"
ansible-playbook -i terraform/inventory.ini \
  ../../playbooks/validate_vm_configuration.yml

# Phase II: Remote macOS Test (using Tart)
cd vm-test-infrastructure/phase2-remote-macos
# Tart commands for VM management
tart create --from-oci ghcr.io/cirruslabs/macos-ventura-base:latest macos-test
tart run macos-test &
# Wait for VM to boot, then run Ansible
ansible-playbook -i inventory/macos.ini \
  ../../playbooks/configure_system.yml \
  --extra-vars "@test-scenarios/macos-test.yml"
ansible-playbook -i inventory/macos.ini \
  ../../playbooks/validate_vm_configuration.yml

# Phase III: Comprehensive Test
cd vm-test-infrastructure/phase3-comprehensive
# Configure both local and remote infrastructure
tofu -chdir=terraform/local init && tofu -chdir=terraform/local apply
# Remote macOS via Tart CLI over SSH
ssh m4-host "tart create --from-oci ghcr.io/cirruslabs/macos-ventura-base:latest macos-comprehensive"
# Run full validation suite
ansible-playbook -i inventory/combined.ini playbooks/configure_system.yml
ansible-playbook -i inventory/combined.ini playbooks/run-discovery.yml
ansible-playbook -i inventory/combined.ini playbooks/validate_vm_configuration.yml
```

## CI Integration
- **Initial approach**: Local-only testing for flexibility
- **Future**: Could add as manual GitLab CI job once stable

## Implementation Order

### Phase I: Local Linux (Immediate)
1. Create Terraform infrastructure for local libvirt (Debian 12, Ubuntu 22.04)
2. Implement confidence test scenarios
3. Create validation playbook
4. Test and validate approach

### Phase II: Remote macOS (After Phase I success)
1. Set up remote macOS host access
2. Create Terraform configuration for remote provider
3. Adapt test scenarios for macOS
4. Validate cross-architecture functionality

### Phase III: Comprehensive (After Phase I & II)
1. Combine local and remote infrastructure
2. Create comprehensive test scenarios
3. Full end-to-end validation with discovery
4. Document results and refine

## Notes and Decisions
- Keep VM testing separate from CI initially
- Focus on validating collection functionality, not OS behavior
- Assume prerequisites are met (user's responsibility)
- Use discovery as the validation mechanism
