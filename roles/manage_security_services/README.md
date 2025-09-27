# manage_security_services

Firewall and intrusion prevention configuration for Ubuntu, Debian, Arch Linux, and macOS.

## What It Does

Manages security services with platform-specific implementations:
- **Linux** - UFW firewall rules and fail2ban intrusion prevention
- **macOS** - Application Layer Firewall configuration

## Usage

### Basic Firewall Configuration
```yaml
- hosts: all
  become: true
  roles:
    - wolskies.infrastructure.manage_security_services
  vars:
    firewall:
      enabled: true
      rules:
        - rule: allow
          port: 22
          protocol: tcp
        - rule: allow
          port: 80,443
          protocol: tcp

fail2ban:
  enabled: true
  maxretry: 3
  bantime: "1h"
```

### Advanced Configuration
```yaml
firewall:
  enabled: true
  prevent_ssh_lockout: true
  rules:
    - rule: allow
      port: 22
      protocol: tcp
      comment: "SSH access"
    - rule: allow
      source: 192.168.1.0/24
      port: 3000
      protocol: tcp
    - rule: deny
      port: 23
      protocol: tcp
      comment: "Block telnet"

fail2ban:
  enabled: true
  bantime: "10m"
  findtime: "10m"
  maxretry: 5
  jails:
    - name: sshd
      enabled: true
      maxretry: 3
      logpath: /var/log/auth.log
```

## Variables

Uses collection-wide variables - see collection README for complete reference.

### Firewall Variables
- `firewall.enabled` - Enable firewall service
- `firewall.prevent_ssh_lockout` - Automatically allow SSH to prevent lockout
- `firewall.rules` - Firewall rules (Linux only)
- `firewall.stealth_mode` - Don't respond to ping (macOS)
- `firewall.block_all` - Block all incoming connections (macOS)
- `firewall.logging` - Enable firewall logging (macOS)

### Firewall Rules Schema
| Field         | Type            | Required | Default   | Description                                    |
|---------------|-----------------|----------|-----------|------------------------------------------------|
| `port`        | integer\|string | Yes      | -         | Port number or range (e.g., 22, "8080:8090")   |
| `protocol`    | string          | No       | `"tcp"`   | Protocol ("tcp", "udp", "any")                 |
| `rule`        | string          | No       | `"allow"` | Rule action ("allow", "deny")                  |
| `source`      | string          | No       | `"any"`   | Source IP/CIDR (e.g., "192.168.1.0/24")       |
| `destination` | string          | No       | `"any"`   | Destination IP/CIDR                            |
| `comment`     | string          | No       | `""`      | Rule description                               |

### fail2ban Variables (Linux only)
- `fail2ban.enabled` - Enable fail2ban intrusion prevention
- `fail2ban.bantime` - Ban duration (e.g., "10m", "1h", "1d")
- `fail2ban.findtime` - Time window for counting failures
- `fail2ban.maxretry` - Number of failures before IP is banned
- `fail2ban.jails` - Jail configurations

### fail2ban Jails Schema
| Field      | Type    | Required | Default      | Description                                                |
|------------|---------|----------|--------------|-----------------------------------------------------------|
| `name`     | string  | Yes      | -            | Jail name (e.g., "sshd", "apache-auth", "nginx-http-auth") |
| `enabled`  | boolean | No       | `true`       | Whether this jail is active                                |
| `port`     | string  | No       | varies       | Port(s) to monitor (e.g., "ssh", "http,https", "22")       |
| `filter`   | string  | No       | auto         | Filter name to use (defaults to jail name)                 |
| `logpath`  | string  | Yes      | -            | Log file path to monitor (e.g., "/var/log/auth.log")       |
| `maxretry` | integer | No       | inherit      | Override global maxretry for this jail                     |

## Platform Differences

### Linux (UFW + fail2ban)
- Port-based firewall rules with comprehensive options
- SSH anti-lockout protection automatically detects SSH port
- fail2ban provides intrusion detection and prevention
- Supports rule actions: allow, deny, limit, reject

### macOS (Application Layer Firewall)
- Application-based firewall (not port-based)
- Firewall rules are ignored - ALF controls application access
- No fail2ban support (different security model)
- SSH access managed via System Preferences → Sharing → Remote Login

## Tags

Control which components run:
- `firewall` - Complete firewall management
- `firewall-rules` - Firewall rule application only
- `firewall-services` - Firewall service state management only
- `fail2ban` - Intrusion prevention service management
- `security` - All security services (firewall + fail2ban)
- `no-container` - Tasks requiring host capabilities

Example:
```bash
# Skip fail2ban configuration
ansible-playbook --skip-tags fail2ban playbook.yml

# Skip all security services
ansible-playbook --skip-tags security playbook.yml
```

## Platform Support

- **Ubuntu** 22.04+, 24.04+
- **Debian** 12+, 13+
- **Arch Linux** (Rolling)
- **macOS** 13+ (Ventura)

## Dependencies

- `community.general.ufw` (Linux firewall management)
- `ansible.posix` (Service management)
