# Ansible Collection - wolskies.infrastructure

Automates installation and maintenance tasks for multiple machines/operating systems.

## Included Roles

- **configure_system**: meta-role that orchestrates system configuration, system-level package installation, and initial user configuration (user, password, ssh keys)
- **configure_users**: Configures users preferences and user-level software installation
- **os_configuration**: System settings (timezone, hostname, services, kernel parameters, locale) + comprehensive security hardening for Linux systems
- **manage_users**: Creates user accounts, groups, and SSH keys (system-level)
- **manage_packages**: Manages packages via os-native package management system. For MacOS, homebrew is considered the 'native' package management system. If not present it will be installed via geerlingguy.mac collection.
- **manage_security_services**: Firewall (UFW/macOS) and fail2ban configuration
- **manage_snap_packages**: System level snap management and snap package management. Has the option to completely remove and disable snap on Ubuntu systems
- **manage_flatpak**: System level flatpak management, can enable flathub and browser extensions for flatpak
- **nodejs**: Nodejs installation (system level) and user-level package management
- **rust**: Rustup installation (system level) and user-level rust package management
- **go**: Go installation (system level) and user-level go package management

## Supported Operating Systems

**Ubuntu 22+**, **Debian 12+**, **Arch Linux**, and **macOS**.

**Note**:
This collection has the ability to specify nodejs, go and rust packages to install at the user level in configure_users. The nodejs, rustup, and go packages, if missing, are installed via system package manager. For Debian family, only **Ubuntu 24.04+** and **Debian 13+** have system packages available. For those operating systems nodejs, rustup, and go must be installed manually before running the script.

## Privilege and Execution Model

This collection supports a limited ability to configure multiple users and preferences on a host. System packages are installed normally with elevated privileges. In the case of homebrew, which can be picky about privileges, while intended to be common across users, the "homebrew user" will be the ansible user. Local packages and preferences can be configured at the user-level and will be installed to the user's home directory with the exception that any tooling ("rustup" in the case of rust) will be installed at the system level.

**Important for Docker/Kubernetes users**: The collection applies security hardening that disables IP forwarding by default. If you're running containers, you must enable it:

```yaml
host_sysctl:
  parameters:
    net.ipv4.ip_forward: 1 # Required for Docker/Kubernetes
```

**Note on compatibility**: Some older systems may need adjusted hardening settings (see os_configuration role documentation for memory randomization and SSH key compatibility).

## Installation

Install the collection and its dependencies:

```bash
# Install all dependencies (collections and roles)
ansible-galaxy install -r requirements.yml

# Install the collection
ansible-galaxy collection install wolskies.infrastructure
```

Or install from a local clone:

```bash
git clone https://github.com/wolskinet/ansible-infrastructure
cd ansible-infrastructure
ansible-galaxy install -r requirements.yml
ansible-galaxy collection install . --force
```

## Quick Start

```yaml
# group_vars/all.yml
domain_name: "company.com"
domain_timezone: "America/New_York"
domain_locale: "en_US.UTF-8"
domain_ntp:
  enabled: true
  servers: ["time1.company.com"]
users:
  - name: admin
    groups: [sudo]
    ssh_keys:
      - "ssh-ed25519 AAAAC3..."
target_user:
  name: admin
  nodejs:
    packages: [typescript, eslint]
  rust:
    packages: [ripgrep, bat]

# host_vars/web01.yml
host_hostname: "web01"
host_services:
  enable: [nginx]
  disable: [bluetooth]
packages:
  present:
    host:
      Ubuntu: [redis-server]
firewall:
  enabled: true
  rules:
    - rule: allow
      port: 80
      proto: tcp
```

```yaml
# playbook.yml
- hosts: all
  become: true
  roles:
    - wolskies.infrastructure.configure_system
    - wolskies.infrastructure.configure_users
```

## Dependencies and Credits

This collection uses and builds upon:

- **geerlingguy.mac**: Homebrew installation on macOS
- **devsec.hardening**: Comprehensive OS security hardening for Linux systems
- **kewlfft.aur**: AUR package management for Arch Linux
- **Jeff Geerling's nodejs role**: Inspiration for our nodejs implementation

## Additional Security Hardening

This collection includes comprehensive OS-level security hardening for Linux systems via devsec.hardening.os_hardening. For additional SSH-specific hardening, consider adding:

- **devsec.hardening**: OS and SSH hardening (os_hardening, ssh_hardening roles)

## Variable Reference

### Domain Configuration

```yaml
domain_name: "company.com" # Optional domain name
domain_timezone: "America/New_York" # System timezone
domain_locale: "en_US.UTF-8" # System locale
domain_language: "en_US" # System language
domain_ntp:
  enabled: true # Enable NTP synchronization
  servers: # Custom NTP servers
    - "time1.company.com"
    - "time2.company.com"
users: [] # Domain-wide user definitions
```

### Host Configuration

```yaml
host_hostname: "web01" # Individual hostname
host_update_hosts: true # Manage /etc/hosts file

host_services: # systemd service management
  enable: [nginx, redis]
  disable: [bluetooth, cups]

host_sysctl: # Kernel parameters
  parameters:
    vm.swappiness: 10
    net.ipv4.ip_forward: 1

host_limits: # PAM limits
  - domain: "*"
    type: soft
    item: nofile
    value: 65536

host_modules: # Kernel modules
  load: [uvcvideo]
  blacklist: [nouveau, radeon]

host_udev: # udev rules
  rules:
    - name: pico-permissions
      content: 'SUBSYSTEM=="usb", ATTRS{idVendor}=="2e8a", MODE="0666"'
      priority: 99
      state: present

packages: {} # Package management (see below)
firewall: {} # Firewall configuration (see below)
fail2ban: {} # Fail2ban configuration (see below)
journal: {} # Journal settings (see below)
snap: {} # Snap management (see below)
flatpak: {} # Flatpak management (see below)
```

### Package Management

```yaml
packages:
  present:
    all: # Packages for all hosts
      Ubuntu: [git, curl, vim]
      Debian: [git, curl, vim]
      Archlinux: [git, curl, vim]
      MacOSX: [git, curl, vim]
    group: # Group-specific packages
      Ubuntu: [nginx, postgresql]
    host: # Host-specific packages
      Ubuntu: [redis-server]
  remove:
    all:
      Ubuntu: [snapd] # Remove unwanted packages
  casks_present: # macOS casks
    all: [visual-studio-code, docker]

apt: # APT-specific settings
  unattended_upgrades:
    enabled: true
  repositories: # Custom repositories
    nodejs:
      name: nodejs
      types: [deb]
      uris: "https://deb.nodesource.com/node_20.x"
      suites: ["nodistro"]
      components: [main]
      signed_by: "https://deb.nodesource.com/gpgkey/nodesource.gpg.key"

homebrew: # Homebrew settings
  taps:
    - homebrew/cask-fonts
```

### User Management

```yaml
users:
  - name: developer
    comment: "Development User"
    groups: [sudo, docker]
    ssh_keys:
      - "ssh-ed25519 AAAAC3..."

    # Cross-platform preferences (identical across OS)
    git:
      user_name: "Developer Name"
      user_email: "dev@company.com"
      editor: vim

    # Language packages with auto-installation
    nodejs:
      packages: [typescript, eslint, prettier]
    rust:
      packages: [ripgrep, bat, fd-find]
    go:
      packages: [github.com/charmbracelet/glow@latest]

    # OS-specific preferences
    shell: /bin/zsh # Cross-platform shell
    dotfiles: # Linux/macOS dotfiles
      enable: true
      repository: "https://github.com/user/dotfiles"
      branch: main
```

### Firewall Configuration

```yaml
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
    - rule: allow
      from_ip: 192.168.1.0/24
      port: 3000
      proto: tcp
```

### Fail2ban Configuration

```yaml
fail2ban:
  enabled: true
  dest_email: "admin@company.com"
  defaults:
    bantime: 3600
    findtime: 600
    maxretry: 5
  services:
    - name: sshd
      enabled: true
      maxretry: 3
      bantime: 7200
```


### System Journal

```yaml
journal:
  max_size: "500M"
  max_retention: "30d"
  forward_to_syslog: false
```

### Alternative Package Systems

```yaml
snap:
  packages:
    install: [hello-world, code]
    remove: [unwanted-snap]

flatpak:
  enabled: true
  flathub: true
  packages:
    install: [org.gimp.GIMP, com.spotify.Client]
```

## Role Usage

### System Orchestration

Use `configure_system` to orchestrate all infrastructure roles:

```yaml
- hosts: all
  become: true
  roles:
    - wolskies.infrastructure.configure_system
```

### Individual Roles

Each role can be used independently:

```yaml
- hosts: web_servers
  become: true
  roles:
    - wolskies.infrastructure.os_configuration
    - wolskies.infrastructure.manage_users
    - wolskies.infrastructure.manage_packages
    - wolskies.infrastructure.manage_security_services

- hosts: all
  become: true
  tasks:
    - name: Configure users individually
      include_role:
        name: wolskies.infrastructure.configure_user
      vars:
        target_user: "{{ item }}"
      loop: "{{ users }}"
      when: item.name != 'root'
      become_user: "{{ item.name }}"
```

## Dependencies

- **ansible-core**: 2.13+
- **community.general**: For npm, homebrew, and flatpak modules
- **ansible.posix**: For ACL and system management
- **Xcode Command Line Tools**: Required on macOS hosts
