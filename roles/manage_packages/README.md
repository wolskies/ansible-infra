# manage_packages

Advanced hierarchical package management with multi-platform support and discovery integration.

## Description

This role provides sophisticated package management across Ubuntu, Debian, Arch Linux, and macOS. It implements hierarchical package variable merging that combines packages from global (all), group, and host levels with intelligent duplicate removal. The role supports multiple package managers including APT, Pacman, AUR (via paru), and Homebrew.

## Features

- **📦 Multi-Platform Support**: APT, Pacman, AUR, and Homebrew package managers
- **🔄 Hierarchical Merging**: Combines all/group/host package lists automatically
- **🎯 Smart Deduplication**: Removes duplicate packages across all levels
- **🔍 Discovery Integration**: Works with discovered package configurations
- **⚙️ Repository Management**: APT repositories, Homebrew taps, AUR packages
- **📱 Application Support**: Homebrew casks for macOS applications
- **🔒 Cache Management**: Intelligent package cache handling
- **⬆️ System Updates**: Optional system upgrade capabilities

## Role Variables

See `defaults/main.yml` for complete variable documentation. Key variables include:

### Package Management Settings
```yaml
packages_update_cache: true            # Update package cache before operations
packages_cache_valid_time: 3600        # APT cache validity in seconds
packages_perform_system_upgrade: false # Perform full system upgrade
packages_upgrade_type: safe            # safe, full, or dist (APT only)
```

### Arch Linux Configuration
```yaml
packages_pacman_multilib: true         # Enable multilib repository
packages_enable_aur: true              # Enable AUR support (security consideration)
packages_aur_helper: paru              # AUR helper to use (paru, yay, etc.)
config_archlinux_reflector: true       # Configure reflector for mirror optimization
```

### macOS (Homebrew) Settings
```yaml
homebrew_installed: true               # Install Homebrew if not present (macOS only)
packages_homebrew_taps: []             # List of Homebrew taps to add
packages_homebrew_casks: []            # List of Homebrew casks to install
packages_homebrew_casks_remove: []     # List of Homebrew casks to remove
packages_macos_update_homebrew: true   # Update Homebrew before installing
packages_macos_cleanup_cache: false    # Clean Homebrew cache after operations
```

### Snap Package Management (Ubuntu)
```yaml
packages_snap_packages: []             # List of snap packages to install
packages_snap_packages_remove: []      # List of snap packages to remove
packages_snap_classic: []              # List of snap packages to install with --classic
```

### Flatpak Package Management (Linux)
```yaml
packages_flatpak_packages: []          # List of Flatpak packages to install
packages_flatpak_packages_remove: []   # List of Flatpak packages to remove
packages_flatpak_remotes: []           # List of Flatpak remotes to add
```

## Hierarchical Package Variables

The role's key feature is hierarchical package management using inventory-level variables:

### Variable Structure
```yaml
# Format: {level}_packages_{action}_{Distribution}
# Levels: all, group, host
# Actions: install, remove
# Distributions: Ubuntu, Debian, Archlinux, MacOSX
```

### Inventory Configuration
```yaml
# group_vars/all/packages.yml - Global packages for ALL systems
all_packages_install_Ubuntu:
  - curl
  - wget
  - git
  - htop

all_packages_remove_Ubuntu:
  - snapd  # Remove from all Ubuntu systems

# group_vars/servers/packages.yml - Server-specific packages
group_packages_install_Ubuntu:
  - nginx
  - certbot
  - fail2ban

# host_vars/web-01.yml - Host-specific packages (often from discovery)
host_packages_install_Ubuntu:
  - redis-server
  - postgresql-client
```

### Supported Distributions
- **Ubuntu**: `packages_install_Ubuntu`, `packages_remove_Ubuntu`
- **Debian**: `packages_install_Debian`, `packages_remove_Debian`  
- **Arch Linux**: `packages_install_Archlinux`, `packages_remove_Archlinux`
- **macOS**: `packages_install_MacOSX`, `packages_remove_MacOSX`

## Dependencies

None. This role is designed to be fully standalone.

## Example Playbook

### Basic Package Management
```yaml
- hosts: all
  roles:
    - role: wolskinet.infrastructure.manage_packages
      vars:
        packages_update_cache: true
        packages_perform_system_upgrade: false
```

### Repository Management
```yaml
- hosts: ubuntu_servers
  roles:
    - role: wolskinet.infrastructure.manage_packages
      vars:
        packages_apt_repositories:
          - "ppa:nginx/stable"
        packages_apt_keys:
          - "https://nginx.org/keys/nginx_signing.key"
```

### macOS with Homebrew
```yaml
- hosts: macos_workstations
  roles:
    - role: wolskinet.infrastructure.manage_packages
      vars:
        packages_homebrew_taps:
          - homebrew/cask-fonts
        packages_homebrew_casks:
          - visual-studio-code
          - docker
          - font-jetbrains-mono
```

### Arch Linux with AUR
```yaml
- hosts: arch_systems
  roles:
    - role: wolskinet.infrastructure.manage_packages
      vars:
        packages_aur_packages:
          - paru
          - yay
          - visual-studio-code-bin
```

### System Upgrade
```yaml
- hosts: all
  roles:
    - role: wolskinet.infrastructure.manage_packages
      vars:
        packages_perform_system_upgrade: true
        packages_upgrade_type: "safe"  # safe, full, or dist
```

## Hierarchical Package Example

### Complete Inventory Structure
```yaml
# group_vars/all/packages.yml
all_packages_install_Ubuntu: [git, curl, htop, vim]
all_packages_install_Debian: [git, curl, htop, vim]

# group_vars/servers/packages.yml  
group_packages_install_Ubuntu: [nginx, fail2ban, certbot]
group_packages_install_Debian: [nginx, fail2ban, certbot]

# group_vars/docker_hosts/packages.yml
group_packages_install_Ubuntu: [docker.io, docker-compose]
group_packages_install_Debian: [docker.io, docker-compose]

# host_vars/web-01.yml (from discovery)
host_packages_install_Ubuntu: [redis-server, postgresql-client]
```

### Resulting Package Lists
- **web-01** (servers + docker_hosts): `[git, curl, htop, vim, nginx, fail2ban, certbot, docker.io, docker-compose, redis-server, postgresql-client]`
- **app-01** (servers only): `[git, curl, htop, vim, nginx, fail2ban, certbot]`
- **dev-01** (workstations): `[git, curl, htop, vim]`

## Platform Support

### Ubuntu 22+ / Debian 12+
- **Package Manager**: APT with automatic cache management
- **Repositories**: PPA and third-party repository support
- **GPG Keys**: Automatic key import for repositories
- **Upgrades**: Safe, full, and distribution upgrade options

### Arch Linux  
- **Package Manager**: Pacman for official packages
- **AUR Support**: paru for Arch User Repository packages
- **System Updates**: Full system upgrade via pacman -Syu

### macOS
- **Package Manager**: Homebrew for CLI tools and libraries
- **Applications**: Homebrew Casks for GUI applications
- **Taps**: Custom Homebrew repository support
- **Updates**: Homebrew update and upgrade management

## Discovery Integration

The role seamlessly integrates with the discovery role:

```yaml
# Discovery generates host-specific package lists
- hosts: discovered_systems
  roles:
    - wolskinet.infrastructure.discovery  # Populates host_packages_install_*
    - wolskinet.infrastructure.manage_packages  # Installs discovered + group + all packages
```

### Discovery Variables Generated
```yaml
# Example host_vars/server.yml from discovery
host_packages_install_Ubuntu:
  - nginx
  - redis-server  
  - postgresql-client
  - node-js
  - git
```

## Advanced Configuration

### Conditional Package Installation
```yaml
# Install packages based on system characteristics
- hosts: workstations
  roles:
    - role: wolskinet.infrastructure.manage_packages
  vars:
    group_packages_install_Ubuntu: >-
      {{ ['firefox', 'libreoffice'] + 
         (['nvidia-driver-470'] if ansible_kernel is search('nvidia') else []) }}
```

### Multi-Distribution Support
```yaml
# Single playbook for multiple OS families
- hosts: mixed_environment
  roles:
    - role: wolskinet.infrastructure.manage_packages
  vars:
    # Ubuntu/Debian
    all_packages_install_Ubuntu: [git, curl, htop]
    all_packages_install_Debian: [git, curl, htop]
    # Arch Linux
    all_packages_install_Archlinux: [git, curl, htop]
    # macOS
    all_packages_install_MacOSX: [git, curl, htop]
```

## Integration with Other Roles

### Full Infrastructure Stack
```yaml
- hosts: servers
  roles:
    - wolskinet.infrastructure.configure_host  # System configuration
    - wolskinet.infrastructure.manage_packages # Package management
    - wolskinet.infrastructure.manage_users    # User creation
    - wolskinet.infrastructure.manage_firewall # Security setup
```

### Development Environment Setup
```yaml
- hosts: workstations
  roles:
    - wolskinet.infrastructure.manage_packages # Install base packages
    - wolskinet.infrastructure.manage_language_packages # Language tools
    - wolskinet.infrastructure.manage_users    # Create dev users with dotfiles
```

## Performance Considerations

- **Cache Management**: Updates package cache only when needed
- **Deduplication**: Removes duplicate packages before installation
- **Batch Operations**: Installs all packages in single operations per manager
- **Conditional Updates**: Only updates when packages change

## License

MIT

## Author Information

Ed Wolski - wolskinet