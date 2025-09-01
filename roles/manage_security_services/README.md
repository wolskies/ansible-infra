# manage_security_services

Security services management: firewall services, fail2ban, and intrusion prevention.

## Description

This role manages security services that complement basic OS configuration. It handles firewall service installation/enablement, fail2ban intrusion prevention, and platform-specific security configurations. This role assumes basic OS setup is complete and focuses on security service deployment.

## Features

- **🔥 Firewall Services**: Install and enable UFW, macOS ALF, and other firewall services
- **🛡️ Intrusion Prevention**: Complete fail2ban installation and configuration
- **🍎 macOS Security**: Application Layer Firewall with stealth mode and logging
- **🔧 Service Management**: Proper service enablement and startup configuration
- **📧 Alert Integration**: Email notifications for security events

## Role Variables

See `defaults/main.yml` for complete configuration options.

### Core Security Configuration

```yaml
security_services_enabled: false       # Master switch for security services
```

### Firewall Services

```yaml
security_firewall_install: true        # Install firewall packages
security_firewall_enable: true         # Enable firewall service  
security_firewall_start: true          # Start firewall service
```

### macOS Firewall

```yaml
security_macos_firewall:
  enabled: true                         # Enable macOS firewall management
  stealth_mode: false                   # Enable stealth mode
  block_all: false                      # Block all incoming connections
  logging: false                        # Enable firewall logging
```

### Fail2ban Configuration

```yaml
security_fail2ban_enabled: false       # Install and configure fail2ban
security_fail2ban_default_bantime: 3600     # Default ban time (1 hour)
security_fail2ban_default_findtime: 600     # Default find time (10 minutes)
security_fail2ban_default_maxretry: 5       # Default max retry attempts

security_fail2ban_services:
  - name: sshd
    enabled: true
    maxretry: 5
    bantime: 3600
    findtime: 600
    logpath: /var/log/auth.log

security_fail2ban_ignoreips:
  - "127.0.0.1/8"
  - "::1"
```

## Example Usage

### Basic Security Services

```yaml
- name: Configure security services
  include_role:
    name: wolskinet.infrastructure.manage_security_services
  vars:
    security_services_enabled: true
    security_fail2ban_enabled: true
```

### Server with Enhanced Protection

```yaml
- name: Configure server security
  include_role:
    name: wolskinet.infrastructure.manage_security_services
  vars:
    security_services_enabled: true
    security_fail2ban_enabled: true
    security_fail2ban_services:
      - name: sshd
        enabled: true
        maxretry: 3
        bantime: 7200
      - name: nginx-http-auth
        enabled: true
        maxretry: 5
        bantime: 3600
```

### macOS Security Configuration

```yaml
- name: Configure macOS security
  include_role:
    name: wolskinet.infrastructure.manage_security_services
  vars:
    security_services_enabled: true
    security_macos_firewall:
      enabled: true
      stealth_mode: true
      logging: true
```

## Architecture

This role is designed to work with the infrastructure collection architecture:

1. **os_configuration**: Basic OS setup (hostname, locale, NTP)
2. **manage_security_services**: Install and enable security services (this role)
3. **manage_firewall**: Configure firewall rules (uses services installed here)

## Requirements

- **macOS**: Xcode Command Line Tools (`xcode-select --install`)
- **All platforms**: Appropriate sudo/admin privileges

## Dependencies

- `community.general` collection (for service management)
- `ansible.posix` collection (for systemd management)

## Platform Support

- **Ubuntu 22+**: Full UFW and fail2ban support
- **Debian 12+**: Full UFW and fail2ban support  
- **Arch Linux**: UFW and fail2ban support
- **macOS**: Application Layer Firewall configuration

## Integration

Works seamlessly with other infrastructure roles:

```yaml
- hosts: servers
  roles:
    - wolskinet.infrastructure.os_configuration      # Basic OS setup
    - wolskinet.infrastructure.manage_security_services  # Security services
    - wolskinet.infrastructure.manage_firewall       # Firewall rules
```

## License

MIT

## Author Information

This role is part of the `wolskinet.infrastructure` Ansible collection.