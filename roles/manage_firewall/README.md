# manage_firewall

Pure firewall rule management role. Manages firewall rules without handling service installation or configuration (which is handled by `manage_security_services`).

## Description

This role provides a clean, declarative interface for managing firewall rules. It currently supports UFW (Uncomplicated Firewall) with a structure that allows for future backend expansion (firewalld, iptables, etc.).

The role accepts a simple list of rules that directly map to the `community.general.ufw` module parameters, providing full flexibility while maintaining simplicity.

## Features

- **📝 Declarative Rule Management**: Simple list of rules with all UFW options
- **🔒 SSH Safety**: Automatically ensures SSH access before applying rules
- **🎯 Direct UFW Mapping**: All parameters match the UFW module exactly
- **🔄 Idempotent**: Safe to run multiple times
- **🏗️ Backend Agnostic Structure**: Ready for future firewall backend support

## Role Variables

See `defaults/main.yml` for complete examples and all available parameters.

### Basic Configuration

```yaml
firewall_rules: []                      # List of firewall rules to apply
firewall_backend: "ufw"                 # Currently only UFW is supported
```

### Rule Parameters

All parameters from the [community.general.ufw module](https://docs.ansible.com/ansible/latest/collections/community/general/ufw_module.html) are supported:

- `rule`: allow, deny, reject, limit (required)
- `port`: Port number or range (e.g., "80", "8000:8100")
- `proto`: Protocol (tcp, udp, ipv6, esp, ah, gre, igmp)
- `name`: Service name (e.g., "OpenSSH")
- `src`/`source`: Source IP/subnet
- `dest`/`destination`: Destination IP/subnet
- `interface`: Network interface
- `direction`: in, out, routed
- `delete`: Set to true to remove the rule
- `comment`: Rule description
- And more...

## Example Usage

### Basic Web Server Rules

```yaml
- name: Configure web server firewall
  include_role:
    name: wolskinet.infrastructure.manage_firewall
  vars:
    firewall_rules:
      - rule: allow
        port: 80
        proto: tcp
        comment: "HTTP traffic"
      - rule: allow
        port: 443
        proto: tcp
        comment: "HTTPS traffic"
```

### Database Server with Source Restrictions

```yaml
- name: Configure database firewall
  include_role:
    name: wolskinet.infrastructure.manage_firewall
  vars:
    firewall_rules:
      - rule: allow
        port: 3306
        proto: tcp
        src: 10.0.1.0/24
        comment: "MySQL from app subnet"
      - rule: allow
        port: 5432
        proto: tcp
        src: 10.0.2.0/24
        comment: "PostgreSQL from admin subnet"
```

### Complex Rules with Rate Limiting

```yaml
- name: Configure advanced firewall rules
  include_role:
    name: wolskinet.infrastructure.manage_firewall
  vars:
    firewall_rules:
      # Rate limiting on SSH
      - rule: limit
        port: 22
        proto: tcp
        comment: "SSH rate limiting"

      # Port range for application
      - rule: allow
        port: 8000:8100
        proto: tcp
        comment: "Application port range"

      # Interface-specific rule
      - rule: allow
        interface: docker0
        direction: in
        comment: "Docker network traffic"

      # Delete an old rule
      - rule: allow
        port: 9999
        proto: tcp
        delete: yes
        comment: "Remove deprecated service"
```

### Using Service Names

```yaml
- name: Configure services by name
  include_role:
    name: wolskinet.infrastructure.manage_firewall
  vars:
    firewall_rules:
      - rule: allow
        name: OpenSSH
        comment: "SSH service"
      - rule: allow
        name: "WWW Full"
        comment: "HTTP and HTTPS"
      - rule: allow
        name: "Postfix"
        comment: "Mail server"
```

## Architecture Integration

This role works in conjunction with other infrastructure roles:

1. **manage_security_services**: Installs and configures firewall service
2. **manage_firewall**: Manages firewall rules (this role)
3. **configure_system**: Orchestrates the overall system configuration

### Typical Workflow

```yaml
- hosts: servers
  roles:
    # First: Install and configure firewall service
    - role: wolskinet.infrastructure.manage_security_services
      tags: security-services

    # Then: Apply firewall rules
    - role: wolskinet.infrastructure.manage_firewall
      vars:
        firewall_rules: "{{ my_firewall_rules }}"
      tags: firewall-rules
```

## SSH Safety

The role automatically ensures SSH access (port 22) is allowed before applying any rules. This prevents accidental lockout during remote management.

## Platform Support

- **Ubuntu 22+**: Full UFW support
- **Debian 12+**: Full UFW support
- **Arch Linux**: UFW support (if installed)
- **Future**: firewalld, iptables backends

## Requirements

- **Linux**: UFW must be installed (handled by `manage_security_services`)
- **Ansible Collections**: `community.general` for UFW module

## Dependencies

- `community.general` collection (for UFW module)
- Firewall service must be installed (use `manage_security_services` role)

## License

MIT

## Author Information

This role is part of the `wolskinet.infrastructure` Ansible collection.
