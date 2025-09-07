# manage_security_services

Security services management: UFW wrapper for Linux, native ALF control for macOS, and fail2ban configuration.

## Description

This role provides platform-specific security service management. On Linux, it acts as a wrapper around `community.general.ufw` with SSH anti-lockout protection. On macOS, it directly manages the Application Layer Firewall via `socketfilterfw` commands. The role also handles fail2ban configuration on Linux systems.

## Features

- **Linux**: Direct pass-through to `community.general.ufw` with SSH anti-lockout
- **macOS**: Native Application Layer Firewall control via `socketfilterfw`
- **fail2ban**: Jail configuration and service management (Linux only)
- **Platform detection**: Automatic OS-specific task routing

## Role Variables

### Core Configuration

```yaml
# Distribution-specific security configuration
security_config:
  Ubuntu:
    firewall:
      enabled: false
      prevent_ssh_lockout: true
      package: "ufw"
      rules: []                   # Passed to community.general.ufw
    fail2ban:
      enabled: false
      sender: "root@localhost"
      dest_email: ""
      defaults:
        bantime: 3600
        findtime: 600
        maxretry: 5
      services:
        - name: sshd
          enabled: true
          maxretry: 5
          bantime: 3600
          findtime: 600
          logpath: /var/log/auth.log
      ignoreips:
        - "127.0.0.1/8"
        - "::1"
        
  Debian:
    firewall:
      enabled: false
      prevent_ssh_lockout: true
      package: "ufw"
      rules: []
    fail2ban:
      enabled: false
      sender: "root@localhost"
      dest_email: ""
      # ... same structure as Ubuntu
      
  Archlinux:
    firewall:
      enabled: false
      prevent_ssh_lockout: true
      package: "ufw"
      rules: []
    fail2ban:
      enabled: false
      # ... same structure as Ubuntu
      
  Darwin:
    firewall:
      enabled: false
      package: "macos_alf"        # Identifier (not actually installed)
      stealth_mode: false         # macOS socketfilterfw --setstealthmode
      block_all: false            # macOS socketfilterfw --setblockall
      logging: false              # macOS socketfilterfw --setloggingmode
    # Note: fail2ban not supported on macOS

# Backward compatibility - these will override distribution-specific if set
security:
  firewall:
    all_os:
      enabled: false
      prevent_ssh_lockout: true
    linux:
      package: "ufw"
    darwin:
      package: "macos_alf"
      stealth_mode: false
      block_all: false
      logging: false
    rules: []
  fail2ban:
    enabled: false
    # ... full structure available
```

## Platform-Specific Implementation

### Linux (UFW via community.general.ufw)

On Linux systems, firewall rules are passed directly to `community.general.ufw`:

```yaml
security:
  firewall:
    rules:  # All parameters from community.general.ufw supported
      - rule: allow/deny/limit/reject
        port: 80
        proto: tcp/udp/any
        from: "10.0.0.0/8"
        to: "any"
        comment: "Description"
        delete: false
        direction: in/out/routed
        interface: eth0
        log: false
```

**SSH Anti-Lockout**: When `prevent_ssh_lockout: true`, automatically prepends SSH allow rule if not present in rules list.

### macOS (Native ALF Control)

On macOS, the role uses `/usr/libexec/ApplicationFirewall/socketfilterfw` directly:

```yaml
security:
  firewall:
    darwin:
      stealth_mode: true   # --setstealthmode on/off
      block_all: false     # --setblockall on/off  
      logging: true        # --setloggingmode on/off
    # Note: 'rules' are ignored on macOS - ALF is application-based, not port-based
```

**Important**: macOS ALF works differently than UFW:
- Controls which applications can receive incoming connections
- Does not use port-based rules
- SSH access controlled via System Preferences → Sharing → Remote Login

## Usage Examples

### Linux Firewall with UFW
```yaml
- hosts: linux_servers
  roles:
    - role: wolskinet.infrastructure.manage_security_services
      vars:
        security_config:
          Ubuntu:
            firewall:
              enabled: true
              prevent_ssh_lockout: true
              rules:  # Standard community.general.ufw parameters
                - rule: allow
                  port: 80
                  proto: tcp
                  comment: "HTTP"
                - rule: allow
                  port: 443
                  proto: tcp
                  comment: "HTTPS"
                - rule: limit
                  port: 22
                  proto: tcp
                  from: 10.0.0.0/8
                  comment: "SSH from internal"
```

### macOS Firewall Configuration
```yaml
- hosts: macos_hosts
  roles:
    - role: wolskinet.infrastructure.manage_security_services
      vars:
        security_config:
          Darwin:
            firewall:
              enabled: true
              stealth_mode: true    # Don't respond to ping
              block_all: false      # Don't block all incoming
              logging: true         # Log firewall events
              # rules: ignored on macOS
```

### fail2ban (Linux Only)
```yaml
- hosts: linux_servers
  roles:
    - role: wolskinet.infrastructure.manage_security_services
      vars:
        security_config:
          Ubuntu:
            fail2ban:
              enabled: true
              services:
                - name: sshd
                  enabled: true
                  maxretry: 3
                  bantime: 7200
                  findtime: 600
                  logpath: /var/log/auth.log
```

### Backward Compatibility
```yaml
# Legacy format still supported (overrides distribution-specific)
- hosts: linux_servers
  roles:
    - role: wolskinet.infrastructure.manage_security_services
      vars:
        security:
          firewall:
            all_os:
              enabled: true
            rules:
              - rule: allow
                port: 80
```

## What This Role Adds

### For Linux
- **SSH Anti-Lockout**: Prevents accidental lockout when enabling UFW
- **Service Management**: UFW package installation and enablement
- **fail2ban Integration**: Complete jail.local templating

### For macOS
- **Native ALF Control**: Direct socketfilterfw command execution
- **Simplified Interface**: Manages stealth mode, logging, and block_all settings
- **No fail2ban**: macOS uses different security model

## Dependencies

- `community.general.ufw` - Linux firewall management
- `ansible.posix` - Service management

## See Also

- [community.general.ufw documentation](https://docs.ansible.com/ansible/latest/collections/community/general/ufw_module.html) (Linux)
- [macOS Application Layer Firewall](https://support.apple.com/guide/mac-help/block-connections-to-your-mac-with-a-firewall-mh34041/mac) (macOS)
- [fail2ban documentation](https://www.fail2ban.org/) (Linux)

## Testing

```bash
molecule test -s manage_security_services
```

## License

MIT

## Author Information

Ed Wolski - wolskinet