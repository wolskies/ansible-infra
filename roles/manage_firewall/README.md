# Ansible Role: System Security

Firewall and fail2ban management. Complements devsec.hardening collection.

## Scope

**This Role**: Firewall management + fail2ban
**Use devsec.hardening For**: SSH hardening, OS security, application hardening

## Usage

```yaml
- hosts: servers
  roles:
    - devsec.hardening.os_hardening      # OS-level security
    - devsec.hardening.ssh_hardening     # SSH security  
    - wolskinet.infrastructure.system_security  # Firewall + fail2ban
```

## Variables

```yaml
# Core settings
enable_firewall: true
enable_fail2ban: false

# Simple port lists
firewall_allowed_ports: ["22", "80", "443"]
firewall_allowed_services: ["ssh", "http", "https"]

# Advanced rules with source restrictions
firewall_custom_rules:
  - port: 3306
    protocol: tcp
    source: "10.0.1.0/24"
    comment: "MySQL from app subnet"

# Fail2ban configuration
fail2ban_services:
  - name: sshd
    enabled: true
    maxretry: 5
    bantime: 3600

fail2ban_ignoreips:
  - "127.0.0.1/8"
  - "192.168.1.0/24"
```

## Examples

### Web Server
```yaml
- hosts: web_servers
  vars:
    enable_firewall: true
    firewall_allowed_services: ["ssh", "http", "https"]
    enable_fail2ban: true
  roles:
    - wolskinet.infrastructure.system_security
```

### Database Server (Restricted)
```yaml
- hosts: db_servers
  vars:
    enable_firewall: true
    firewall_allowed_ports: ["22"]
    firewall_custom_rules:
      - port: 3306
        protocol: tcp
        source: "10.0.1.0/24"
  roles:
    - wolskinet.infrastructure.system_security
```

### Docker Host
```yaml
- hosts: docker_hosts
  vars:
    enable_firewall: true
    firewall_docker_integration: true
    firewall_allowed_ports: ["22", "80", "443"]
  roles:
    - wolskinet.infrastructure.system_security
```

## Discovery Integration

Discovery automatically provides:
- `firewall_type`: Detected firewall (ufw/firewalld/iptables)
- `enable_fail2ban`: False if already installed

## Platform Support

- **Ubuntu 24+**: UFW + fail2ban
- **Debian 12+**: UFW + fail2ban  
- **Arch Linux**: firewalld + fail2ban
- **macOS**: Limited (Application Layer Firewall only)

## Dependencies

- `community.general` (UFW module)
- `ansible.posix` (firewalld module)
- **Recommended**: `devsec.hardening` collection