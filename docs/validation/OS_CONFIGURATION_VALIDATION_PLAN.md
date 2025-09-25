# os_configuration Role Validation Plan

**Document Version:** 1.1
**Role:** os_configuration
**Total Requirements:** 28 (REQ-OS-001 through REQ-OS-028)
**Last Updated:** September 23, 2025

**Reference**: See TRD for general molecule testing methodology and best practices.

---

## Cross-Platform Requirements (REQ-OS-001 to REQ-OS-003)

### REQ-OS-001: System Hostname Configuration

**Requirement**: The system SHALL be capable of setting the system hostname
**Implementation**: Uses `ansible.builtin.hostname` module when `host_hostname` is defined and non-empty
**Production Code**: `roles/os_configuration/tasks/main.yml` - "Configure system hostname" task

#### State Validation Specifications

**Initial State**: Container hostname is typically the container ID (e.g., "ubuntu-hostname-positive")
**Target State**: System hostname should match `host_hostname` variable when defined and non-empty

#### Validation Test Scenarios

**Scenario 1: Positive Validation**

```yaml
test_case: "Set hostname to test-hostname"
platform: ubuntu-hostname-positive
input_variables:
  host_hostname: "test-hostname"
initial_state:
  hostname_before: "ubuntu-hostname-positive" # Container ID
expected_final_state:
  hostname_after: "test-hostname"
verification_commands:
  - command: "hostname"
    expected_output: "test-hostname"
    environment: "VM/bare metal only (container limitation)"
validation_logic:
  positive_case:
    - host_hostname is defined ✓
    - host_hostname | length > 0 ✓
    - Task should execute
  container_behavior:
    - Skip assertion due to Docker limitations
    - Display warning: "⚠️ REQ-OS-001: Hostname validation skipped in container"
success_criteria:
  - "✅ VM/bare metal: hostname command returns 'test-hostname'"
  - "✅ Container: Conditional logic validated, limitation documented"
```

**Scenario 2: Negative Validation - Empty Hostname**

```yaml
test_case: "Empty hostname unchanged"
platform: ubuntu-hostname-empty
input_variables:
  host_hostname: "" # Empty string
initial_state:
  hostname_before: "ubuntu-hostname-empty" # Container ID
expected_final_state:
  hostname_after: "ubuntu-hostname-empty" # Unchanged
verification_commands:
  - command: "hostname"
    expected_output: "ubuntu-hostname-empty" # Original container name
validation_logic:
  negative_case:
    - host_hostname is defined ✓
    - host_hostname | length > 0 ✗ (empty string)
    - Task should be skipped
success_criteria:
  - "✅ hostname command returns original value (unchanged)"
  - "✅ Conditional logic working: empty string triggers skip"
```

**Scenario 3: Negative Validation - Undefined Hostname**

```yaml
test_case: "Undefined hostname unchanged"
platform: ubuntu-hostname-undefined
input_variables:
  # host_hostname variable intentionally not defined
initial_state:
  hostname_before: "ubuntu-hostname-undefined" # Container ID
expected_final_state:
  hostname_after: "ubuntu-hostname-undefined" # Unchanged
verification_commands:
  - command: "hostname"
    expected_output: "ubuntu-hostname-undefined" # Original container name
validation_logic:
  negative_case:
    - host_hostname is defined ✗ (undefined)
    - Task should be skipped
success_criteria:
  - "✅ hostname command returns original value (unchanged)"
  - "✅ Conditional logic working: undefined variable triggers skip"
```

#### Implementation Strategy

**Testing Environment**: Molecule with Docker containers (sufficient for state validation)

**Container Limitations**: Hostname changes may not persist in containers due to Docker restrictions. Verification approach:

- **Container environment**: Skip hostname assertion, document limitation with warning message
- **VM/bare metal environment**: Full hostname validation via `hostname` command
- **Conditional logic**: Always validated regardless of environment (negative test cases)
- **CI compatibility**: Tests pass in containers by gracefully handling limitations

**Molecule Platform Configuration**:

```yaml
platforms:
  - name: ubuntu-hostname-positive
    image: geerlingguy/docker-ubuntu2404-ansible:latest
  - name: ubuntu-hostname-empty
    image: geerlingguy/docker-ubuntu2404-ansible:latest
  - name: ubuntu-hostname-undefined
    image: geerlingguy/docker-ubuntu2404-ansible:latest

host_vars:
  ubuntu-hostname-positive:
    host_hostname: "test-hostname"
  ubuntu-hostname-empty:
    host_hostname: ""
  ubuntu-hostname-undefined:
    # host_hostname intentionally omitted
```

**Validation Approach**: State-based verification after role execution with environment detection

- **Positive case (VM/bare metal)**: Check actual hostname via `hostname` command matches expected value
- **Positive case (containers)**: Document limitation, defer to VM testing - ensures CI compatibility
- **Negative cases**: Check hostname remains at original value (unchanged) - works in all environments
- **Environment detection**: Uses `ansible_virtualization_type != "docker"` to determine validation approach

**Success Criteria**:

- **Containers**: Conditional logic validation + graceful limitation handling
- **VM/bare metal**: Full system state validation including hostname changes
  **CI Compatibility**: All tests pass in container environments by design

**Environment**: Container (Primary) + CI Pipeline, VM (Complete hostname functionality in Phase 3)

---

### REQ-OS-002: /etc/hosts Update

**Requirement**: The system SHALL be capable of updating the `/etc/hosts` file with hostname entries
**Implementation**: Uses `ansible.builtin.lineinfile` to update `/etc/hosts` when `host_update_hosts` is true, format: `127.0.0.1 localhost {hostname}.{domain} {hostname}`
**Production Code**: `roles/os_configuration/tasks/main.yml` - "Update /etc/hosts file" task

#### State Validation Specifications

**Initial State**: Basic `/etc/hosts` with standard localhost entries
**Target State**: `/etc/hosts` should contain additional line `127.0.0.1 localhost {hostname}.{domain} {hostname}` when all conditions met

#### Validation Test Scenarios

**Scenario 1: Positive Validation - All Conditions Met**

```yaml
test_case: "Add hostname to /etc/hosts"
platform: ubuntu-hosts-positive
input:
  host_hostname: "testhost"
  domain_name: "example.com"
  host_update_hosts: true
expected_file_state:
  - file_path: "/etc/hosts"
  - contains_entry: "127.0.0.1	localhost testhost.example.com testhost"
  - format_correct: true
verification_method:
  - command: "grep 'testhost\.example\.com' /etc/hosts"
    expected_match: "127.0.0.1.*localhost.*testhost.example.com.*testhost"
  - file_check: "/etc/hosts"
    contains: "testhost.example.com"
success_criteria:
  - "✅ /etc/hosts contains correct hostname entry"
  - "✅ Entry format matches expected pattern"
  - "✅ Multiple hostname references present (FQDN and short)"
```

**Scenario 2: Negative Validation - host_update_hosts Disabled**

```yaml
test_case: "No changes when host_update_hosts false"
platform: ubuntu-hosts-disabled
input:
  host_hostname: "testhost"
  domain_name: "example.com"
  host_update_hosts: false
expected_file_state:
  - file_path: "/etc/hosts"
  - no_hostname_entries: true
  - unchanged_from_baseline: true
verification_method:
  - command: "grep testhost /etc/hosts || echo 'not found'"
    expected_output: "not found"
  - verify: /etc/hosts contains no testhost references
success_criteria:
  - "✅ /etc/hosts contains no hostname entries"
  - "✅ File remains unchanged from baseline"
```

**Scenario 3: Negative Validation - Missing domain_name**

```yaml
test_case: "No changes when domain_name missing"
platform: ubuntu-hosts-no-domain
input:
  host_hostname: "testhost"
  host_update_hosts: true
  # domain_name intentionally undefined
expected_file_state:
  - file_path: "/etc/hosts"
  - no_hostname_entries: true
  - unchanged_from_baseline: true
verification_method:
  - command: "grep testhost /etc/hosts || echo 'not found'"
    expected_output: "not found"
  - verify: /etc/hosts contains no testhost references
success_criteria:
  - "✅ /etc/hosts contains no hostname entries"
  - "✅ File remains unchanged from baseline"
```

**Scenario 4: Negative Validation - Missing host_hostname**

```yaml
test_case: "No changes when host_hostname missing"
platform: ubuntu-hosts-no-hostname
input:
  domain_name: "example.com"
  host_update_hosts: true
  # host_hostname intentionally undefined
expected_file_state:
  - file_path: "/etc/hosts"
  - no_new_entries: true
  - unchanged_from_baseline: true
verification_method:
  - command: "grep -c '127.0.0.1.*localhost' /etc/hosts"
    expected_behavior: returns_baseline_count_only
  - verify: no additional hostname entries added
success_criteria:
  - "✅ /etc/hosts contains no new hostname entries"
  - "✅ File remains unchanged from baseline"
```

#### Implementation Strategy

**Testing Environment**: Molecule with Docker containers (sufficient for file operations and conditional logic validation)

**Molecule Platform Configuration**:

```yaml
platforms:
  - name: ubuntu-hosts-positive
    image: geerlingguy/docker-ubuntu2404-ansible:latest
  - name: ubuntu-hosts-disabled
    image: geerlingguy/docker-ubuntu2404-ansible:latest
  - name: ubuntu-hosts-no-domain
    image: geerlingguy/docker-ubuntu2404-ansible:latest
  - name: ubuntu-hosts-no-hostname
    image: geerlingguy/docker-ubuntu2404-ansible:latest

host_vars:
  ubuntu-hosts-positive:
    host_hostname: "testhost"
    domain_name: "example.com"
    host_update_hosts: true
  ubuntu-hosts-disabled:
    host_hostname: "testhost"
    domain_name: "example.com"
    host_update_hosts: false
  ubuntu-hosts-no-domain:
    host_hostname: "testhost"
    host_update_hosts: true
    # domain_name intentionally omitted
  ubuntu-hosts-no-hostname:
    domain_name: "example.com"
    host_update_hosts: true
    # host_hostname intentionally omitted
```

**Validation Approach**:

- Full role execution with Ansible task execution metadata validation
- Task execution behavior validation (skipped/changed/unchanged)
- Idempotency testing via multiple role executions

**Container Testing Success Criteria**:

- Task execution behavior (skipped/changed/unchanged) validates conditional logic
- File operations may fail in containers - focus on task execution metadata

**VM Testing (Phase 3) Success Criteria**:

- All container testing criteria PLUS
- File content verification for positive cases
- Actual `/etc/hosts` entry format validation
- End-to-end functional testing

**Environment**: Container (Primary - conditional logic) + CI Pipeline, VM (Complete validation in Phase 3)

---

### REQ-OS-003: System Timezone

**Requirement**: The system SHALL be capable of setting the system timezone
**Implementation**: Uses `community.general.timezone` module when `domain_timezone` is defined and non-empty
**Production Code**: `roles/os_configuration/tasks/main.yml` - "Set system timezone" task

#### State Validation Specifications

**Initial State**: Container default timezone (typically `Etc/UTC` or `America/New_York`)
**Target State**: System timezone should match `domain_timezone` variable when defined and non-empty

#### Validation Test Scenarios

**Scenario 1: Positive Validation**

```yaml
test_case: "Set timezone to America/New_York"
platform: ubuntu-timezone-positive
input:
  domain_timezone: "America/New_York"
expected_system_state:
  - timezone: "America/New_York"
  - timedatectl_output: contains "America/New_York"
verification_method:
  - command: "timedatectl show --property=Timezone --value"
    expected_output: "America/New_York"
  - command: "date +%Z"
    expected_behavior: shows_eastern_timezone
success_criteria:
  - "✅ System timezone is set to America/New_York"
  - "✅ timedatectl shows correct timezone"
```

**Scenario 2: Negative Validation - Empty Timezone**

```yaml
test_case: "Empty timezone unchanged"
platform: ubuntu-timezone-empty
input:
  domain_timezone: "" # Empty string
expected_system_state:
  - timezone: original_timezone (unchanged)
  - no_timezone_changes: true
verification_method:
  - command: "timedatectl show --property=Timezone --value"
    expected_behavior: returns_original_timezone
  - verify: timezone remains at system default
success_criteria:
  - "✅ System timezone remains unchanged"
  - "✅ No timezone modification attempted"
```

**Scenario 3: Negative Validation - Undefined Timezone**

```yaml
test_case: "Undefined timezone unchanged"
platform: ubuntu-timezone-undefined
input:
  # domain_timezone variable intentionally not defined
expected_system_state:
  - timezone: original_timezone (unchanged)
  - no_timezone_changes: true
verification_method:
  - command: "timedatectl show --property=Timezone --value"
    expected_behavior: returns_original_timezone
  - verify: timezone remains at system default
success_criteria:
  - "✅ System timezone remains unchanged"
  - "✅ No timezone modification attempted"
```

#### Implementation Strategy

**Testing Environment**: Molecule with Docker containers (sufficient for conditional logic validation)

**Container Limitations**: Timezone changes may not persist in containers due to systemd restrictions. Verification approach:

- **Container environment**: Skip timezone assertion, document limitation with warning message
- **VM/bare metal environment**: Full timezone validation via `timedatectl` command
- **Conditional logic**: Always validated regardless of environment (negative test cases)
- **CI compatibility**: Tests pass in containers by gracefully handling limitations

**Molecule Platform Configuration**:

```yaml
platforms:
  - name: ubuntu-timezone-positive
    image: geerlingguy/docker-ubuntu2404-ansible:latest
  - name: ubuntu-timezone-empty
    image: geerlingguy/docker-ubuntu2404-ansible:latest
  - name: ubuntu-timezone-undefined
    image: geerlingguy/docker-ubuntu2404-ansible:latest

host_vars:
  ubuntu-timezone-positive:
    domain_timezone: "America/New_York"
  ubuntu-timezone-empty:
    domain_timezone: ""
  ubuntu-timezone-undefined:
    # domain_timezone intentionally omitted
```

**Validation Approach**: State-based verification after role execution with environment detection

- **Positive case (VM/bare metal)**: Check actual timezone via `timedatectl` command matches expected value
- **Positive case (containers)**: Document limitation, defer to VM testing - ensures CI compatibility
- **Negative cases**: Check timezone remains at original value (unchanged) - works in all environments
- **Environment detection**: Uses `ansible_virtualization_type != "docker"` to determine validation approach

**Success Criteria**:

- **Containers**: Conditional logic validation + graceful limitation handling
- **VM/bare metal**: Full system state validation including timezone changes
  **CI Compatibility**: All tests pass in container environments by design

**Environment**: Container (Primary) + CI Pipeline, VM (Complete timezone functionality in Phase 3)

---

### REQ-OS-004: OS Security Hardening

**Requirement**: The system SHALL be capable of implementing OS security hardening configurations using `devsec.hardening.os_hardening` role
**Implementation**: Uses `ansible.builtin.include_role` to call `devsec.hardening.os_hardening` when security hardening is enabled
**Production Code**: `roles/os_configuration/tasks/configure-Linux.yml` - "Apply OS security hardening (Linux)" task

#### Validation Test Scenarios

**Scenario 1: Positive Validation - Security Hardening Enabled**

```yaml
test_case: "Call devsec.hardening.os_hardening role when enabled"
platform: ubuntu-security-enabled
input:
  host_security:
    hardening_enabled: true
expected_task_result:
  - task_name: "Apply OS security hardening (Linux)"
  - execution: included (not skipped)
  - role_called: devsec.hardening.os_hardening
  - no_failures: true
success_criteria:
  - "✅ devsec.hardening.os_hardening role inclusion executes when enabled"
```

**Scenario 2: Negative Validation - Security Hardening Disabled**

```yaml
test_case: "Skip devsec.hardening.os_hardening role when disabled"
platform: ubuntu-security-disabled
input:
  host_security:
    hardening_enabled: false
expected_task_result:
  - task_name: "Apply OS security hardening (Linux)"
  - execution: skipped=true
  - skip_reason: "host_security.hardening_enabled | default(true) evaluates to false"
  - no_failures: true
success_criteria:
  - "✅ devsec.hardening.os_hardening role inclusion skipped when disabled"
```

#### Implementation Strategy

**Testing Environment**: Molecule with Docker containers (sufficient for role delegation validation)

**Molecule Platform Configuration**:

```yaml
platforms:
  - name: ubuntu-security-enabled
    image: geerlingguy/docker-ubuntu2404-ansible:latest
  - name: ubuntu-security-disabled
    image: geerlingguy/docker-ubuntu2404-ansible:latest

host_vars:
  ubuntu-security-enabled:
    host_security:
      hardening_enabled: true
  ubuntu-security-disabled:
    host_security:
      hardening_enabled: false
```

**Validation Approach**: Task execution metadata validation for `devsec.hardening.os_hardening` role inclusion
**Success Criteria**: Role inclusion behavior (skipped vs executed) - validates OUR conditional logic

**Environment**: Container (Primary) + CI Pipeline

---

## Scaling Strategy for Remaining Requirements

**Current Implementation**: Individual requirement testing with dedicated scenarios

- REQ-OS-001 to REQ-OS-004: 12 containers total (3+4+3+2 scenarios)
- Pattern: Detailed scenario coverage for each requirement

**Future Consolidation Plan**: Shared container strategy for remaining requirements

- **Target**: 15-20 containers total for all 28 requirements (instead of ~84)
- **Approach**: Group requirements by conditional logic patterns
- **Shared Containers**:
  ```yaml
  ubuntu-full-positive: # Multiple requirements enabled
  ubuntu-security-disabled: # Security off, basic features on
  ubuntu-minimal: # Most features disabled
  ubuntu-edge-cases: # Complex variable combinations
  ```

**Implementation Strategy**:

1. **Phase 1**: Continue individual requirement testing (REQ-OS-005+) to understand patterns
2. **Phase 2**: Consolidate into shared containers once patterns are clear
3. **Phase 3**: Document final shared container design in validation plan

**Benefits**: Maintains thorough validation while scaling efficiently across the full role.

---

## Linux-Specific Requirements (REQ-OS-004 to REQ-OS-021)

### REQ-OS-004: OS Security Hardening

**Requirement**: The system SHALL be capable of applying OS security hardening on Linux systems
**Implementation**: Uses `devsec.hardening.os_hardening` role when `host_security.hardening_enabled` is true

**Positive Validation**:

```yaml
test_case: "Apply OS hardening"
input:
  host_security:
    hardening_enabled: true
verify:
  - role_executed: "devsec.hardening.os_hardening"
  - file_exists: "/etc/sysctl.d/99-hardening.conf"
  - sysctl_value: "kernel.dmesg_restrict"
    expected: "1"
```

**Negative Validation**:

```yaml
test_case: "Skip when hardening disabled"
input:
  host_security:
    hardening_enabled: false
verify:
  - role_not_executed: "devsec.hardening.os_hardening"
  - no_changes: true
```

**Environment**: Both (Container + VM)

---

### REQ-OS-005: SSH Security Hardening

**Requirement**: The system SHALL be capable of applying SSH security hardening on Linux systems
**Implementation**: Uses `ansible.builtin.include_role` to call `devsec.hardening.ssh_hardening` when SSH hardening is enabled
**Production Code**: `roles/os_configuration/tasks/configure-Linux.yml` - "Apply SSH security hardening (Linux)" task

#### Validation Test Scenarios

**Scenario 1: Positive Validation - SSH Hardening Enabled**

```yaml
test_case: "Call devsec.hardening.ssh_hardening role when enabled"
platform: ubuntu-ssh-enabled
input:
  host_security:
    ssh_hardening_enabled: true
expected_task_result:
  - task_name: "Apply SSH security hardening (Linux)"
  - execution: included (not skipped)
  - role_called: devsec.hardening.ssh_hardening
  - no_failures: true
success_criteria:
  - "✅ devsec.hardening.ssh_hardening role inclusion executes when enabled"
```

**Scenario 2: Negative Validation - SSH Hardening Disabled**

```yaml
test_case: "Skip devsec.hardening.ssh_hardening role when disabled"
platform: ubuntu-ssh-disabled
input:
  host_security:
    ssh_hardening_enabled: false
expected_task_result:
  - task_name: "Apply SSH security hardening (Linux)"
  - execution: skipped=true
  - skip_reason: "host_security.ssh_hardening_enabled | default(false) evaluates to false"
  - no_failures: true
success_criteria:
  - "✅ devsec.hardening.ssh_hardening role inclusion skipped when disabled"
```

#### Implementation Strategy

**Testing Environment**: Molecule with Docker containers (sufficient for role delegation validation)

**Molecule Platform Configuration**:

```yaml
platforms:
  - name: ubuntu-ssh-enabled
    image: geerlingguy/docker-ubuntu2404-ansible:latest
  - name: ubuntu-ssh-disabled
    image: geerlingguy/docker-ubuntu2404-ansible:latest

host_vars:
  ubuntu-ssh-enabled:
    host_security:
      ssh_hardening_enabled: true
  ubuntu-ssh-disabled:
    host_security:
      ssh_hardening_enabled: false
```

**Validation Approach**: Task execution metadata validation for `devsec.hardening.ssh_hardening` role inclusion
**Success Criteria**: Role inclusion behavior (skipped vs executed) - validates OUR conditional logic

**Environment**: Container (Primary) + CI Pipeline

---

### REQ-OS-006: System Locale Configuration

**Requirement**: The system SHALL be capable of setting the system locale on Linux systems
**Implementation**: Uses `community.general.locale_gen` + `localectl set-locale` command when `domain_locale` is defined
**Production Code**: `roles/os_configuration/tasks/configure-Linux.yml` - "Configure system locale", "Check current system locale", "Set system locale using localectl" tasks

#### State Validation Specifications

**Initial State**: Container default locale (typically `C.UTF-8` or system default)
**Target State**: System locale should be generated via `locale_gen` and set via `localectl` to match `domain_locale` variable

#### Validation Test Scenarios

**Scenario 1: Positive Validation - Valid Locale**

```yaml
test_case: "Set locale to en_US.UTF-8"
platform: ubuntu-locale-positive
input:
  domain_locale: "en_US.UTF-8"
expected_system_state:
  - locale: "en_US.UTF-8"
  - locale_generated: true
  - lang_environment: "en_US.UTF-8"
verification_method:
  - command: "localectl status"
    expected_contains: "LANG=en_US.UTF-8"
  - command: "locale -a | grep en_US.utf8"
    expected_behavior: locale_exists
success_criteria:
  - "✅ System locale is set to en_US.UTF-8"
  - "✅ localectl shows correct LANG setting"
  - "✅ Locale is properly generated and available"
```

**Scenario 2: Negative Validation - Empty Locale**

```yaml
test_case: "Empty locale skipped"
platform: ubuntu-locale-empty
input:
  domain_locale: "" # Empty string
expected_task_result:
  - task_name: "Configure system locale"
  - execution: skipped=true
  - skip_reason: "domain_locale | length > 0 evaluates to false"
  - no_failures: true
success_criteria:
  - "✅ Ansible task skipped due to when condition"
  - "✅ No task failures or errors"
```

**Scenario 3: Negative Validation - Undefined Locale**

```yaml
test_case: "Undefined locale skipped"
platform: ubuntu-locale-undefined
input:
  # domain_locale variable intentionally not defined
expected_task_result:
  - task_name: "Configure system locale"
  - execution: skipped=true
  - skip_reason: "domain_locale is defined evaluates to false"
  - no_failures: true
success_criteria:
  - "✅ Ansible task skipped due to when condition"
  - "✅ No task failures or errors"
```

#### Implementation Strategy

**Testing Environment**: Molecule with Docker containers (sufficient for conditional logic validation)

**Molecule Platform Configuration**:

```yaml
platforms:
  - name: ubuntu-locale-positive
    image: geerlingguy/docker-ubuntu2404-ansible:latest
  - name: ubuntu-locale-empty
    image: geerlingguy/docker-ubuntu2404-ansible:latest
  - name: ubuntu-locale-undefined
    image: geerlingguy/docker-ubuntu2404-ansible:latest

host_vars:
  ubuntu-locale-positive:
    domain_locale: "en_US.UTF-8"
  ubuntu-locale-empty:
    domain_locale: ""
  ubuntu-locale-undefined:
    # domain_locale intentionally omitted
```

**Validation Approach**: Full role execution with Ansible task execution metadata validation
**Success Criteria**: Task execution behavior (skipped/changed/failed) - validates OUR conditional logic
**Error Tolerance**: Module failures in containers are acceptable - we test our conditional logic, not the locale_gen module

**Environment**: Container (Primary) + CI Pipeline

---

### REQ-OS-007: System Language (Linux)

**Requirement**: The system SHALL be capable of setting the system language on Linux systems
**Implementation**: Uses `ansible.builtin.lineinfile` for LANGUAGE in `/etc/default/locale`

**Positive Validation**:

```yaml
test_case: "Set language to en_US.UTF-8"
input:
  domain_language: "en_US.UTF-8"
verify:
  - file_contains: "/etc/default/locale"
    pattern: "LANGUAGE=en_US.UTF-8"
  - command: "locale | grep LANGUAGE"
    expected: "LANGUAGE=en_US.UTF-8"
```

**Negative Validation**:

```yaml
test_case: "Skip when language undefined"
input: {}
verify:
  - no_changes: true
```

**Environment**: Both (Container + VM)

---

### REQ-OS-008: Basic Time Synchronization (Linux)

**Requirement**: The system SHALL be capable of configuring basic time synchronization on Linux systems
**Implementation**: Uses systemd-timesyncd for client-side time synchronization via SNTP. Steps: 1) `ansible.builtin.package` ensures systemd-timesyncd is installed, 2) `ansible.builtin.systemd` ensures service is enabled, 3) `ansible.builtin.template` configures `/etc/systemd/timesyncd.conf` when `domain_ntp.enabled` is true
**Production Code**: `roles/os_configuration/tasks/configure-Linux.yml` - "Configure NTP time synchronization" task block

#### State Validation Specifications

**Initial State**: systemd-timesyncd may or may not be installed/enabled; default or no configuration file
**Target State**:

- systemd-timesyncd package installed
- systemd-timesyncd service enabled and running
- `/etc/systemd/timesyncd.conf` configured with specified NTP servers when `domain_ntp.enabled` is true

#### Validation Test Scenarios

**Scenario 1: Positive Validation - Time Sync Enabled with Servers**

```yaml
test_case: "Configure time synchronization with multiple servers"
platform: ubuntu-ntp-enabled
input_variables:
  domain_ntp:
    enabled: true
    servers:
      - "0.pool.ntp.org"
      - "1.pool.ntp.org"
initial_state:
  package: "systemd-timesyncd may not be installed"
  service: "systemd-timesyncd may not be enabled"
  config_file: "/etc/systemd/timesyncd.conf - default or missing"
expected_final_state:
  package: "systemd-timesyncd installed"
  service: "systemd-timesyncd enabled and running"
  config_file: "/etc/systemd/timesyncd.conf with NTP servers configured"
  file_content: "NTP=0.pool.ntp.org 1.pool.ntp.org"
verification_commands:
  - command: "dpkg -l | grep systemd-timesyncd || systemctl status systemd-timesyncd"
    expected_result: "package_installed_or_service_available"
  - command: "systemctl is-enabled systemd-timesyncd"
    expected_result: "enabled"
  - command: "systemctl is-active systemd-timesyncd"
    expected_result: "active"
  - command: "test -f /etc/systemd/timesyncd.conf"
    expected_result: "file exists"
  - command: "grep '^NTP=' /etc/systemd/timesyncd.conf"
    expected_output: "NTP=0.pool.ntp.org 1.pool.ntp.org"
validation_logic:
  positive_case:
    - domain_ntp is defined ✓
    - domain_ntp.enabled is true ✓
    - domain_ntp.servers is defined ✓
    - All three tasks should execute (package, service, template)
success_criteria:
  - "✅ systemd-timesyncd package is installed"
  - "✅ systemd-timesyncd service is enabled and running"
  - "✅ /etc/systemd/timesyncd.conf exists"
  - "✅ File contains correct NTP server configuration"
  - "✅ Template properly applied with server list"
```

**Scenario 2: Negative Validation - Time Sync Disabled**

```yaml
test_case: "Skip when NTP disabled"
platform: ubuntu-ntp-disabled
input_variables:
  domain_ntp:
    enabled: false
    servers:
      - "pool.ntp.org"
initial_state:
  config_file: "default or missing"
expected_final_state:
  config_file: "unchanged from initial state"
verification_commands:
  - command: "test -f /etc/systemd/timesyncd.conf && echo 'exists' || echo 'not exists'"
    expected_behavior: "file state unchanged from baseline"
validation_logic:
  negative_case:
    - domain_ntp is defined ✓
    - domain_ntp.enabled is false ✗
    - Task should be skipped
success_criteria:
  - "✅ No changes to /etc/systemd/timesyncd.conf"
  - "✅ Conditional logic working: enabled=false triggers skip"
```

**Scenario 3: Negative Validation - NTP Undefined**

```yaml
test_case: "Skip when NTP undefined"
platform: ubuntu-ntp-undefined
input_variables:
  # domain_ntp not defined
initial_state:
  config_file: "default or missing"
expected_final_state:
  config_file: "unchanged from initial state"
verification_commands:
  - command: "test -f /etc/systemd/timesyncd.conf && echo 'exists' || echo 'not exists'"
    expected_behavior: "file state unchanged from baseline"
validation_logic:
  negative_case:
    - domain_ntp is not defined ✗
    - Task should be skipped
success_criteria:
  - "✅ No changes to /etc/systemd/timesyncd.conf"
  - "✅ Conditional logic working: undefined variable triggers skip"
```

#### Implementation Strategy

**Testing Environment**: Molecule with Docker containers
**Container Limitations**: systemd-timesyncd service may not start in containers, but file configuration can be validated
**Validation Approach**: Focus on file creation and content validation rather than service state

**Environment**: Container (file validation) + VM (full service validation in Phase 3)

---

### REQ-OS-009: Systemd Journal Configuration (Linux)

**Requirement**: The system SHALL be capable of configuring systemd journal settings on Linux systems
**Implementation**: Uses `ansible.builtin.template` for `/etc/systemd/journald.conf.d/00-ansible-managed.conf` when `journal.configure` is true
**Production Code**: `roles/os_configuration/tasks/configure-Linux.yml` - "Configure systemd journal" task block

#### State Validation Specifications

**Initial State**: No journal configuration file or default systemd-journald settings
**Target State**:
- `/etc/systemd/journald.conf.d/` directory exists with proper permissions
- `/etc/systemd/journald.conf.d/00-ansible-managed.conf` configured with specified journal settings when `journal.configure` is true

#### Validation Test Scenarios

**Scenario 1: Positive Validation - Journal Configuration Enabled**
```yaml
test_case: "Configure systemd journal settings"
platform: ubuntu-journal-enabled
input_variables:
  journal:
    configure: true
    max_size: "100M"
    max_retention: "7d"
initial_state:
  directory: "/etc/systemd/journald.conf.d may not exist"
  config_file: "/etc/systemd/journald.conf.d/00-ansible-managed.conf missing"
expected_final_state:
  directory: "/etc/systemd/journald.conf.d exists with mode 0755"
  config_file: "/etc/systemd/journald.conf.d/00-ansible-managed.conf exists with mode 0644"
  file_content_contains:
    - "SystemMaxUse=100M"
    - "RuntimeMaxUse=100M"
    - "MaxRetentionSec=7d"
    - "Storage=persistent"
    - "Compress=yes"
verification_commands:
  - command: "test -d /etc/systemd/journald.conf.d"
    expected_result: "directory exists"
  - command: "test -f /etc/systemd/journald.conf.d/00-ansible-managed.conf"
    expected_result: "file exists"
  - command: "grep '^SystemMaxUse=100M' /etc/systemd/journald.conf.d/00-ansible-managed.conf"
    expected_output: "SystemMaxUse=100M"
  - command: "grep '^MaxRetentionSec=7d' /etc/systemd/journald.conf.d/00-ansible-managed.conf"
    expected_output: "MaxRetentionSec=7d"
validation_logic:
  positive_case:
    - journal is defined ✓
    - journal.configure is true ✓
    - ansible_service_mgr == "systemd" ✓
    - All tasks should execute (directory, template)
success_criteria:
  - "✅ /etc/systemd/journald.conf.d directory exists with correct permissions"
  - "✅ Journal configuration file exists with correct content"
  - "✅ Template properly applied with specified settings"
```

**Scenario 2: Negative Validation - Journal Configuration Disabled**
```yaml
test_case: "Skip when journal configuration disabled"
platform: ubuntu-journal-disabled
input_variables:
  journal:
    configure: false
    max_size: "100M"
    max_retention: "7d"
initial_state:
  directory: "may or may not exist"
  config_file: "should remain unchanged"
expected_final_state:
  no_changes: true
verification_commands:
  - command: "test -f /etc/systemd/journald.conf.d/00-ansible-managed.conf"
    expected_result: "file_not_found"
validation_logic:
  negative_case:
    - journal is defined ✓
    - journal.configure is false ✗
    - Task should be skipped
success_criteria:
  - "✅ No changes to journal configuration"
  - "✅ Conditional logic working: configure=false triggers skip"
```

**Scenario 3: Negative Validation - Journal Undefined**
```yaml
test_case: "Skip when journal undefined"
platform: ubuntu-journal-undefined
input_variables:
  # journal not defined
initial_state:
  directory: "may or may not exist"
  config_file: "should remain unchanged"
expected_final_state:
  no_changes: true
verification_commands:
  - command: "test -f /etc/systemd/journald.conf.d/00-ansible-managed.conf"
    expected_result: "file_not_found"
validation_logic:
  negative_case:
    - journal is defined ✗
    - Task should be skipped
success_criteria:
  - "✅ No changes to journal configuration"
  - "✅ Conditional logic working: undefined variable triggers skip"
```

#### Implementation Strategy

**Testing Environment**: Molecule with Docker containers (sufficient for file operations and conditional logic validation)

**Container Limitations**: Journal configuration files can be created and verified in containers. Service restart validation deferred to VM testing.

**Molecule Platform Configuration**:
```yaml
platforms:
  - name: ubuntu-journal-enabled
    image: geerlingguy/docker-ubuntu2404-ansible:latest
  - name: ubuntu-journal-disabled
    image: geerlingguy/docker-ubuntu2404-ansible:latest
  - name: ubuntu-journal-undefined
    image: geerlingguy/docker-ubuntu2404-ansible:latest

host_vars:
  ubuntu-journal-enabled:
    journal:
      configure: true
      max_size: "100M"
      max_retention: "7d"
  ubuntu-journal-disabled:
    journal:
      configure: false
      max_size: "100M"
      max_retention: "7d"
  ubuntu-journal-undefined:
    # journal intentionally omitted
```

**Validation Approach**: State-based verification after role execution

- **Positive case**: Check actual file existence, permissions, and content matches template output
- **Negative cases**: Check no configuration files are created - works in all environments
- **Container testing**: Focus on file operations and conditional logic validation
- **VM testing (Phase 3)**: Add service restart verification and journal functionality testing

**Success Criteria**:

- **Containers**: File operations + conditional logic validation
- **VM/bare metal**: Full system configuration including service restart functionality
- **CI Compatibility**: All tests pass in container environments by design

**Environment**: Container (Primary) + CI Pipeline, VM (Complete service integration in Phase 3)
```

**Environment**: VM Only (systemd required)

---

### REQ-OS-010: DELETED

**Remote logging capabilities moved to dedicated logging role (future work)**

**Environment**: VM Only (rsyslog service required)

---

### REQ-OS-011: Systemd Unit Control

**Requirement**: The system SHALL be capable of controlling systemd units (services, timers, and so on) on Linux systems
**Implementation**: Uses `ansible.builtin.systemd_service` to manage systemd units with three operations:
- Enable/start: When `host_services.enable` is defined (enabled: true, state: started)
- Disable/stop: When `host_services.disable` is defined (enabled: false, state: stopped)
- Mask/stop: When `host_services.mask` is defined (masked: true, state: stopped)
Loop variable: `item` (from respective `host_services.*` arrays).

#### Validation Test Scenarios

**Scenario 1: Enable Services**
```yaml
test_case: "Enable and start multiple services"
input:
  host_services:
    enable:
      - "nginx"
      - "postgresql"
verify:
  - service_enabled: "nginx"
  - service_enabled: "postgresql"
  - service_running: "nginx"
  - service_running: "postgresql"
```

**Scenario 2: Disable Services**
```yaml
test_case: "Disable and stop multiple services"
input:
  host_services:
    disable:
      - "apache2"
      - "sendmail"
verify:
  - service_disabled: "apache2"
  - service_disabled: "sendmail"
  - service_stopped: "apache2"
  - service_stopped: "sendmail"
```

**Scenario 3: Mask Services**
```yaml
test_case: "Mask and stop multiple services"
input:
  host_services:
    mask:
      - "telnet"
      - "rsh"
verify:
  - service_masked: "telnet"
  - service_masked: "rsh"
  - service_stopped: "telnet"
  - service_stopped: "rsh"
```

**Scenario 4: Mixed Operations**
```yaml
test_case: "Combined enable/disable/mask operations"
input:
  host_services:
    enable: ["nginx"]
    disable: ["apache2"]
    mask: ["telnet"]
verify:
  - service_enabled: "nginx"
  - service_running: "nginx"
  - service_disabled: "apache2"
  - service_stopped: "apache2"
  - service_masked: "telnet"
  - service_stopped: "telnet"
```

**Negative Validation**:
```yaml
test_case: "Skip when no services defined"
input:
  host_services:
    enable: []
    disable: []
    mask: []
verify:
  - no_changes: true

test_case: "Handle non-existent service gracefully"
input:
  host_services:
    enable: ["non-existent-service"]
verify:
  - task_continues: true  # failed_when: false
```

#### State Validation Specifications

**Initial State**: Services may be in various states (enabled/disabled, running/stopped, masked/unmasked)
**Target State**: Services should reach expected state based on `host_services.*` configuration
**Verification Commands**:
- `systemctl is-enabled <service>` - Check enablement state
- `systemctl is-active <service>` - Check running state
- `systemctl is-masked <service>` - Check mask state

#### Implementation Strategy

**Testing Environment**: VM Only (systemd operations require actual systemd)

**Container Limitations**: systemd service operations cannot be reliably tested in containers due to:
- Limited systemd functionality in Docker containers
- Missing service files for test services
- Container isolation preventing proper systemd interaction

**Validation Approach**:
- **VM environment**: Full systemd service state validation
- **Container environment**: Skip systemd tests, document limitation
- **Conditional logic**: Test variable handling and task execution logic

**Environment**: VM Only (systemd required)

**REQ-OS-012**: DELETED - Consolidated into REQ-OS-011 (systemd unit control)

**REQ-OS-013**: DELETED - Consolidated into REQ-OS-011 (systemd unit control)

---

### REQ-OS-014: Kernel Module Management

**Requirement**: The system SHALL be capable of managing kernel modules on Linux systems
**Implementation**: Uses `community.general.modprobe` to manage kernel modules with operations:
- Load modules: When `host_modules.load` is defined (state: present, persistent: present)
- Blacklist modules: When `host_modules.blacklist` is defined (state: absent, persistent: absent)
Loop variable: `item` (from respective `host_modules.*` arrays).

#### State Validation Specifications

**Initial State**: No specific modules loaded/blacklisted; clean module configuration
**Target State**: Modules should be loaded/blacklisted with persistent configuration as specified by `host_modules.*` variables
**Verification Commands**:
- `lsmod | grep <module>` - Check if module is currently loaded
- `modprobe <module>` - Test if module can be loaded (should fail for blacklisted)
- Check persistence files created by `community.general.modprobe` with `persistent: present/absent`

#### Validation Test Scenarios

**Scenario 1: Load Kernel Modules (state: present, persistent: present)**
```yaml
test_case: "Load and persist kernel modules via modprobe"
input_variables:
  host_modules:
    load:
      - "br_netfilter"
      - "overlay"
initial_state:
  modules: "br_netfilter and overlay not necessarily loaded"
  persistence_files: "may not exist"
expected_final_state:
  modules: "br_netfilter and overlay loaded in kernel"
  persistence_files: "created by community.general.modprobe for boot loading"
verification_commands:
  - command: "lsmod | grep br_netfilter"
    expected_result: "module found in lsmod output"
  - command: "lsmod | grep overlay"
    expected_result: "module found in lsmod output"
  - command: "test -f /etc/modules-load.d/br_netfilter.conf"
    expected_result: "persistence file exists"
  - command: "test -f /etc/modules-load.d/overlay.conf"
    expected_result: "persistence file exists"
validation_logic:
  positive_case:
    - host_modules is defined ✓
    - host_modules.load is defined ✓
    - host_modules.load | length > 0 ✓
    - Task should execute with state: present, persistent: present
success_criteria:
  - "✅ Modules immediately loaded in kernel (lsmod verification)"
  - "✅ Persistence files created for boot-time loading"
```

**Scenario 2: Blacklist Kernel Modules (state: absent, persistent: absent)**
```yaml
test_case: "Blacklist and prevent kernel modules via modprobe"
input_variables:
  host_modules:
    blacklist:
      - "pcspkr"
      - "snd_pcsp"
initial_state:
  modules: "may or may not be loaded"
  blacklist_files: "may not exist"
expected_final_state:
  modules: "unloaded and prevented from loading"
  blacklist_files: "created by community.general.modprobe for persistent prevention"
verification_commands:
  - command: "modprobe pcspkr 2>&1"
    expected_result: "error indicating module is blacklisted"
  - command: "modprobe snd_pcsp 2>&1"
    expected_result: "error indicating module is blacklisted"
  - command: "test -f /etc/modprobe.d/pcspkr.conf"
    expected_result: "blacklist file exists"
  - command: "grep 'blacklist pcspkr' /etc/modprobe.d/pcspkr.conf"
    expected_result: "blacklist entry found"
validation_logic:
  positive_case:
    - host_modules is defined ✓
    - host_modules.blacklist is defined ✓
    - host_modules.blacklist | length > 0 ✓
    - Task should execute with state: absent, persistent: absent
success_criteria:
  - "✅ Modules cannot be loaded (modprobe fails)"
  - "✅ Persistence files created for boot-time prevention"
```

**Scenario 3: Mixed Module Operations**
```yaml
test_case: "Combined load and blacklist operations"
input_variables:
  host_modules:
    load: ["br_netfilter"]
    blacklist: ["pcspkr"]
verification_commands:
  - command: "lsmod | grep br_netfilter"
    expected_result: "module loaded"
  - command: "modprobe pcspkr 2>&1"
    expected_result: "blacklisted error"
  - command: "test -f /etc/modules-load.d/br_netfilter.conf"
    expected_result: "load persistence file exists"
  - command: "test -f /etc/modprobe.d/pcspkr.conf"
    expected_result: "blacklist persistence file exists"
success_criteria:
  - "✅ Load and blacklist operations both work correctly"
  - "✅ Both types of persistence files created"
```

**Scenario 4: Negative Validation - Empty Arrays**
```yaml
test_case: "Skip when no modules defined"
input_variables:
  host_modules:
    load: []
    blacklist: []
validation_logic:
  negative_case:
    - host_modules is defined ✓
    - host_modules.load | length == 0 ✗
    - host_modules.blacklist | length == 0 ✗
    - Tasks should be skipped
success_criteria:
  - "✅ No module operations attempted"
  - "✅ Conditional logic working correctly"
```

**Scenario 5: Negative Validation - Undefined Variable**
```yaml
test_case: "Skip when host_modules undefined"
input_variables:
  # host_modules intentionally not defined
validation_logic:
  negative_case:
    - host_modules is defined ✗
    - Tasks should be skipped
success_criteria:
  - "✅ No module operations attempted"
  - "✅ Conditional logic working correctly"
```

**Scenario 6: Edge Case - Non-existent Module**
```yaml
test_case: "Handle non-existent module gracefully"
input_variables:
  host_modules:
    load: ["non-existent-module"]
validation_logic:
  edge_case:
    - Uses failed_when: false for graceful handling
    - Should not fail entire playbook
success_criteria:
  - "✅ Task continues despite module not existing"
  - "✅ Graceful error handling"
```

#### Implementation Strategy

**Testing Environment**: VM Only (kernel module operations require actual kernel access)

**Container Limitations**: Kernel module operations cannot be reliably tested in containers due to:
- Limited kernel access in Docker containers
- Missing kernel modules in container kernels
- Container isolation preventing modprobe operations

**Validation Approach**:
- **VM environment**: Full kernel module state validation via lsmod, modprobe, and file checks
- **Container environment**: Skip module tests, document limitation
- **Conditional logic**: Test variable handling and task execution logic

**Environment**: VM Only (kernel module operations required)

**REQ-OS-015**: DELETED - Consolidated into REQ-OS-014 (kernel module management)

---

### REQ-OS-016: Custom Udev Rules

**Requirement**: The system SHALL be capable of deploying custom udev rules on Linux systems
**Implementation**:
- Uses `ansible.builtin.file` to ensure `/etc/udev/rules.d/` directory exists with mode 0755
- Uses `ansible.builtin.copy` to deploy rules to `/etc/udev/rules.d/{priority}-{name}.rules` when `item.state` is 'present' (default)
- Uses `ansible.builtin.file` with `state: absent` to remove rules when `item.state` is 'absent'
- Triggers handler to reload udev via `udevadm control --reload-rules && udevadm trigger`
- Loop variable: `item` (from `host_udev.rules`)

**Positive Validation**:

```yaml
test_case: "Deploy custom udev rules with priority"
input:
  host_udev:
    rules:
      - name: "test-usb-device"
        priority: 50
        content: 'SUBSYSTEM=="usb", ATTR{idVendor}=="1234", ATTR{idProduct}=="5678", MODE="0666"'
        state: present
      - name: "test-network-device"
        priority: 60
        content: 'SUBSYSTEM=="net", ACTION=="add", ATTRS{address}=="aa:bb:cc:dd:ee:ff", NAME="testnet0"'
        state: present
verify:
  - file_exists: "/etc/udev/rules.d/50-test-usb-device.rules"
  - file_contains: "/etc/udev/rules.d/50-test-usb-device.rules"
    exact_content: 'SUBSYSTEM=="usb", ATTR{idVendor}=="1234", ATTR{idProduct}=="5678", MODE="0666"'
  - file_exists: "/etc/udev/rules.d/60-test-network-device.rules"
  - file_contains: "/etc/udev/rules.d/60-test-network-device.rules"
    exact_content: 'SUBSYSTEM=="net", ACTION=="add", ATTRS{address}=="aa:bb:cc:dd:ee:ff", NAME="testnet0"'
```

**Negative Validation (Rule Removal)**:

```yaml
test_case: "Remove udev rules"
input:
  host_udev:
    rules:
      - name: "test-remove-rule"
        priority: 70
        content: 'SUBSYSTEM=="block", ACTION=="add", MODE="0644"'
        state: absent
verify:
  - file_not_exists: "/etc/udev/rules.d/70-test-remove-rule.rules"
```

**Conditional Logic Validation**:

```yaml
test_case: "Skip when host_udev undefined"
input:
  # host_udev not defined
verify:
  - no_changes_made
  - debug_message: "udev rules skipped when host_udev undefined"
```

**Environment**: Container (can verify file operations, but udev daemon may not reload properly)

---

### REQ-OS-017: APT Behavior Configuration (Debian/Ubuntu)

**Requirement**: The system SHALL be capable of configuring APT behavior on Debian/Ubuntu systems
**Implementation**: Uses `ansible.builtin.copy` for `/etc/apt/apt.conf.d/` files

**Positive Validation**:

```yaml
test_case: "Configure APT no-recommends"
input:
  apt:
    no_install_recommends: true
    proxy: "http://proxy.example.com:3128"
verify:
  - file_exists: "/etc/apt/apt.conf.d/99-no-install-recommends"
  - file_contains: "/etc/apt/apt.conf.d/99-no-install-recommends"
    pattern: 'APT::Install-Recommends "false"'
  - file_exists: "/etc/apt/apt.conf.d/99-proxy"
  - file_contains: "/etc/apt/apt.conf.d/99-proxy"
    pattern: "proxy.example.com:3128"
```

**Environment**: Container + VM (Debian/Ubuntu only)

---

### REQ-OS-018: APT Unattended Upgrades (Debian/Ubuntu)

**Requirement**: The system SHALL be capable of configuring APT unattended upgrades on Debian/Ubuntu systems
**Implementation**: Uses `ansible.builtin.template` for `/etc/apt/apt.conf.d/50unattended-upgrades`

**Positive Validation**:

```yaml
test_case: "Configure unattended upgrades"
input:
  apt:
    unattended_upgrades:
      enabled: true
      automatic_reboot: true
      reboot_time: "02:00"
verify:
  - file_exists: "/etc/apt/apt.conf.d/50unattended-upgrades"
  - file_contains: "/etc/apt/apt.conf.d/50unattended-upgrades"
    pattern: 'Automatic-Reboot "true"'
  - file_contains: "/etc/apt/apt.conf.d/50unattended-upgrades"
    pattern: 'Automatic-Reboot-Time "02:00"'
```

**Environment**: Container + VM (Debian/Ubuntu only)

---

### REQ-OS-019: Purge Snapd (Debian/Ubuntu)

**Requirement**: The system SHALL be capable of purging snapd on Debian/Ubuntu systems
**Implementation**: Uses `wolskies.infrastructure.manage_snap_packages` role to purge snapd

**Positive Validation**:

```yaml
test_case: "Purge snapd completely"
input:
  snapd:
    purge: true
verify:
  - role_executed: "wolskies.infrastructure.manage_snap_packages"
  - package_absent: "snapd"
  - package_absent: "snap-confine"
  - directory_absent: "/snap"
  - directory_absent: "/var/snap"
```

**Environment**: Container + VM (Debian/Ubuntu only)

---

### REQ-OS-020: Install Nerd Fonts (Debian/Ubuntu)

**Requirement**: The system SHALL be capable of installing Nerd Fonts on Debian/Ubuntu systems
**Implementation**: Uses `ansible.builtin.unarchive` to download and install fonts. Loop variable: `font_item`

**Positive Validation**:

```yaml
test_case: "Install Nerd Fonts"
input:
  nerd_fonts:
    install:
      - "JetBrainsMono"
      - "FiraCode"
verify:
  - directory_exists: "/usr/local/share/fonts/JetBrainsMono"
  - directory_exists: "/usr/local/share/fonts/FiraCode"
  - file_exists: "/usr/local/share/fonts/JetBrainsMono/JetBrainsMono-Regular.ttf"
  - command: "fc-list | grep JetBrains"
    returns_non_empty: true
```

**Environment**: Container + VM (Debian/Ubuntu only)

---

### REQ-OS-021: Pacman Configuration (Arch Linux)

**Requirement**: The system SHALL be capable of configuring Pacman behavior on Arch Linux systems
**Implementation**: Uses `ansible.builtin.lineinfile` to modify `/etc/pacman.conf`

**Positive Validation**:

```yaml
test_case: "Configure Pacman with multilib and proxy"
input:
  pacman:
    no_confirm: true
    multilib_enabled: true
    proxy: "http://proxy.example.com:3128"
verify:
  - file_contains: "/etc/pacman.conf"
    pattern: "NoConfirm"
  - file_contains: "/etc/pacman.conf"
    pattern: "\\[multilib\\]"
  - file_contains: "/etc/pacman.conf"
    pattern: "XferCommand.*proxy.example.com"
```

**Environment**: Container + VM (Arch Linux only)

---

## macOS-Specific Requirements (REQ-OS-022 to REQ-OS-028)

### REQ-OS-022: System Locale (macOS)

**Requirement**: The system SHALL be capable of setting the system locale on macOS systems
**Implementation**: Uses `community.general.osx_defaults` with NSGlobalDomain/AppleLocale

**Positive Validation**:

```yaml
test_case: "Set macOS locale to en_US"
input:
  domain_locale: "en_US"
verify:
  - osx_defaults: "NSGlobalDomain"
    key: "AppleLocale"
    expected: "en_US"
  - command: "defaults read NSGlobalDomain AppleLocale"
    expected: "en_US"
```

**Environment**: VM Only (macOS only)

---

### REQ-OS-023: System Language (macOS)

**Requirement**: The system SHALL be capable of setting the system language on macOS systems
**Implementation**: Uses `community.general.osx_defaults` with NSGlobalDomain/AppleLanguages

**Positive Validation**:

```yaml
test_case: "Set macOS language to English"
input:
  domain_language: "en"
verify:
  - osx_defaults: "NSGlobalDomain"
    key: "AppleLanguages"
    expected: ["en"]
```

**Environment**: VM Only (macOS only)

---

### REQ-OS-024: NTP Configuration (macOS)

**Requirement**: The system SHALL be capable of configuring NTP time synchronization on macOS systems
**Implementation**: Uses `ansible.builtin.command` with `systemsetup` utility

**Positive Validation**:

```yaml
test_case: "Configure NTP on macOS"
input:
  domain_ntp:
    enabled: true
    servers: ["time.apple.com"]
verify:
  - command: "systemsetup -getnetworktimeserver"
    expected: "time.apple.com"
  - command: "systemsetup -getusingnetworktime"
    expected: "Network Time: On"
```

**Environment**: VM Only (macOS only)

---

### REQ-OS-025: macOS Automatic Updates

**Requirement**: The system SHALL be capable of configuring macOS automatic updates
**Implementation**: Uses `community.general.osx_defaults` for `/Library/Preferences/com.apple.SoftwareUpdate`

**Positive Validation**:

```yaml
test_case: "Enable automatic updates"
input:
  macos:
    automatic_updates:
      enabled: true
      install_system_updates: true
      install_app_updates: true
verify:
  - osx_defaults: "/Library/Preferences/com.apple.SoftwareUpdate"
    key: "AutomaticCheckEnabled"
    expected: true
  - osx_defaults: "/Library/Preferences/com.apple.SoftwareUpdate"
    key: "AutomaticDownload"
    expected: true
```

**Environment**: VM Only (macOS only)

---

### REQ-OS-026: macOS Gatekeeper

**Requirement**: The system SHALL be capable of configuring macOS Gatekeeper security
**Implementation**: Uses `ansible.builtin.command` with `spctl` utility

**Positive Validation**:

```yaml
test_case: "Enable Gatekeeper"
input:
  macos:
    gatekeeper:
      enabled: true
verify:
  - command: "spctl --status"
    expected: "assessments enabled"
```

**Environment**: VM Only (macOS only)

---

### REQ-OS-027: macOS System Preferences

**Requirement**: The system SHALL be capable of configuring macOS system preferences
**Implementation**: Uses `community.general.osx_defaults` with NSGlobalDomain

**Positive Validation**:

```yaml
test_case: "Configure system preferences"
input:
  macos:
    preferences:
      show_hidden_files: true
      disable_quarantine: false
verify:
  - osx_defaults: "NSGlobalDomain"
    key: "AppleShowAllFiles"
    expected: true
  - osx_defaults: "com.apple.LaunchServices"
    key: "LSQuarantine"
    expected: false
```

**Environment**: VM Only (macOS only)

---

### REQ-OS-028: AirDrop over Ethernet

**Requirement**: The system SHALL be capable of configuring AirDrop over Ethernet
**Implementation**: Uses `community.general.osx_defaults` for `com.apple.NetworkBrowser`

**Positive Validation**:

```yaml
test_case: "Enable AirDrop over Ethernet"
input:
  macos:
    airdrop:
      ethernet_enabled: true
verify:
  - osx_defaults: "com.apple.NetworkBrowser"
    key: "BrowseAllInterfaces"
    expected: true
```

**Environment**: VM Only (macOS only)

---

## Test Environment Summary

### Container-Testable Requirements (15 total)

- REQ-OS-002: /etc/hosts update
- REQ-OS-003: Timezone configuration
- REQ-OS-004: OS security hardening
- REQ-OS-006: System locale (Linux)
- REQ-OS-007: System language (Linux)
- REQ-OS-017: APT behavior (Debian/Ubuntu)
- REQ-OS-018: APT unattended upgrades (Debian/Ubuntu)
- REQ-OS-019: Purge snapd (Debian/Ubuntu)
- REQ-OS-020: Install Nerd Fonts (Debian/Ubuntu)
- REQ-OS-021: Pacman configuration (Arch Linux)

### VM-Required Requirements (13 total)

- REQ-OS-001: Hostname configuration
- REQ-OS-005: SSH hardening
- REQ-OS-008: NTP time synchronization (Linux)
- REQ-OS-009: Systemd journal configuration
- REQ-OS-010: Rsyslog remote logging
- REQ-OS-011: Systemd unit control (enable/disable/mask services)
- REQ-OS-014: Kernel module management (load/blacklist modules)
- REQ-OS-016: Custom udev rules
- REQ-OS-022 to REQ-OS-028: macOS requirements (7 total)

### Platform-Specific Requirements

- **Cross-platform**: REQ-OS-001 to REQ-OS-003 (3 requirements)
- **Linux-specific**: REQ-OS-004 to REQ-OS-021 (18 requirements)
- **Debian/Ubuntu-specific**: REQ-OS-017 to REQ-OS-020 (4 requirements)
- **Arch Linux-specific**: REQ-OS-021 (1 requirement)
- **macOS-specific**: REQ-OS-022 to REQ-OS-028 (7 requirements)

---

**Implementation Priority**:

1. **Phase 1**: Container-testable requirements (quick feedback)
2. **Phase 2**: Linux VM requirements (core functionality)
3. **Phase 3**: macOS requirements (platform expansion)

This validation plan provides comprehensive test criteria for all 28 os_configuration requirements with both positive and negative test cases.
