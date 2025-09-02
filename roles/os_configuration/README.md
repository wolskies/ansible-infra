# os_configuration

Post-install OS configuration and setup for Ubuntu 22+, Debian 12+, Arch Linux, and macOS.

## Description

This role handles essential operating system configuration after initial installation. It focuses on OS-level settings like hostname, timezone, locale, NTP, system services, and platform-specific optimizations. The role follows a clean architecture with cross-platform common tasks and OS-specific implementations.

## Features

- **🖥️ Hostname & Domain**: Cross-platform hostname and FQDN management
- **⏰ Time & Timezone**: Timezone and NTP synchronization setup
- **🌐 Locale Configuration**: System locale and language settings (Linux + macOS)
- **📝 Logging**: systemd-journald and rsyslog configuration (Linux)
- **🔄 System Updates**: Unattended upgrades configuration (Debian family + Arch)
- **⚙️ System Services**: Service management and optimizations
- **🗂️ Package Manager**: APT/Pacman behavior configuration
- **🍎 macOS Integration**: Core OS configuration (hostname, NTP, locale, updates)

## Architecture

**Task Flow:**
1. **Common Setup** (`main.yml`): Hostname validation, timezone, facts
2. **Linux Common** (`configure-linux-common.yml`): Locale, NTP, journal, hostname
3. **OS-Specific**:
   - `configure-Debian-family.yml` (Ubuntu + Debian)
   - `configure-Archlinux.yml` (Arch Linux)
   - `configure-MacOSX.yml` (macOS)

## Role Variables

See `defaults/main.yml` for complete configuration options.

### Cross-Platform Variables

```yaml
# Hostname and domain
config_common_hostname: ""              # Hostname (empty = keep current)
config_common_domain: ""                # Domain (empty = localdomain)
config_common_update_hosts: true        # Update /etc/hosts with FQDN
config_common_timezone: 'UTC'           # System timezone

# Locale configuration
config_common_locale:
  locale: 'en_US.UTF-8'                # System locale
  language: 'en_US.UTF-8'              # Language setting

# NTP time synchronization
config_common_ntp:
  enabled: true                        # Enable NTP synchronization
  servers:                             # NTP servers
    - 0.pool.ntp.org
    - 1.pool.ntp.org
    - 2.pool.ntp.org
    - 3.pool.ntp.org
```

### Linux Configuration

```yaml
# systemd journal
config_linux_journal:
  enabled: true                        # Configure systemd journal
  max_size: "500M"                     # Maximum journal size
  max_retention: "30d"                 # Maximum retention time
  forward_to_syslog: false             # Forward to syslog
  compress: true                       # Compress archived journals

# Remote logging
config_linux_rsyslog:
  enabled: false                       # Enable remote syslog
  remote_host: ""                      # Remote syslog server
  remote_port: 514                     # Remote syslog port
  protocol: "udp"                      # Protocol (udp/tcp)
```

### Debian Family (Ubuntu + Debian)

```yaml
config_debian_family:
  # Snap management
  snap:
    remove_completely: false           # Remove snap entirely

  # Automatic updates
  unattended_upgrades:
    enabled: true                      # Enable unattended upgrades
    email: ""                          # Email for notifications
    auto_reboot: false                 # Allow automatic reboots
    reboot_with_users: false          # Reboot with users logged in
    reboot_time: "02:00"              # Reboot time

  # APT configuration
  apt:
    no_recommends: false               # Don't install recommends
    proxy: ""                          # HTTP proxy for APT

  # System services
  services:
    disable_unnecessary: false         # Disable bluetooth, cups, etc.
    unnecessary_services:              # Services to disable
      - bluetooth.service
      - cups.service

  # Performance optimizations
  optimizations:
    tune_swappiness: false             # Configure swappiness
    swappiness: 10                     # Swappiness value
```

### Arch Linux

```yaml
config_archlinux:
  # Automatic updates (systemd timer)
  unattended_upgrades:
    enabled: false                     # Enable daily upgrades

  # Pacman configuration
  pacman:
    no_confirms: false                 # Skip confirmation prompts
    proxy: ""                          # Pacman mirror proxy

  # System services
  services:
    disable_unnecessary: false         # Disable unnecessary services
    unnecessary_services:              # Services to disable
      - bluetooth.service
      - cups.service

  # Performance optimizations
  optimizations:
    tune_swappiness: false             # Configure swappiness
    swappiness: 10                     # Swappiness value
```

### macOS

```yaml
config_macos:
  computer_name: ""                    # Computer name (empty = use hostname)

  # System updates
  updates:
    auto_check: true                   # Check for updates automatically
```

**Note**: GUI-related macOS settings (Dock, Finder, behavior tweaks) have been moved to the `manage_system_settings` role for better separation of concerns. Use that role for desktop customizations.

## Example Usage

### Basic Configuration

```yaml
- name: Configure operating system
  include_role:
    name: wolskinet.infrastructure.os_configuration
  vars:
    config_common_hostname: "web-server-01"
    config_common_domain: "example.com"
    config_common_timezone: "America/New_York"
```

### Advanced Debian Server

```yaml
- name: Configure Debian server
  include_role:
    name: wolskinet.infrastructure.os_configuration
  vars:
    config_common_hostname: "db-primary"
    config_common_domain: "internal.company.com"
    config_debian_family:
      unattended_upgrades:
        enabled: true
        email: "admin@company.com"
        auto_reboot: true
        reboot_time: "03:00"
      services:
        disable_unnecessary: true
      optimizations:
        tune_swappiness: true
        swappiness: 1
```

### macOS Workstation

```yaml
- name: Configure macOS workstation
  include_role:
    name: wolskinet.infrastructure.os_configuration
  vars:
    config_common_hostname: "MacBook-Pro"
    config_common_domain: "local"
    config_macos:
      computer_name: "MacBook Pro"

# For GUI customizations, use manage_system_settings role:
- name: Configure macOS GUI settings
  include_role:
    name: wolskinet.infrastructure.manage_system_settings
  vars:
    config_macos_gui:
      dock:
        tile_size: 64
        autohide: true
      finder:
        show_hidden_files: true
      security:
        require_password_immediately: true
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
