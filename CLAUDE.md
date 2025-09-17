# CLAUDE.md

Project guidance for Claude Code when working with the `wolskies.infrastructure` Ansible Collection.

## Key Principles

**Target Users**: Moderately experienced - no excessive warnings or defensive programming
**Supported OS**: Ubuntu 22+, Debian 12+, Arch Linux, macOS
**Philosophy**: Use existing modules/roles over custom implementations

- **Comments**: Only for non-standard implementations, not obvious functionality
- **Module preference**: Use existing ansible.builtin/community.general over custom code
- **Command usage**: `ansible.builtin.command` as last resort, `ansible.builtin.shell` requires explicit permission
- **Repository management**: ALWAYS use `ansible.builtin.deb822_repository` (apt_repository is deprecated and will fail)

## Critical Rules

**NEVER change production code to make tests pass without investigation first**
**ALWAYS investigate if test failure indicates setup issue vs production bug**
**NEVER add Claude attribution to git commits** - No "Generated with Claude Code" or "Co-Authored-By: Claude" lines

## Testing Strategy

### Core Testing Principles
- **No test-specific production code** - Never add `when: not molecule_test` conditionals
- **Tags for container limits** - Use `skip-tags: hostname,docker-compose` for container issues
- **Semantic failures** - Let roles fail properly rather than masking issues
- **Individual role tests over integration-only** - Every role gets its own test
- **VM vs container testing** - Use delegated driver for VM testing when containers insufficient

### Test Types by Role Complexity

1. **Simple roles** → `roles/{role-name}/molecule/default/` tests
   - Focus: Role-specific functionality, packages, configuration
   - Examples: nodejs, rust, go, os_configuration, manage_packages

2. **Orchestrating roles** → `molecule/test-integration/` tests
   - Focus: Role interactions, cross-dependencies, end-to-end workflows
   - Examples: configure_system (calls multiple roles)

3. **Integration tests don't repeat individual role testing**

### Development Test Flow

**CRITICAL: NEVER push code that fails local molecule testing to CI**

**Required sequence** (each phase should catch issues before the next):
1. `ansible-lint` - syntax/standards validation
2. `molecule converge` - role functionality testing during development
3. `molecule test` - **MUST PASS** before any commit - full test suite including verification
4. `pre-commit` - formatting, linting, custom hooks
5. **CI** - should be identical to local molecule tests and pass if local passes

**Rule**: If `molecule test` fails locally, it will fail in CI. Fix all local issues before committing.

**Test Contract**: Individual role tests are authoritative. If role tests pass but integration fails → investigate missing role test coverage, not integration code.

## Current Implementation Status (Sept 2025)

**Individual role tests completed**: nodejs, rust, go, neovim, terminal_config
**Phase II target**: Extract os_configuration, manage_packages, manage_security_services, configure_user to individual role tests
**CI pipeline**: 5 parallel role tests + test-integration + test-discovery + test-minimal

## VM Testing Infrastructure Plan

### **Phase III: Comprehensive VM Testing with Terraform + libvirt**

**Infrastructure**: On-premise libvirt with Terraform IaC management
**Network**: Bridged networking (br0) for direct SSH access
**Access**: SSH as `ed` user with pre-loaded public key
**Images**: Upstream cloud images (minimal/bare - ideal test case for collection)

#### **VM Configuration Matrix**
```yaml
vm_targets:
  ubuntu2204:
    image: "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
    os_family: "Debian"
  ubuntu2404:
    image: "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
    os_family: "Debian"
  debian12:
    image: "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
    os_family: "Debian"
  debian13:
    image: "https://cloud.debian.org/images/cloud/trixie/daily/latest/debian-13-generic-amd64.qcow2"
    os_family: "Debian"
  archlinux:
    image: "https://geo.mirror.pkgbuild.com/images/latest/Arch-Linux-x86_64-cloudimg.qcow2"
    os_family: "Archlinux"
  # Future: macOS (licensing/technical challenges)
```

#### **Test User Matrix**
```yaml
test_users:
  # Standard developer with full toolchain
  devuser:
    shell: "/bin/bash"
    groups: ["sudo", "docker"]
    ssh_keys: ["ed25519_primary", "rsa_backup"]
    dotfiles: "standard_dev_config"
    packages: ["nodejs", "rust", "go"]

  # Power user with advanced shell/tools
  poweruser:
    shell: "/bin/zsh"
    groups: ["sudo", "admin", "systemd-journal"]
    ssh_keys: ["ecdsa_key"]
    dotfiles: "advanced_zsh_config"
    packages: ["neovim", "terminal_tools"]

  # Minimal/restricted user
  restricteduser:
    shell: "/bin/sh"
    groups: []
    ssh_keys: []
    packages: []

  # Service account
  serviceacct:
    shell: "/bin/false"
    groups: ["systemd-journal"]
    system: true
    packages: []
```

#### **Test Scenario Variables**
```yaml
edge_case_scenarios:
  firewall_rules:
    - { port: 22, protocol: "tcp", source: "10.0.0.0/8", comment: "SSH from internal" }
    - { port: 80, protocol: "tcp", source: "any", comment: "HTTP public" }
    - { port: 443, protocol: "tcp", source: "any", comment: "HTTPS public" }
    - { port: 8080, protocol: "tcp", source: "192.168.1.0/24", comment: "Dev server local" }

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

  system_packages:
    security: ["fail2ban", "ufw", "aide", "rkhunter"]
    development: ["git", "curl", "wget", "tree", "jq", "htop"]
    languages: ["python3", "nodejs", "golang", "rustc"]
```

#### **Testing Workflow**
```bash
# 1. Infrastructure provisioning
terraform -chdir=vm-test-infrastructure apply -auto-approve

# 2. Full system deployment
ansible-playbook -i inventory/vm-hosts.ini \
  --extra-vars "@test-scenarios/comprehensive-test.yml" \
  configure_system.yml

# 3. Configuration discovery
ansible-playbook -i inventory/vm-hosts.ini discovery.yml

# 4. Validation: discovery results vs input expectations
ansible-playbook -i inventory/vm-hosts.ini validate_vm_configuration.yml

# 5. Cleanup
terraform -chdir=vm-test-infrastructure destroy -auto-approve
```

**Validation Strategy**: Compare discovery playbook results against expected configuration inputs to ensure:
- All users created with correct shells, groups, SSH keys
- All packages installed and functional
- All services enabled and running
- All firewall rules applied correctly
- All security hardening measures active

#### **Terraform Implementation Details**

**Provider Configuration**:
```hcl
provider "libvirt" {
  uri = "qemu+ssh://ed@libvirt-host/system"
}
```

**Key Features**:
- **Storage**: Uses libvirt default storage pool (/var/lib/libvirt/images)
- **Networking**: Bridged networking on br0 for direct SSH access
- **Cloud-Init**: Minimal configuration - just SSH key for `ed` user and basic connectivity
- **Images**: Downloads and caches upstream cloud images automatically
- **Parallel Provisioning**: All 5 VMs created simultaneously
- **Dynamic Inventory**: Auto-generates Ansible inventory with VM IP addresses

**File Structure**:
```
vm-test-infrastructure/
├── main.tf                 # VM resource definitions
├── variables.tf            # VM configuration matrix
├── outputs.tf              # Ansible inventory generation
├── cloud-init/
│   └── user-data.yml      # Minimal cloud-init (ssh key only)
└── templates/
    └── inventory.tpl      # Ansible inventory template
test-scenarios/
└── comprehensive-test.yml  # Full test variable set
```

This approach provides **true end-to-end validation** on bare cloud images across the full OS matrix, ensuring the collection works on realistic target environments.

## Environment Requirements

**Ansible config**: `ANSIBLE_HASH_BEHAVIOUR=merge` required for variable merging
**Collections**: Run `ansible-galaxy collection install -r requirements.yml` before testing
**Local development**: Use `cd roles/{name} && molecule converge` for quick testing

## Common Issues & Solutions

**PATH problems**: Language roles install to user directories - ensure verification uses correct PATH
**Container limits**: Use `skip-tags: terminal-config,hostname,docker-compose` for container tests
**Fresh systems**: Always use `update_cache: true` for apt tasks
**deb822_repository**: Requires `python3-debian` package prerequisite
