# Ansible Collection - wolskinet.infrastructure

Infrastructure automation collection for multi-OS environments: **Ubuntu 22+**, **Debian 12+**, **Arch Linux**, and **macOS**.

**Language Package Requirements**: nodejs, rust, go packages require **Ubuntu 24.04+** and **Debian 13+** for reliable auto-installation due to package availability.

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
    ssh_pubkey: "ssh-ed25519 AAAAC3..."
    git:
      user_name: "Admin User"
      user_email: "admin@company.com"
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
    - port: 80
      proto: tcp
      comment: "HTTP"
```

```yaml
# playbook.yml
- hosts: all
  become: true
  roles:
    - wolskinet.infrastructure.configure_system
```

## Included Roles

- **configure_system**: Orchestrates all infrastructure roles for complete system setup
- **os_configuration**: System settings (timezone, hostname, services, kernel parameters, locale)
- **manage_users**: Creates user accounts, groups, and SSH keys (system-level)
- **configure_user**: Per-user preferences, language packages, Git config, dotfiles (user-level)
- **manage_packages**: Package installation across distributions (apt, pacman, homebrew)
- **manage_security_services**: Firewall (UFW/macOS) and fail2ban configuration
- **manage_snap_packages/manage_flatpak**: Alternative package system management

## Dependencies and Credits

This collection uses and builds upon:

- **geerlingguy.mac**: Homebrew installation on macOS
- **Jeff Geerling's nodejs role**: Inspiration for our nodejs implementation

## Recommended Security Hardening

For comprehensive security hardening, use alongside:

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
    all:
      Ubuntu:
        - name: nodejs
          types: deb
          uris: "https://deb.nodesource.com/node_20.x"
          suites: nodistro
          components: [main]
          signed_by: /etc/apt/keyrings/nodesource.gpg

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
    ssh_pubkey: "ssh-ed25519 AAAAC3..."

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
  prevent_ssh_lockout: true # Always allow SSH
  rules:
    - port: 80
      proto: tcp
      comment: "HTTP traffic"
    - port: 443
      proto: tcp
      comment: "HTTPS traffic"
    - port: "8080:8090"
      proto: tcp
      comment: "Application range"
```

### Security Services

```yaml
fail2ban:
  enabled: true
  services:
    - name: sshd
      enabled: true
      maxretry: 5
      bantime: 3600
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
    - wolskinet.infrastructure.configure_system
```

### Individual Roles

Each role can be used independently:

```yaml
- hosts: web_servers
  become: true
  roles:
    - wolskinet.infrastructure.os_configuration
    - wolskinet.infrastructure.manage_users
    - wolskinet.infrastructure.manage_packages
    - wolskinet.infrastructure.manage_security_services

- hosts: all
  become: true
  tasks:
    - name: Configure users individually
      include_role:
        name: wolskinet.infrastructure.configure_user
      vars:
        target_user: "{{ item.name }}"
      loop: "{{ users }}"
      when: item.name != 'root'
      become_user: "{{ item.name }}"
```

## Platform Support

**Critical**: Debian 12 and earlier do NOT include rustup packages. Use Debian 13+ or manually install rustup for Rust package support.

## Dependencies

- **ansible-core**: 2.13+
- **community.general**: For npm, homebrew, and flatpak modules
- **ansible.posix**: For ACL and system management
- **Xcode Command Line Tools**: Required on macOS hosts

This collection provides consistent infrastructure automation across multiple operating systems with a focus on simplicity and reusability.
