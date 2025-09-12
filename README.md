# Ansible Collection - wolskinet.infrastructure

Infrastructure automation collection for multi-OS environments: **Ubuntu 22+**, **Debian 12+**, **Arch Linux**, and **macOS**.

**Language Package Requirements**: nodejs, rust, go packages require **Ubuntu 24.04+** and **Debian 13+** for reliable auto-installation due to package availability.

## Quick Start

```yaml
# group_vars/all/infrastructure.yml
infrastructure:
  domain:
    name: "company.com"
    timezone: "America/New_York"
    locale: "en_US.UTF-8"
    ntp:
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
infrastructure:
  host:
    hostname: "web01"
    services:
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

## Features

- **OS Configuration**: Timezone, hostname, services, kernel parameters
- **User Management**: Account creation and per-user preferences
- **Package Management**: System packages, snap, flatpak, homebrew
- **Security**: Firewall (UFW/macOS), fail2ban
- **Language Packages**: Auto-installs nodejs/rust/go when users request packages

## Variable Reference

### Domain Configuration

```yaml
infrastructure:
  domain:
    name: "company.com"              # Optional domain name
    timezone: "America/New_York"     # System timezone
    locale: "en_US.UTF-8"           # System locale
    language: "en_US"               # System language
    ntp:
      enabled: true                 # Enable NTP synchronization
      servers:                      # Custom NTP servers
        - "time1.company.com"
        - "time2.company.com"
    users: []                       # Domain-wide user definitions
```

### Host Configuration

```yaml
infrastructure:
  host:
    hostname: "web01"               # Individual hostname
    update_hosts: true              # Manage /etc/hosts file

    services:                       # systemd service management
      enable: [nginx, redis]
      disable: [bluetooth, cups]

    sysctl:                         # Kernel parameters
      parameters:
        vm.swappiness: 10
        net.ipv4.ip_forward: 1

    limits:                         # PAM limits
      - domain: "*"
        type: soft
        item: nofile
        value: 65536

    modules:                        # Kernel modules
      load: [uvcvideo]
      blacklist: [nouveau, radeon]

    udev:                          # udev rules
      rules:
        - name: pico-permissions
          content: 'SUBSYSTEM=="usb", ATTRS{idVendor}=="2e8a", MODE="0666"'
          priority: 99
          state: present

    packages: {}                   # Package management (see below)
    firewall: {}                   # Firewall configuration (see below)
    journal: {}                    # Journal settings (see below)
    snap: {}                       # Snap management (see below)
    flatpak: {}                    # Flatpak management (see below)
```

### Package Management

```yaml
infrastructure:
  host:
    packages:
      present:
        all:                       # Packages for all hosts
          Ubuntu: [git, curl, vim]
          Debian: [git, curl, vim]
          Archlinux: [git, curl, vim]
          Darwin: [git, curl, vim]
        group:                     # Group-specific packages
          Ubuntu: [nginx, postgresql]
        host:                      # Host-specific packages
          Ubuntu: [redis-server]
      remove:
        all:
          Ubuntu: [snapd]          # Remove unwanted packages
      casks_present:               # macOS casks
        all: [visual-studio-code, docker]
      apt:                         # APT-specific settings
        unattended_upgrades:
          enabled: true
        repositories:              # Custom repositories
          all:
            Ubuntu:
              - name: nodejs
                types: deb
                uris: "https://deb.nodesource.com/node_20.x"
                suites: nodistro
                components: [main]
                signed_by: /etc/apt/keyrings/nodesource.gpg
      homebrew:                    # Homebrew settings
        taps:
          - homebrew/cask-fonts
```

### User Management

```yaml
infrastructure:
  domain:
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
        shell: /bin/zsh             # Cross-platform shell
        dotfiles:                   # Linux/macOS dotfiles
          enable: true
          repository: "https://github.com/user/dotfiles"
          branch: main
```

### Firewall Configuration

```yaml
infrastructure:
  host:
    firewall:
      enabled: true
      prevent_ssh_lockout: true    # Always allow SSH
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
infrastructure:
  host:
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
infrastructure:
  host:
    journal:
      max_size: "500M"
      max_retention: "30d"
      forward_to_syslog: false
```

### Alternative Package Systems

```yaml
infrastructure:
  host:
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
      loop: "{{ infrastructure.domain.users }}"
      when: item.name != 'root'
      become_user: "{{ item.name }}"
```

## Platform Support

| Feature | Ubuntu 22+ | Debian 12+ | Debian 13+ | Arch Linux | macOS |
|---------|------------|------------|------------|------------|--------|
| Core OS Config | ✅ | ✅ | ✅ | ✅ | ✅ |
| Package Management | ✅ | ✅ | ✅ | ✅ | ✅ |
| User Management | ✅ | ✅ | ✅ | ✅ | ✅ |
| Node.js Auto-Install | ❌ | ❌ | ✅ | ✅ | ✅ |
| Rust Auto-Install | ✅ | ❌ | ✅ | ✅ | ✅ |
| Go Auto-Install | ✅ | ✅ | ✅ | ✅ | ✅ |
| Firewall (UFW/macOS) | ✅ | ✅ | ✅ | ✅ | ✅ |
| Snap Management | ✅ | ✅ | ✅ | ❌ | ❌ |
| Flatpak Management | ✅ | ✅ | ✅ | ✅ | ❌ |

**Critical**: Debian 12 and earlier do NOT include rustup packages. Use Debian 13+ or manually install rustup for Rust package support.

## Dependencies

- **ansible-core**: 2.13+
- **community.general**: For npm, homebrew, and flatpak modules
- **ansible.posix**: For ACL and system management
- **Xcode Command Line Tools**: Required on macOS hosts

## Advanced Examples

### Multi-Environment Setup

```yaml
# group_vars/all/infrastructure.yml
infrastructure:
  domain:
    name: "company.com"
    timezone: "UTC"
    users:
      - name: admin
        groups: [sudo]
        ssh_pubkey: "ssh-ed25519 AAAAC3..."

# group_vars/web_servers/infrastructure.yml
infrastructure:
  host:
    packages:
      present:
        group:
          Ubuntu: [nginx, certbot]
    firewall:
      enabled: true
      rules:
        - {port: 80, proto: tcp}
        - {port: 443, proto: tcp}

# host_vars/web01.yml
infrastructure:
  host:
    hostname: "web01.company.com"
    packages:
      present:
        host:
          Ubuntu: [redis-server, memcached]
```

### Development Environment

```yaml
infrastructure:
  domain:
    users:
      - name: dev
        groups: [sudo, docker]
        git:
          user_name: "Developer"
          user_email: "dev@company.com"
        nodejs:
          packages: [typescript, "@vue/cli", eslint, prettier]
        rust:
          packages: [ripgrep, bat, fd-find, exa]
        go:
          packages:
            - "github.com/charmbracelet/glow@latest"
            - "github.com/jesseduffield/lazygit@latest"
        shell: /bin/zsh
        dotfiles:
          enable: true
          repository: "https://github.com/dev/dotfiles"
          branch: main
```

This collection provides consistent infrastructure automation across multiple operating systems with a focus on simplicity and reusability.
