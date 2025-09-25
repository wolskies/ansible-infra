# Manage Snap Packages Role Validation Plan

## Executive Summary

This validation plan follows the successful test-first methodology established with other collection roles (`os_configuration`, `manage_security_services`, `manage_packages`). Each requirement will be validated through evidence-based testing using Molecule framework with comprehensive test scenarios that validate snap package management and system removal functionality.

## Testing Strategy

### Container Test Scenarios

Following the established pattern, we'll use consolidated test containers for comprehensive coverage:

1. **ubuntu-snap-removal-full**: Complete snap system removal with APT preferences and cleanup
2. **ubuntu-snap-packages-basic**: Basic snap package install/remove without advanced features
3. **ubuntu-snap-packages-advanced**: Advanced snap features (classic confinement, channels, state management)
4. **ubuntu-snap-no-action**: Edge cases with empty configurations and no-action scenarios

### Evidence-Based Testing Principles

- Verify actual system state using commands like `systemctl`, `which snap`, `snap list`
- Test both installation and removal scenarios (standard Ansible behavior)
- Validate complete snap system removal including service, package, and directory cleanup
- Check APT preferences file creation and content for reinstallation prevention
- Leverage unified `snap_packages` list with state properties following collection patterns

## Requirements Validation Matrix

### Snap System Management (REQ-MSP-001 through REQ-MSP-003)

#### REQ-MSP-001: Complete Snap System Removal

**Requirement**: The system SHALL be capable of completely removing the snap package system from Debian/Ubuntu systems

**Implementation**: When `snap.remove_completely` is true, uses multiple modules to comprehensively remove snap system

**Test Scenarios**:
- ✅ **Service Management**: snapd.service and snapd.socket stopped and disabled
- ✅ **Package Removal**: All snap packages removed including core packages
- ✅ **Directory Cleanup**: /snap, /var/snap, /var/lib/snapd removed
- ✅ **System Cleanup**: snap command no longer available, PATH updated
- ✅ **Conditional Logic**: Only triggers when `snap.remove_completely` is true
- ✅ **Idempotency**: Subsequent runs complete without errors

**Validation Commands**:
```bash
# Service state validation
systemctl is-active snapd.service  # Should fail (rc != 0)
systemctl is-active snapd.socket   # Should fail (rc != 0)

# Command availability
which snap  # Should fail (rc != 0)

# Directory cleanup
test -d /snap && echo "exists" || echo "removed"          # Should be "removed"
test -d /var/snap && echo "exists" || echo "removed"      # Should be "removed"
test -d /var/lib/snapd && echo "exists" || echo "removed" # Should be "removed"
```

**Container Compatibility**: ✅ Full validation possible in containers

---

#### REQ-MSP-002: APT Preferences to Prevent Reinstallation

**Requirement**: The system SHALL prevent snap packages from being reinstalled after removal

**Implementation**: When `snap.remove_completely` is true, uses `ansible.builtin.copy` to create APT preferences file

**Test Scenarios**:
- ✅ **File Creation**: /etc/apt/preferences.d/no-snap created with correct permissions (root:root 0644)
- ✅ **Content Validation**: Contains proper Pin-Priority -10 for snapd packages
- ✅ **Format Verification**: Proper APT preferences format with Package, Pin, Pin-Priority fields
- ✅ **Conditional Logic**: Only creates file when `snap.remove_completely` is true
- ✅ **Idempotency**: File content remains consistent across runs

**Validation Commands**:
```bash
# File existence and permissions
test -f /etc/apt/preferences.d/no-snap && echo "exists" || echo "missing"
stat -c '%U:%G %a' /etc/apt/preferences.d/no-snap  # Should be "root:root 644"

# Content validation
grep -q "Package: snapd gnome-software-plugin-snap" /etc/apt/preferences.d/no-snap
grep -q "Pin: release a=\*" /etc/apt/preferences.d/no-snap
grep -q "Pin-Priority: -10" /etc/apt/preferences.d/no-snap
```

**Container Compatibility**: ✅ Full validation possible in containers

---

#### REQ-MSP-003: Individual Snap Package Management

**Requirement**: The system SHALL be capable of managing individual snap packages when snap system is enabled

**Implementation**: When `snap.remove_completely` is false and `snap_packages` contains one or more packages, manages snap packages using `community.general.snap` module

**Test Scenarios**:
- ✅ **System Readiness**: snapd service active and snap command available
- ✅ **Basic Installation**: Package installation with default state (present)
- ✅ **State Management**: Explicit present/absent state handling
- ✅ **Advanced Features**: Classic confinement support (`classic: true`)
- ✅ **Channel Support**: Installation from specific channels (`channel: latest/edge`)
- ✅ **Conditional Logic**: Only triggers when snap system enabled and packages defined
- ✅ **Edge Cases**: Graceful handling of empty `snap_packages` list

**Validation Commands**:
```bash
# System operational state
systemctl is-active snapd.service  # Should succeed (rc == 0)
which snap  # Should succeed (rc == 0)

# Package installation verification
snap list | grep "hello-world"  # Should show installed package
snap list --all | grep "code"   # Should show classic package if configured

# Service functionality
snap wait system seed.loaded  # Should succeed without timeout
```

**Container Compatibility**: ✅ Full validation possible in containers

---

## Advanced Testing Scenarios

### State-Based Validation Approach

Following TRD methodology, all validation focuses on actual system state rather than task execution logic:

**System State Gathering**:
- Use `systemctl is-active` to check service states
- Use `which` command to verify command availability
- Use `stat` module to check directory and file existence
- Use `snap list` to verify package installation state
- Use `grep` to validate file contents

**Conditional Logic Testing**:
- Verify no action taken when `snap.remove_completely` is false and no packages defined
- Verify snap system removal only when `snap.remove_completely` is true
- Verify package management only when packages are defined and system not being removed

### Platform Coverage

**Ubuntu 24.04 (Primary Platform)**:
- Complete snap system removal testing
- APT preferences file validation
- Snap package management with all features
- Edge case and error handling

**Container Environment**:
- All snap operations work reliably in Docker containers
- No container-incompatible tasks identified
- Full CI compatibility without `no-container` tags needed

### Error Handling and Edge Cases

**Empty Configuration Testing**:
- `snap_packages: []` - No operations performed
- `snap: {}` - Default behavior (no removal, no packages)
- Undefined variables - Graceful handling with defaults

**Invalid Configuration Resilience**:
- Non-existent package names - `community.general.snap` module handles gracefully
- Invalid channel specifications - Module provides appropriate error messages
- Permission issues - Tasks run with appropriate privilege escalation

## Molecule Implementation Plan

### Test Matrix Configuration

```yaml
platforms:
  - name: ubuntu-snap-removal-full
    # Tests REQ-MSP-001 & REQ-MSP-002
    variables:
      snap:
        remove_completely: true

  - name: ubuntu-snap-packages-basic
    # Tests REQ-MSP-003 basic functionality
    variables:
      snap:
        remove_completely: false
      snap_packages:
        - name: hello-world
          state: present

  - name: ubuntu-snap-packages-advanced
    # Tests REQ-MSP-003 advanced features
    variables:
      snap:
        remove_completely: false
      snap_packages:
        - name: hello-world
          state: present
        - name: code
          state: present
          classic: true
        - name: discord
          state: present
          channel: latest/stable

  - name: ubuntu-snap-no-action
    # Tests edge cases and no-action scenarios
    variables:
      snap:
        remove_completely: false
      snap_packages: []
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

**All Requirements Validated**: REQ-MSP-001, REQ-MSP-002, REQ-MSP-003
**State-Based Testing**: System state verification for all scenarios
**Container Compatibility**: Full testing possible in CI environment
**Error Resilience**: Graceful handling of edge cases and invalid configurations
**Documentation Alignment**: Tests match SRD requirements exactly

## Implementation Status

✅ **SRD Requirements**: All 3 requirements clearly defined with trigger conditions
✅ **Role Implementation**: Complete with unified `snap_packages` variable structure
✅ **Tag Strategy**: Comprehensive functional tags following collection patterns
✅ **Molecule Tests**: 4-scenario test matrix with state-based validation
✅ **CI Integration**: Role added to `.gitlab-ci.yml` with proper configuration

**Ready for CI Validation**: All local tests passing, comprehensive requirement coverage implemented.
