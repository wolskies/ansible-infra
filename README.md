# Ansible Collection - wolskinet.infrastructure

Cross-platform infrastructure automation collection with discovery-driven deployment for Ubuntu 24+, Debian 12+, Arch Linux, and macOS. Features inventory-group-based architecture and hierarchical package management.

## Architecture Overview

### Group-Based Configuration
Machines are configured through inventory group membership with role combinations:
- **`servers`**: Security hardening + basic setup + system packages  
- **`docker_hosts`**: Server features + Docker installation + container services
- **`workstations`**: Basic setup + dotfiles + desktop configurations + shell enhancements
- **Custom groups**: User-defined role combinations

### Hierarchical Package Management
Advanced package variable merging with OS-specific distribution support:
```yaml
# Variable precedence (merged in order):
all_packages_install_Ubuntu: [git, curl, htop]        # All Ubuntu machines
group_packages_install_Ubuntu: [nginx, certbot]       # Server group only  
host_packages_install_Ubuntu: [redis-server]          # Single host (from discovery)
# Final result: [git, curl, htop, nginx, certbot, redis-server] + conditional packages
```

Supported distributions: `Ubuntu`, `Debian`, `Archlinux`, `MacOSX`

## Core Roles

### **basic_setup** - System Foundation (Meta Role)
Coordinates foundational setup by delegating to specialized roles:
- **configure_host**: System configuration (timezone, locale, firewall, repositories)
- **manage_system_packages**: Hierarchical package management with OS-specific support
- **manage_users**: User and group management with optional dotfiles integration

### **configure_host** - System Configuration
Host-level system configuration and settings:
- **System Config**: Locale, timezone settings
- **Firewall Setup**: UFW/firewalld installation and basic configuration
- **Repository Management**: Additional APT sources and GPG keys
- **Platform Features**: Ubuntu snap removal, Arch mirror optimization, macOS preferences

### **manage_system_packages** - Package Management  
Advanced hierarchical package management:
- **Variable Merging**: all_ + group_ + host_ package lists
- **Conditional Packages**: Shell enhancements, dotfiles support
- **Multi-OS Support**: APT, Pacman, Homebrew package managers
- **System Updates**: Configurable package upgrades via manage_packages role

### **manage_users** - User Management
User and group administration:
- **User Creation**: With UID, shell, groups, password management
- **Group Management**: Create and remove system groups  
- **Dotfiles Integration**: Automatic deployment for users with repositories
- **Multi-Platform**: Linux and macOS user management

### **discovery** - Infrastructure Scanning
Automated discovery and inventory generation:
- **System Discovery**: Packages, services, Docker containers, users, configuration
- **Smart Filtering**: Excludes system packages, focuses on user-installed software
- **Output Generation**: host_vars and deployment playbooks ready for use
- **Cross-Platform**: Full support for Linux distros and macOS

### **container_platform** - Docker Infrastructure
Docker installation and container service management:
- **Docker Setup**: Installation, user management, daemon configuration
- **Service Management**: Deploy services from discovery or manual configuration
- **Compose Integration**: Automatic compose file handling and service mapping

### **dotfiles** - Configuration Management
Automated dotfiles deployment with conflict resolution:
- **Stow Integration**: GNU Stow-based symlink management
- **Conflict Resolution**: Intelligent backup of existing files
- **Multi-User Support**: Integration with basic_setup for per-user deployment

### **manage_firewall** - Firewall and Security Configuration
Independent firewall configuration and intrusion prevention:
- **Firewall Management**: UFW (Ubuntu/Debian), firewalld (Arch), macOS firewall
- **Fail2ban Integration**: Intrusion detection and prevention
- **Rule Management**: Port-based and custom firewall rules
- **Standalone Operation**: No dependencies on other roles


### **system_tuning** - Performance Optimization
Hardware and performance optimization:
- **Gaming Optimization**: Kernel parameters, CPU governor settings
- **Media Support**: GPU drivers, codec installation
- **Hardware Support**: Bluetooth, camera, audio optimizations

### **manage_language_packages** - Language Ecosystems
Language ecosystem package management with dependency checking:
- **Python**: uv package management with user/global/project methods
- **Node.js**: npm global package management
- **Rust**: cargo package installation with rustup
- **Go**: go module installation
- **Dependency Checking**: Automatic installation of missing language tools

## Installation & Quick Start

```bash
# Install collection
ansible-galaxy collection install wolskinet.infrastructure

# Basic inventory structure
mkdir -p inventory/{group_vars/{all,servers,docker_hosts,workstations},host_vars}
mkdir -p playbooks
```

### Example Inventory
```yaml
# inventory/hosts.yml
servers:
  hosts:
    web-server:
      ansible_host: 192.168.1.20

docker_hosts:
  hosts:
    docker-01:
      ansible_host: 192.168.1.30
      
workstations:
  hosts:
    dev-machine:
      ansible_host: 192.168.1.10
```

### Hierarchical Variables
```yaml
# inventory/group_vars/all/Ubuntu.yml - Global packages
all_packages_install_Ubuntu:
  - git
  - curl
  - htop

# inventory/group_vars/servers/Ubuntu.yml - Server packages  
group_packages_install_Ubuntu:
  - nginx
  - fail2ban
  - certbot
```

### Main Playbook
```yaml
# playbooks/site.yml
- name: Basic infrastructure setup
  hosts: all
  roles:
    - wolskinet.infrastructure.basic_setup

- name: Docker infrastructure  
  hosts: docker_hosts
  roles:
    - wolskinet.infrastructure.container_platform

- name: Security configuration
  hosts: servers
  roles:
    - devsec.hardening.os_hardening
    - devsec.hardening.ssh_hardening  
    - wolskinet.infrastructure.manage_firewall
```

## Discovery-Driven Deployment

### 1. Discover Existing Infrastructure
```bash
# Scan existing machine to generate configuration
ansible-playbook playbooks/run-discovery.yml -i existing-server, --ask-become-pass
```

**Generated Output:**
- `inventory/host_vars/existing-server.yml` - Discovered configuration
- `playbooks/existing-server_discovered.yml` - Ready-to-deploy playbook

### 2. Review and Customize  
```yaml
# Example generated host_vars/web-01.yml
host_packages_install_Ubuntu:
  - nginx
  - redis-server
  - git
  
discovered_users_config:
  - name: deploy
    shell: /bin/bash
    groups: [sudo, docker]
    dotfiles_repository_url: "https://github.com/deploy/dotfiles"
    
install_docker_services:
  - role: nginx_proxy_manager
    name: proxy
    # ... service configuration
```

### 3. Deploy to New Machines
```bash
# Use discovered configuration for new deployments
ansible-playbook playbooks/web-01_discovered.yml -i inventory/hosts.yml -l new-server
```

## Advanced Configuration

### Shell Enhancement Integration
```yaml
# Automatic modern shell tool installation
install_shell_enhancements: true  # Adds: zsh, starship, zoxide, eza, fzf, bat
```

### macOS System Preferences (geerlingguy-inspired)
```yaml
# Comprehensive macOS customization
macos_configure_dock: true
macos_dock_tile_size: 48
macos_dock_autohide: true
macos_finder_show_extensions: true
macos_enable_full_keyboard_access: true
```

### Dotfiles Integration
```yaml
# Per-user dotfiles deployment via basic_setup
install_dotfiles_support: true
discovered_users_config:
  - name: developer
    dotfiles_repository_url: "https://github.com/developer/dotfiles"
    dotfiles_uses_stow: true
    dotfiles_stow_packages: ["zsh", "git", "tmux"]
```

### Ubuntu Snap Management
```yaml
# Complete snap removal for Ubuntu
ubuntu_disable_snap: true  # Removes all snaps, disables snapd service
```

### Container Service Mapping
```yaml
# Automatic Docker service role mapping
install_docker_services:
  - role: gitlab                    # From gitlab/gitlab-ce image
  - role: jellyfin                  # From jellyfin/jellyfin image
  - role: nginx_proxy_manager       # From jc21/nginx-proxy-manager image
```

## Platform Support

### Ubuntu 24+ / Debian 12+
- Full APT package management with additional repositories
- Optional snap removal with complete cleanup
- UFW firewall configuration
- Automatic security update configuration

### Arch Linux
- Native pacman + AUR packages via paru
- Automated mirror optimization with reflector
- firewalld configuration
- Pacman hook management

### macOS (Intel/Apple Silicon)  
- Homebrew package management (Intel + Apple Silicon paths)
- Comprehensive system preferences automation
- Platform-specific firewall configuration
- Xcode Command Line Tools installation

## Security Integration

This collection complements the devsec.hardening collection:

```yaml
# Recommended security layering
- name: Complete security setup
  hosts: servers
  roles:
    - wolskinet.infrastructure.basic_setup      # Foundation + firewall install
    - devsec.hardening.os_hardening            # OS-level security hardening
    - devsec.hardening.ssh_hardening           # SSH security configuration
    - wolskinet.infrastructure.manage_firewall  # Firewall rules + fail2ban
```

## Dependencies

**Required Collections:**
```yaml
# galaxy.yml dependencies
collections:
  - community.general
  - ansible.posix
```

**Recommended Collections:**
- `devsec.hardening` - Comprehensive security hardening

**System Requirements:**
- **Ansible**: 2.9+ (tested with ansible-core 2.12+)
- **Python**: 2.7+/3.6+ on target systems
- **Privileges**: Sudo access for system configuration
- **macOS**: Homebrew installation for package management

## Development & Testing

```bash
# Development workflow
make lint          # Run ansible-lint, yamllint, security checks
make test-quick    # Fast validation tests  
make test          # Full molecule test suite
make build         # Build collection package

# Individual role testing
make test-basic    # Test basic_setup role
make test-docker   # Test container_platform role
make test-discovery # Test discovery role
```

## License

MIT

---

**Key Features Summary:**
- **Discovery-Driven**: Scan existing infrastructure, generate deployment configs
- **Cross-Platform**: Ubuntu, Debian, Arch Linux, macOS support
- **Hierarchical Variables**: Smart package merging across all/group/host levels
- **Modern Tooling**: Shell enhancements, dotfiles automation, macOS preferences
- **Security-Ready**: Integrates seamlessly with devsec.hardening collection
- **Container-Aware**: Docker service discovery and automatic role mapping