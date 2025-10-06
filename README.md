# Ansible Collection - wolskies.infrastructure

Cross-platform system configuration, package management, and development environment setup.

**Supported Platforms:**
- Ubuntu 22.04+, 24.04+
- Debian 12+, 13+
- Arch Linux (Rolling)
- macOS 13+ (Ventura)

## Included Roles

### Core System Management
- **configure_system**: Meta-role orchestrating OS settings, packages, security, and user preferences
- **os_configuration**: System settings (timezone, hostname, locale, services, kernel parameters)
- **manage_packages**: Package management (APT, Pacman, Homebrew) with repository configuration
- **manage_security_services**: Firewall (UFW/macOS ALF) and fail2ban configuration

### User and Development Environment
- **configure_users**: User preferences (dotfiles, development tools, language environments)
- **nodejs**: Node.js and user-level npm package management
- **rust**: Rust/Cargo and user-level package management
- **go**: Go and user-level package management
- **neovim**: Neovim installation and configuration

### Package Systems
- **manage_snap_packages**: Snap package management
- **manage_flatpak**: Flatpak package management

### Utilities
- **discovery**: System state discovery
- **terminal_config**: Terminal configuration (kitty, alacritty, wezterm)
- **docker_compose_generic**: Docker Compose service management
- **install_docker**: Docker Engine installation

## Platform Support

- **Tier 1** (CI tested): Ubuntu 22.04+/24.04+, Debian 12+/13+, Arch Linux
- **Tier 2** (No CI): macOS 13+

## Installation Model

- System packages: Installed via native package managers (APT, Pacman, Homebrew)
- User packages: Installed to user home directories (npm, cargo, go)
- macOS Homebrew: Managed under ansible user account

**Container Usage**: Security hardening disables IP forwarding. Enable for Docker/Kubernetes:

```yaml
hardening:
  os_hardening_enabled: true
  sysctl_overwrite:
    net.ipv4.ip_forward: 1 # Required for Docker/Kubernetes
```

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

### Basic Server Configuration
```yaml
# group_vars/all.yml
domain_timezone: "America/New_York"
domain_locale: "en_US.UTF-8"

# host_vars/web01.yml
host_hostname: "web01"
manage_packages_host:
  Ubuntu: [nginx, git, curl]
  Debian: [nginx, git, curl]

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
```

### Development Workstation Configuration
```yaml
# group_vars/workstations.yml
users:
  - name: developer
    git:
      user_name: "Developer Name"
      user_email: "dev@company.com"
      editor: "nvim"
    nodejs:
      packages: [typescript, eslint, prettier]
    rust:
      packages: [ripgrep, bat, fd-find]
    neovim:
      enabled: true
    dotfiles:
      enable: true
      repository: "https://github.com/developer/dotfiles"
```

### Complete Playbook
```yaml
# site.yml - Complete infrastructure setup
- hosts: all
  become: true
  roles:
    - wolskies.infrastructure.configure_system
```

## Variable Reference

### Domain-Wide Configuration
```yaml
domain_timezone: "America/New_York"    # IANA timezone
domain_locale: "en_US.UTF-8"          # System locale
domain_language: "en_US.UTF-8"        # System language
domain_timesync:
  enabled: true                       # Enable NTP sync
  servers: ["pool.ntp.org"]           # NTP servers
```

### Host-Specific Configuration
```yaml
host_hostname: "web01"                # System hostname
host_update_hosts: true               # Update /etc/hosts

host_services:
  enable: [nginx, postgresql]         # Enable services
  disable: [apache2, sendmail]        # Disable services
  mask: [snapd, telenet]              # Mask services

host_modules:
  load: [br_netfilter, overlay]       # Load modules
  blacklist: [pcspkr, nouveau]       # Blacklist modules
```

### Package Management
```yaml
packages:
  present:
    all:
      Ubuntu: [git, curl, vim]
      Debian: [git, curl, vim]
    group:
      Ubuntu: [nginx, postgresql]
    host:
      Ubuntu: [redis-server]

apt:
  proxy: ""
  no_recommends: false
  unattended_upgrades:
    enabled: false

apt_repositories_host:
  Ubuntu:
    - name: nodejs
        types: [deb]
        uris: "https://deb.nodesource.com/node_20.x"
        suites: ["nodistro"]
        components: [main]
        signed_by: "https://deb.nodesource.com/gpgkey/nodesource.gpg.key"
  unattended_upgrades:
    enabled: true
  system_upgrade:
    enable: false
    type: "safe"                     # Options: safe, dist, full, yes

# Pacman Configuration (Arch Linux)
pacman:
  proxy: ""                          # Pacman proxy URL
  no_confirm: false                  # Skip confirmation prompts
  multilib:
    enabled: false                   # Enable 32-bit packages
  enable_aur: false                  # Enable AUR with paru

# macOS Configuration
macosx:
  updates:
    auto_check: true
    auto_download: true
  gatekeeper:
    enabled: true
  system_preferences:
    natural_scroll: true
    measurement_units: "Inches"
    use_metric: false
    show_all_extensions: false
  airdrop:
    ethernet_enabled: false

# Homebrew Configuration (macOS)
homebrew:
  cleanup_cache: true
  taps: [homebrew/cask-fonts]
manage_casks:
  Darwin:
    - name: visual-studio-code
      state: present
    - name: docker
      state: present
```

### User Configuration
```yaml
users:
  - name: developer
    password: "{{ vault_developer_password }}"
    groups: [sudo, docker]
    shell: /bin/bash
    ssh_keys:
      - key: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5..."
        comment: "developer@workstation"
        state: present
    git:
      user_name: "Developer Name"
      user_email: "developer@company.com"
      editor: "nvim"
    nodejs:
      packages: [typescript, eslint, "@vue/cli"]
    rust:
      packages: [ripgrep, bat, fd-find]
    go:
      packages: [github.com/charmbracelet/glow@latest]
    neovim:
      enabled: true
    dotfiles:
      enable: true
      repository: "https://github.com/developer/dotfiles"
      branch: main
      dest: ".dotfiles"
```

### Security Configuration
```yaml
firewall:
  enabled: true
  prevent_ssh_lockout: true
  rules:
    - rule: allow
      port: 22
      protocol: tcp
    - rule: allow
      port: 80,443
      protocol: tcp
      comment: "Web services"
    - rule: allow
      from_ip: 192.168.1.0/24
      port: 3000
      protocol: tcp

fail2ban:
  enabled: true
  bantime: "10m"
  findtime: "10m"
  maxretry: 5
  jails:
    - name: sshd
      enabled: true
      maxretry: 3
      bantime: "1h"
```

### Alternative Package Systems
```yaml
snap:
  remove_completely: false           # Don't remove snapd
snap_packages:
  - name: code
    state: present
  - name: unwanted-snap
    state: absent

flatpak:
  enabled: true
  flathub: true                      # Enable Flathub
  method: system                     # System-wide install
flatpak_packages:
  - name: org.gimp.GIMP
    state: present
  - name: com.spotify.Client
    state: present
```

### System Configuration
```yaml
journal:
  configure: true
  max_size: "500M"
  max_retention: "30d"
  compress: true
  forward_to_syslog: false

host_security:
  hardening_enabled: true           # Enable OS hardening
  ssh_hardening_enabled: true      # Enable SSH hardening
```

## Role Usage Patterns

### System Orchestration
Use `configure_system` for complete infrastructure setup:
```yaml
- hosts: all
  become: true
  roles:
    - wolskies.infrastructure.configure_system
```

### Selective Role Usage
Apply specific functionality as needed:
```yaml
- hosts: web_servers
  become: true
  roles:
    - wolskies.infrastructure.os_configuration
    - wolskies.infrastructure.manage_packages
    - wolskies.infrastructure.manage_security_services

- hosts: development_machines
  become: true
  roles:
    - wolskies.infrastructure.nodejs
    - wolskies.infrastructure.rust
    - wolskies.infrastructure.neovim
```

### User Configuration
Configure user accounts with their preferences:
```yaml
- hosts: all
  become: true
  roles:
    - wolskies.infrastructure.configure_users
```

The role automatically iterates over the `users` list from your inventory.

## Dependencies and Credits

This collection builds upon excellent work from the community:

- **geerlingguy.mac**: Homebrew installation and macOS configuration
- **devsec.hardening**: OS and SSH security hardening (os_hardening, ssh_hardening roles)
- **kewlfft.aur**: AUR package management for Arch Linux
- **community.general**: Core modules for package management and system configuration

## Documentation

**📖 Complete documentation is available on GitLab Pages:**
- **Collection Overview**: Full variable reference and usage patterns
- **Individual Role Documentation**: Detailed specifications for each role
- **Requirements and Examples**: Platform-specific configuration examples
- **Auto-Generated**: Documentation is generated from the Software Requirements Document (SRD)

**Local Documentation Generation:**
```bash
# Generate complete documentation
python3 scripts/generate_enhanced_docs.py
python3 scripts/generate_collection_docs.py
```

## Requirements

- **Ansible Core**: 2.15+ (tested with 2.17)
- **Python**: 3.9+ on control and managed nodes
- **Collections**:
  - `community.general` - Package management and system modules
  - `ansible.posix` - POSIX system management
- **Platform-Specific**:
  - **macOS**: Xcode Command Line Tools
  - **Arch Linux**: `base-devel` group for AUR support
  - **Debian/Ubuntu**: `python3-debian` for repository management

## Development

This collection uses modern Python tooling for development:

- **uv**: Fast Python package manager
- **just**: Command runner (modern Make alternative)
- **molecule**: Role testing with Docker
- **ansible-lint**: Linting
- **pytest**: Unit testing

### Prerequisites

Before setting up the development environment, ensure you have:

1. **Python 3.13+** installed
2. **Docker** installed and running (required for molecule tests)
3. **just** - Command runner (see: https://github.com/casey/just#installation)
4. **uv** - Python package manager

### Setup Development Environment

```bash
# 1. Install uv (if not already installed)
curl -LsSf https://astral.sh/uv/install.sh | sh

# 2. Install just (if not already installed)
# Linux/macOS:
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to ~/.local/bin
# Or use your package manager (Arch: pacman -S just, macOS: brew install just)

# 3. Clone and initialize the project
git clone https://github.com/wolskinet/ansible-infrastructure
cd ansible-infrastructure
just init
# This will:
# - Install all Python dependencies via uv
# - Set up pre-commit hooks

# 4. View available commands
just --list
```

### Common Development Tasks

```bash
# Run linters
just lint-all

# Run tests
just test

# Run molecule tests for a role
just molecule-test <role-name>

# Build collection
just build

# Generate documentation
just docs-build
```

## Testing and Validation

The collection includes comprehensive testing:
- **Molecule tests** for individual roles
- **CI/CD integration** with GitLab
- **Cross-platform validation** on Ubuntu, Debian, Arch Linux
- **VM-based end-to-end testing** with multi-VM test matrix

For local testing:
```bash
# Test individual role
just molecule-test <role-name>

# Run collection-wide tests
just test
```
