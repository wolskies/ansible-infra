# os_configuration

Core OS configuration for Ubuntu 22.04+, Debian 12+, Arch Linux, and macOS 13+.

## What It Does

Handles fundamental operating system configuration:

- **Hostname** - Set system hostname and update /etc/hosts
- **Timezone** - Configure system timezone
- **Locale** - Set system locale and language (Linux)
- **Services** - Enable/disable/mask systemd services (Linux)
- **Security** - Apply OS and SSH hardening (Linux, optional)
- **System Tuning** - Kernel parameters, modules, udev rules (Linux)
- **NTP** - Configure time synchronization
- **Journal** - Configure systemd journal settings (Linux)
- **Package Managers** - APT/Pacman proxy and configuration (Linux)
- **System Preferences** - Basic system settings (macOS)

## Usage

### Basic Configuration
```yaml
- hosts: all
  become: true
  roles:
    - wolskies.infrastructure.os_configuration
  vars:
    domain_timezone: "America/New_York"
    host_hostname: "{{ inventory_hostname }}"
    host_update_hosts: true
```

### Advanced Configuration
```yaml
# group_vars/all.yml
domain_timezone: "America/New_York"
domain_locale: "en_US.UTF-8"

# host_vars/web01.yml
host_hostname: "web01"
host_services:
  enable: [nginx, postgresql]
  disable: [apache2, sendmail]
  mask: [snapd]

host_modules:
  load: [br_netfilter]
  blacklist: [pcspkr]

hardening:
  os_hardening_enabled: true
  ssh_hardening_enabled: true
  # All devsec.hardening variables can be set directly:
  os_auth_pw_max_age: 90
  os_ctrlaltdel_disabled: true
  ssh_server_ports: ["22"]
  sftp_enabled: true

journal:
  configure: true
  max_size: "500M"
  max_retention: "30d"
```

## Variables

Uses collection-wide variables - see collection README for complete reference.

### Core Variables
- `domain_timezone` - System timezone (IANA format)
- `domain_locale` - System locale (e.g., "en_US.UTF-8")
- `host_hostname` - System hostname
- `host_update_hosts` - Update /etc/hosts file

### System Management
- `host_services.enable` - Services to enable and start
- `host_services.disable` - Services to disable and stop
- `host_services.mask` - Services to mask
- `host_modules.load` - Kernel modules to load
- `host_modules.blacklist` - Kernel modules to blacklist

### Security Hardening
- `hardening.os_hardening_enabled` - Enable OS hardening (Linux, via devsec.hardening.os_hardening)
- `hardening.ssh_hardening_enabled` - Enable SSH hardening (Linux, via devsec.hardening.ssh_hardening)

All [devsec.hardening.os_hardening](https://github.com/dev-sec/ansible-collection-hardening/tree/master/roles/os_hardening) and [devsec.hardening.ssh_hardening](https://github.com/dev-sec/ansible-collection-hardening/tree/master/roles/ssh_hardening) variables can be set directly in your inventory:

```yaml
hardening:
  os_hardening_enabled: true
  ssh_hardening_enabled: true
  # devsec.hardening.os_hardening variables:
  os_auth_pw_max_age: 90
  os_ctrlaltdel_disabled: true
  os_security_users_allow: []
  # devsec.hardening.ssh_hardening variables:
  ssh_server_ports: ["22"]
  ssh_listen_to: ["0.0.0.0"]
  sftp_enabled: true
```

### Optional Features
- `domain_timesync.enabled` - Enable NTP configuration
- `journal.configure` - Enable journal configuration
- `apt.proxy` - APT proxy URL (Ubuntu/Debian)
- `pacman.proxy` - Pacman proxy URL (Arch Linux)

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
- `apt` - APT configuration (Ubuntu/Debian)
- `pacman` - Pacman configuration (Arch Linux)
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
