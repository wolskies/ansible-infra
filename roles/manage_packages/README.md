# manage_packages

Cross-platform package management for Ubuntu, Debian, Arch Linux, and macOS.

## Description

Manages system packages across multiple operating systems using a unified variable structure. Automatically detects the platform and uses the appropriate package manager (apt, pacman, homebrew). Supports hierarchical package organization (all/group/host levels) with automatic deduplication and repository management.

## Role Variables

```yaml
packages:
  present: {}                    # Packages to install (hierarchical structure)
  remove: {}                     # Packages to remove (hierarchical structure)
  casks_present:                 # macOS GUI applications (homebrew casks)
    all: []
    group: []
    host: []
  casks_remove: []               # macOS casks to remove

apt:                             # APT configuration (Ubuntu/Debian)
  no_recommends: false
  proxy: ""
  unattended_upgrades:
    enabled: true
    email: ""
    auto_reboot: false
    reboot_with_users: false
    reboot_time: "02:00"
  repositories: {}               # Additional APT repositories

pacman:                          # Pacman configuration (Arch Linux)
  no_confirms: false
  proxy: ""
  multilib: false
  enable_aur: false              # Enable AUR package support

homebrew:                        # Homebrew configuration (macOS)
  install: true
  update_homebrew: true
  cleanup_cache: false
  taps: []                       # Additional homebrew taps
```

## Package Structure

Packages are organized hierarchically to allow different scopes:

```yaml
packages:
  present:
    all:                         # Packages for all hosts
      Ubuntu: [git, curl, vim]
      Debian: [git, curl, vim]
      Archlinux: [git, curl, vim]
      MacOSX: [git, curl, vim]
    group:                       # Group-specific packages
      Ubuntu: [nginx, certbot]
    host:                        # Host-specific packages
      Ubuntu: [redis-server]
```

## Usage Examples

### Standalone Usage

```yaml
- hosts: all
  become: true
  roles:
    - role: wolskies.infrastructure.manage_packages
      vars:
        packages:
          present:
            all:
              Ubuntu: [git, curl, vim, htop]
              Debian: [git, curl, vim, htop]
              Archlinux: [git, curl, vim, htop]
              MacOSX: [git, curl, vim, htop]
```

### With Variable Files

```yaml
# group_vars/all.yml
packages:
  present:
    all:
      Ubuntu: [git, curl, htop]
      Debian: [git, curl, htop]
      Archlinux: [git, curl, htop]
      MacOSX: [git, curl, htop]

# group_vars/webservers.yml
packages:
  present:
    group:
      Ubuntu: [nginx, certbot]
      Debian: [nginx, certbot]

# host_vars/web01.yml
packages:
  present:
    host:
      Ubuntu: [redis-server]

# playbook.yml
- hosts: all
  become: true
  roles:
    - wolskies.infrastructure.manage_packages
```

### Repository Management

```yaml
packages:
  present:
    all:
      Ubuntu: [docker-ce, docker-ce-cli]

apt:
  repositories:
    docker:
      name: docker
      types: [deb]
      uris: "https://download.docker.com/linux/ubuntu"
      suites: ["{{ ansible_distribution_release }}"]
      components: [stable]
      signed_by: "https://download.docker.com/linux/ubuntu/gpg"
```

### Arch Linux with AUR

```yaml
packages:
  present:
    all:
      Archlinux:
        - base-devel
        - yay
        - visual-studio-code-bin    # AUR package

pacman:
  enable_aur: true                # Enable AUR support via kewlfft.aur
```

### macOS with Homebrew Casks

```yaml
packages:
  present:
    all:
      MacOSX: [git, wget, htop]    # Command-line tools
  casks_present:
    all:
      - visual-studio-code         # GUI applications
      - docker
      - firefox

homebrew:
  taps:
    - homebrew/cask-fonts         # Additional repositories
```

## Package Hierarchical Merging

The role automatically combines packages from all levels:

1. **all**: Packages applied to every host of that OS
2. **group**: Packages applied to hosts in specific groups
3. **host**: Packages applied to individual hosts

Example result for `web01` host in `webservers` group:
- All packages: `[git, curl, htop]`
- Group packages: `[nginx, certbot]`
- Host packages: `[redis-server]`
- **Final result**: `[git, curl, htop, nginx, certbot, redis-server]`

## Platform-Specific Behavior

### Ubuntu/Debian (APT)
- Uses `ansible.builtin.apt` for package management
- Supports deb822 repository format
- Handles unattended-upgrades configuration
- Repository GPG key management

### Arch Linux (Pacman/AUR)
- Uses `community.general.pacman` by default
- With `pacman.enable_aur: true`, uses `kewlfft.aur` for AUR support
- AUR helper auto-detection (yay, paru, etc.)
- Seamless official + AUR package management

### macOS (Homebrew)
- Uses `community.general.homebrew` for packages
- Uses `community.general.homebrew_cask` for GUI applications
- Custom tap management
- Automatic Homebrew installation if missing

## Installation Behavior

1. **Platform Detection**: Identifies OS and selects appropriate package manager
2. **Repository Setup**: Configures additional repositories (if specified)
3. **Package Removal**: Removes packages in `remove` lists
4. **Package Installation**: Installs packages in `present` lists
5. **Cache Management**: Updates package caches and cleans up (configurable)

## OS Support

- **Ubuntu 22+**: Full APT support with deb822 repositories
- **Debian 12+**: Full APT support with deb822 repositories
- **Arch Linux**: Full pacman + optional AUR support
- **macOS 10.15+**: Full Homebrew + cask support

## Requirements

- System package manager access (sudo privileges)
- Internet access for downloading packages and repository metadata
- For AUR (Arch): `kewlfft.aur` collection
- For macOS: `community.general` collection

## Integration Notes

### With configure_system Role
This role integrates with system configuration:

```yaml
- hosts: all
  become: true
  roles:
    - wolskies.infrastructure.os_configuration     # System settings
    - wolskies.infrastructure.manage_packages      # Package management
    - wolskies.infrastructure.manage_users         # User accounts
```

### Package Manager Configuration
Configure package manager behavior:

```yaml
apt:
  unattended_upgrades:
    enabled: true
    auto_reboot: false
    email: "admin@company.com"

pacman:
  enable_aur: true              # Enable AUR package support

homebrew:
  cleanup_cache: true           # Clean up download cache
```

## Dependencies

- `ansible.builtin.apt`: Ubuntu/Debian package management
- `community.general.pacman`: Arch Linux package management
- `community.general.homebrew`: macOS package management
- `kewlfft.aur`: AUR support for Arch Linux (optional)

## License

MIT

## Author Information

This role is part of the wolskies.infrastructure collection.
