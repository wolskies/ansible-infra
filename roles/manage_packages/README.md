# manage_packages

Hierarchical package management with unified variable structure for Ubuntu 22+, Debian 12+, Arch Linux, and macOS.

## Description

This role provides a unified interface for package management across multiple operating systems. It acts as a wrapper around platform-specific package managers (`ansible.builtin.apt`, `community.general.pacman`, `geerlingguy.mac.homebrew`) while adding hierarchical variable merging that combines packages from all/group/host levels with automatic deduplication.

## Features

- **Unified structure** - Uses `infrastructure.host.packages` hierarchy across all platforms
- **Hierarchical merging** - Combines all/group/host package lists with automatic deduplication
- **Platform detection** - Automatically uses correct package manager based on `ansible_distribution`
- **Repository management** - APT repositories (Debian/Ubuntu), Homebrew taps (macOS)
- **AUR Integration** - Seamless official+AUR package management for Arch Linux

## Role Variables

### Core Configuration

Uses the unified infrastructure structure:

```yaml
infrastructure:
  host:
    packages:
      present:
        all:
          Ubuntu: []    # Global packages for all Ubuntu machines
          Debian: []    # Global packages for all Debian machines
          Archlinux: [] # Global packages for all Arch machines
          MacOSX: []    # Global packages for all macOS machines
        group:
          Ubuntu: []    # Group-specific packages
          Debian: []
          Archlinux: []
          MacOSX: []
        host:
          Ubuntu: []    # Host-specific packages
          Debian: []
          Archlinux: []
          MacOSX: []
      remove:
        all:
          Ubuntu: []    # Packages to remove
          Debian: []
          Archlinux: []
          MacOSX: []
        group:
          Ubuntu: []
          Debian: []
          Archlinux: []
          MacOSX: []
        host:
          Ubuntu: []
          Debian: []
          Archlinux: []
          MacOSX: []
      casks_present:      # macOS only
        all: []
        group: []
        host: []
      casks_remove: []    # macOS only

      # Package manager specific settings
      apt:                # Debian/Ubuntu settings
        apt_cache:
          update_cache: true
          valid_time: 3600
        system_upgrade:
          enable: false
          type: safe        # safe, full, or dist
        repositories:
          all:
            Ubuntu: []
            Debian: []
          group:
            Ubuntu: []
            Debian: []
          host:
            Ubuntu: []
            Debian: []
      pacman:             # Arch Linux settings
        enable_aur: true  # Use kewlfft.aur module for AUR packages
      homebrew:           # macOS settings
        taps: []
        cleanup_cache: false
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
infrastructure:
  host:
    packages:
      present:
        all:
          Ubuntu: [git, curl, htop]
      apt:
        apt_cache:
          update_cache: true
          valid_time: 3600
        system_upgrade:
          enable: false
          type: safe
        repositories:
          all:
            Ubuntu:
              - name: "docker"
                types: "deb"
                uris: "https://download.docker.com/linux/ubuntu"
                suites: "{{ ansible_distribution_release }}"
                components: "stable"
                signed_by: "https://download.docker.com/linux/ubuntu/gpg"
```

### Arch Linux (kewlfft.aur module with auto-detection)

**When `enable_aur: true`** - Uses kewlfft.aur module for all packages (official + AUR):

The kewlfft.aur module automatically:
- Detects installed AUR helpers (yay, paru, pacaur, trizen, pikaur)
- Uses the first available helper found
- Falls back to makepkg if no helper is installed
- Handles both official repository and AUR packages seamlessly
- Runs as the ansible_user (non-root) with sudo privileges for pacman
```yaml
infrastructure:
  host:
    packages:
      present:
        all:
          Archlinux:
            - firefox        # Official package
            - visual-studio-code-bin  # AUR package - handled transparently
      pacman:
        enable_aur: true     # Use kewlfft.aur for all packages
```

**When `enable_aur: false`** - Uses `community.general.pacman` directly:
```yaml
infrastructure:
  host:
    packages:
      pacman:
        enable_aur: false  # Use pacman module only
```

### macOS (via geerlingguy.mac.homebrew)

Direct pass-through to `geerlingguy.mac.homebrew` role:

```yaml
infrastructure:
  host:
    packages:
      present:
        all:
          MacOSX: [git, wget, htop]  # Homebrew formulae
      casks_present:
        all: [visual-studio-code, docker]  # GUI applications
      homebrew:
        taps: [homebrew/cask-fonts]  # Additional taps
        cleanup_cache: false
```

## Usage Examples

### Basic Cross-Platform
```yaml
- hosts: all
  roles:
    - role: wolskinet.infrastructure.manage_packages
      vars:
        infrastructure:
          host:
            packages:
              present:
                all:
                  Ubuntu: [git, curl, vim, htop]
                  Debian: [git, curl, vim, htop]
                  Archlinux: [git, curl, vim, htop]
                  MacOSX: [git, curl, vim, htop]
```

### Hierarchical Package Management
```yaml
# group_vars/all.yml
infrastructure:
  host:
    packages:
      present:
        all:
          Ubuntu: [git, curl, htop]  # All Ubuntu machines

# group_vars/webservers.yml
infrastructure:
  host:
    packages:
      present:
        group:
          Ubuntu: [nginx, certbot]  # Web servers only

# host_vars/web01.yml
infrastructure:
  host:
    packages:
      present:
        host:
          Ubuntu: [redis-server]  # This host only

# Result for web01: [git, curl, htop, nginx, certbot, redis-server]
```

### Repository Management (Debian/Ubuntu)
```yaml
- hosts: ubuntu_servers
  roles:
    - role: wolskinet.infrastructure.manage_packages
      vars:
        infrastructure:
          host:
            packages:
              present:
                all:
                  Ubuntu: [docker-ce, docker-ce-cli]
              apt:
                repositories:
                  all:
                    Ubuntu:
                      - name: docker
                        types: deb
                        uris: "https://download.docker.com/linux/ubuntu"
                        suites: "{{ ansible_distribution_release }}"
                        components: stable
                        signed_by: "https://download.docker.com/linux/ubuntu/gpg"
```

### Arch Linux with AUR
```yaml
- hosts: arch_systems
  roles:
    - role: wolskinet.infrastructure.manage_packages
      vars:
        infrastructure:
          host:
            packages:
              present:
                all:
                  Archlinux:
                    - base-devel           # Official
                    - yay                  # AUR (or any AUR helper)
                    - visual-studio-code-bin  # AUR
              pacman:
                enable_aur: true           # Handle both official and AUR
```

## Dependencies

- `community.general` - For pacman module (Arch Linux fallback)
- `kewlfft.aur` - For AUR package management on Arch Linux
- `ansible.posix` - For various system tasks
- `geerlingguy.mac.homebrew` - For macOS package management (auto-installed via galaxy)

## See Also

- [ansible.builtin.apt module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/apt_module.html) (Debian/Ubuntu)
- [community.general.pacman module](https://docs.ansible.com/ansible/latest/collections/community/general/pacman_module.html) (Arch Linux)
- [geerlingguy.mac.homebrew role](https://galaxy.ansible.com/geerlingguy/mac) (macOS)
- [kewlfft.aur module](https://github.com/kewlfft/ansible-aur) (Arch Linux AUR support)

## License

MIT

## Author Information

This role is part of the `wolskinet.infrastructure` Ansible collection.
