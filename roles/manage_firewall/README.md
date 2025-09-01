# manage_firewall

Pure firewall rule management across platforms.

## Description

This role provides firewall rule management only, assuming firewall services are already installed and enabled. It focuses purely on configuring firewall rules across Ubuntu, Debian, Arch Linux, and macOS, supporting UFW, firewalld, iptables, and macOS Application Layer Firewall with intelligent detection.

## Features

- **🔥 Multi-Platform Rules**: UFW, firewalld, iptables, macOS ALF rule management
- **⚙️ Flexible Rules**: Simple port lists, service names, or complex custom rules
- **🔍 Auto-Detection**: Automatically selects appropriate firewall tool per OS
- **🔒 SSH Protection**: Never blocks SSH access to prevent lockout
- **📊 Logging Support**: Configurable firewall logging levels

## Role Variables

See `defaults/main.yml` for complete variable documentation. Key variables include:

### Core Rule Configuration
```yaml
firewall_manage_rules: true            # Whether to manage firewall rules
firewall_type: "auto"                  # auto, ufw, firewalld, iptables, pf
firewall_reset_to_defaults: false      # Reset rules before applying new ones
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

## Dependencies

- `community.general` collection (for UFW support)
- `ansible.posix` collection (for firewalld support)

## Example Usage

### Basic Web Server Rules
```yaml
- hosts: web_servers
  roles:
    - role: wolskinet.infrastructure.manage_firewall
      vars:
        firewall_allowed_services: ["ssh", "http", "https"]
```

### Database Server with Restricted Access
```yaml
- hosts: db_servers
  roles:
    - role: wolskinet.infrastructure.manage_firewall
      vars:
        firewall_allowed_ports: ["22"]
        firewall_custom_rules:
          - rule: allow
            port: 3306
            protocol: tcp
            source: "10.0.1.0/24"
            comment: "MySQL from application servers"
```

## Architecture Integration

This role is designed to work with the infrastructure collection architecture:

1. **os_configuration**: Basic OS setup (hostname, NTP, locale)
2. **manage_security_services**: Install and enable firewall services
3. **manage_firewall**: Configure firewall rules (this role)

## Requirements

- Firewall service must be installed and enabled (handled by `manage_security_services`)
- Appropriate sudo/admin privileges for rule configuration

## Platform Support

- **Ubuntu 22+**: UFW rule management
- **Debian 12+**: UFW rule management  
- **Arch Linux**: UFW rule management
- **macOS**: Application Layer Firewall rule configuration (limited)

## Safety Features

- **SSH Protection**: Automatically maintains SSH access to prevent lockout
- **Validation**: Validates custom rules before application
- **Rule Reset**: Supports firewall reset if needed

## Integration Example

```yaml
- hosts: servers
  roles:
    - wolskinet.infrastructure.os_configuration         # Basic OS setup
    - wolskinet.infrastructure.manage_security_services  # Install firewall services
    - wolskinet.infrastructure.manage_firewall          # Configure rules
```

## License

MIT

## Author Information

This role is part of the `wolskinet.infrastructure` Ansible collection.