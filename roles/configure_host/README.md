# configure_host

Comprehensive host-level configuration and settings management across multiple platforms.

## Description

This role handles essential host configuration without package management. It configures hostname, timezone, locale, NTP, system limits, logging, unattended upgrades, and platform-specific optimizations. The role is designed to be standalone and can be used independently or as part of a larger infrastructure deployment.

## Features

- **🖥️ Hostname Configuration**: FQDN and /etc/hosts management
- **⏰ Time & Timezone**: NTP configuration and timezone settings  
- **🌐 Locale Settings**: System locale and language configuration
- **📊 System Limits**: File descriptor and process limits via PAM
- **🔧 Kernel Parameters**: sysctl configuration for performance tuning
- **📝 Logging Configuration**: systemd-journald management
- **🔄 Unattended Upgrades**: Automated security updates (Ubuntu/Debian)
- **🔥 Firewall**: Basic firewall enablement (macOS)
- **🗂️ Platform Optimizations**: Ubuntu snap removal, macOS system preferences

## Role Variables

See `defaults/main.yml` for complete variable documentation. Key variables include:

### Hostname Configuration
```yaml
config_hostname: ""                     # Set hostname (leave empty to skip)
config_fqdn: ""                        # Set FQDN (fully qualified domain name)
config_update_hosts: true              # Update /etc/hosts with hostname
```

### Time & Locale Configuration
```yaml
config_system_timezone: 'UTC'          # System timezone
config_ntp_enabled: true               # Enable NTP time synchronization
config_ntp_servers:                    # NTP servers list
  - 0.pool.ntp.org
  - 1.pool.ntp.org
  - 2.pool.ntp.org
  - 3.pool.ntp.org
config_system_locale: 'en_US.UTF-8'    # System locale for all platforms
config_system_language: 'en_US.UTF-8'  # Language setting (Linux only)
```

### System Configuration
```yaml
config_system_limits: false            # Configure PAM limits
config_limits:                         # PAM limits configuration
  - domain: '*'
    limit_type: soft
    limit_item: nofile
    value: 65536

config_sysctl: false                   # Configure kernel parameters
config_sysctl_params:                  # Sysctl parameters dictionary
  net.core.somaxconn: 65535
  vm.swappiness: 10
```

### Logging & Journal Configuration
```yaml
config_journal: true                   # Configure systemd journal
config_journal_max_size: "500M"       # Maximum journal size
config_journal_max_retention: "30d"   # Maximum retention time
```

### Firewall Configuration
```yaml
configure_firewall: true              # Enable firewall configuration (macOS)
enable_firewall: true                 # Enable firewall rules (macOS)
```

### System Updates Configuration
```yaml
enable_system_updates: true           # Include system updates in unattended upgrades
```

### Ubuntu/Debian Specific
```yaml
config_ubuntu_disable_snap: false      # Remove snap completely
config_ubuntu_unattended_upgrades: true # Configure unattended upgrades (Ubuntu)
config_debian_unattended_upgrades: true # Configure unattended upgrades (Debian)
config_unattended_email: ""           # Email for upgrade notifications
config_unattended_reboot: false       # Allow automatic reboots
config_unattended_reboot_with_users: false # Reboot even with users logged in
config_unattended_reboot_time: "02:00" # Time for automatic reboots
```

### macOS Specific
```yaml
config_macos_computer_name: ""         # Computer name (empty = use hostname)
config_macos_configure_system: true   # Apply macOS system preferences
config_macos_configure_dock: true     # Configure Dock preferences
config_macos_dock_tile_size: 48       # Dock tile size (16-128)
config_macos_dock_position: "bottom"  # Dock position (bottom, left, right)
config_macos_dock_autohide: false     # Auto-hide Dock
config_macos_configure_finder: true   # Configure Finder preferences
config_macos_finder_show_extensions: true # Show file extensions
config_macos_fast_key_repeat: true    # Enable fast key repeat
config_macos_configure_security: true # Apply security settings
# ... and many more macOS configuration options
```

## Dependencies

None. This role is designed to be fully standalone.

## Example Playbook

### Basic Usage
```yaml
- hosts: all
  roles:
    - role: wolskinet.infrastructure.configure_host
      vars:
        config_hostname: "web-server-01"
        config_fqdn: "web-server-01.example.com"
        config_system_timezone: "America/New_York"
```

### Server Configuration
```yaml
- hosts: servers
  roles:
    - role: wolskinet.infrastructure.configure_host
      vars:
        config_hostname: "{{ inventory_hostname }}"
        config_fqdn: "{{ inventory_hostname }}.{{ domain_name }}"
        config_system_timezone: "{{ site_timezone }}"
        config_system_limits: true
        config_sysctl: true
        config_unattended_email: "admin@example.com"
        config_unattended_reboot: true
        config_unattended_reboot_time: "03:00"
```

### Platform-Specific Examples
```yaml
# Ubuntu workstations - disable snap
- hosts: ubuntu_workstations
  roles:
    - role: wolskinet.infrastructure.configure_host
      vars:
        config_ubuntu_disable_snap: true

# macOS systems - full configuration        
- hosts: macos_systems
  roles:
    - role: wolskinet.infrastructure.configure_host
      vars:
        config_macos_configure_system: true
        config_macos_configure_dock: true
        config_macos_dock_autohide: true
        config_macos_configure_finder: true
        config_macos_finder_show_hidden: true
```

## Platform Support

- **Ubuntu 22+**: Full support with unattended upgrades and snap management
- **Debian 12+**: Full support with unattended upgrades
- **Arch Linux**: Basic configuration support  
- **macOS**: Full system preferences and security configuration

## Integration with Other Roles

This role works well as a foundation for other infrastructure roles:

```yaml
- hosts: servers
  roles:
    - wolskinet.infrastructure.configure_host    # Base system configuration
    - wolskinet.infrastructure.manage_packages   # Package management  
    - wolskinet.infrastructure.manage_users      # User management
    - wolskinet.infrastructure.manage_firewall   # Advanced firewall rules
```

## File Locations

The role manages these system files:
- `/etc/hostname` - System hostname
- `/etc/hosts` - Hostname resolution
- `/etc/timezone` - Timezone configuration (Debian/Ubuntu)
- `/etc/systemd/timesyncd.conf` - NTP configuration
- `/etc/locale.conf` - Locale settings (Arch)
- `/etc/default/locale` - Locale settings (Debian/Ubuntu)
- `/etc/security/limits.conf` - PAM limits
- `/etc/sysctl.d/99-custom.conf` - Kernel parameters
- `/etc/systemd/journald.conf` - Journal configuration
- `/etc/apt/apt.conf.d/50unattended-upgrades` - Unattended upgrade configuration

## License

MIT

## Author Information

Ed Wolski - wolskinet