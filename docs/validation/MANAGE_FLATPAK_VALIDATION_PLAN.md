# Manage Flatpak Role Validation Plan

## Executive Summary

This validation plan follows the successful test-first methodology established with other collection roles (`os_configuration`, `manage_packages`, `manage_snap_packages`). Each requirement will be validated through evidence-based testing using Molecule framework with comprehensive test scenarios that validate flatpak runtime installation, desktop plugin management, and package management functionality.

## Testing Strategy

### Container Test Scenarios

Following the established pattern, we'll use consolidated test containers for comprehensive coverage:

1. **ubuntu-flatpak-system-full**: Complete flatpak system setup with plugins and packages
2. **arch-flatpak-system-full**: Arch Linux flatpak system with different package names for plugins
3. **ubuntu-flatpak-packages-basic**: Basic flatpak package install/remove without plugins
4. **ubuntu-flatpak-no-action**: Edge cases with empty configurations and no-action scenarios

### Evidence-Based Testing Principles

- Verify actual system state using commands like `systemctl`, `which flatpak`, `flatpak list`
- Test both installation and removal scenarios (standard Ansible behavior)
- Validate flatpak runtime installation and Flathub repository configuration
- Check desktop plugin installation for GNOME and Plasma environments
- Leverage unified `flatpak_packages` list with state properties following collection patterns

## Requirements Validation Matrix

### Flatpak Infrastructure Management (REQ-MF-001 through REQ-MF-003)

#### REQ-MF-001: Flatpak Installation

**Requirement**: The system SHALL install flatpak runtime on Debian and Arch Linux systems when enabled

**Implementation**: Uses `ansible.builtin.apt` for Debian/Ubuntu and `community.general.pacman` for Arch Linux to install flatpak package when `flatpak.enabled` is true

**Test Scenarios**:
- ✅ **Package Installation**: flatpak package installed via system package manager
- ✅ **Command Availability**: flatpak command available in system PATH
- ✅ **Service Functionality**: flatpak can list packages without error
- ✅ **Conditional Logic**: Only triggers when `flatpak.enabled` is true
- ✅ **Idempotency**: Subsequent runs complete without changes

**Validation Commands**:
```bash
# Package installation verification
dpkg -l flatpak  # Debian/Ubuntu (should show installed package)
pacman -Q flatpak  # Arch Linux (should show installed package)

# Command availability
which flatpak  # Should succeed (rc == 0)
flatpak --version  # Should return version information

# Basic functionality
flatpak list  # Should succeed without error
```

**Container Compatibility**: ✅ Full validation possible in containers

---

#### REQ-MF-002: Desktop Integration Plugins (Debian/Ubuntu only)

**Requirement**: The system SHALL install desktop environment flatpak plugins when configured (Debian/Ubuntu only)

**Implementation**: On Debian/Ubuntu systems, installs GNOME Software plugin (`gnome-software-plugin-flatpak`) when `flatpak.plugins.gnome` is true, and Plasma Discover plugin (`plasma-discover-backend-flatpak`) when `flatpak.plugins.plasma` is true. On Arch Linux, flatpak support is built into the desktop packages themselves rather than requiring separate plugins.

**Test Scenarios**:
- ✅ **GNOME Plugin (Debian/Ubuntu)**: gnome-software-plugin-flatpak installed when enabled
- ✅ **Plasma Plugin (Debian/Ubuntu)**: plasma-discover-backend-flatpak installed when enabled
- ✅ **Arch Linux**: No separate plugin installation (built into desktop packages)
- ✅ **Conditional Logic**: Only installs plugins when explicitly enabled
- ✅ **Graceful Failure**: Uses `failed_when: false` for optional components

**Validation Commands**:
```bash
# GNOME plugin verification (Debian/Ubuntu)
dpkg -l gnome-software-plugin-flatpak  # Should show installed when enabled

# GNOME plugin verification (Arch Linux)
pacman -Q gnome-software-flatpak  # Should show installed when enabled

# Plasma plugin verification (Debian/Ubuntu)
dpkg -l plasma-discover-backend-flatpak  # Should show installed when enabled

# Plasma plugin verification (Arch Linux)
pacman -Q discover  # Should show installed when enabled
```

**Container Compatibility**: ✅ Full validation possible in containers

---

#### REQ-MF-003: Repository Management

**Requirement**: The system SHALL enable Flathub repository when configured

**Implementation**: Uses `community.general.flatpak_remote` to add flathub repository with configurable method from `flatpak.method` and user from `flatpak.user` when `flatpak.flathub` is true

**Test Scenarios**:
- ✅ **Repository Addition**: Flathub remote added to flatpak configuration
- ✅ **Method Support**: System vs user-level repository configuration
- ✅ **User Context**: Proper user context handling for user-level installs
- ✅ **Conditional Logic**: Only adds repository when `flatpak.flathub` is true
- ✅ **Repository Verification**: Repository accessible for package operations

**Validation Commands**:
```bash
# Repository verification
flatpak remotes  # Should show flathub remote when enabled
flatpak remotes --show-details  # Should show flathub URL and metadata

# Method verification (system vs user)
flatpak remotes --system  # Should show flathub for system method
flatpak remotes --user    # Should show flathub for user method (if applicable)
```

**Container Compatibility**: ✅ Full validation possible in containers

---

### Flatpak Package Management (REQ-MF-004)

#### REQ-MF-004: Individual Flatpak Package Management

**Requirement**: The system SHALL be capable of managing individual flatpak packages when flatpak system is enabled

**Implementation**: When `flatpak.enabled` is true and `flatpak_packages` contains one or more packages, uses `community.general.flatpak` for package management with configurable method from `flatpak.method` and user from `flatpak.user`. Supports state-based management (present/absent)

**Test Scenarios**:
- ✅ **System Readiness**: flatpak system operational and repository accessible
- ✅ **Basic Installation**: Package installation with default state (present)
- ✅ **State Management**: Explicit present/absent state handling
- ✅ **Method Configuration**: System vs user-level package installation
- ✅ **User Context**: Proper user context for user-level operations
- ✅ **Conditional Logic**: Only triggers when flatpak enabled and packages defined
- ✅ **Edge Cases**: Graceful handling of empty `flatpak_packages` list

**Validation Commands**:
```bash
# System operational state
flatpak --version  # Should succeed (rc == 0)
flatpak remotes   # Should show configured remotes

# Package installation verification
flatpak list | grep "org.freedesktop.Platform"  # Should show installed package
flatpak list --system  # Should show system-level packages
flatpak list --user    # Should show user-level packages (if applicable)

# Package removal verification
flatpak list | grep "removed-package"  # Should NOT show removed packages
```

**Container Compatibility**: ✅ Full validation possible in containers

---

## Advanced Testing Scenarios

### State-Based Validation Approach

Following TRD methodology, all validation focuses on actual system state rather than task execution logic:

**System State Gathering**:
- Use package manager queries (`dpkg -l`, `pacman -Q`) to verify package installation
- Use `which` command to verify command availability
- Use `flatpak list` to verify package installation state
- Use `flatpak remotes` to validate repository configuration

**Conditional Logic Testing**:
- Verify no action taken when `flatpak.enabled` is false
- Verify plugins only installed when explicitly enabled
- Verify repository only added when `flatpak.flathub` is true
- Verify package management only when packages defined and system enabled

### Platform Coverage

**Ubuntu 24.04 (Primary Platform)**:
- Complete flatpak system installation testing
- Desktop plugin installation with Debian package names
- Flathub repository configuration
- Package management with all features

**Arch Linux (Secondary Platform)**:
- Flatpak installation via pacman
- Desktop plugin installation with Arch package names
- Repository and package management validation

**Container Environment**:
- All flatpak operations work reliably in Docker containers
- No container-incompatible tasks identified
- Full CI compatibility without `no-container` tags needed

### Error Handling and Edge Cases

**Empty Configuration Testing**:
- `flatpak_packages: []` - No operations performed
- `flatpak: {}` - Default behavior (no system setup, no packages)
- Undefined variables - Graceful handling with defaults

**Invalid Configuration Resilience**:
- Non-existent package names - `community.general.flatpak` module handles gracefully
- Invalid method specifications - Module provides appropriate error messages
- Permission issues - Tasks run with appropriate privilege escalation

## Molecule Implementation Plan

### Test Matrix Configuration

```yaml
platforms:
  - name: ubuntu-flatpak-system-full
    # Tests REQ-MF-001, REQ-MF-002, REQ-MF-003, REQ-MF-004
    variables:
      flatpak:
        enabled: true
        flathub: true
        method: system
        plugins:
          gnome: true
          plasma: false
      flatpak_packages:
        - name: org.freedesktop.Platform//23.08
          state: present
        - name: org.mozilla.firefox
          state: present

  - name: arch-flatpak-system-full
    # Tests platform-specific plugin installation
    variables:
      flatpak:
        enabled: true
        flathub: true
        method: system
        plugins:
          gnome: true
          plasma: true
      flatpak_packages:
        - name: org.freedesktop.Platform//23.08
          state: present

  - name: ubuntu-flatpak-packages-basic
    # Tests REQ-MF-004 basic package management
    variables:
      flatpak:
        enabled: true
        flathub: true
        method: system
        plugins:
          gnome: false
          plasma: false
      flatpak_packages:
        - name: org.freedesktop.Platform//23.08
          state: present
        - name: unwanted-package
          state: absent

  - name: ubuntu-flatpak-no-action
    # Tests edge cases and no-action scenarios
    variables:
      flatpak:
        enabled: false
      flatpak_packages: []
```

### Verification Strategy

**Positive Case Validation**:
- Assert expected system state after role execution
- Verify all requirements met through direct system commands
- Validate idempotency through molecule's built-in idempotence testing

**Negative Case Validation**:
- Verify no unwanted actions when features disabled
- Confirm conditional logic prevents inappropriate operations
- Test graceful handling of edge cases and empty configurations

### CI Integration

**Container Compatibility**: ✅ All tasks compatible with container environment
**CI Configuration**: Standard molecule test without special skip-tags needed
**Performance**: Estimated test duration < 5 minutes per scenario

## Success Criteria

**All Requirements Validated**: REQ-MF-001, REQ-MF-002, REQ-MF-003, REQ-MF-004
**State-Based Testing**: System state verification for all scenarios
**Container Compatibility**: Full testing possible in CI environment
**Error Resilience**: Graceful handling of edge cases and invalid configurations
**Documentation Alignment**: Tests match SRD requirements exactly

## Implementation Status

✅ **SRD Requirements**: All 4 requirements clearly defined with trigger conditions
✅ **Role Implementation**: Complete with unified `flatpak_packages` variable structure
✅ **Tag Strategy**: Comprehensive functional tags following collection patterns
✅ **Variable Documentation**: Complete flatpak.* variable definitions in Section 2.2.1
✅ **CI Integration**: Role exists in `.gitlab-ci.yml` with proper configuration

**Ready for CI Validation**: All requirements documented, comprehensive variable structure implemented, validation plan complete.
