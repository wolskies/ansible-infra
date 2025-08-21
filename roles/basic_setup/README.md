## Ansible Role: Basic Setup

Provides essential packages and OS-specific feature management for consistent system foundations across different operating systems.

## Description

This role creates a **minimal, predictable starting point** for each supported OS by:

- Installing packages via hierarchical OS-specific variables (all/group/host levels)
- Installing language-specific packages (AUR, pip, npm)
- Managing OS-specific features (disabling snap on Ubuntu, installing paru on Arch, etc.)
- Providing user management and system optimization
- Installing and configuring basic firewall security

**Philosophy:** This role provides essential system foundations using a clean hierarchical package architecture that integrates seamlessly with discovery-generated variables.

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
Include in your playbook after facts gathering:

```yaml
- hosts: all
  roles:
    - wolskinet.infrastructure.basic_setup
```

### With Hierarchical Variables
The role uses OS-specific hierarchical package variables:

```yaml
# group_vars/all/Ubuntu.yml - Global packages for all Ubuntu machines
all_packages_install_Ubuntu:
  - htop
  - vim

# group_vars/servers/Ubuntu.yml - Server group packages
group_packages_install_Ubuntu:
  - nginx
  - certbot

# host_vars/web-01.yml - Host-specific packages (includes discovery)
host_packages_install_Ubuntu:
  - redis-server
```

Final packages = essential + all + group + host (discovery populates host level)

### Variable Examples

```yaml
# User management
user_details:
  - name: deploy
    uid: 1001
    shell: /bin/bash
    groups: ["sudo", "docker"]

# OS feature management
ubuntu_disable_snap: true
archlinux_enable_reflector: true
macos_install_xcode_tools: true

# Cross-OS package mapping
# Ubuntu packages
host_packages_install_Ubuntu:
  - redis-server
  - postgresql-client

# Equivalent Arch packages
host_packages_install_Archlinux:
  - redis
  - postgresql
```

## Integration with Collection

This role works with:
- **Discovery System:** Discovery generates `host_packages_install_<Distribution>` variables
- **Container Platform:** Prepares systems for Docker service deployment  
- **Maintenance Role:** Provides foundation for system updates
- **User Management:** Creates users with appropriate groups and shells

## Hierarchical Package Architecture

### Variable Sources (merged in order)
1. **all_packages_install_<Distribution>** (group_vars/all)
2. **group_packages_install_<Distribution>** (group_vars/<group>)  
3. **host_packages_install_<Distribution>** (host_vars/<host>, includes discovery)

### Package Types Handled
- **OS packages:** Via system package managers (apt, pacman, homebrew)
- **AUR packages:** Arch Linux user repository (via paru/yay)
- **Homebrew packages:** macOS formulae
- **Homebrew casks:** macOS GUI applications

**Note:** Python (pip) and Node.js (npm) packages are handled by the third_party_packages role:
- Use `third_party_packages` role for pip packages, npm packages, and repositories

### OS-Specific Package Variables
- `aur_packages` - Arch Linux AUR packages (handled by basic_setup)
- `homebrew_packages` - macOS Homebrew formulae
- `homebrew_casks` - macOS GUI applications

## Tags

- `basic-setup` - All tasks
- `os-setup` - OS-specific setup and configuration
- `packages` - Package installation (OS packages)
- `aur` - AUR package installation (Arch Linux only)
- `users` - User creation and management
- `variables` - Variable loading and merging
- `validation` - OS version and compatibility checks

## Variables

### Core Variables
- `all_packages_install_<Distribution>` - Global packages (group_vars/all)
- `group_packages_install_<Distribution>` - Group-specific packages (group_vars/<group>)  
- `host_packages_install_<Distribution>` - Host-specific packages (host_vars/<host>, includes discovery)
- `packages_remove_<Distribution>` - Packages to remove (hierarchical)
- `user_details` - Users to create
- `default_user_shell` - Default shell for new users

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

### Development Workstation with Discovery
```yaml
# 1. Run discovery on existing machine
# ansible-playbook utilities/playbooks/discover-essential.yml

# 2. Discovery generates host_packages_install_Ubuntu in host_vars/

# 3. Deploy with additional packages
- hosts: workstations
  vars:
    default_user_shell: /bin/zsh
    # Discovery packages merged with group packages
    group_packages_install_Ubuntu:
      - nodejs
      - python3-dev
      - build-essential
  roles:
    - wolskinet.infrastructure.basic_setup
```

### Cross-OS Infrastructure
```yaml
# Define packages for multiple distributions
- hosts: all
  vars:
    # Global packages - Ubuntu
    all_packages_install_Ubuntu:
      - htop
      - curl
    
    # Global packages - Arch Linux  
    all_packages_install_Archlinux:
      - htop
      - curl
      
    # Global packages - macOS
    homebrew_packages:
      - htop
      - curl
  roles:
    - wolskinet.infrastructure.basic_setup
```

## Discovery Integration

The discovery role generates host-level variables that integrate seamlessly:

1. **Discovery scans machine:** `ansible-playbook discover-essential.yml`
2. **Generates host_vars:** Creates `host_packages_install_<Distribution>` variables
3. **User adds hierarchy:** Can add group/all level packages that merge with discovery
4. **Deploy replicates:** `ansible-playbook deploy-<host>.yml` recreates configuration

```yaml
# Generated by discovery in host_vars/web-01.yml
host_packages_install_Ubuntu:
  - nginx
  - redis-server
  - curl
  # ... all discovered packages

# User can add at any level - these merge with discovery
# group_vars/servers/Ubuntu.yml
group_packages_install_Ubuntu:
  - certbot
  - ufw

# Final result: nginx + redis-server + curl + certbot + ufw + essentials
```