# Ansible Collection - wolskies.infrastructure

Automated scripts for system configuration, package management, and user environment configuration.

**Supported Platforms:**
- Ubuntu 22.04+, 24.04+
- Debian 12+, 13+
- Arch Linux (Rolling)

**Limited Support:** (due to lack of readily available test resources)
- macOS 13+ (Ventura)

## Roles

- **configure_system**: Meta-role for convenience (calls multiple roles in order)
- **os_configuration**: System settings (timezone, hostname, locale, services, kernel parameters)
- **manage_packages**: Package management (APT, Pacman, Homebrew) with repository configuration
- **manage_security_services**: Firewall (UFW/macOS ALF) and fail2ban configuration
- **configure_users**: User preferences (dotfiles, development tools, language environments)
- **nodejs**: Node.js and user-level npm package management
- **rust**: Rust/Cargo and user-level package management
- **go**: Go and user-level package management
- **neovim**: Neovim installation and configuration
- **manage_snap_packages**: Snap package management
- **manage_flatpak**: Flatpak package management
- **terminal_config**: Terminal configuration (kitty, alacritty, wezterm)

### Utility Role
- **discovery**: provides a convenient method to generate compatible host_vars that capture the state of an existing system.


## Installation

Install the collection and its dependencies:

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
