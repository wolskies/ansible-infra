# os_configuration

Core OS configuration for Ubuntu 22.04+, Debian 12+, Arch Linux, and macOS 13+.

## What It Does

Handles fundamental operating system configuration:

- **Hostname** - Set system hostname and update /etc/hosts
- **Timezone** - Configure system timezone
- **Locale** - Set system locale and language (Linux)
- **Users** - Create user accounts with SSH keys and groups
- **Services** - Enable/disable/mask systemd services (Linux)
- **Security** - Apply OS and SSH hardening (Linux, optional)
- **System Tuning** - Kernel parameters, modules, udev rules (Linux)
- **NTP** - Configure time synchronization
- **Journal** - Configure systemd journal settings (Linux)

## Usage

### Basic Configuration
```yaml
- hosts: all
  become: true
  roles:
    - wolskies.infrastructure.os_configuration
  vars:
    domain_timezone: "America/New_York"
    host_hostname: "web01"
    users:
      - name: admin
        groups: [sudo]
        ssh_keys:
          - "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5..."
```

### Advanced Configuration
```yaml
domain_timezone: "America/New_York"
domain_locale: "en_US.UTF-8"
host_hostname: "{{ inventory_hostname }}"
host_update_hosts: true

users:
  - name: admin
    uid: 1000
    groups: [sudo]
    shell: /bin/bash
    ssh_keys:
      - key: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5..."
        comment: "admin@workstation"

host_services:
  enable: [nginx, postgresql]
  disable: [apache2, sendmail]
  mask: [snapd]

host_sysctl:
  parameters:
    vm.swappiness: 10
    net.ipv4.ip_forward: 1

host_modules:
  load: [br_netfilter]
  blacklist: [pcspkr]

host_security:
  hardening_enabled: true
  ssh_hardening_enabled: true

journal:
  configure: true
  max_size: "500M"
  max_retention: "30d"
```

## Variables

Uses collection-wide variables:

- `domain_timezone` - System timezone (IANA format)
- `domain_locale` - System locale (e.g., "en_US.UTF-8")
- `host_hostname` - System hostname
- `host_update_hosts` - Update /etc/hosts file
- `users` - User account definitions
- `host_services` - Service management
- `host_sysctl` - Kernel parameters
- `host_modules` - Kernel modules
- `host_security` - Security hardening settings
- `domain_ntp` - NTP configuration
- `journal` - Journal settings

## Tags

Skip specific configuration areas:

- `hostname` - Hostname and /etc/hosts management
- `timezone` - Timezone configuration
- `locale` - Locale/language settings
- `ntp` - NTP time synchronization
- `services` - Systemd service management
- `modules` - Kernel module configuration
- `security` - Security hardening
- `journal` - Journal configuration
- `no-container` - Tasks requiring host capabilities

Example:
```bash
# Skip container-incompatible tasks
ansible-playbook --skip-tags no-container playbook.yml

# Skip security hardening
ansible-playbook --skip-tags security playbook.yml
```

## Platform Support

- **Ubuntu** 22.04+, 24.04+
- **Debian** 12+, 13+
- **Arch Linux** (Rolling)
- **macOS** 13+ (Ventura)

## Dependencies

- `devsec.hardening.os_hardening` (Linux security hardening)
- `devsec.hardening.ssh_hardening` (SSH security hardening)
