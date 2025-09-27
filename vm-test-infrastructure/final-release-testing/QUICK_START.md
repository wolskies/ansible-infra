# Final Release Testing - Quick Start

Comprehensive end-to-end validation for the wolskies.infrastructure collection before v1.2.0 release.

## Prerequisites

```bash
# Install required tools
sudo apt install terraform libvirt-daemon-system qemu-kvm
# or
brew install terraform qemu libvirt

# Ensure your user is in libvirt group
sudo usermod -a -G libvirt $USER

# Generate SSH key if needed
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519
```

## Quick Test Run

```bash
# Run complete test suite
./run-comprehensive-test.sh

# View help
./run-comprehensive-test.sh --help
```

## What It Does

1. **Provisions 4 VMs** via Terraform:
   - `ubuntu2204-server` - Server configuration testing
   - `ubuntu2404-workstation` - Development environment testing
   - `debian12-server` - Debian server testing
   - `arch-workstation` - Arch development testing

2. **Deploys Configurations**:
   - **Servers**: os_configuration, manage_packages, manage_security_services, configure_user
   - **Workstations**: All roles including nodejs, rust, go, neovim, terminal_config

3. **Validates Results**:
   - Runs discovery role to capture actual system state
   - Compares discovery vs expected configuration
   - Generates comprehensive test report

## Test Scenarios

### Server Configuration
- System hardening (firewall, fail2ban)
- User management with SSH keys
- Package installation and services
- Hostname and timezone configuration

### Workstation Configuration
- Development toolchain (Node.js, Rust, Go)
- Editor setup (Neovim with configuration)
- Terminal emulator support
- User environment with dotfiles

## Expected Results

**Success Criteria:**
- All VMs provision successfully
- All roles deploy without errors
- Discovery captures expected configuration
- Validation report shows all tests passing

**Validation Checks:**
- ✅ Hostname/timezone configuration
- ✅ User account creation with correct groups
- ✅ Development tools installed and functional
- ✅ Security services enabled (servers only)
- ✅ Package management working correctly

## Cleanup

```bash
# Clean up all VMs and files
./cleanup.sh

# Force cleanup if stuck
./cleanup.sh --force
```

## Test Results

Results are saved in:
- `validation/reports/final-test-report.txt` - Comprehensive test summary
- `validation/discovery-results/` - Raw discovery data from each VM

## Troubleshooting

**VMs not accessible:**
```bash
# Check libvirt status
sudo systemctl status libvirtd

# Verify VM status
virsh list --all

# Check SSH connectivity manually
ssh -F ssh-config ed@<vm-ip>
```

**Deployment failures:**
```bash
# Check specific role deployment
ansible-playbook -i inventory/hosts.ini deploy-servers.yml --limit ubuntu2204-server -v

# Debug individual VM
ansible ubuntu2204-server -i inventory/hosts.ini -m setup
```

**Discovery issues:**
```bash
# Run discovery manually
ansible-playbook -i inventory/hosts.ini run-discovery.yml --limit ubuntu2204-server -v
```

## Integration with Development

This testing infrastructure validates the collection using the same proven variable formats from CI molecule tests, ensuring:

1. **Configuration consistency** - Same variables work in CI and real VMs
2. **Platform coverage** - Tests across Ubuntu, Debian, Arch Linux
3. **Scenario coverage** - Both server and workstation configurations
4. **End-to-end validation** - Full collection deployment + discovery verification

Perfect for final validation before v1.2.0 release!
