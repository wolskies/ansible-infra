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
    packages:
      present:
        all:
          Ubuntu: [git, curl, vim]
          Debian: [git, curl, vim]
          Archlinux: [git, curl, vim]
          Darwin: [git, curl, vim]
```

### Advanced Configuration
```yaml
packages:
  present:
    all:                              # All hosts
      Ubuntu: [git, curl, vim, htop]
      Darwin: [git, curl, vim, htop]
    group:                            # Group-specific
      Ubuntu: [nginx, postgresql]
    host:                             # Host-specific
      Ubuntu: [redis-server]
  remove:
    all:
      Ubuntu: [snapd]                 # Remove unwanted packages

# APT Configuration (Ubuntu/Debian)
apt:
  unattended_upgrades:
    enabled: true
  repositories:
    Ubuntu:
      - name: nodejs
        types: [deb]
        uris: "https://deb.nodesource.com/node_20.x"
        suites: ["nodistro"]
        components: [main]
        signed_by: "https://deb.nodesource.com/gpgkey/nodesource.gpg.key"

# Homebrew Configuration (macOS)
homebrew:
  taps: [homebrew/cask-fonts]
manage_casks:
  Darwin:
    - name: visual-studio-code
    - name: docker

# Pacman Configuration (Arch Linux)
pacman:
  enable_aur: true                    # Enable AUR packages
  multilib:
    enabled: true                     # Enable 32-bit packages
```

## Variables

Package management uses hierarchical structure for flexibility:

### Core Variables
- `packages.present` - Packages to install (by OS and scope)
- `packages.remove` - Packages to remove (by OS and scope)
- `manage_casks.Darwin` - macOS GUI applications
- `apt.repositories` - Custom APT repositories
- `homebrew.taps` - Homebrew tap repositories

### Platform-Specific Settings
- `apt.unattended_upgrades` - Automatic security updates (Ubuntu/Debian)
- `pacman.enable_aur` - AUR package support (Arch Linux)
- `homebrew.cleanup_cache` - Clean download cache (macOS)

## Package Hierarchy

Packages are merged from multiple scopes:
1. **all** - Applied to all hosts
2. **group** - Applied to inventory groups
3. **host** - Applied to specific hosts

This allows flexible package management from global to host-specific needs.

## Repository Management

### APT Repositories (Ubuntu/Debian)
Uses modern deb822 format for repository definitions. Automatically installs GPG keys and configures sources.

### Homebrew Taps (macOS)
Manages additional Homebrew repositories for extended package availability.

### AUR Support (Arch Linux)
Optional support for Arch User Repository packages using `paru` helper.

## Platform Support

- **Ubuntu** 22.04+, 24.04+
- **Debian** 12+, 13+
- **Arch Linux** (Rolling)
- **macOS** 13+ (Ventura)

## Dependencies

- `geerlingguy.mac.homebrew` (macOS Homebrew installation)
- `kewlfft.aur.aur` (Arch Linux AUR support)
