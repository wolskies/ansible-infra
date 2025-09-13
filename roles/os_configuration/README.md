# os_configuration

OS configuration for Ubuntu 22+, Debian 12+, Arch Linux, and MacOSX.

## Description

Configures basic OS configuration (timezone, locale, NTP, hostname) and distribution-specific settings (services, journals). On Linux systems, applies comprehensive security hardening using devsec.hardening.os_hardening.

## Features

- **Security hardening**: Comprehensive OS hardening for Linux systems (200+ security configurations)
- **Basic OS settings**: timezone, locale, NTP, hostname, /etc/hosts management
- **Distribution-specific**: systemd services, journald, unattended upgrades, platform optimizations
- **Cross-platform**: Ubuntu/Debian/Arch Linux/macOS

## Architecture

**Task Flow:**

1. **Common Setup** (`main.yml`): Distribution config setup, timezone
2. **OS-Specific**:
   - `configure-Linux.yml`: **devsec.hardening.os_hardening first** (handles sysctl, PAM limits, kernel modules), then locale, NTP, journal, hostname
   - `configure-Darwin.yml`: macOS-specific configuration
3. **Distribution-Specific** (for Linux only):
   - `configure-Debian.yml`: Ubuntu + Debian specific settings
   - `configure-Archlinux.yml`: Arch Linux specific settings

**Security Hardening:** Uses devsec.hardening.os_hardening for comprehensive Linux security (200+ configurations). Some variables are exposed in our defaults for convenience. Power users should refer to devsec.hardening documentation for additional functionality.

## Role Variables

### Variable Structure

Uses flat variables for configuration (see configure_system/defaults/main.yml for complete reference):

```yaml
# Domain-level variables (shared across hosts)
domain_name: "company.com"
domain_timezone: "America/New_York"
domain_locale: "en_US.UTF-8"
domain_language: "en_US.UTF-8"
domain_ntp:
  enabled: true
  servers: ["time1.company.com"]

# Host-level variables
host_hostname: ""
host_update_hosts: true

host_services: {} # systemd service management
# Example: { enable: ["nginx"], disable: ["bluetooth"], mask: ["snapd"] }

host_sysctl: # passed to devsec.hardening as sysctl_overwrite
  parameters: {} # Example: { "vm.swappiness": 10, "net.ipv4.ip_forward": 1 }

host_modules: {} # kernel module management
# Example: { load: ["uvcvideo"], blacklist: ["nouveau"] }

host_udev: {} # udev rules
# Example: { rules: [{ name: "pico", priority: 99, content: "...", state: "present" }] }

host_security:
  hardening_enabled: true # passed to devsec.hardening as os_hardening_enabled
  disable_ctrl_alt_del: false # passed to devsec.hardening as os_ctrlaltdel_disabled
  users_allow: [] # passed to devsec.hardening as os_security_users_allow
  remove_additional_root_users: false # passed to devsec.hardening as os_remove_additional_root_users
  enforce_password_aging: true # passed to devsec.hardening as os_user_pw_ageing
  ssh_hardening_enabled: false # Enable SSH hardening via devsec.hardening.ssh_hardening
  ssh_server_ports: ["22"] # SSH server ports
  ssh_client_port: "22" # SSH client port
  ssh_listen_to: ["0.0.0.0"] # IP addresses SSH server should listen on
  sftp_enabled: true # Enable SFTP (required for Ansible file transfers)

# Journal configuration (Linux)
journal:
  configure: false
  max_size: "500M"
  max_retention: "30d"
  forward_to_syslog: false
  compress: true

# Remote logging (Linux)
rsyslog:
  enabled: false
  remote_host: ""
  remote_port: 514
  protocol: "udp"

```

## Example Usage

### Basic Configuration

```yaml
- name: Configure operating system
  include_role:
    name: wolskinet.infrastructure.os_configuration
  vars:
    domain_name: "example.com"
    domain_timezone: "America/New_York"
    host_hostname: "web-server-01"
```

### Advanced Linux Server

```yaml
- name: Configure Linux server with hardening
  include_role:
    name: wolskinet.infrastructure.os_configuration
  vars:
    domain_name: "internal.company.com"
    domain_timezone: "America/New_York"
    domain_ntp:
      enabled: true
      servers: ["ntp1.company.com", "ntp2.company.com"]

    host_hostname: "db-primary"
    host_services:
      enable: ["systemd-timesyncd"]
      disable: ["bluetooth", "cups"]
    host_security:
      disable_ctrl_alt_del: true
      enforce_password_aging: true
      ssh_hardening_enabled: true
      ssh_server_ports: ["22"]
      ssh_listen_to: ["10.0.0.5"]  # Only listen on internal interface
      sftp_enabled: true
    host_sysctl:
      parameters:
        vm.swappiness: 1
        net.core.default_qdisc: "fq"

    journal:
      configure: true
      max_size: "1G"
```

### macOS Configuration

```yaml
- name: Configure macOS system
  include_role:
    name: wolskinet.infrastructure.os_configuration
  vars:
    domain_name: "local"
    domain_timezone: "America/Los_Angeles"
    host_hostname: "MacBook-Pro"
```

### Multi-Host Environment

```yaml
# inventory/group_vars/all.yml
domain_name: "company.com"
domain_timezone: "America/New_York"
domain_locale: "en_US.UTF-8"
domain_ntp:
  enabled: true
  servers: ["time1.company.com", "time2.company.com"]

# inventory/host_vars/web01.yml
host_hostname: "web01"
host_services:
  disable: ["bluetooth"]
host_security:
  disable_ctrl_alt_del: true

# inventory/host_vars/development.yml (disable hardening for dev systems)
host_security:
  hardening_enabled: false

# inventory/host_vars/docker-host.yml (Docker/Kubernetes host)
host_sysctl:
  parameters:
    # Enable IPv4 forwarding for Docker/Kubernetes
    net.ipv4.ip_forward: 1
    # Optional: Enable IPv6 forwarding if using IPv6
    net.ipv6.conf.all.forwarding: 1
```

## Docker/Kubernetes Support

The OS hardening configuration disables IP forwarding by default for security. If you're running Docker or Kubernetes, you must override this setting:

```yaml
host_sysctl:
  parameters:
    # Required for Docker/Kubernetes
    net.ipv4.ip_forward: 1
    # Optional: Enable IPv6 forwarding if needed
    net.ipv6.conf.all.forwarding: 1
```

**Why this is needed**: Docker and Kubernetes require IP forwarding to route container traffic. The security hardening sets `net.ipv4.ip_forward: 0` by default, which will break container networking.

**Common use cases requiring IP forwarding**:
- Docker container hosts
- Kubernetes nodes (masters and workers)
- Systems running container orchestration
- Hosts with NAT/routing requirements

## Common Hardening Issues and Solutions

### Memory Randomization Compatibility (vm.mmap_rnd_bits)

The hardening sets `vm.mmap_rnd_bits: 32` by default for enhanced security, but some older systems only support smaller values. If you encounter errors like "Invalid argument" during sysctl application:

```yaml
host_sysctl:
  parameters:
    # Reduce memory randomization for older systems
    vm.mmap_rnd_bits: 16
    # Or disable completely if needed
    vm.mmap_rnd_bits: 0
```

**Common systems requiring lower values**:
- Older kernel versions (< 4.1)
- 32-bit systems
- Some virtualization platforms
- Embedded systems

### SSH Keys and Password Expiry

The hardening enables password aging by default, which can block SSH key logins after passwords expire. The collection handles this automatically, but if you use custom PAM configuration, ensure the `pam_unix.so` module includes `no_pass_expiry`:

```
account     required      pam_unix.so no_pass_expiry
```

To disable password aging entirely:
```yaml
host_security:
  enforce_password_aging: false
```

## Requirements

- **macOS**: Xcode Command Line Tools (`xcode-select --install`)
- **All platforms**: Appropriate sudo/admin privileges for system configuration

## Dependencies

- `community.general` (for timezone, locale_gen, osx_defaults)
- `ansible.posix` (for sysctl)

## Tags

Available tags for selective execution:

- **security, hardening** - Security hardening via devsec.hardening
- **hostname** - Hostname configuration
- **timezone** - Timezone settings
- **ntp, time** - NTP time synchronization
- **journal, logging** - Journal and logging configuration
- **rsyslog** - Remote syslog configuration
- **modules, kernel** - Kernel module management
- **udev, hardware** - udev hardware rules
- **os-configuration** - General OS configuration
- **distribution-specific** - Distribution-specific tasks

```bash
# Examples
ansible-playbook -t security playbook.yml         # Security hardening only
ansible-playbook -t hostname,timezone playbook.yml # Basic system identity
ansible-playbook -t modules,udev playbook.yml     # Hardware configuration
ansible-playbook --skip-tags hardening playbook.yml # Skip security hardening
```

## License

MIT

## Author Information

This role is part of the `wolskinet.infrastructure` Ansible collection.
