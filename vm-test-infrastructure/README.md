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
- **Roles**: configure_users, nodejs, rust, go, neovim, terminal_config
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

Test scenarios in `test-scenarios/` are aligned with collection v1.2.0 SRD variable formats and role defaults. All variables match the current production role interfaces.

## Validation Method

1. **Deploy**: Run collection playbooks against VMs
2. **Discover**: Execute discovery role to capture actual state
3. **Compare**: Automated comparison of discovery results vs expected configuration
4. **Report**: Generate test results and identify any discrepancies

## Prerequisites

### Bridge Network Setup

VMs use bridged networking (br0) with static IPs for direct SSH access.

**Required**: Configure br0 bridge on host before provisioning VMs.

See **[BRIDGE_SETUP.md](BRIDGE_SETUP.md)** for detailed instructions.

Quick setup (Arch Linux with systemd-networkd):
```bash
# Create bridge with static IP 192.168.100.1/24
sudo tee /etc/systemd/network/10-br0.netdev << EOF
[NetDev]
Name=br0
Kind=bridge
EOF

sudo tee /etc/systemd/network/20-br0.network << EOF
[Match]
Name=br0

[Network]
Address=192.168.100.1/24
DHCPServer=yes
IPMasquerade=yes
IPForward=yes
EOF

sudo systemctl restart systemd-networkd
```

Verify bridge:
```bash
ip addr show br0  # Should show 192.168.100.1/24
```

## Quick Start

```bash
# 1. Set up br0 bridge (see BRIDGE_SETUP.md)

# 2. Provision VMs
cd terraform
terraform init
terraform apply

# 3. Run comprehensive tests
cd ..
./run-comprehensive-test.sh

# 4. Clean up
./cleanup.sh
```

## Directory Structure

```
vm-test-infrastructure/
├── terraform/               # VM provisioning (libvirt + cloud-init)
├── test-scenarios/          # Test configuration files
│   ├── server-config.yml    # Server test scenario
│   └── workstation-config.yml # Workstation test scenario
├── validation/              # Discovery comparison scripts
├── inventory/               # Generated Ansible inventory
├── run-comprehensive-test.sh # Full test workflow
└── cleanup.sh               # VM cleanup
```
