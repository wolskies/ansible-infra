# Manage Security Services Role Validation Plan

## Executive Summary

This validation plan follows the successful test-first methodology established with the `os_configuration` role. Each requirement will be validated through evidence-based testing using Molecule framework with comprehensive test scenarios.

## Testing Strategy

### Container Test Scenarios

Following the `os_configuration` model, we'll use consolidated test containers for comprehensive coverage:

1. **ubuntu-firewall-full**: Complete firewall + fail2ban configuration (positive tests)
2. **ubuntu-firewall-partial**: Firewall only, no fail2ban (mixed state tests)
3. **ubuntu-fail2ban-only**: Fail2ban only, no firewall (isolation tests)
4. **ubuntu-security-disabled**: All security features disabled (negative tests)
5. **ubuntu-edge-cases**: Special configurations and error conditions

### Evidence-Based Testing Principles

- Verify actual system state, not just task execution
- Test both enable and disable scenarios (standard Ansible behavior)
- Validate idempotency through Molecule's built-in checks
- Check for proper error handling and edge cases

## Requirements Validation Matrix

### Linux Security Services (REQ-SS-001 through REQ-SS-007)

#### REQ-SS-001: UFW Package Installation

**Test Scenarios**:
- ✅ Positive: Package installed when `firewall.enabled: true`
- ✅ Negative: Package not installed when `firewall.enabled: false`
- ✅ Edge: Handle unknown package type gracefully

**Validation Approach**:
```yaml
- name: Check UFW package installation
  ansible.builtin.package_facts:
    manager: auto

- name: Verify UFW installed (positive)
  ansible.builtin.assert:
    that:
      - "'ufw' in ansible_facts.packages"
    fail_msg: "UFW package not installed"
```

#### REQ-SS-002: SSH Protection During Firewall Operations

**Test Scenarios**:
- ✅ Positive: SSH port detected from connection
- ✅ Fallback: Use ansible_port when SSH_CONNECTION unavailable
- ✅ Default: Fall back to port 22
- ✅ Disabled: Skip when `firewall.prevent_ssh_lockout: false`

**Validation Approach**:
```yaml
- name: Verify SSH port detection
  ansible.builtin.assert:
    that:
      - current_ssh_port is defined
      - current_ssh_port | int > 0
      - current_ssh_port | int < 65536
```

#### REQ-SS-003: Firewall Rules Configuration

**Test Scenarios**:
- ✅ Basic rules: allow/deny with port
- ✅ Complex rules: source, destination, interface, direction
- ✅ Multiple rules: proper ordering
- ✅ Empty rules: handle gracefully
- ✅ Invalid rules: proper error messages

**Validation Approach**:
```yaml
- name: Check UFW rules
  ansible.builtin.command: ufw status numbered
  register: ufw_rules

- name: Verify specific rule exists
  ansible.builtin.assert:
    that:
      - ufw_rules.stdout is search('22/tcp.*ALLOW')
```

#### REQ-SS-004: UFW Service State Management

**Test Scenarios**:
- ✅ Enable: Service activated when `firewall.enabled: true`
- ✅ Current state preserved: Don't force disable (avoid lockouts)
- ✅ Idempotency: No changes on second run

**Validation Approach**:
```yaml
- name: Check UFW service state
  ansible.builtin.command: ufw status
  register: ufw_status

- name: Verify UFW enabled
  ansible.builtin.assert:
    that:
      - "'Status: active' in ufw_status.stdout"
```

#### REQ-SS-005: Fail2ban Package Installation

**Test Scenarios**:
- ✅ Positive: Package installed when `fail2ban.enabled: true`
- ✅ Negative: Package not installed when disabled
- ✅ Undefined: Handle missing fail2ban config gracefully

**Validation Approach**:
```yaml
- name: Verify fail2ban package
  ansible.builtin.assert:
    that:
      - "'fail2ban' in ansible_facts.packages"
    when: fail2ban.enabled | default(false)
```

#### REQ-SS-006: Fail2ban Configuration

**Test Scenarios**:
- ✅ Global settings: bantime, findtime, maxretry
- ✅ Jail configurations: sshd, custom jails
- ✅ Template rendering: proper file generation
- ✅ File permissions: 0644 with root ownership

**Validation Approach**:
```yaml
- name: Check jail.local exists
  ansible.builtin.stat:
    path: /etc/fail2ban/jail.local

- name: Verify jail configuration
  ansible.builtin.command: fail2ban-client status sshd
  register: jail_status
```

#### REQ-SS-007: Fail2ban Service Management

**Test Scenarios**:
- ✅ Started/enabled when `fail2ban.enabled: true`
- ✅ Stopped/disabled when false
- ✅ Service restart on config change (handler)

**Validation Approach**:
```yaml
- name: Check fail2ban service
  ansible.builtin.service_facts:

- name: Verify fail2ban running
  ansible.builtin.assert:
    that:
      - ansible_facts.services['fail2ban.service'].state == 'running'
      - ansible_facts.services['fail2ban.service'].status == 'enabled'
```

### macOS Security Services (REQ-SS-008 through REQ-SS-012)

#### REQ-SS-008: Firewall State Check

**Test Scenarios**:
- ✅ Query current state without changes
- ✅ Idempotency: changed_when false

**Validation Approach**:
```yaml
- name: Get firewall state
  ansible.builtin.command: /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
  register: fw_state

- name: Verify state check idempotent
  ansible.builtin.assert:
    that:
      - not fw_state.changed
```

#### REQ-SS-009: Application Layer Firewall Enable/Disable

**Test Scenarios**:
- ✅ Enable when `firewall.enabled: true`
- ✅ Disable when false
- ✅ Idempotency based on state comparison

**Validation Approach**:
```yaml
- name: Verify firewall enabled
  ansible.builtin.assert:
    that:
      - "'Firewall is enabled' in fw_state.stdout"
    when: firewall.enabled | default(false)
```

#### REQ-SS-010: Stealth Mode Configuration

**Test Scenarios**:
- ✅ Enable stealth when `firewall.stealth_mode: true`
- ✅ Disable when false
- ✅ Default to false

**Validation Approach**:
```yaml
- name: Check stealth mode
  ansible.builtin.command: /usr/libexec/ApplicationFirewall/socketfilterfw --getstealthmode
```

#### REQ-SS-011: Block All Configuration

**Test Scenarios**:
- ✅ Enable block all when `firewall.block_all: true`
- ✅ Disable when false
- ✅ Default to false

**Validation Approach**:
```yaml
- name: Check block all setting
  ansible.builtin.command: /usr/libexec/ApplicationFirewall/socketfilterfw --getblockall
```

#### REQ-SS-012: Firewall Logging

**Test Scenarios**:
- ✅ Version check for logging capability
- ✅ Enable logging when supported and requested
- ✅ Set detailed logging level
- ✅ Skip gracefully on older versions

**Validation Approach**:
```yaml
- name: Check logging availability
  ansible.builtin.command: /usr/libexec/ApplicationFirewall/socketfilterfw -h
  register: fw_help

- name: Verify logging if available
  ansible.builtin.command: /usr/libexec/ApplicationFirewall/socketfilterfw --getloggingmode
  when: "'--setloggingmode' in fw_help.stdout"
```

## Test Data Configuration

### Container: ubuntu-firewall-full
```yaml
firewall:
  enabled: true
  package: ufw
  prevent_ssh_lockout: true
  rules:
    - rule: allow
      port: 22
      protocol: tcp
      comment: "SSH access"
    - rule: allow
      port: 80
      protocol: tcp
      comment: "HTTP"
    - rule: allow
      port: 443
      protocol: tcp
      comment: "HTTPS"
    - rule: deny
      source: 10.0.0.0/8
      comment: "Block private network"

fail2ban:
  enabled: true
  bantime: "10m"
  findtime: "10m"
  maxretry: 5
  jails:
    - name: sshd
      enabled: true
      port: ssh
      logpath: /var/log/auth.log
      maxretry: 3
```

### Container: ubuntu-firewall-partial
```yaml
firewall:
  enabled: true
  package: ufw
  prevent_ssh_lockout: true
  rules:
    - rule: allow
      port: 22
      protocol: tcp

fail2ban:
  enabled: false
```

### Container: ubuntu-fail2ban-only
```yaml
firewall:
  enabled: false

fail2ban:
  enabled: true
  bantime: "1h"
  findtime: "30m"
  maxretry: 10
  jails:
    - name: sshd
      enabled: true
      port: ssh
      logpath: /var/log/auth.log
```

### Container: ubuntu-security-disabled
```yaml
firewall:
  enabled: false

fail2ban:
  enabled: false
```

### Container: ubuntu-edge-cases
```yaml
firewall:
  enabled: true
  package: unknown  # Test unknown package handling
  prevent_ssh_lockout: false  # Test SSH lockout prevention disabled
  rules: []  # Empty rules array

fail2ban:
  enabled: true
  bantime: "1d"
  findtime: "1h"
  maxretry: 2
  jails: []  # Empty jails array
```

## Success Criteria

1. **All positive tests pass**: Services enabled and configured correctly
2. **All negative tests pass**: Services properly disabled/absent
3. **Idempotency verified**: No changes on second run
4. **Error handling works**: Graceful handling of edge cases
5. **Standard Ansible behavior**: Proper enable/disable behavior
6. **Cross-platform compatibility**: Works on Linux and macOS (when applicable)

## Implementation Order

Following the successful `os_configuration` pattern:

1. Create molecule test infrastructure
2. Write comprehensive verify.yml with all assertions
3. Implement test scenarios in molecule.yml
4. Fix production code issues found during testing
5. Document any discovered requirements gaps
6. Ensure CI pipeline integration

This validation plan ensures comprehensive testing of all security service requirements with the same rigor and quality that made `os_configuration` successful.
