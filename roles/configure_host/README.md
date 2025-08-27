# configure_host

System-level host configuration and settings management across multiple platforms.

## Description

This role handles comprehensive host-level configuration without package management. It configures hostname, timezone, locale, NTP, system limits, logging, and platform-specific optimizations. The role is designed to be standalone and can be used independently or as part of a larger infrastructure deployment.

## Features

- **🖥️ Hostname Configuration**: FQDN and /etc/hosts management
- **⏰ Time & Timezone**: NTP configuration and timezone settings  
- **🌐 Locale Settings**: System locale and language configuration
- **📊 System Limits**: File descriptor and process limits
- **📝 Logging Configuration**: systemd-journald and syslog settings
- **🔧 Platform Optimizations**: Ubuntu snap removal, Arch mirror optimization, macOS preferences
- **🗂️ Directory Management**: Create standard directories and set permissions
- **📋 Message of the Day**: Custom MOTD configuration

## Role Variables

### Core Settings
- `config_hostname: ""` - Set system hostname (empty = skip)
- `config_fqdn: ""` - Set fully qualified domain name
- `config_system_timezone: 'UTC'` - System timezone
- `config_system_locale: 'en_US.UTF-8'` - System locale

### Time Configuration
- `config_ntp_enabled: true` - Enable NTP synchronization
- `config_ntp_servers: [...]` - List of NTP servers

### System Optimization
- `config_system_limits: true` - Configure file descriptor limits
- `config_journald_enabled: true` - Configure systemd logging
- `config_motd_enabled: true` - Configure message of the day

### Platform-Specific Options
- `config_ubuntu_disable_snap: false` - Remove snap packages (Ubuntu)
- `config_arch_optimize_mirrors: false` - Optimize pacman mirrors (Arch)
- `config_macos_configure_defaults: false` - Configure system preferences (macOS)

### Directory Management  
- `config_create_directories: []` - Directories to create
- `config_directory_permissions: '0755'` - Default directory permissions

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
        config_system_locale: "en_US.UTF-8"
```

### Advanced Configuration
```yaml
- hosts: servers
  roles:
    - role: wolskinet.infrastructure.configure_host
      vars:
        config_hostname: "{{ inventory_hostname }}"
        config_fqdn: "{{ inventory_hostname }}.{{ domain_name }}"
        config_system_timezone: "{{ site_timezone }}"
        config_ntp_enabled: true
        config_ntp_servers:
          - ntp1.example.com
          - ntp2.example.com
        config_system_limits: true
        config_limits:
          - domain: '*'
            limit_type: soft
            limit_item: nofile
            value: 65536
        config_create_directories:
          - "/opt/applications"
          - "/var/log/applications"
        config_motd_enabled: true
```

### Platform-Specific Optimization
```yaml
# Ubuntu workstations
- hosts: ubuntu_workstations
  roles:
    - role: wolskinet.infrastructure.configure_host
      vars:
        config_ubuntu_disable_snap: true
        
# Arch Linux systems
- hosts: arch_systems  
  roles:
    - role: wolskinet.infrastructure.configure_host
      vars:
        config_arch_optimize_mirrors: true
        
# macOS systems
- hosts: macos_systems
  roles:
    - role: wolskinet.infrastructure.configure_host
      vars:
        config_macos_configure_defaults: true
```

## Platform Support

- **Ubuntu 24.04+**: Full support with snap removal options
- **Debian 12+**: Full support  
- **Arch Linux**: Full support with mirror optimization
- **macOS**: Basic support with system preferences configuration

## Integration with Other Roles

This role works well with other infrastructure roles:

```yaml
- hosts: servers
  roles:
    - wolskinet.infrastructure.configure_host    # System configuration
    - wolskinet.infrastructure.manage_packages   # Package management  
    - wolskinet.infrastructure.manage_users      # User management
    - wolskinet.infrastructure.manage_firewall   # Security configuration
```

## File Locations

The role manages these system files:
- `/etc/hostname` - System hostname
- `/etc/hosts` - Hostname resolution
- `/etc/timezone` - Timezone configuration
- `/etc/systemd/timesyncd.conf` - NTP configuration
- `/etc/locale.conf` - Locale settings
- `/etc/security/limits.conf` - System limits
- `/etc/systemd/journald.conf` - Logging configuration
- `/etc/motd` - Message of the day

## License

MIT

## Author Information

Ed Wolski - wolskinet