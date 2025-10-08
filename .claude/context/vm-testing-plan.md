# Phase III: VM Testing Infrastructure Plan

Comprehensive VM-based testing using Terraform + libvirt for true end-to-end validation.

## Overview

**Goal**: Validate the collection on bare cloud images across the full OS matrix, ensuring it works on realistic target environments.

**Infrastructure**: On-premise libvirt with Terraform IaC management
**Network**: Bridged networking (br0) for direct SSH access
**Access**: SSH as `ed` user with pre-loaded public key
**Images**: Upstream cloud images (minimal/bare - ideal test case for collection)

## VM Configuration Matrix

### Supported Operating Systems

```yaml
vm_targets:
  ubuntu2204:
    image: "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
    os_family: "Debian"
    python: "python3"

  ubuntu2404:
    image: "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
    os_family: "Debian"
    python: "python3"

  archlinux:
    image: "https://geo.mirror.pkgbuild.com/images/latest/Arch-Linux-x86_64-cloudimg.qcow2"
    os_family: "Archlinux"
    python: "python"

  # Future: macOS (licensing/technical challenges)
  # macOS virtualization requires:
  # - macOS host for legal compliance
  # - Virtualization.framework (macOS 11+)
  # - Special licensing considerations
```

**Why these distributions?**
- Ubuntu 22.04/24.04: Most common deployment targets, LTS releases
- Arch Linux: Rolling release, tests cutting-edge package versions
- Debian: Future expansion target
- macOS: Aspirational, blocked by licensing

### Test User Matrix

Complex user scenarios to validate user management features:

```yaml
test_users:
  # Standard developer with full toolchain
  devuser:
    shell: "/bin/bash"
    groups: ["sudo", "docker"]
    ssh_keys: ["ed25519_primary", "rsa_backup"]
    dotfiles: "standard_dev_config"
    packages: ["nodejs", "rust", "go"]
    git:
      user_name: "Dev User"
      user_email: "dev@example.com"
    nodejs:
      packages: ["typescript", "eslint", "prettier"]
    rust:
      packages: ["ripgrep", "bat", "fd-find"]
    go:
      packages: ["github.com/jesseduffield/lazygit@latest"]

  # Power user with advanced shell/tools
  poweruser:
    shell: "/bin/zsh"
    groups: ["sudo", "admin", "systemd-journal"]
    ssh_keys: ["ecdsa_key"]
    dotfiles: "advanced_zsh_config"
    packages: ["neovim", "terminal_tools"]
    neovim:
      deploy_config: true
    terminal_config:
      install_terminfo: ["alacritty", "kitty"]

  # Minimal/restricted user
  restricteduser:
    shell: "/bin/sh"
    groups: []
    ssh_keys: []
    packages: []
    # Tests minimal configuration, ensures no failures with empty config

  # Service account
  serviceacct:
    shell: "/bin/false"
    groups: ["systemd-journal"]
    system: true
    packages: []
    # Tests system account creation, non-interactive users
```

**User scenarios validate**:
- Multiple concurrent users with different configs
- Different shells (bash, zsh, sh, false)
- Various permission levels (sudo, restricted, service)
- Development tool installation per-user
- Empty/minimal configurations don't break

### Test Scenario Variables

Edge cases and complex configurations:

```yaml
edge_case_scenarios:
  # Complex firewall rules
  firewall_rules:
    - port: 22
      protocol: "tcp"
      source: "10.0.0.0/8"
      comment: "SSH from internal network"
    - port: 80
      protocol: "tcp"
      source: "any"
      comment: "HTTP public access"
    - port: 443
      protocol: "tcp"
      source: "any"
      comment: "HTTPS public access"
    - port: 8080
      protocol: "tcp"
      source: "192.168.1.0/24"
      comment: "Development server local only"

  # Comprehensive SSH hardening
  ssh_hardening:
    disable_root_login: true
    password_authentication: false
    permit_empty_passwords: false
    challenge_response_auth: false
    kerberos_authentication: false
    gssapi_authentication: false
    x11_forwarding: false
    max_auth_tries: 3
    client_alive_interval: 300

  # Extensive package installation
  system_packages:
    security: ["fail2ban", "ufw", "aide", "rkhunter"]
    development: ["git", "curl", "wget", "tree", "jq", "htop"]
    languages: ["python3", "nodejs", "golang", "rustc"]
    databases: ["postgresql", "redis"]
    webservers: ["nginx", "apache2"]
```

## Testing Workflow

### End-to-End Test Cycle

```bash
# 1. Infrastructure provisioning
terraform -chdir=vm-test-infrastructure apply -auto-approve
# Creates 5 VMs (ubuntu2204, ubuntu2404, archlinux x3 for user tests)
# Generates dynamic inventory at inventory/vm-hosts.ini

# 2. Full system deployment
ansible-playbook -i inventory/vm-hosts.ini \
  --extra-vars "@test-scenarios/comprehensive-test.yml" \
  configure_system.yml
# Applies complete system configuration with all test scenarios

# 3. Configuration discovery
ansible-playbook -i inventory/vm-hosts.ini discovery.yml
# Scans configured systems and captures actual state
# Outputs: discovery-results.json

# 4. Validation: discovery results vs input expectations
ansible-playbook -i inventory/vm-hosts.ini validate_vm_configuration.yml
# Compares discovery results against expected configuration
# Fails if mismatches found

# 5. Cleanup
terraform -chdir=vm-test-infrastructure destroy -auto-approve
# Removes all VMs and network resources
```

### Validation Strategy

**Discovery-based validation** - Compare discovery playbook results against expected configuration inputs:

**Users and Authentication**:
- All users created with correct UID/GID
- Correct shells assigned (/bin/bash, /bin/zsh, etc.)
- Groups membership accurate (sudo, docker, etc.)
- SSH keys deployed properly
- Home directories exist with correct permissions

**Packages and Software**:
- All system packages installed
- Development tools present (nodejs, rust, go)
- User-level packages installed (npm, cargo, go packages)
- Correct versions where specified

**Services**:
- All systemd services enabled
- Services in expected states (running/stopped)
- Service dependencies satisfied

**Firewall**:
- UFW enabled with correct default policies
- All firewall rules present and active
- Source restrictions applied correctly
- Port ranges handled properly

**Security Hardening**:
- SSH configuration matches hardening spec
- OS hardening settings applied
- fail2ban jails active
- Security packages installed

**Configuration Files**:
- Expected config files exist
- Correct ownership and permissions
- Content matches templates

### Why This Approach?

**Advantages over assertions-only testing**:
1. **Real-world validation** - Tests actual deployed state, not just test assertions
2. **Discovery reusability** - Same discovery playbook useful for auditing production
3. **Comprehensive coverage** - Validates everything, not just what we remember to test
4. **Self-documenting** - Discovery output shows exactly what was configured
5. **Regression detection** - Easy to compare configurations across versions

## Terraform Implementation

### Infrastructure as Code Structure

```
vm-test-infrastructure/
├── main.tf                 # VM resource definitions
├── variables.tf            # VM configuration matrix
├── outputs.tf              # Ansible inventory generation
├── provider.tf             # libvirt provider config
├── network.tf              # Network bridge configuration
├── cloud-init/
│   └── user-data.yml      # Minimal cloud-init (ssh key only)
└── templates/
    └── inventory.tpl      # Ansible inventory template

test-scenarios/
├── comprehensive-test.yml  # Full test variable set
├── minimal-test.yml        # Minimal configuration test
└── edge-cases-test.yml     # Edge case scenarios
```

### Provider Configuration

```hcl
# provider.tf
terraform {
  required_version = ">= 1.5"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7"
    }
  }
}

provider "libvirt" {
  uri = "qemu+ssh://ed@libvirt-host/system"
}
```

### VM Resource Definition

```hcl
# main.tf
resource "libvirt_volume" "ubuntu2204" {
  name   = "ubuntu2204-test.qcow2"
  pool   = "default"
  source = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
  format = "qcow2"
}

resource "libvirt_cloudinit_disk" "ubuntu2204" {
  name      = "ubuntu2204-cloudinit.iso"
  user_data = file("${path.module}/cloud-init/user-data.yml")
}

resource "libvirt_domain" "ubuntu2204" {
  name   = "ubuntu2204-test"
  memory = "2048"
  vcpu   = 2

  cloudinit = libvirt_cloudinit_disk.ubuntu2204.id

  disk {
    volume_id = libvirt_volume.ubuntu2204.id
  }

  network_interface {
    bridge = "br0"
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
}
```

### Dynamic Inventory Generation

```hcl
# outputs.tf
output "ansible_inventory" {
  value = templatefile("${path.module}/templates/inventory.tpl", {
    ubuntu2204_ip = libvirt_domain.ubuntu2204.network_interface[0].addresses[0]
    ubuntu2404_ip = libvirt_domain.ubuntu2404.network_interface[0].addresses[0]
    archlinux_ip  = libvirt_domain.archlinux.network_interface[0].addresses[0]
  })
}
```

```ini
# templates/inventory.tpl
[ubuntu]
ubuntu2204 ansible_host=${ubuntu2204_ip}
ubuntu2404 ansible_host=${ubuntu2404_ip}

[archlinux]
arch01 ansible_host=${archlinux_ip}

[all:vars]
ansible_user=ed
ansible_ssh_private_key_file=~/.ssh/id_ed25519
ansible_python_interpreter=/usr/bin/python3
```

### Cloud-Init Configuration

```yaml
# cloud-init/user-data.yml
#cloud-config
users:
  - name: ed
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5... ed@workstation

packages:
  - python3
  - python3-apt  # For Debian/Ubuntu
  - python-pip   # For Arch

package_update: true
package_upgrade: false  # Don't upgrade, test on minimal cloud image

# Minimal networking
network:
  version: 2
  ethernets:
    enp1s0:
      dhcp4: true
```

## Key Features

**Storage**:
- Uses libvirt default storage pool (`/var/lib/libvirt/images`)
- Downloads and caches cloud images
- Snapshot support for quick reset

**Networking**:
- Bridged networking on br0
- Direct SSH access (no NAT)
- VMs get DHCP from local network
- Accessible from control node

**Cloud-Init**:
- Minimal configuration
- Just SSH key for `ed` user
- Basic connectivity
- Tests bare-bones setup (realistic for production)

**Parallel Provisioning**:
- All 5 VMs created simultaneously
- Faster test cycles
- Independent failure isolation

**Dynamic Inventory**:
- Auto-generates Ansible inventory with VM IPs
- No manual IP management
- Works with Terraform outputs

## Execution Time Estimates

### VM Provisioning
- **First run**: 5-10 minutes (downloads images)
- **Subsequent runs**: 2-3 minutes (cached images)
- **Parallel provisioning**: All VMs simultaneously

### Ansible Deployment
- **configure_system playbook**: 10-15 minutes
- **discovery playbook**: 2-3 minutes
- **validation playbook**: 1-2 minutes

### Total Test Cycle
- **Complete end-to-end**: ~20-30 minutes first run
- **Cached images**: ~15-20 minutes
- **Much faster than manual testing across 3 distributions**

### Cleanup
- **terraform destroy**: 1-2 minutes

## Future Enhancements

### macOS Support

**Challenges**:
- Requires macOS host for legal virtualization
- Virtualization.framework (macOS 11+) needed
- No cloud images available (must build custom)
- Different networking (no libvirt)

**Potential approach**:
```hcl
# Requires macOS host with Tart/Packer
provider "macvm" {
  # Custom provider for macOS virtualization
}
```

### Multi-Region Testing

Test collection against different network configurations:
- Isolated networks (no internet)
- Proxy environments
- Custom DNS servers
- VPN scenarios

### Performance Testing

Measure collection execution time:
- Track role execution time
- Identify bottlenecks
- Optimize slow tasks

### Continuous VM Testing

Integrate into CI/CD:
- Nightly VM test runs
- Report results to dashboard
- Alert on failures

## Comparison: Container vs VM Testing

| Aspect | Container (Current) | VM (Phase III) |
|--------|---------------------|----------------|
| **Startup Time** | Seconds | Minutes |
| **Cleanup** | Instant | 1-2 minutes |
| **Resource Usage** | Low (MB) | High (GB) |
| **System Capabilities** | Limited | Full |
| **Networking** | Isolated | Real |
| **Real-world Accuracy** | Medium | High |
| **CI Integration** | Easy | Complex |
| **Use Case** | Development, fast feedback | Pre-release validation |

**Strategy**: Use both
- Containers for development (fast iteration)
- VMs for release validation (comprehensive)

## Implementation Timeline

**Phase III-A: Basic VM Testing (Q1 2026)**
- Terraform infrastructure for Ubuntu 22.04/24.04
- Basic configure_system deployment
- Simple validation (service state, package presence)

**Phase III-B: Discovery Integration (Q2 2026)**
- Full discovery playbook integration
- Comprehensive validation against expected state
- Automated report generation

**Phase III-C: Multi-Distribution (Q3 2026)**
- Add Arch Linux testing
- Add Debian testing
- Parallel VM execution

**Phase III-D: CI Integration (Q4 2026)**
- Nightly automated VM tests
- Dashboard with test results
- Slack/email notifications on failure

## References

- Terraform libvirt provider: https://github.com/dmacvicar/terraform-provider-libvirt
- Cloud images: https://cloud-images.ubuntu.com/
- Discovery playbook: `playbooks/discovery.yml`
