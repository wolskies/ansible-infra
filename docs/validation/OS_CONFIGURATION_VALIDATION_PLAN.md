# os_configuration Role Validation Plan

**Document Version:** 1.0
**Role:** os_configuration
**Total Requirements:** 28 (REQ-OS-001 through REQ-OS-028)
**Last Updated:** September 22, 2025

---

## Cross-Platform Requirements (REQ-OS-001 to REQ-OS-003)

### REQ-OS-001: System Hostname Configuration

**Requirement**: The system SHALL be capable of setting the system hostname
**Implementation**: Uses `ansible.builtin.hostname` module when `host_hostname` is defined and non-empty

**Positive Validation**:
```yaml
test_case: "Set hostname to test-hostname"
input:
  host_hostname: "test-hostname"
verify:
  - command: "hostname"
    expected: "test-hostname"
  - command: "cat /etc/hostname"
    expected: "test-hostname"
  - ansible_fact: "ansible_hostname"
    expected: "test-hostname"
```

**Negative Validation**:
```yaml
test_case: "Empty hostname skipped"
input:
  host_hostname: ""
verify:
  - no_changes: true
  - hostname: unchanged from original

test_case: "Undefined hostname skipped"
input: {}
verify:
  - no_changes: true
  - hostname: unchanged from original
```

**Environment**: VM Only (container limitation)

---

### REQ-OS-002: /etc/hosts Update

**Requirement**: The system SHALL be capable of updating the `/etc/hosts` file with hostname entries
**Implementation**: Uses `ansible.builtin.lineinfile` to update `/etc/hosts` when `host_update_hosts` is true, format: `127.0.0.1 localhost {hostname}.{domain} {hostname}`

**Positive Validation**:
```yaml
test_case: "Add hostname to /etc/hosts"
input:
  host_hostname: "testhost"
  domain_name: "example.com"
  host_update_hosts: true
verify:
  - command: "grep testhost /etc/hosts"
    expected: "127.0.0.1\tlocalhost testhost.example.com testhost"
  - file_contains: "/etc/hosts"
    pattern: "127\\.0\\.0\\.1.*testhost\\.example\\.com.*testhost"
```

**Negative Validation**:
```yaml
test_case: "Skip when host_update_hosts false"
input:
  host_hostname: "testhost"
  domain_name: "example.com"
  host_update_hosts: false
verify:
  - file_not_contains: "/etc/hosts"
    pattern: "testhost"

test_case: "Skip when missing domain_name"
input:
  host_hostname: "testhost"
  host_update_hosts: true
verify:
  - no_changes: true
  - file_not_contains: "/etc/hosts"
    pattern: "testhost"

test_case: "Skip when missing host_hostname"
input:
  domain_name: "example.com"
  host_update_hosts: true
verify:
  - no_changes: true
```

**Environment**: Both (Container + VM)

---

### REQ-OS-003: System Timezone

**Requirement**: The system SHALL be capable of setting the system timezone
**Implementation**: Uses `community.general.timezone` module when `domain_timezone` is defined and non-empty
**Production Code**: `roles/os_configuration/tasks/main.yml` - "Set system timezone" task

#### Validation Test Scenarios

**Scenario 1: Positive Validation**
```yaml
test_case: "Set timezone to America/New_York"
platform: ubuntu-timezone-positive
input:
  domain_timezone: "America/New_York"
expected_task_result:
  - task_name: "Set system timezone"
  - execution: changed=true OR ok=true (NOT skipped)
  - module: community.general.timezone
  - no_failures: true
success_criteria:
  - "✅ Ansible task executes successfully (not skipped)"
  - "✅ No task failures or errors"
```

**Scenario 2: Negative Validation - Empty Timezone**
```yaml
test_case: "Empty timezone skipped"
platform: ubuntu-timezone-empty
input:
  domain_timezone: ""  # Empty string
expected_task_result:
  - task_name: "Set system timezone"
  - execution: skipped=true
  - skip_reason: "domain_timezone | length > 0 evaluates to false"
  - no_failures: true
success_criteria:
  - "✅ Ansible task skipped due to when condition"
  - "✅ No task failures or errors"
```

**Scenario 3: Negative Validation - Undefined Timezone**
```yaml
test_case: "Undefined timezone skipped"
platform: ubuntu-timezone-undefined
input:
  # domain_timezone variable intentionally not defined
expected_task_result:
  - task_name: "Set system timezone"
  - execution: skipped=true
  - skip_reason: "domain_timezone is defined evaluates to false"
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

**Validation Approach**: Full role execution with Ansible task execution metadata validation
**Success Criteria**: Task execution behavior (skipped/changed/failed) - validates OUR conditional logic

**Environment**: Container (Primary) + CI Pipeline

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
**Implementation**: Uses `devsec.hardening.ssh_hardening` role when `host_security.ssh_hardening_enabled` is true

**Positive Validation**:
```yaml
test_case: "Apply SSH hardening"
input:
  host_security:
    ssh_hardening_enabled: true
verify:
  - role_executed: "devsec.hardening.ssh_hardening"
  - file_contains: "/etc/ssh/sshd_config"
    pattern: "PermitRootLogin no"
  - file_contains: "/etc/ssh/sshd_config"
    pattern: "PasswordAuthentication no"
```

**Negative Validation**:
```yaml
test_case: "Skip when SSH hardening disabled"
input:
  host_security:
    ssh_hardening_enabled: false
verify:
  - role_not_executed: "devsec.hardening.ssh_hardening"
  - no_changes: true
```

**Environment**: VM Only (SSH service required)

---

### REQ-OS-006: System Locale (Linux)

**Requirement**: The system SHALL be capable of setting the system locale on Linux systems
**Implementation**: Uses `community.general.locale_gen` + `ansible.builtin.lineinfile` for `/etc/default/locale`

**Positive Validation**:
```yaml
test_case: "Set locale to en_US.UTF-8"
input:
  domain_locale: "en_US.UTF-8"
verify:
  - command: "locale -a | grep en_US.UTF-8"
    expected: "en_US.UTF-8"
  - file_contains: "/etc/default/locale"
    pattern: "LANG=en_US.UTF-8"
  - command: "locale | grep LANG"
    expected: "LANG=en_US.UTF-8"

test_case: "Set locale to fr_FR.UTF-8"
input:
  domain_locale: "fr_FR.UTF-8"
verify:
  - command: "locale -a | grep fr_FR.UTF-8"
    expected: "fr_FR.UTF-8"
  - file_contains: "/etc/default/locale"
    pattern: "LANG=fr_FR.UTF-8"
```

**Negative Validation**:
```yaml
test_case: "Skip when locale undefined"
input: {}
verify:
  - no_changes: true

test_case: "Invalid locale handled gracefully"
input:
  domain_locale: "invalid_locale"
verify:
  - task_failed: true
  - error_message_contains: "locale"
```

**Environment**: Both (Container + VM)

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

### REQ-OS-008: NTP Time Synchronization (Linux)

**Requirement**: The system SHALL be capable of configuring NTP time synchronization on Linux systems
**Implementation**: Uses `ansible.builtin.template` for `/etc/systemd/timesyncd.conf` when `domain_ntp.enabled` is true

**Positive Validation**:
```yaml
test_case: "Configure NTP with multiple servers"
input:
  domain_ntp:
    enabled: true
    servers:
      - "pool.ntp.org"
      - "time.google.com"
verify:
  - file_exists: "/etc/systemd/timesyncd.conf"
  - file_contains: "/etc/systemd/timesyncd.conf"
    pattern: "NTP=pool.ntp.org time.google.com"
  - service_enabled: "systemd-timesyncd"
```

**Negative Validation**:
```yaml
test_case: "Skip when NTP disabled"
input:
  domain_ntp:
    enabled: false
verify:
  - no_changes: true

test_case: "Skip when NTP undefined"
input: {}
verify:
  - no_changes: true
```

**Environment**: VM Only (systemd service required)

---

### REQ-OS-009: Systemd Journal Configuration

**Requirement**: The system SHALL be capable of configuring systemd journal settings on Linux systems
**Implementation**: Uses `ansible.builtin.template` for `/etc/systemd/journald.conf.d/00-ansible-managed.conf` when `journal.configure` is true

**Positive Validation**:
```yaml
test_case: "Configure journal settings"
input:
  journal:
    configure: true
    max_use: "100M"
    max_files: 5
verify:
  - file_exists: "/etc/systemd/journald.conf.d/00-ansible-managed.conf"
  - file_contains: "/etc/systemd/journald.conf.d/00-ansible-managed.conf"
    pattern: "SystemMaxUse=100M"
  - file_contains: "/etc/systemd/journald.conf.d/00-ansible-managed.conf"
    pattern: "SystemMaxFiles=5"
```

**Negative Validation**:
```yaml
test_case: "Skip when journal configure disabled"
input:
  journal:
    configure: false
verify:
  - no_changes: true
```

**Environment**: VM Only (systemd required)

---

### REQ-OS-010: Rsyslog Remote Logging

**Requirement**: The system SHALL be capable of configuring rsyslog for remote logging on Linux systems
**Implementation**: Uses `ansible.builtin.lineinfile` to configure rsyslog remote host when `rsyslog.enabled` is true

**Positive Validation**:
```yaml
test_case: "Configure remote rsyslog"
input:
  rsyslog:
    enabled: true
    remote_host: "log.example.com"
    port: 514
verify:
  - file_contains: "/etc/rsyslog.conf"
    pattern: "*.* @@log.example.com:514"
  - service_restarted: "rsyslog"
```

**Negative Validation**:
```yaml
test_case: "Skip when rsyslog disabled"
input:
  rsyslog:
    enabled: false
verify:
  - no_changes: true
```

**Environment**: VM Only (rsyslog service required)

---

### REQ-OS-011: Enable System Services

**Requirement**: The system SHALL be capable of enabling system services on Linux systems
**Implementation**: Uses `ansible.builtin.systemd` for enable/start operations. Loop variable: `item` (from `host_services.enable`)

**Positive Validation**:
```yaml
test_case: "Enable multiple services"
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

**Negative Validation**:
```yaml
test_case: "Skip when no services to enable"
input:
  host_services:
    enable: []
verify:
  - no_changes: true

test_case: "Handle non-existent service gracefully"
input:
  host_services:
    enable:
      - "non-existent-service"
verify:
  - task_failed: true
  - error_message_contains: "service"
```

**Environment**: VM Only (systemd required)

---

### REQ-OS-012: Disable System Services

**Requirement**: The system SHALL be capable of disabling system services on Linux systems
**Implementation**: Uses `ansible.builtin.systemd` for disable/stop operations. Loop variable: `item` (from `host_services.disable`)

**Positive Validation**:
```yaml
test_case: "Disable multiple services"
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

**Environment**: VM Only (systemd required)

---

### REQ-OS-013: Mask System Services

**Requirement**: The system SHALL be capable of masking system services on Linux systems
**Implementation**: Uses `ansible.builtin.systemd` for mask/stop operations. Loop variable: `item` (from `host_services.mask`)

**Positive Validation**:
```yaml
test_case: "Mask multiple services"
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

**Environment**: VM Only (systemd required)

---

### REQ-OS-014: Load Kernel Modules

**Requirement**: The system SHALL be capable of loading kernel modules at boot on Linux systems
**Implementation**: Uses `ansible.builtin.lineinfile` for `/etc/modules-load.d/{module}.conf` files. Loop variable: `item` (from `host_modules.load`)

**Positive Validation**:
```yaml
test_case: "Load kernel modules at boot"
input:
  host_modules:
    load:
      - "br_netfilter"
      - "overlay"
verify:
  - file_exists: "/etc/modules-load.d/br_netfilter.conf"
  - file_contains: "/etc/modules-load.d/br_netfilter.conf"
    pattern: "br_netfilter"
  - file_exists: "/etc/modules-load.d/overlay.conf"
  - file_contains: "/etc/modules-load.d/overlay.conf"
    pattern: "overlay"
```

**Environment**: VM Only (module loading required)

---

### REQ-OS-015: Blacklist Kernel Modules

**Requirement**: The system SHALL be capable of blacklisting kernel modules on Linux systems
**Implementation**: Uses `ansible.builtin.lineinfile` for `/etc/modprobe.d/blacklist-ansible-managed.conf`. Loop variable: `item` (from `host_modules.blacklist`)

**Positive Validation**:
```yaml
test_case: "Blacklist kernel modules"
input:
  host_modules:
    blacklist:
      - "pcspkr"
      - "snd_pcsp"
verify:
  - file_exists: "/etc/modprobe.d/blacklist-ansible-managed.conf"
  - file_contains: "/etc/modprobe.d/blacklist-ansible-managed.conf"
    pattern: "blacklist pcspkr"
  - file_contains: "/etc/modprobe.d/blacklist-ansible-managed.conf"
    pattern: "blacklist snd_pcsp"
```

**Environment**: VM Only (modprobe required)

---

### REQ-OS-016: Custom Udev Rules

**Requirement**: The system SHALL be capable of deploying custom udev rules on Linux systems
**Implementation**: Uses `ansible.builtin.copy` to deploy rules to `/etc/udev/rules.d/`. Loop variable: `item` (from `host_udev.rules`)

**Positive Validation**:
```yaml
test_case: "Deploy custom udev rules"
input:
  host_udev:
    rules:
      - name: "99-usb-permissions"
        content: 'SUBSYSTEM=="usb", ATTR{idVendor}=="1234", MODE="0666"'
verify:
  - file_exists: "/etc/udev/rules.d/99-usb-permissions.rules"
  - file_contains: "/etc/udev/rules.d/99-usb-permissions.rules"
    pattern: 'SUBSYSTEM=="usb"'
```

**Environment**: VM Only (udev required)

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
    pattern: "Automatic-Reboot \"true\""
  - file_contains: "/etc/apt/apt.conf.d/50unattended-upgrades"
    pattern: "Automatic-Reboot-Time \"02:00\""
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
- REQ-OS-011: Enable system services
- REQ-OS-012: Disable system services
- REQ-OS-013: Mask system services
- REQ-OS-014: Load kernel modules
- REQ-OS-015: Blacklist kernel modules
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
