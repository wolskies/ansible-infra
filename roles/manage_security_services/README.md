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

### Tag-Based Control

This role uses tags for fine-grained control instead of enable/disable variables:

```bash
# Install only firewall services
ansible-playbook -t firewall-services playbook.yml

# Install only fail2ban
ansible-playbook -t fail2ban playbook.yml  

# Install all security services
ansible-playbook -t security-services playbook.yml
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
# Control via tags - no enable/disable variable needed
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
# Install all security services
- name: Configure security services
  include_role:
    name: wolskinet.infrastructure.manage_security_services
  tags: security-services
```

### Server with Enhanced Protection

```yaml
- name: Configure server security
  include_role:
    name: wolskinet.infrastructure.manage_security_services
  vars:
    security_fail2ban_services:
      - name: sshd
        enabled: true
        maxretry: 3
        bantime: 7200
      - name: nginx-http-auth
        enabled: true
        maxretry: 5
        bantime: 3600
  tags: security-services
```

### macOS Security Configuration

```yaml
- name: Configure macOS security
  include_role:
    name: wolskinet.infrastructure.manage_security_services
  vars:
    security_macos_firewall:
      enabled: true
      stealth_mode: true
      logging: true
  tags: firewall-services
```

## Architecture

This role is designed to work with the infrastructure collection architecture:

1. **os_configuration**: Basic OS setup (hostname, locale, NTP)
2. **manage_security_services**: Install and enable security services (this role)
3. **manage_firewall**: Configure firewall rules and start services safely

### Firewall Safety

This role safely handles firewall activation using proper separation of concerns:

**Architecture Flow:**
1. **manage_security_services**: Installs firewall package and enables service
2. **manage_firewall**: Configures rules (called automatically with SSH protection)
3. **manage_security_services**: Starts firewall service (handlers reload on rule changes)

**Linux (UFW)**: When `security_firewall_common.start: true`, the role:
1. Installs UFW package
2. Calls manage_firewall with default rules (minimum: SSH access)
3. Starts UFW service (with deny-by-default policy)

**macOS (Application Layer Firewall)**: ALF works differently - it's application-based, not port-based:
- SSH access is controlled by "Remote Login" system preference, not firewall rules  
- `default_rules` are ignored on macOS (only applies to Linux)
- ALF controls which applications can accept incoming connections
- Configured via `security_firewall_macosx` settings (stealth_mode, block_all, logging)

```yaml
security_firewall_common:
  enabled: true    # Enable service for boot (implies package installation)  
  start: true      # Start firewall service (with SSH protection via manage_firewall)
  # default_rules automatically includes SSH protection - see defaults/main.yml
```

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