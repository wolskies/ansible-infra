# manage_security_services

Configures firewall (UFW on Linux, ALF on macOS) and fail2ban security services.

## Description

This role manages security services using simple, direct variable structures. On Linux, it configures UFW firewall rules and fail2ban jails. On macOS, it manages the Application Layer Firewall (ALF). The role includes SSH anti-lockout protection and automatic service management.

## Features

- **Linux**: UFW firewall with rule management and SSH anti-lockout protection
- **macOS**: Application Layer Firewall control via `socketfilterfw`
- **fail2ban**: Jail configuration and intrusion prevention (Linux only)
- **Platform detection**: Automatic OS-specific configuration

## Role Variables

### Firewall Configuration

```yaml
firewall:
  enabled: false                # Enable firewall service
  prevent_ssh_lockout: true     # Automatically allow SSH to prevent lockout
  package: "ufw"                # Firewall package (Linux only)
  stealth_mode: false           # macOS: Don't respond to ping/stealth mode
  block_all: false              # macOS: Block all incoming connections
  logging: false                # Enable firewall logging
  rules: []                     # Firewall rules (Linux only)
```

### Firewall Rules (Linux only)

Rules are passed directly to the `community.general.ufw` module:

```yaml
firewall:
  rules:
    - rule: allow               # allow/deny/limit/reject
      port: 22                  # Port number or range
      proto: tcp                # tcp/udp/any
    - rule: allow
      port: 80,443              # Multiple ports
      proto: tcp
    - rule: allow
      from_ip: 192.168.1.0/24   # Source IP/network
      port: 3000
      proto: tcp
    - rule: deny
      port: 23
      proto: tcp
      comment: "Block telnet"
```

### fail2ban Configuration (Linux only)

```yaml
fail2ban:
  enabled: false                # Enable fail2ban service
  sender: "root@localhost"      # Email sender for notifications
  dest_email: ""                # Email destination for notifications
  defaults:                     # Global defaults for all jails
    bantime: 3600               # Ban duration (seconds)
    findtime: 600               # Time window to count failures (seconds)
    maxretry: 5                 # Max failures before ban
  services:                     # Individual jail configurations
    - name: sshd                # Jail name
      enabled: true             # Enable this jail
      maxretry: 5               # Override global maxretry
      bantime: 3600             # Override global bantime
      findtime: 600             # Override global findtime
      logpath: /var/log/auth.log # Log file to monitor
  ignoreips:                    # IPs to never ban
    - "127.0.0.1/8"
    - "::1"
```

## Usage Examples

### Basic Linux Firewall

```yaml
- hosts: linux_servers
  become: true
  roles:
    - role: wolskies.infrastructure.manage_security_services
      vars:
        firewall:
          enabled: true
          prevent_ssh_lockout: true
          rules:
            - rule: allow
              port: 80
              proto: tcp
            - rule: allow
              port: 443
              proto: tcp
            - rule: limit
              port: 22
              proto: tcp
```

### macOS Firewall

```yaml
- hosts: macos_hosts
  become: true
  roles:
    - role: wolskies.infrastructure.manage_security_services
      vars:
        firewall:
          enabled: true
          stealth_mode: true    # Don't respond to ping
          logging: true         # Log firewall events
          # Note: rules are ignored on macOS
```

### fail2ban Protection

```yaml
- hosts: linux_servers
  become: true
  roles:
    - role: wolskies.infrastructure.manage_security_services
      vars:
        fail2ban:
          enabled: true
          dest_email: "admin@company.com"
          defaults:
            bantime: 3600
            maxretry: 3
          services:
            - name: sshd
              enabled: true
              maxretry: 3
              bantime: 7200
              logpath: /var/log/auth.log
            - name: nginx-http-auth
              enabled: true
              logpath: /var/log/nginx/error.log
```

### Combined Configuration

```yaml
# group_vars/webservers.yml
firewall:
  enabled: true
  prevent_ssh_lockout: true
  rules:
    - rule: allow
      port: 22
      proto: tcp
    - rule: allow
      port: 80,443
      proto: tcp

fail2ban:
  enabled: true
  dest_email: "security@company.com"
  services:
    - name: sshd
      enabled: true
      maxretry: 3
      bantime: 3600
```

## Platform Differences

### Linux (UFW)
- Uses `community.general.ufw` module for rule management
- Supports comprehensive port-based rules with protocols, sources, etc.
- SSH anti-lockout automatically allows SSH before applying rules
- fail2ban provides intrusion detection and prevention

### macOS (ALF)
- Uses native `socketfilterfw` command for configuration
- Application-based firewall (not port-based)
- Rules are ignored - ALF controls application access
- No fail2ban support (different security model)
- SSH access managed via System Preferences → Sharing → Remote Login

## SSH Anti-Lockout Protection

When `firewall.prevent_ssh_lockout: true` (default):
- Automatically allows SSH (port 22) before applying other rules
- Prevents accidental lockout when enabling firewall
- Only applies if SSH rule not already present in rules list
- Works on both IPv4 and IPv6

## Dependencies

- `community.general.ufw` - Linux firewall management
- `ansible.posix` - Service management

## Testing

```bash
molecule test -s manage_security_services
```

## License

MIT

## Author Information

This role is part of the wolskies.infrastructure collection.
