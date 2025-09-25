# CONFIGURE_USER_VALIDATION_PLAN.md

Validation plan for the `configure_user` role based on Software Requirements Document (SRD) Section 3.6.

## Overview

This validation plan covers all requirements for the `configure_user` role, which configures a single user and their preferences. The role acts as a thin wrapper around `ansible.builtin.user` for core functionality while orchestrating SSH keys, sudo configuration, development environments, platform preferences, and dotfiles deployment.

## Requirements Coverage

**Total Requirements**: 19 (REQ-CU-001 through REQ-CU-019)
- **Active Requirements**: 17
- **Removed Requirements**: 2 (REQ-CU-003, REQ-CU-013)

## Container Testing Approach

**Philosophy**: Don't assume container limitations - prove them. Let functions fail in molecule first, investigate to confirm container vs code issues, then decide how to handle.

**Test Strategy**:
- Primary testing in containers (Ubuntu/Arch Linux)
- macOS requirements defer to VM testing (existing production code frozen)
- Container-incompatible features will be identified and handled appropriately

**Critical Testing Limitation**: User removal idempotence testing is problematic in containers due to the test design (create user then remove in same run). The molecule test skips user-removal-test tagged tasks during idempotence runs. **VM testing MUST verify full idempotence including user removal scenarios.**

---

## REQ-CU-001: User Account Creation and Configuration

**Requirement**: The system SHALL create and configure user accounts using ansible.builtin.user

**Container Compatibility**: ✅ Full validation possible in containers

**Test Scenarios**:
- ✅ **Basic user creation**: Create user with minimal config (name only)
- ✅ **Full user configuration**: All ansible.builtin.user parameters
- ✅ **User modification**: Update existing user properties
- ✅ **Multiple users**: Sequential single-user configurations
- ✅ **System users**: uid < 1000, no home directory
- ✅ **Custom home directory**: Non-standard home path
- ✅ **Password handling**: Both plaintext and hashed passwords
- ✅ **Group membership**: Primary and secondary groups

**Validation Commands**:
```bash
# Verify user exists with correct properties
id testuser
getent passwd testuser | grep -E "testuser:.*:/home/testuser:/bin/bash"

# Verify group membership
groups testuser | grep -E "(docker|users)"

# Verify home directory
test -d /home/testuser
```

---

## REQ-CU-002: User Account Removal

**Requirement**: The system SHALL remove user accounts when state is absent

**Container Compatibility**: ✅ Full validation possible in containers

**Test Scenarios**:
- ✅ **Basic user removal**: state: absent (keeps home by default)
- ✅ **Complete removal**: state: absent with remove: yes
- ✅ **Force removal**: state: absent with force: yes
- ✅ **Non-existent user**: Graceful handling of missing users

**Validation Commands**:
```bash
# Verify user removed
! id testuser 2>/dev/null

# Verify home directory handling
test -d /home/testuser  # Should exist unless remove: yes
```

---

## ~~REQ-CU-003: Platform Admin Group Filtering~~

**Status**: Removed (Legacy requirement, overly restrictive)

---

## REQ-CU-004: Cross-Platform Sudo Access

**Requirement**: The system SHALL grant cross-platform sudo access through platform admin group membership

**Container Compatibility**: ✅ Full validation possible in containers

**Test Scenarios**:
- ✅ **Ubuntu sudo group**: superuser: true adds to 'sudo' group
- ✅ **Arch wheel group**: superuser: true adds to 'wheel' group
- ✅ **Group addition**: Additive to existing groups
- ✅ **Platform detection**: Correct group per OS family
- ✅ **Sudo functionality**: User can execute sudo commands with password

**Validation Commands**:
```bash
# Verify correct platform group membership
groups testuser | grep -E "(sudo|wheel)"

# Verify sudo access (with password)
sudo -u testuser sudo -n true 2>&1 | grep "password is required"
```

---

## REQ-CU-005: Passwordless Sudo Configuration

**Requirement**: The system SHALL support passwordless sudo configuration for superusers

**Container Compatibility**: ✅ Full validation possible in containers

**Test Scenarios**:
- ✅ **Security requirement**: Only works when superuser: true
- ✅ **Sudoers file creation**: /etc/sudoers.d/username exists
- ✅ **File permissions**: 0440, root:root ownership
- ✅ **Sudoers syntax**: Valid sudoers syntax (validated)
- ✅ **Passwordless access**: User can sudo without password
- ✅ **Security prevention**: superuser_passwordless without superuser ignored

**Validation Commands**:
```bash
# Verify sudoers file exists with correct permissions
test -f /etc/sudoers.d/testuser
stat -c "%a %U:%G" /etc/sudoers.d/testuser | grep "440 root:root"

# Verify sudoers content
grep "testuser ALL=(ALL) NOPASSWD: ALL" /etc/sudoers.d/testuser

# Verify passwordless sudo works
sudo -u testuser sudo -n true
```

---

## REQ-CU-006: SSH Key Management

**Requirement**: The system SHALL be capable of managing SSH authorized keys for users

**Container Compatibility**: ✅ Full validation possible in containers

**Purpose**: Enable cloud-init-like functionality where defined public keys allow SSH access into the user's account (inbound access management)

**Test Scenarios**:
- ✅ **Single key addition**: Add SSH public key to ~/.ssh/authorized_keys
- ✅ **Multiple keys**: Manage multiple authorized keys per user
- ✅ **Key removal**: state: absent removes specific key from authorized_keys
- ✅ **Key options**: SSH restrictions like from="ip", no-port-forwarding, command="..."
- ✅ **Exclusive mode**: Replace all existing authorized keys
- ✅ **Key comments**: Custom key comments in authorized_keys
- ✅ **Invalid keys**: Graceful handling of malformed public keys
- ✅ **SSH directory creation**: Automatic ~/.ssh directory with correct permissions (700)
- ✅ **Inbound SSH access**: Verify SSH login works with configured keys

**Validation Commands**:
```bash
# Verify SSH directory exists with correct permissions
test -d /home/testuser/.ssh
stat -c "%a %U:%G" /home/testuser/.ssh | grep "700 testuser:testuser"

# Verify authorized_keys file exists with correct permissions
test -f /home/testuser/.ssh/authorized_keys
stat -c "%a %U:%G" /home/testuser/.ssh/authorized_keys | grep "600 testuser:testuser"

# Verify public key content (example ed25519 key)
grep "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5" /home/testuser/.ssh/authorized_keys

# Verify key options and restrictions
grep "from=\"192.168.1.0/24\"" /home/testuser/.ssh/authorized_keys
grep "no-port-forwarding" /home/testuser/.ssh/authorized_keys

# Verify key comments
grep "testuser@example.com" /home/testuser/.ssh/authorized_keys

# Test inbound SSH access (simulated in container)
# Note: Actual SSH testing requires SSH service and proper container setup
sudo -u testuser ssh-keygen -y -f /dev/stdin <<< "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5..." | grep "ssh-ed25519"
```

---

## REQ-CU-007: Node.js Development Environment

**Requirement**: The system SHALL configure Node.js development environment for users

**Container Compatibility**: ✅ Full validation possible in containers

**Dependencies**: Requires `wolskies.infrastructure.nodejs` role

**Test Scenarios**:
- ✅ **Role delegation**: Calls nodejs role with correct parameters
- ✅ **Variable mapping**: node_user and node_packages passed correctly
- ✅ **Conditional execution**: Only when nodejs.packages defined and non-empty
- ✅ **Missing role handling**: Graceful failure when nodejs role missing
- ✅ **Empty package list**: Skipped when packages list empty

**Validation Commands**:
```bash
# Verify Node.js installation (delegated to nodejs role testing)
# This requirement validates the orchestration, not the implementation
```

---

## REQ-CU-008: Rust Development Environment

**Requirement**: The system SHALL configure Rust development environment for users

**Container Compatibility**: ✅ Full validation possible in containers

**Dependencies**: Requires `wolskies.infrastructure.rust` role

**Test Scenarios**:
- ✅ **Role delegation**: Calls rust role with correct parameters
- ✅ **Variable mapping**: rust_user and rust_packages passed correctly
- ✅ **Conditional execution**: Only when rust.packages defined and non-empty
- ✅ **Missing role handling**: Graceful failure when rust role missing
- ✅ **Empty package list**: Skipped when packages list empty

---

## REQ-CU-009: Go Development Environment

**Requirement**: The system SHALL configure Go development environment for users

**Container Compatibility**: ✅ Full validation possible in containers

**Dependencies**: Requires `wolskies.infrastructure.go` role

**Test Scenarios**:
- ✅ **Role delegation**: Calls go role with correct parameters
- ✅ **Variable mapping**: go_user and go_packages passed correctly
- ✅ **Conditional execution**: Only when go.packages defined and non-empty
- ✅ **Missing role handling**: Graceful failure when go role missing
- ✅ **Empty package list**: Skipped when packages list empty

---

## REQ-CU-010: Neovim Configuration

**Requirement**: The system SHALL configure Neovim for users

**Container Compatibility**: ✅ Full validation possible in containers

**Dependencies**: Requires `wolskies.infrastructure.neovim` role

**Test Scenarios**:
- ✅ **Role delegation**: Calls neovim role with correct parameters
- ✅ **Variable mapping**: neovim_user passed correctly
- ✅ **Conditional execution**: Only when neovim.enabled is true
- ✅ **Missing role handling**: Graceful failure when neovim role missing

---

## REQ-CU-011: Terminal Configuration

**Requirement**: The system SHALL configure terminal emulators for users

**Container Compatibility**: ❓ **To be determined** - may have container limitations

**Dependencies**: Requires `wolskies.infrastructure.terminal_config` role

**Test Scenarios**:
- ✅ **Role delegation**: Calls terminal_config role with correct parameters
- ✅ **Variable mapping**: terminal_user and terminal_entries passed correctly
- ✅ **Conditional execution**: Only when terminal_entries non-empty
- ❓ **Container limitations**: Terminal config may fail in containers
- ✅ **Missing role handling**: Graceful failure when terminal_config role missing

**Container Testing Strategy**: Let it fail first, then investigate and document limitations

---

## REQ-CU-012: Git Configuration

**Requirement**: The system SHALL be capable of configuring Git settings for users

**Container Compatibility**: ✅ Full validation possible in containers

**Test Scenarios**:
- ✅ **Git user name**: Set global user.name
- ✅ **Git user email**: Set global user.email
- ✅ **Git editor**: Set global core.editor
- ✅ **Partial config**: Some fields defined, others undefined
- ✅ **No git config**: Skipped when git object undefined

**Validation Commands**:
```bash
# Verify git configuration
sudo -u testuser git config --global user.name | grep "Test User"
sudo -u testuser git config --global user.email | grep "test@example.com"
sudo -u testuser git config --global core.editor | grep "vim"
```

---

## ~~REQ-CU-013: Linux Shell Configuration~~

**Status**: Removed (Redundant with REQ-CU-001)

---

## REQ-CU-014: Homebrew PATH Configuration (macOS)

**Requirement**: The system SHALL configure Homebrew PATH for macOS users

**Container Compatibility**: ❌ **macOS only** - Deferred to VM testing

**Implementation**: Frozen - matches existing production code

**Test Scenarios**: Deferred to VM testing phase

---

## REQ-CU-015: Dock Preferences (macOS)

**Requirement**: The system SHALL configure Dock preferences for macOS users

**Container Compatibility**: ❌ **macOS only** - Deferred to VM testing

**Implementation**: Frozen - matches existing production code

**Test Scenarios**: Deferred to VM testing phase

---

## REQ-CU-016: Finder Preferences (macOS)

**Requirement**: The system SHALL configure Finder preferences for macOS users

**Container Compatibility**: ❌ **macOS only** - Deferred to VM testing

**Implementation**: Frozen - matches existing production code

**Test Scenarios**: Deferred to VM testing phase

---

## REQ-CU-017: Screenshot Preferences (macOS)

**Requirement**: The system SHALL configure screenshot preferences for macOS users

**Container Compatibility**: ❌ **macOS only** - Deferred to VM testing

**Implementation**: Frozen - matches existing production code

**Test Scenarios**: Deferred to VM testing phase

---

## REQ-CU-018: iTerm2 Preferences (macOS)

**Requirement**: The system SHALL configure iTerm2 preferences for macOS users

**Container Compatibility**: ❌ **macOS only** - Deferred to VM testing

**Implementation**: Frozen - matches existing production code

**Test Scenarios**: Deferred to VM testing phase

---

## REQ-CU-019: Dotfiles Management

**Requirement**: The system SHALL deploy user dotfiles using GNU stow

**Container Compatibility**: ✅ Full validation possible in containers

**Implementation Found**: Production code shows complete dotfiles management with conflict detection and backup strategy

**Test Scenarios**:
- ✅ **Git repository clone**: Clone dotfiles repo to ~/{{dest}} (default: ~/.dotfiles)
- ✅ **Stow package installation**: Install GNU stow via package manager (platform-specific)
- ✅ **Conflict detection**: stow --no --dry-run to detect existing files
- ✅ **Backup conflicts**: Move conflicting files with timestamp (.backup.YYYYMMDD-HHMMSS)
- ✅ **Stow deployment**: Deploy dotfiles with stow from cloned repository
- ✅ **Conditional execution**: Only when dotfiles.enable true and repository defined
- ✅ **Skip clone**: Honor dotfiles.disable_clone flag (use existing repo)
- ✅ **Custom destination**: Use dotfiles.dest directory (default: .dotfiles)
- ✅ **Branch selection**: Checkout specified branch or use default
- ✅ **Directory permissions**: Proper ownership and permissions for dotfiles directory
- ✅ **Stow package selection**: Support for stowing specific packages within dotfiles repo

**Validation Commands**:
```bash
# Verify dotfiles repository cloned with correct ownership
test -d /home/testuser/.dotfiles/.git
stat -c "%U:%G" /home/testuser/.dotfiles | grep "testuser:testuser"

# Verify stow package installed
which stow || command -v stow

# Verify dotfiles deployed via stow (symlinks to .dotfiles)
test -L /home/testuser/.bashrc
readlink /home/testuser/.bashrc | grep "\.dotfiles"

# Verify stow structure (example for bash package)
test -d /home/testuser/.dotfiles/bash
test -f /home/testuser/.dotfiles/bash/.bashrc

# Verify backups created when conflicts existed
ls /home/testuser/*.backup.20* 2>/dev/null || echo "No conflicts, no backups needed"

# Verify branch checkout if specified
cd /home/testuser/.dotfiles && git branch | grep "* main\|* master"

# Test stow dry-run functionality (conflict detection)
cd /home/testuser/.dotfiles && stow --no --dry-run bash || echo "Conflicts detected"
```

---

## Molecule Test Structure

### Container Platforms

```yaml
platforms:
  - name: ubuntu-user-full
    image: geerlingguy/docker-ubuntu2404-ansible:latest
    # Full user configuration testing

  - name: ubuntu-user-basic
    image: geerlingguy/docker-ubuntu2404-ansible:latest
    # Basic user creation and SSH keys

  - name: ubuntu-user-privileged
    image: geerlingguy/docker-ubuntu2404-ansible:latest
    # Sudo and privilege testing

  - name: arch-user-basic
    image: carlodepieri/docker-archlinux-ansible:latest
    # Cross-platform validation (wheel vs sudo groups)

  - name: ubuntu-user-edge-cases
    image: geerlingguy/docker-ubuntu2404-ansible:latest
    # Edge cases, removals, error conditions
```

### Test Scenarios by Container

**ubuntu-user-full**:
- Complete user with all features
- Development environments (nodejs, rust, go, neovim)
- Git configuration
- Dotfiles deployment
- SSH key management

**ubuntu-user-basic**:
- Minimal user creation (REQ-CU-001)
- Basic SSH key management (REQ-CU-006)
- User modification and updates

**ubuntu-user-privileged**:
- Superuser flag testing (REQ-CU-004)
- Passwordless sudo (REQ-CU-005)
- Security validations

**arch-user-basic**:
- Cross-platform group assignment (wheel vs sudo)
- Basic user creation on Arch Linux

**ubuntu-user-edge-cases**:
- User removal (REQ-CU-002)
- Empty configurations
- Missing dependencies
- Error conditions

## Success Criteria

**All Requirements Validated**: 17 active requirements (CU-001,002,004-012,014-019)
**Container Testing**: Linux requirements fully validated in CI
**macOS Deferred**: Requirements CU-014 through CU-018 deferred to VM testing
**Security Validated**: Privilege escalation properly controlled
**Dependencies Handled**: Role orchestration tested with proper error handling
**Edge Cases Covered**: Removal, empty configs, missing dependencies

## Implementation Status

✅ **SRD Complete**: All requirements defined with clear implementations
✅ **Validation Plan**: Comprehensive test scenarios for container-testable features
⏳ **Test Implementation**: Ready to implement molecule tests
⏳ **Production Code**: Ready to implement based on SRD requirements
⏳ **VM Testing Setup**: macOS requirements deferred to future VM infrastructure

## Container Limitations Discovery

As we implement and test, we will discover actual container limitations through the "fail first" approach:

1. **Let functions fail** in molecule testing
2. **Investigate failures** to determine if container limitation or code issue
3. **Document limitations** and decide how to handle (skip, mock, defer to VM)
4. **Update validation plan** with actual discovered limitations

This approach ensures we don't prematurely assume limitations without evidence.
