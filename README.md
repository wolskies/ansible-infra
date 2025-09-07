# Ansible Collection - wolskinet.infrastructure

Ansible infrastructure automation for Ubuntu 22+, Debian 12+, Arch Linux, and macOS.

## Architecture Overview

### Variable Structure

Roles share a common variable structure for interoperability. Most OS differences are handled by task logic. The major exception is for packages, since package names may differ across operating systems. Some functionality has been include in user configuration for operating system specific preferences as well.

```yaml
infrastructure:
  domain:
    name: "company.com"
    timezone: "America/New_York"
    locale: "en_US.UTF-8"
    ntp:
      enabled: true
      servers: [0.pool.ntp.org, 1.pool.ntp.org]
    users: []

  host:
    hostname: "web01" # Individual hostname
    update_hosts: true # /etc/hosts management
    packages: # Package management
      present:
        all:
          Ubuntu: [git, curl]
          Darwin: [git, curl]
        group:
          Ubuntu: [nginx]
        host:
          Ubuntu: [redis-server]
    firewall: # Firewall configuration
      enabled: false
      rules: []
    snap: # Snap management
      disable_and_remove: true
    flatpak: # Flatpak management
      enabled: false
```

## Core Roles

### **discovery**

Provided as a convenience to allow a user to get up and running. Will scan a system and populate a host_vars/host.yml file with data in the right format to be consumed by roles in this collection. It can be used on multiple hosts, however, it will not aggregate variables at the group level - that is left up to the user.

### **configure_system** - Orchestration

Simple role provided as a convenience that walks through the remaining roles in the collection with the aim at configuring a system/systems.

### **os_configuration** - System Foundation

OS-level configuration tasks:

- **Domain settings**: timezone, locale, NTP (consistent across environment)
- **Host settings**: hostname, /etc/hosts management, system services, logging
- **Platform specifics**: unattended upgrades (apt), gatekeeper (macOS), journal configuration

### **manage_users** - System Account Management

A thin wrapper around ansible.builtin.users that provides all of the functionality of that role, integrated in a way that it can be called by os_configuration.

### **configure_user** - User Preference Configuration

Provides per-user configuration of preferences. In general, these are settings that are local to the user (dotfiles, GUI configuration, locally installed applications)

- **Cross-platform**: Git config, language packages (nodejs, rust, go), shell, dotfiles
- **OS-specific**: macOS-only GUI preferences (dock, finder settings)
- **Auto-dependency installation**: installs nodejs/rustup/golang if packages requested
- **Dotfiles integration**: Stow-based dotfiles deployment from repositories

### **manage_packages** - Package Management

Distribution-specific package installation. For MacOS, "distribution-specific" means those packages and casks that can be installed by homebrew. Packages are installed system-wide for all users.

- **Package categories**: `all`, `group`, `host` are provided as a workaround for ansible's variable precedence for users that may prefer to specify packages at the all, group or host level and have them globbed together rather than overriden.
- **Repository management**: APT sources, Homebrew taps, AUR helpers
- **Multi-package-manager**: handles APT, pacman, Homebrew transparently

### **manage_security_services** - Security Configuration

Firewall and intrusion prevention options:

- **UFW** (Ubuntu/Debian/Arch), **macOS application firewall**
- **fail2ban**: intrusion detection with distribution-specific jails (Linux only)
- **Rule management**: declarative firewall rule configuration

### **manage_snap_packages** / **manage_flatpak** - Alternative Package Systems

- **Snap**: Ubuntu/Debian snap management (install/remove or complete system removal)
- **Flatpak**: Linux flatpak management with repository and plugin handling

## Installation & Usage

```bash
ansible-galaxy collection install wolskinet.infrastructure

# Create inventory structure (flexible - organize as needed)
mkdir -p inventory/{group_vars/all,host_vars}
mkdir -p playbooks
```

### Declarative Configuration

Variables are set anywhere in your inventory hierarchy:

```yaml
# inventory/group_vars/all.yml
infrastructure:
  domain:
    name: "company.local"
    timezone: "America/New_York"
    ntp:
      servers: [time1.company.com, time2.company.com]
    users:
      - name: deploy
        comment: "Deployment User"
        groups: [sudo]
        ssh_pubkey: "ssh-ed25519 AAAAC3..."
        shell: /bin/zsh              # Cross-platform shell preference

        # Cross-platform user preferences
        git:
          user_name: "Deploy User"
          user_email: "deploy@company.com"
        nodejs:
          packages: [pm2, typescript]
        rust:
          packages: [ripgrep, bat]
        dotfiles:
          repository: "https://github.com/deploy/dotfiles"
          method: stow
          packages: [zsh, tmux]

        # Only macOS-specific GUI preferences need their own section
        macosx:
          dock:
            tile_size: 48
            autohide: true

  host:
    packages:
      present:
        all:
          Ubuntu: [git, curl, htop, vim]
          Darwin: [git, curl, htop, vim]
    snap:
      disable_and_remove: true

# inventory/group_vars/webservers.yml
infrastructure:
  host:
    packages:
      present:
        group:
          Ubuntu: [nginx, certbot]
          Darwin: [nginx, certbot]
    firewall:
      enabled: true
      rules:
        - { port: 80, proto: tcp }
        - { port: 443, proto: tcp }

# inventory/host_vars/web01.yml
infrastructure:
  host:
    hostname: "web01"
    packages:
      present:
        host:
          Ubuntu: [redis-server]
          Darwin: [redis]
```

### Basic Playbook

```yaml
# playbooks/site.yml
- hosts: all
  roles:
    - wolskinet.infrastructure.os_configuration
    - wolskinet.infrastructure.manage_users # Creates user accounts
    - wolskinet.infrastructure.manage_packages

- hosts: webservers
  roles:
    - wolskinet.infrastructure.manage_security_services

# Configure user preferences (runs as each user)
- hosts: all
  vars:
    target_user: "{{ item }}"
  include_role:
    name: wolskinet.infrastructure.configure_user
  become: true
  become_user: "{{ item }}"
  loop: "{{ infrastructure.domain.users | map(attribute='name') | list }}"
```

## Advanced Configuration

### Multi-OS Package Management

```yaml
infrastructure:
  host:
    packages:
      present:
        all:
          Ubuntu: [git, curl, htop]
          Darwin: [git, curl, htop] # Installed via Homebrew
          Archlinux: [git, curl, htop] # Installed via pacman
      apt:
        repositories:
          all:
            Ubuntu:
              - name: docker
                types: deb
                uris: https://download.docker.com/linux/ubuntu
                suites: "{{ ansible_distribution_release }}"
                components: stable
                signed_by: https://download.docker.com/linux/ubuntu/gpg
            Debian:
              - name: docker
                types: deb
                uris: https://download.docker.com/linux/debian
                suites: "{{ ansible_distribution_release }}"
                components: stable
                signed_by: https://download.docker.com/linux/debian/gpg
```

### Firewall Configuration

```yaml
infrastructure:
  host:
    firewall:
      enabled: true
      rules:
        - port: 22
          proto: tcp
          src: "192.168.1.0/24"
          comment: "SSH from local network"
        - port: [80, 443]
          proto: tcp
          comment: "HTTP/HTTPS"
    fail2ban:
      enabled: true
      services:
        - name: sshd
          enabled: true
          bantime: 3600
```

### Alternative Package Systems

```yaml
infrastructure:
  host:
    snap:
      disable_and_remove: true # Complete snap removal
      # OR for managed snap usage:
      # disable_and_remove: false
      # packages:
      #   install: [hello-world]

    flatpak:
      enabled: true
      packages:
        install: [org.mozilla.firefox]
      flathub: true
      plugins:
        gnome: true
```

### User Language Development Environments

User-scoped language packages are configured per-user with automatic dependency installation:

```yaml
infrastructure:
  domain:
    users:
      - name: developer
        shell: /bin/zsh # Cross-platform shell preference
        # Cross-platform language packages (auto-installs tools if missing)
        nodejs:
          packages: [typescript, eslint, prettier] # Auto-installs nodejs
        rust:
          packages: [ripgrep, fd-find, bat] # Auto-installs rustup
        go:
          packages: [github.com/charmbracelet/glow@latest] # Auto-installs golang

        # Only macOS-specific GUI preferences
        macosx:
          dock:
            tile_size: 36
            autohide: false
```

Language tools are installed automatically when user requests packages:

- `nodejs.packages` → installs `nodejs` system package if `npm` not found
- `rust.packages` → installs `rustup` system package if `cargo` not found
- `go.packages` → installs `golang` system package if `go` not found

## Platform Support

**Ubuntu 22+ / Debian 12+**

- APT package management with repository handling
- Snap system management (complete removal or controlled usage)
- UFW firewall with fail2ban integration
- Unattended upgrades configuration

**Arch Linux**

- Pacman package management with AUR support
- Flatpak support
- systemd journal/service management

**macOS (Intel/Apple Silicon)**

- Homebrew package management
- System preference automation
- Built-in application firewall configuration
- Xcode Command Line Tools requirement

## Variable Hierarchy & Merging

The `infrastructure` structure supports flexible configuration patterns:

```yaml
# Roles merge all/group/host categories additively within final variable structure
# inventory/group_vars/all.yml
infrastructure:
  host:
    packages:
      present:
        all:
          Ubuntu: [git, curl]

# inventory/group_vars/webservers.yml
infrastructure:
  host:
    packages:
      present:
        group:
          Ubuntu: [nginx]

# inventory/host_vars/web01.yml
infrastructure:
  host:
    packages:
      present:
        host:
          Ubuntu: [redis-server]

# Final result: [git, curl, nginx, redis-server]
```

Variables follow standard Ansible precedence rules (group_vars < host_vars). Package management roles provide `all`, `group`, `host` categories within the package structure for organizational convenience - these are merged additively by the roles, but still subject to Ansible's standard variable precedence.

## Dependencies

**Required Collections:**

- `community.general` - firewall, package management, macOS defaults
- `ansible.posix` - sysctl, authorized_key, other POSIX utilities

**System Requirements:**

- **Ansible**: Core 2.12+
- **Target Systems**: Python 3.6+, sudo access
- **macOS**: Xcode Command Line Tools (`xcode-select --install`)

## License

MIT

---

**Architecture Summary:**

- **Domain/Host** separation eliminates configuration duplication
- **Distribution fact-driven** OS detection - no forced inventory structure
- **Declarative configuration** - users specify desired state, roles handle implementation
- **Multi-platform** with unified variable structure across Ubuntu/Debian/Arch/macOS
