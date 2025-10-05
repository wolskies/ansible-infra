# Ansible Collection - wolskies.infrastructure

Infrastructure management automation for cross-platform development and production environments. Focuses on configuration management, security hardening, and development environment setup.

**Supported Operating Systems:**
- Ubuntu 22.04+, 24.04+
- Debian 12+, 13+
- Arch Linux (Rolling)
- macOS 13+ (Ventura)

## Included Roles

### Core System Management
- **configure_system**: Meta-role orchestrating complete system configuration including OS settings, packages, security, and initial user setup
- **os_configuration**: System settings (timezone, hostname, locale, services, kernel parameters) with comprehensive security hardening
- **manage_packages**: Cross-platform package management (APT, Pacman, Homebrew) with repository configuration
- **manage_security_services**: Firewall (UFW/macOS ALF) and fail2ban configuration for intrusion prevention

### User and Development Environment
- **configure_user**: User-specific configuration including dotfiles, development tools, and language environments
- **nodejs**: Node.js installation and user-level package management with npm
- **rust**: Rust/Cargo installation and user-level package management
- **go**: Go installation and user-level package management
- **neovim**: Neovim installation and basic configuration

### Package Systems
- **manage_snap_packages**: Snap package management with option to completely remove snapd system
- **manage_flatpak**: Flatpak runtime and package management with Flathub integration

### Utilities
- **discovery**: System state discovery and documentation for validation and auditing

### Coming in 1.0.3
The following roles are under development for the next release:
- **terminal_config**: Terminal and shell configuration (bash, zsh, tmux)
- **docker_compose_generic**: Generic Docker Compose service management
- **install_docker**: Docker Engine installation and configuration

## Platform Support

This collection categorizes platform support into the following tiers:

- **Tier 1 (Fully Tested)**: These platforms are automatically tested in CI on every change. They are considered fully supported and stable.
- **Tier 2 (Best Effort)**: Functionality has been developed and is expected to work, but lacks automated CI testing. We welcome contributions to expand CI coverage for these platforms.

### Supported Platforms by Tier

- **Tier 1**:
  - Ubuntu 22.04+, 24.04+
  - Debian 12+, 13+
  - Arch Linux (Rolling)
- **Tier 2**:
  - macOS 13+ (Ventura) - *Lacks automated CI testing*

**Note on Development Tools**:
Language runtimes (Node.js, Rust, Go) are installed via system package managers when available. For older Debian/Ubuntu versions that lack system packages, manual installation is required before running collection roles.

## Privilege and Execution Model

The collection supports multi-user configuration with appropriate privilege separation:

- **System packages**: Installed with elevated privileges via native package managers
- **User-level packages**: Installed to user home directories without elevation
- **Development tools**: Language runtimes installed system-wide, packages installed per-user
- **macOS Homebrew**: Installed and managed under the Ansible user account

**Important for Container Users**: Security hardening disables IP forwarding by default. Enable for Docker/Kubernetes:

```yaml
host_sysctl:
  parameters:
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
    groups: [sudo]
    ssh_keys:
      - "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5..."

target_user:
  name: developer
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
# site.yml
- hosts: all
  become: true
  roles:
    - wolskies.infrastructure.configure_system

- hosts: all
  become: true
  become_user: "{{ target_user.name }}"
  roles:
    - wolskies.infrastructure.configure_user
  when: target_user is defined
```

## Variable Reference

### Domain-Wide Configuration
```yaml
domain_timezone: "America/New_York"    # IANA timezone
domain_locale: "en_US.UTF-8"          # System locale
domain_language: "en_US.UTF-8"        # System language
domain_ntp:
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
  mask: [snapd, telnet]              # Mask services

host_sysctl:
  parameters:
    vm.swappiness: 10                 # Kernel parameters
    net.ipv4.ip_forward: 1

host_modules:
  load: [br_netfilter, overlay]       # Load modules
  blacklist: [pcspkr, nouveau]       # Blacklist modules
```

### Package Management
```yaml
# Base packages for all hosts
manage_packages_all:
  Ubuntu: [git, curl, vim]
  Debian: [git, curl, vim]
  Archlinux: [git, curl, vim]

# Group-specific packages
manage_packages_group:
  Ubuntu: [nginx, postgresql]

# Host-specific packages
manage_packages_host:
  Ubuntu: [redis-server]

# APT Configuration (Debian/Ubuntu)
apt:
  proxy: ""                          # APT proxy URL
  no_recommends: false               # Disable recommended packages
  repositories:
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
  install: true
  update_homebrew: true
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
    uid: 1000
    groups: [sudo, docker]
    shell: /bin/bash
    ssh_keys:
      - key: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5..."
        comment: "developer@workstation"
        state: present

target_user:
  name: developer
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

### User-Specific Configuration
Configure individual users with their preferences:
```yaml
- hosts: all
  become: true
  tasks:
    - name: Configure each user
      include_role:
        name: wolskies.infrastructure.configure_user
      vars:
        target_user: "{{ item }}"
      loop: "{{ users }}"
      when: item.name != 'root'
      become_user: "{{ item.name }}"
```

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

## Testing and Validation

The collection includes comprehensive testing:
- **Molecule tests** for individual roles
- **CI/CD integration** with GitLab
- **Cross-platform validation** on Ubuntu, Debian, Arch, macOS
- **VM-based end-to-end testing** with 4-VM test matrix

For local testing:
```bash
# Test individual role
cd roles/role_name && molecule test

# Run collection-wide tests
make test
```
