# manage_firewall

Cross-platform firewall and intrusion prevention management with fail2ban integration.

## Description

This role provides comprehensive firewall management across Ubuntu, Debian, Arch Linux, and macOS. It supports UFW, firewalld, iptables, and macOS Application Layer Firewall with intelligent detection and configuration. The role also includes optional fail2ban integration for intrusion prevention.

## Features

- **🔥 Multi-Platform Firewall**: UFW, firewalld, iptables, macOS ALF support
- **🛡️ Intrusion Prevention**: fail2ban integration with service-specific rules
- **⚙️ Flexible Rules**: Simple port lists, service names, or complex custom rules
- **🔍 Auto-Detection**: Automatically selects appropriate firewall tool per OS
- **🔒 SSH Protection**: Never blocks SSH access to prevent lockout
- **📊 Logging Support**: Configurable firewall logging levels

## Role Variables

See `defaults/main.yml` for complete variable documentation. Key variables include:

### Core Firewall Configuration
```yaml
firewall_enable: false                 # Enable firewall management (opt-in for safety)
firewall_type: "auto"                  # auto, ufw, firewalld, iptables, pf
firewall_default_policy: "deny"        # Default policy for incoming connections
firewall_logging: false                # Enable firewall logging
```

### Access Control
```yaml
firewall_allowed_ports: []             # List of ports to allow (e.g., ["80", "443"])
firewall_allowed_services: []          # List of service names (e.g., ["http", "https"])
firewall_denied_ports: []              # List of ports to explicitly deny
firewall_denied_services: []           # List of services to explicitly deny
```

### Advanced Rules
```yaml
firewall_custom_rules: []              # Complex rules with source restrictions
# Example:
# firewall_custom_rules:
#   - rule: allow
#     port: 3306
#     protocol: tcp
#     source: "10.0.1.0/24"
#     comment: "MySQL from app subnet"
#   - rule: allow
#     name: "OpenSSH"
#     comment: "SSH access"
```

### Fail2ban Configuration
```yaml
firewall_enable_fail2ban: false        # Install and configure fail2ban
firewall_fail2ban_services:
  - name: sshd
    enabled: true
    maxretry: 5
    bantime: 3600
    findtime: 600
    logpath: /var/log/auth.log

firewall_fail2ban_ignoreips:
  - "127.0.0.1/8"
  - "::1"
```

### Platform-Specific Settings
```yaml
# OS-specific tool preferences
firewall_tool_preference:
  Ubuntu: "ufw"
  Debian: "ufw" 
  Archlinux: "ufw"
  MacOSX: "macos_alf"

# macOS-specific settings
firewall_macos_stealth_mode: false     # Enable stealth mode
firewall_macos_block_all: false        # Block all incoming connections
```

## Dependencies

- `community.general` collection (for UFW support)
- `ansible.posix` collection (for firewalld support)

## Example Playbook

### Basic Web Server
```yaml
- hosts: web_servers
  roles:
    - role: wolskinet.infrastructure.manage_firewall
      vars:
        firewall_enable: true
        firewall_allowed_services: ["ssh", "http", "https"]
```

### Database Server with Restricted Access
```yaml
- hosts: db_servers
  roles:
    - role: wolskinet.infrastructure.manage_firewall
      vars:
        firewall_enable: true
        firewall_allowed_ports: ["22"]
        firewall_custom_rules:
          - rule: allow
            port: 3306
            protocol: tcp
            source: "10.0.1.0/24"
            comment: "MySQL from application servers"
```

### Server with Fail2ban Protection
```yaml
- hosts: servers
  roles:
    - role: wolskinet.infrastructure.manage_firewall
      vars:
        firewall_enable: true
        firewall_allowed_services: ["ssh", "http", "https"]
        firewall_enable_fail2ban: true
        firewall_fail2ban_services:
          - name: sshd
            enabled: true
            maxretry: 3
            bantime: 7200
          - name: nginx-http-auth
            enabled: true
            maxretry: 5
            bantime: 3600
```

### macOS Firewall Configuration
```yaml
- hosts: macos_systems
  roles:
    - role: wolskinet.infrastructure.manage_firewall
      vars:
        firewall_enable: true
        firewall_macos_stealth_mode: true
        firewall_logging: true
```

## Platform Support

- **Ubuntu 22+**: Full UFW and fail2ban support
- **Debian 12+**: Full UFW and fail2ban support  
- **Arch Linux**: UFW and fail2ban support
- **macOS**: Application Layer Firewall (limited functionality)

## Safety Features

- **SSH Protection**: Automatically allows SSH to prevent lockout
- **Opt-in Design**: Firewall disabled by default (`firewall_enable: false`)
- **Validation**: Validates custom rules before application
- **Rollback**: Supports firewall reset if needed

## Integration with Other Roles

Works well with security-focused roles:

```yaml
- hosts: servers
  roles:
    - devsec.hardening.os_hardening        # OS security hardening
    - devsec.hardening.ssh_hardening       # SSH security
    - wolskinet.infrastructure.manage_firewall  # Firewall management
```

## File Locations

The role manages these system files:
- `/etc/ufw/` - UFW configuration (Ubuntu/Debian/Arch)
- `/etc/fail2ban/jail.local` - Fail2ban configuration
- macOS Application Layer Firewall via `socketfilterfw` command

## License

MIT

## Author Information

Ed Wolski - wolskinet