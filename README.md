# Ansible Collection - wolskies.infrastructure

Automated scripts for system configuration, package management, and user environment configuration.

**Supported Platforms:**
- Ubuntu 22.04+, 24.04+
- Debian 12+, 13+
- Arch Linux (Rolling)

**Limited Support:** (due to lack of readily available test resources)
- macOS 13+ (Ventura)

## Roles

- **configure_system**: Meta-role for convenience (calls multiple roles in order)
- **os_configuration**: System settings (timezone, hostname, locale, services, kernel parameters)
- **manage_packages**: Package management (APT, Pacman, Homebrew) with repository configuration
- **manage_security_services**: Firewall (UFW/macOS ALF) and fail2ban configuration
- **configure_users**: User preferences (dotfiles, development tools, language environments)
- **nodejs**: Node.js and user-level npm package management
- **rust**: Rust/Cargo and user-level package management
- **go**: Go and user-level package management
- **neovim**: Neovim installation and configuration
- **manage_snap_packages**: Snap package management
- **manage_flatpak**: Flatpak package management
- **terminal_config**: Terminal configuration (kitty, alacritty, wezterm)

### Utility Role
- **discovery**: provides a convenient method to generate compatible host_vars that capture the state of an existing system.


## Installation

Install the collection and its dependencies:

```bash
git clone https://github.com/wolskinet/ansible-infrastructure
cd ansible-infrastructure
ansible-galaxy install -r requirements.yml
ansible-galaxy collection install . --force
```

## Quick Start

```yaml
# site.yml - Complete infrastructure setup
- hosts: all
  become: true
  roles:
    - wolskies.infrastructure.configure_system
```

## Variable Reference

A complete list of variables and their default values is provided in defaults/main.yml

## Dependencies and Credits

This collection leverages the following community roles:

- **geerlingguy.mac**: Homebrew installation and macOS configuration
- **devsec.hardening**: OS and SSH security hardening (os_hardening, ssh_hardening roles)
- **kewlfft.aur**: AUR package management for Arch Linux
- **community.general**: Core modules for package management and system configuration

## Documentation

**📖 Complete documentation is available on GitLab Pages:**
- **Collection Overview**: Full variable reference and usage patterns
- **Individual Role Documentation**: Detailed specifications for each role
- **Requirements and Examples**: Platform-specific configuration examples
- **Auto-Generated**: Documentation is generated from the Software Requirements Document (SRD)

**Local Documentation Generation:**
```bash
# Generate complete documentation
python3 scripts/generate_enhanced_docs.py
python3 scripts/generate_collection_docs.py
```

## Requirements

- **Ansible Core**: 2.15+ (tested with 2.17)
- **Python**: 3.9+ on control and managed nodes
- **Collections**:
  - `community.general` - Package management and system modules
  - `ansible.posix` - POSIX system management
- **Platform-Specific**:
  - **macOS**: Xcode Command Line Tools
  - **Arch Linux**: `base-devel` group for AUR support
  - **Debian/Ubuntu**: `python3-debian` for repository management

