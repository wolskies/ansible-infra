# manage_packages

Cross-platform package management for Ubuntu, Debian, Arch Linux, and macOS.

## What It Does

Manages system packages using the appropriate package manager:
- **Ubuntu/Debian** - APT with repository management and unattended upgrades
- **Arch Linux** - Pacman with AUR support (optional)
- **macOS** - Homebrew with cask support for GUI applications

## Usage

### Basic Package Installation
```yaml
- hosts: all
  become: true
  roles:
    - wolskies.infrastructure.manage_packages
  vars:
    manage_packages_all:
      Ubuntu: [git, curl, vim]
      Debian: [git, curl, vim]
      Archlinux: [git, curl, vim]
      Darwin: [git, curl, vim]
```

### Layered Package Management
```yaml
# group_vars/all.yml - Base packages for all hosts
manage_packages_all:
  Ubuntu: [git, curl, vim, htop]
  Darwin: [git, curl, vim, htop]

# group_vars/webservers.yml - Group-specific packages
manage_packages_group:
  Ubuntu: [nginx, postgresql]

# host_vars/web01.yml - Host-specific packages
manage_packages_host:
  Ubuntu: [redis-server]
```

### APT Repository Management
```yaml
apt_repositories_all:
  Ubuntu:
    - name: nodejs
      uris: "https://deb.nodesource.com/node_20.x"
      suites: "nodistro"
      components: "main"
      signed_by: "https://deb.nodesource.com/gpgkey/nodesource.gpg.key"

apt:
  unattended_upgrades:
    enabled: true
  proxy: "http://proxy.example.com:8080"
```

### macOS Homebrew Configuration
```yaml
homebrew:
  taps: [homebrew/cask-fonts]
  cleanup_cache: true

manage_casks:
  Darwin:
    - name: visual-studio-code
    - name: docker
    - name: firefox
      state: present
```

### Arch Linux AUR Support
```yaml
pacman:
  enable_aur: true
  multilib:
    enabled: true
```

## Variables

Uses collection-wide variables - see collection README for complete reference.

### Package Structure
Packages are organized by scope and OS family:
```yaml
# Base-level packages (merged first)
manage_packages_all:
  Ubuntu: [package1, package2]
  Debian: [package1, package2]
  Archlinux: [package1, package2]
  Darwin: [package1, package2]

# Group-level packages (merged second)
manage_packages_group:
  Ubuntu: [group-specific-package]

# Host-level packages (merged last)
manage_packages_host:
  Ubuntu: [host-specific-package]
```

### Layered Package Variables
- `manage_packages_all` - Base-level packages (merged first)
- `manage_packages_group` - Group-level packages (merged second)
- `manage_packages_host` - Host-level packages (merged last)

### APT Configuration
- `apt_repositories_all` - Base-level APT repositories
- `apt_repositories_group` - Group-level APT repositories
- `apt_repositories_host` - Host-level APT repositories
- `apt.unattended_upgrades.enabled` - Enable automatic security updates
- `apt.proxy` - APT proxy URL

### Homebrew Configuration (macOS)
- `homebrew.taps` - Additional tap repositories
- `homebrew.cleanup_cache` - Clean download cache after operations
- `manage_casks.Darwin` - macOS GUI applications

### Pacman Configuration (Arch Linux)
- `pacman.enable_aur` - Enable AUR package support
- `pacman.multilib.enabled` - Enable 32-bit packages
- `pacman.proxy` - Pacman proxy URL

## Package Hierarchy

Packages are merged from multiple scopes in order:
1. **all** - Applied to all hosts
2. **group** - Applied to inventory groups
3. **host** - Applied to specific hosts

This allows flexible package management from global to host-specific needs.

## Platform-Specific Features

### Ubuntu/Debian (APT)
- Uses modern deb822 format for repository definitions
- Automatically installs GPG keys and configures sources
- Supports unattended upgrades for security updates
- System upgrade capability with configurable upgrade type

### Arch Linux (Pacman/AUR)
- Official repository packages via pacman
- Optional AUR support using paru helper
- Multilib repository for 32-bit packages
- Automatic dependency resolution

### macOS (Homebrew)
- Formula packages and casks for GUI applications
- Tap repository management
- Automatic cache cleanup
- Applications installed to /Applications

## Tags

Control which package managers run:
- `apt` - APT package management (Ubuntu/Debian)
- `pacman` - Pacman package management (Arch Linux)
- `aur` - AUR package management (Arch Linux)
- `homebrew` - Homebrew package management (macOS)
- `repositories` - Repository management only
- `packages` - Package installation only
- `no-container` - Tasks requiring host capabilities

Example:
```bash
# Skip AUR packages in containers
ansible-playbook --skip-tags aur,no-container playbook.yml

# Only manage repositories
ansible-playbook -t repositories playbook.yml
```

## Platform Support

- **Ubuntu** 22.04+, 24.04+
- **Debian** 12+, 13+
- **Arch Linux** (Rolling)
- **macOS** 13+ (Ventura)

## Dependencies

- `geerlingguy.mac.homebrew` (macOS Homebrew installation)
- `kewlfft.aur.aur` (Arch Linux AUR support)
