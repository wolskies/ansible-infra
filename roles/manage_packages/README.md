# manage_packages

Hierarchical package management wrapper for platform-specific package managers with intelligent merging.

## Description

This role provides a unified interface for package management across Ubuntu 22+, Debian 12+, Arch Linux, and macOS. It acts as a wrapper around platform-specific package managers (`ansible.builtin.apt`, `community.general.pacman`, `geerlingguy.mac.homebrew`) while adding hierarchical variable merging that combines packages from all/group/host levels. The role emphasizes simplicity through direct pass-through to native modules where possible.

## Features

- **Hierarchical merging** - Combines all/group/host package lists with automatic deduplication
- **Platform wrappers** - Direct pass-through to native Ansible modules for each OS
- **Repository management** - APT repositories (Debian/Ubuntu), Homebrew taps (macOS)
- **Hybrid Arch approach** - `community.general.pacman` for official, `paru` command for AUR
- **Intelligent defaults** - Sensible settings with full override capability

## Role Variables

### Core Configuration

```yaml
packages:
  Ubuntu:     # or Debian, Archlinux, Darwin
    all: []   # Global packages for all machines
    group: [] # Group-specific packages  
    host: []  # Host-specific packages
    remove: [] # Packages to remove
    
    settings:  # Platform-specific settings
      # See platform sections below
    
    repositories:  # Debian/Ubuntu only
      all: []
      group: []
      host: []
```

### What This Role Adds

Beyond standard package manager modules:

1. **Hierarchical Merging**: Automatically combines all/group/host levels with deduplication
2. **Cross-Platform Abstraction**: Single variable structure works across all OS families
3. **Repository Lifecycle**: Manages repository addition/removal with proper cleanup
4. **AUR Integration**: Seamless official+AUR package management for Arch Linux

## Platform-Specific Implementation

### Linux (Debian/Ubuntu via ansible.builtin.apt)

Wrapper around `ansible.builtin.apt` and `ansible.builtin.deb822_repository`:

```yaml
packages:
  Ubuntu:  # or Debian
    settings:
      apt_cache:
        update_cache: true    # Pass-through to apt module
        valid_time: 3600      # Cache validity in seconds
      system_upgrade:
        enable: false
        type: safe            # safe, full, or dist
    repositories:
      all:
        - name: "docker"
          types: "deb"
          uris: "https://download.docker.com/linux/ubuntu"
          suites: "{{ ansible_distribution_release }}"
          components: "stable"
          signed_by: "https://download.docker.com/linux/ubuntu/gpg"
```

### Arch Linux (Hybrid pacman/paru approach)

**When `enable_aur: false`** - Uses `community.general.pacman` directly:
```yaml
packages:
  Archlinux:
    settings:
      enable_aur: false      # Use pacman module only
      system_upgrade: false  # Pass-through to pacman upgrade
```

**When `enable_aur: true`** - Uses `paru` command for everything:
```yaml
packages:
  Archlinux:
    all:
      - firefox        # Official package
      - visual-studio-code-bin  # AUR package - handled transparently
    settings:
      enable_aur: true       # Use paru for all packages
      aur_helper: paru       # Currently only paru supported
```

**Note**: With AUR enabled, loses Ansible idempotency but gains unified package management.

### macOS (via geerlingguy.mac.homebrew)

Direct pass-through to `geerlingguy.mac.homebrew` role:

```yaml
packages:
  Darwin:
    all: [git, wget, htop]  # Homebrew formulae
    casks:
      all: [visual-studio-code, docker]  # GUI applications
    settings:
      install: true          # Install Homebrew if missing
      update_homebrew: true  # Update before installing
      cleanup_cache: false   # Clean cache after
      taps: [homebrew/cask-fonts]  # Additional taps
```

## Usage Examples

### Basic Cross-Platform
```yaml
- hosts: all
  roles:
    - role: wolskinet.infrastructure.manage_packages
      vars:
        packages:
          Ubuntu:
            all: [git, curl, vim, htop]
          Debian:
            all: [git, curl, vim, htop]
          Archlinux:
            all: [git, curl, vim, htop]
          Darwin:
            all: [git, curl, vim, htop]
```

### Hierarchical Package Management
```yaml
# group_vars/all/packages.yml
packages:
  Ubuntu:
    all: [git, curl, htop]  # All Ubuntu machines

# group_vars/webservers/packages.yml  
packages:
  Ubuntu:
    group: [nginx, certbot]  # Web servers only

# host_vars/web01/packages.yml
packages:
  Ubuntu:
    host: [redis-server]  # This host only
    
# Result for web01: [git, curl, htop, nginx, certbot, redis-server]
```

### Repository Management (Debian/Ubuntu)
```yaml
- hosts: ubuntu_servers
  roles:
    - role: wolskinet.infrastructure.manage_packages
      vars:
        packages:
          Ubuntu:
            repositories:
              all:
                - name: docker
                  types: deb
                  uris: "https://download.docker.com/linux/ubuntu"
                  suites: "{{ ansible_distribution_release }}"
                  components: stable
                  signed_by: "https://download.docker.com/linux/ubuntu/gpg"
            all:
              - docker-ce
              - docker-ce-cli
```

### Arch Linux with AUR
```yaml
- hosts: arch_systems
  roles:
    - role: wolskinet.infrastructure.manage_packages
      vars:
        packages:
          Archlinux:
            all:
              - base-devel           # Official
              - paru                 # AUR
              - visual-studio-code-bin  # AUR
            settings:
              enable_aur: true       # Handle both official and AUR
```

## Dependencies

- `community.general` - For pacman module (Arch Linux)
- `ansible.posix` - For various system tasks
- `geerlingguy.mac.homebrew` - For macOS package management (auto-installed via galaxy)

## See Also

- [ansible.builtin.apt module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/apt_module.html) (Debian/Ubuntu)
- [community.general.pacman module](https://docs.ansible.com/ansible/latest/collections/community/general/pacman_module.html) (Arch Linux)
- [geerlingguy.mac.homebrew role](https://galaxy.ansible.com/geerlingguy/mac) (macOS)
- [paru AUR helper](https://github.com/Morganamilo/paru) (Arch Linux AUR)

## Testing

```bash
# Test this role
molecule test -s manage_packages

# Quick validation
molecule converge -s manage_packages
molecule verify -s manage_packages
```

## License

MIT

## Author Information

Ed Wolski - wolskinet