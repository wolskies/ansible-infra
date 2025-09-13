# os_configuration

OS configuration for Ubuntu 22+, Debian 12+, Arch Linux, and MacOSX.

## Description

Configures basic OS configuration (timezone, locale, NTP, hostname) and distribution-specific settings (services, journals). On Linux systems, applies comprehensive security hardening using devsec.hardening.os_hardening.

## Features

- **Security hardening**: Comprehensive OS hardening for Linux systems (200+ security configurations)
- **Basic OS settings**: timezone, locale, NTP, hostname, /etc/hosts management
- **Distribution-specific**: systemd services, journald, unattended upgrades, platform optimizations
- **Cross-platform**: Ubuntu/Debian/Arch Linux/macOS

## Architecture

**Task Flow:**

1. **Common Setup** (`main.yml`): Distribution config setup, timezone
2. **OS-Specific**:
   - `configure-Linux.yml`: **OS hardening first**, then locale, NTP, journal, hostname (all Linux distributions)
   - `configure-Darwin.yml`: macOS-specific configuration
3. **Distribution-Specific** (for Linux only):
   - `configure-Debian.yml`: Ubuntu + Debian specific settings
   - `configure-Archlinux.yml`: Arch Linux specific settings

## Role Variables

### Infrastructure Hierarchy

Uses the unified infrastructure structure with domain/host separation:

```yaml
infrastructure:
  domain:
    name: "company.com" # Domain name
    timezone: "America/New_York" # Optional: shared timezone (empty = system default)
    locale: "en_US.UTF-8" # Shared locale
    language: "en_US.UTF-8" # Shared language
    ntp:
      enabled: true # Enable NTP synchronization
      servers: # Optional: custom NTP servers (empty = system defaults)
        - time1.company.com
        - time2.company.com

  host:
    hostname: "" # Individual hostname (empty = keep current)
    update_hosts: true # Update /etc/hosts with hostname

    # systemd journal configuration (Linux)
    journal:
      configure: true
      max_size: "500M"
      max_retention: "30d"
      forward_to_syslog: false
      compress: true

    # Remote logging via rsyslog (Linux)
    rsyslog:
      enabled: false
      remote_host: ""
      remote_port: 514
      protocol: "udp"

    # System service management (Linux)
    services:
      enable: [] # Services to enable and start
      disable: [] # Services to disable and stop

    # System optimizations (Linux)
    optimizations:
      tune_swappiness: false
      swappiness: 10

    # Security hardening options (Linux)
    security:
      disable_ctrl_alt_del: false      # Disable Ctrl-Alt-Del key combination
      users_allow: []                  # List of things users are allowed to do (e.g., ['change_user'])
      remove_additional_root_users: false  # Remove users with UID=0 except root
      enforce_password_aging: true     # Enforce password aging policies

    # Kernel parameters (sysctl) (Linux)
    sysctl:
      parameters: {}
      # Example: { "net.core.default_qdisc": "fq" }
      # Note: These will be merged with/override security hardening sysctl settings

    # PAM limits configuration (Linux)
    limits:
      limits: []
      # Example: [{ domain: "*", limit_type: "soft", limit_item: "nofile", value: 65536 }]

    # Kernel module management (Linux)
    modules:
      load: [] # Modules to load at boot
      blacklist: [] # Modules to blacklist

    # Snap package system settings (Ubuntu/Debian)
    snap:
      remove_completely: false

    # Package manager settings
    packages:
      apt: # Ubuntu/Debian settings
        no_recommends: false
        proxy: ""
        unattended_upgrades:
          enabled: true
          email: ""
          auto_reboot: false
          reboot_time: "02:00"
      pacman: # Arch Linux settings
        no_confirms: false
        proxy: ""
        multilib: false
      macosx: # macOS settings
        updates:
          auto_check: true
          auto_download: true
        gatekeeper:
          enabled: true
```

**Note**: This role focuses on core OS configuration. GUI-related macOS settings were previously handled by the manage_system_settings role, but that functionality has been consolidated into this role.

## Example Usage

### Basic Configuration

```yaml
- name: Configure operating system
  include_role:
    name: wolskinet.infrastructure.os_configuration
  vars:
    infrastructure:
      domain:
        name: "example.com"
        timezone: "America/New_York"
      host:
        hostname: "web-server-01"
```

### Advanced Ubuntu Server

```yaml
- name: Configure Ubuntu server
  include_role:
    name: wolskinet.infrastructure.os_configuration
  vars:
    infrastructure:
      domain:
        name: "internal.company.com"
        timezone: "America/New_York"
        ntp:
          servers: [ntp1.company.com, ntp2.company.com]
      host:
        hostname: "db-primary"
        journal:
          configure: true
          max_size: "1G"
        services:
          enable: ["systemd-timesyncd"]
          disable: ["bluetooth", "cups"]
        optimizations:
          tune_swappiness: true
          swappiness: 1
        packages:
          apt:
            no_recommends: true
            unattended_upgrades:
              enabled: true
              email: "admin@company.com"
              auto_reboot: true
              reboot_time: "03:00"
```

### macOS Workstation

```yaml
- name: Configure macOS workstation
  include_role:
    name: wolskinet.infrastructure.os_configuration
  vars:
    infrastructure:
      domain:
        name: "local"
        timezone: "America/Los_Angeles"
      host:
        hostname: "MacBook-Pro"
        packages:
          macosx:
            updates:
              auto_check: true
              auto_download: false
```

### Multi-Host Environment

```yaml
# inventory/group_vars/all.yml
infrastructure:
  domain:
    name: "company.com"
    timezone: "America/New_York"  # Optional timezone
    locale: "en_US.UTF-8"
    ntp:
      servers: [time1.company.com, time2.company.com]  # Optional: custom NTP servers

# inventory/host_vars/web01.yml
infrastructure:
  host:
    hostname: "web01"
    services:
      disable: [bluetooth]
```

## Requirements

- **macOS**: Xcode Command Line Tools (`xcode-select --install`)
- **All platforms**: Appropriate sudo/admin privileges for system configuration

## Dependencies

- `community.general` (for timezone, locale_gen, osx_defaults)
- `ansible.posix` (for sysctl)

## Tags

Use tags for selective execution:

```bash
# Configure only hostname
ansible-playbook -t hostname playbook.yml

# Configure only time-related settings
ansible-playbook -t ntp,time,timezone playbook.yml

# OS-specific configuration only
ansible-playbook -t os-specific playbook.yml

# Skip NTP configuration
ansible-playbook --skip-tags ntp playbook.yml
```

## License

MIT

## Author Information

This role is part of the `wolskinet.infrastructure` Ansible collection.
