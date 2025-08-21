# Ansible Role: Basic Setup

Essential foundation packages and OS-specific features for all machine types.

## Purpose

Creates minimal, predictable starting point:
- OS packages via hierarchical variables (all/group/host levels)
- Language-specific packages (AUR, pip, npm)
- OS-specific features (snap removal, AUR helper, Homebrew)
- User management and firewall installation

## Hierarchical Package Variables

```yaml
# group_vars/all/Ubuntu.yml - Global packages
all_packages_install_Ubuntu:
  - git
  - curl
  - htop

# group_vars/servers/Ubuntu.yml - Group packages
group_packages_install_Ubuntu:
  - nginx
  - fail2ban

# host_vars/web-01/Ubuntu.yml - Host packages  
host_packages_install_Ubuntu:
  - redis-server
```

Variables merge: all → group → host (duplicates removed).

## Essential Packages by OS

**Ubuntu/Debian**: `git`, `curl`, `build-essential`, `python3-pip`, `ufw`
**Arch Linux**: `base-devel`, `git`, `curl`, `python-pip`, `firewalld`, `paru` (AUR)
**macOS**: `git`, `curl`, `python@3.13`, Homebrew setup

## Key Variables

```yaml
# Package installation
install_development_packages: false
install_media_packages: false
remove_snap_packages: true  # Ubuntu only

# User management  
user_details:
  - name: deploy
    uid: 1001
    shell: /bin/bash
    groups: [sudo, docker]

# Language packages
pip_packages_user:
  - ansible
  - docker-compose
  
npm_packages_global:
  - pm2
  - typescript
```

## Usage

```yaml
# Basic server setup
- hosts: servers
  vars:
    install_development_packages: true
    remove_snap_packages: true
  roles:
    - wolskinet.infrastructure.basic_setup

# Development workstation
- hosts: workstations  
  vars:
    install_development_packages: true
    install_media_packages: true
    pip_packages_user:
      - ansible
      - docker-compose
    npm_packages_global:
      - typescript
      - @vue/cli
  roles:
    - wolskinet.infrastructure.basic_setup
```

## Discovery Integration

Discovery automatically provides:
- `host_packages_install_<Distribution>`: Detected packages
- `install_development_packages`: Based on detected dev tools
- `install_media_packages`: Based on GUI detection
- `user_details`: Current user configuration

## OS-Specific Features

**Ubuntu**: Snap removal, APT sources management
**Arch**: AUR helper (paru) installation, pacman optimization
**macOS**: Homebrew setup, Xcode CLI tools
**All**: Firewall installation (not configuration)