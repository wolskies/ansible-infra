## Ansible Role: Basic Setup

Provides minimal, essential packages and OS-specific feature management for consistent system foundations across different operating systems.

## Description

This role creates a **minimal, predictable starting point** for each supported OS by:

- Installing only essential packages (git, curl, build tools, Python, package managers)
- Managing OS-specific features (disabling snap on Ubuntu, installing paru on Arch, etc.)
- Providing hierarchical variable integration with discovery system
- Supporting user management and system optimization

**Philosophy:** This role provides both essential packages and category-based additional packages (development, desktop, media) controlled by feature flags.

## Supported Operating Systems

- **Ubuntu** 24+ (LTS recommended)
- **Debian** 12+ (Bookworm and later)
- **Arch Linux** (rolling release)
- **macOS** (latest versions)

## Essential Packages by OS

### Ubuntu/Debian
- `git`, `curl`, `wget`, `rsync`, `unzip`
- `build-essential`, `python3`, `python3-pip`
- `ufw` (firewall), `ca-certificates`

### Arch Linux
- `base-devel`, `git`, `curl`, `wget`, `rsync`, `unzip`
- `python`, `python-pip`, `linux-headers`
- `firewalld`, `pacman-contrib`
- `paru` (AUR helper)

### macOS
- `git`, `curl`, `wget`, `rsync`, `unzip`
- `python@3.13`, `homebrew/bundle`
- Xcode Command Line Tools

## OS-Specific Features

### Ubuntu
- **Snap Management:** Disables and removes snapd by default (`ubuntu_disable_snap: true`)
- **Cloud-init:** Optional disabling (`ubuntu_disable_cloud_init: false`)
- **Security Updates:** Configures unattended security updates

### Arch Linux
- **AUR Helper:** Installs paru for AUR package management
- **Pacman Optimization:** Enables color, parallel downloads, verbose lists
- **Mirror Management:** Sets up reflector for optimal mirrors
- **systemd-resolved:** Enables modern DNS resolution

### macOS
- **Homebrew:** Installs and configures for both Intel and Apple Silicon
- **Xcode Tools:** Installs command line tools and accepts license
- **Security Settings:** Configurable Gatekeeper and update management
- **System Optimization:** Keyboard access, Finder settings

### Debian
- **APT Optimization:** Configures for better performance
- **Security Updates:** Unattended security updates only
- **Repository Management:** Optional non-free repositories

## Usage

### Basic Usage
Include in your playbook after facts gathering and before other roles:

```yaml
- hosts: all
  roles:
    - wolskinet.infrastructure.basic_setup
```

### With Hierarchical Variables
The role integrates with the collection's hierarchical variable system:

```yaml
# group_vars/all.yml
packages_install:
  - htop
  - vim

# group_vars/servers.yml  
packages_install:
  - nginx
  - certbot

# host_vars/web-01.yml
packages_install:
  - redis-server
```

Final packages = essential + all + servers + host

### Variable Examples

```yaml
# Minimal server configuration
user_details:
  - name: deploy
    uid: 1001
    shell: /bin/bash
    groups: ["sudo", "docker"]

# Feature management
ubuntu_disable_snap: true
archlinux_enable_reflector: true
macos_install_xcode_tools: true
```

## Adding Opinionated Packages

For fuller package sets (development tools, GUI applications, etc.), see:
- `examples/inventory/group_vars/opinionated-packages-*.yml`
- Copy and modify these files for your specific needs
- Use `packages_install` variable to extend essential packages

## Integration with Collection

This role works with:
- **Discovery System:** Processes `discovered_packages` from infrastructure discovery
- **Docker Setup:** Prepares systems for Docker service deployment  
- **Security Hardening:** Provides foundation for devsec.hardening role
- **User Management:** Creates users with appropriate groups and shells

## Tags

- `basic-setup` - All tasks
- `os-setup` - Package installation and OS configuration
- `os-features` - OS-specific feature management  
- `users` - User creation and management
- `variables` - Variable loading and merging
- `validation` - OS version and compatibility checks

## Variables

### Core Variables
- `packages_install` - Additional packages to install
- `packages_remove` - Packages to remove
- `user_details` - Users to create
- `default_user_shell` - Default shell for new users

### Package Category Controls
- `install_development_packages: true` - Development tools, compilers, etc.
- `install_desktop_packages: true` - GUI applications, themes, etc.
- `install_media_packages: false` - Large media packages (manual review recommended)
- `install_productivity_packages: true` - Editors, terminals, productivity tools

### Package Manager Controls
- `install_aur_packages: true` - Arch Linux AUR packages
- `install_pip_packages: true` - Python packages
- `install_npm_packages: true` - Node.js packages
- `install_homebrew_casks: true` - macOS GUI applications

### OS Feature Variables
- `ubuntu_disable_snap: true` - Remove snapd completely
- `ubuntu_disable_cloud_init: false` - Disable cloud-init
- `archlinux_enable_reflector: true` - Setup mirror optimization
- `macos_install_xcode_tools: true` - Install Xcode CLI tools
- `debian_enable_non_free: false` - Enable non-free repositories

See `defaults/main.yml` and OS-specific variable files for complete lists.

## Examples

### Minimal Server
```yaml
- hosts: servers
  vars:
    ubuntu_disable_snap: true
    user_details:
      - name: admin
        uid: 1000
        shell: /bin/bash
        groups: ["sudo"]
  roles:
    - wolskinet.infrastructure.basic_setup
```

### Development Workstation
```yaml
- hosts: workstations
  vars_files:
    - examples/inventory/group_vars/opinionated-packages-ubuntu.yml
  vars:
    default_user_shell: /bin/zsh
    configure_zsh: true
  roles:
    - wolskinet.infrastructure.basic_setup
```