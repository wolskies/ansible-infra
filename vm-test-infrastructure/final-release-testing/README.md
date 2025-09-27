# Final Release VM Testing Infrastructure

Comprehensive end-to-end validation for wolskies.infrastructure collection 1.2.0 release.

## Testing Strategy

**Goal**: Validate the collection works correctly on real VMs across supported platforms using proven configurations.

**Approach**:
1. **Provision VMs** - Fresh cloud images via Terraform/libvirt
2. **Deploy Collection** - Apply comprehensive configuration using proven variables
3. **Run Discovery** - Capture actual system state via discovery role
4. **Validate Results** - Compare discovery output against expected configuration

## Platform Matrix

Testing across core supported platforms:

| Platform | Version | Test Type | Purpose |
|----------|---------|-----------|---------|
| Ubuntu | 22.04 LTS | Server | Production baseline |
| Ubuntu | 24.04 LTS | Workstation | Current LTS + dev tools |
| Debian | 12 | Server | Debian ecosystem |
| Arch Linux | Current | Workstation | Rolling release + AUR |

## Test Scenarios

### Workstation Configuration
- **Target**: Development environment setup
- **Roles**: configure_user, nodejs, rust, go, neovim, terminal_config
- **Validation**: User accounts, development tools, terminal setup

### Server Configuration
- **Target**: Production server setup
- **Roles**: os_configuration, manage_packages, manage_security_services
- **Validation**: System hardening, firewall rules, services

### Mixed Configuration
- **Target**: Complete system (dev workstation + server capabilities)
- **Roles**: All roles combined
- **Validation**: Full integration testing

## Configuration Source

Uses **MASTER_REFERENCE_CONFIG.yml** as authoritative source for variable formats. This prevents the configuration mistakes found in previous VM testing phases.

## Validation Method

1. **Deploy**: Run collection playbooks against VMs
2. **Discover**: Execute discovery role to capture actual state
3. **Compare**: Automated comparison of discovery results vs expected configuration
4. **Report**: Generate test results and identify any discrepancies

## Quick Start

```bash
# Provision and test
./run-comprehensive-test.sh

# Clean up
./cleanup.sh
```

## Directory Structure

```
final-release-testing/
├── terraform/              # VM provisioning
├── test-scenarios/          # Configuration per scenario
├── validation/              # Discovery comparison scripts
├── run-comprehensive-test.sh
└── cleanup.sh
```
