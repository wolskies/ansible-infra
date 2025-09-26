# CLAUDE.md

Project guidance for Claude Code when working with the `wolskies.infrastructure` Ansible Collection.

## Software Design Documentation

**Primary Reference**: Software design, requirements, and architecture are documented in `/docs/SOFTWARE_REQUIREMENTS_DOCUMENT.md`

## Key Development Principles

**Target Users**: Moderately experienced - no excessive warnings or defensive programming
**Philosophy**: Use existing modules/roles over custom implementations

- **Comments**: Only for non-standard implementations, not obvious functionality
- **Module preference**: Use existing ansible.builtin/community.general over custom code
- **Command usage**: `ansible.builtin.command` as last resort, `ansible.builtin.shell` requires explicit permission

## Critical Rules

**NEVER change production code to make tests pass without investigation first**
**ALWAYS investigate if test failure indicates setup issue vs production bug**
**NEVER add Claude attribution to git commits** - No "Generated with Claude Code" or "Co-Authored-By: Claude" lines

## TDD Process - MUST FOLLOW THIS ORDER

When implementing new features or requirements:
1. **Update SRD** with requirements
2. **Write validation plan** in docs/validation/
3. **Write/update tests** (molecule/verify.yml)
4. **Run tests and OBSERVE FAILURES** - Document what fails and why
5. **ONLY THEN modify production code** (tasks/, defaults/, etc.)
6. **Run tests again** to confirm they pass
7. **Document the implementation** in commit message

**CRITICAL**: Steps 1-4 must be complete BEFORE touching any production code (tasks/, defaults/, handlers/, templates/). Test failures in step 4 prove we're testing the right thing.

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

## Git Commit Message Format

**For requirement implementations:**
```
implement REQ-XX-NNN [requirement description]

- Implementation details
- Testing approach
- Key technical decisions

[Additional context or notes]
```

**Examples:**
- `implement REQ-OS-001 hostname configuration validation`
- `implement REQ-OS-002 /etc/hosts update validation`
- `implement REQ-OS-003 timezone configuration validation`

**Other commit types:**
- Bug fixes: `fix REQ-XX-NNN [description]`
- Test improvements: `test REQ-XX-NNN [description]`
- Refactoring: `refactor [description]`

**Benefits:**
- **Traceability**: Easy to map commits to SRD requirements (`git log --grep="REQ-OS"`)
- **History**: Clear implementation timeline and decision log
- **Review**: Obvious scope and purpose for code review
- **Documentation**: Commit messages form implementation audit trail

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

**Ansible config**: Standard configuration - no special hash_behaviour required
**Collections**: Run `ansible-galaxy collection install -r requirements.yml` before testing
**Local development**: Use `cd roles/{name} && molecule converge` for quick testing

## Common Issues & Solutions

**PATH problems**: Language roles install to user directories - ensure verification uses correct PATH
**Container limits**: Use `skip-tags: terminal-config,hostname,docker-compose` for container tests
**Fresh systems**: Always use `update_cache: true` for apt tasks
**deb822_repository**: Requires `python3-debian` package prerequisite

## SRD and Requirements Best Practices

### Writing Good Requirements
1. **Numbered requirements must be testable** - If you can't test it, make it a standard/guideline
2. **One requirement per number** - Don't combine multiple testable concepts
3. **Separate requirements from implementation** - Requirements state capabilities ("SHALL be capable of..."), implementation documents technical approach
4. **Eliminate redundancy** - Requirements that test the same thing should be consolidated
5. **Use specific, definitive descriptions** - Include format examples, valid ranges, concrete values

### Role Documentation Pattern
For each feature in a role:
- **REQ-XX-XXX**: State the capability requirement ("The system SHALL be capable of...")
- **Implementation**: Document the technical approach (modules, variables, conditions)

### Requirements vs Standards
- **Requirements (REQ-XXX-NNN)**: Testable, verifiable, mandatory
- **Standards**: Coding guidelines, best practices, implementation guidance

### Variable Interface Documentation
- **Consistent table format** throughout - don't mix tables and YAML schemas
- **Complete schemas** for complex objects (users, packages, firewall rules, etc.)
- **Definitive descriptions** with examples and constraints
- **Master interface** covers ALL collection variables for interoperability

### Lessons Learned
- External dependencies are implementation details, not collection requirements
- Idempotency and "tasks report changed only when changes occur" are the same testable concept
- Variable naming conventions are standards, not requirements
- Galaxy compliance should reference official documentation and allow documented exceptions
- **Each feature gets its own section** - Don't group related but distinct functionality (timezone, locale, language each need separate sections)
- **Specify Ansible modules in requirements** - "SHALL set hostname using ansible.builtin.hostname" is more testable than "SHALL set hostname"
- **Delete guidance masquerading as requirements** - Role descriptions and multi-function summaries aren't testable
- **Clean up legacy before release** - No need to document deprecated functionality in v1.2.0 SRD if not yet released
- **Focus on outcomes AND implementation** - Requirements should specify both what should happen and which module to use
