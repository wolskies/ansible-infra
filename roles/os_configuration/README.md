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

### Variable Structure

Uses flat variables for configuration (see configure_system/defaults/main.yml for complete reference):

```yaml
# Domain-level variables (shared across hosts)
domain_name: "company.com"
domain_timezone: "America/New_York"
domain_locale: "en_US.UTF-8"
domain_language: "en_US.UTF-8"
domain_ntp:
  enabled: true
  servers: ["time1.company.com"]

# Host-level variables
host_hostname: ""
host_update_hosts: true

# Host services (Linux)
host_services: {}
# Example: { enable: ["nginx"], disable: ["bluetooth"] }

# Host security hardening (Linux)
host_security:
  hardening_enabled: true              # Enable/disable comprehensive OS hardening
  disable_ctrl_alt_del: false
  users_allow: []
  remove_additional_root_users: false
  enforce_password_aging: true

# Host sysctl parameters (Linux)
host_sysctl: {}
# Example: { parameters: { "vm.swappiness": 10 } }
# Note: These override/extend security hardening sysctl settings

# Host limits (Linux)
host_limits: {}
# Example: { limits: [{ domain: "*", limit_type: "soft", limit_item: "nofile", value: 65536 }] }

# Host modules (Linux)
host_modules: {}
# Example: { load: ["uvcvideo"], blacklist: ["nouveau"] }

# Host udev rules (Linux)
host_udev: {}
# Example: { rules: [{ name: "pico", priority: 99, content: "...", state: "present" }] }

# Journal configuration (Linux)
journal:
  configure: false
  max_size: "500M"
  max_retention: "30d"
  forward_to_syslog: false
  compress: true

# Remote logging (Linux)
rsyslog:
  enabled: false
  remote_host: ""
  remote_port: 514
  protocol: "udp"

# System optimizations (Linux)
optimizations:
  tune_swappiness: false
  swappiness: 10
```

## Example Usage

### Basic Configuration

```yaml
- name: Configure operating system
  include_role:
    name: wolskinet.infrastructure.os_configuration
  vars:
    domain_name: "example.com"
    domain_timezone: "America/New_York"
    host_hostname: "web-server-01"
```

### Advanced Linux Server

```yaml
- name: Configure Linux server with hardening
  include_role:
    name: wolskinet.infrastructure.os_configuration
  vars:
    domain_name: "internal.company.com"
    domain_timezone: "America/New_York"
    domain_ntp:
      enabled: true
      servers: ["ntp1.company.com", "ntp2.company.com"]

    host_hostname: "db-primary"
    host_services:
      enable: ["systemd-timesyncd"]
      disable: ["bluetooth", "cups"]
    host_security:
      disable_ctrl_alt_del: true
      enforce_password_aging: true
    host_sysctl:
      parameters:
        vm.swappiness: 1
        net.core.default_qdisc: "fq"

    journal:
      configure: true
      max_size: "1G"
    optimizations:
      tune_swappiness: true
      swappiness: 1
```

### macOS Configuration

```yaml
- name: Configure macOS system
  include_role:
    name: wolskinet.infrastructure.os_configuration
  vars:
    domain_name: "local"
    domain_timezone: "America/Los_Angeles"
    host_hostname: "MacBook-Pro"
```

### Multi-Host Environment

```yaml
# inventory/group_vars/all.yml
domain_name: "company.com"
domain_timezone: "America/New_York"
domain_locale: "en_US.UTF-8"
domain_ntp:
  enabled: true
  servers: ["time1.company.com", "time2.company.com"]

# inventory/host_vars/web01.yml
host_hostname: "web01"
host_services:
  disable: ["bluetooth"]
host_security:
  disable_ctrl_alt_del: true

# inventory/host_vars/development.yml (disable hardening for dev systems)
host_security:
  hardening_enabled: false
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
