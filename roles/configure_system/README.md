# Configure System Role

Master orchestration role for complete system configuration. Executes infrastructure roles in the proper order to fully configure new machines.

## Purpose

This role orchestrates the execution of multiple infrastructure roles to provide complete system setup:

1. **configure_host** - Basic host setup (hostname, NTP, locale)
2. **manage_security_services** - Security services (firewall, fail2ban)
3. **manage_users** - User and group management
4. **manage_packages** - Package installation and repository management
5. **manage_language_packages** - Language-specific package managers (optional)
6. **manage_snap_packages** - Snap package management (optional)
7. **manage_flatpak** - Flatpak package management (optional)
8. **manage_system_settings** - System performance tuning (optional)
9. **dotfiles** - User dotfiles deployment (optional)

## Usage

### Default Configuration (All Components)
```yaml
- hosts: servers
  roles:
    - wolskinet.infrastructure.configure_system
```

### Core Components Only
```bash
# Execute only core components via command line
ansible-playbook playbook.yml --tags core
```

### Selective Execution with Tags
```bash
# Run specific components
ansible-playbook playbook.yml --tags users,packages

# Run only optional components
ansible-playbook playbook.yml --tags optional

# Skip specific components
ansible-playbook playbook.yml --skip-tags dotfiles,snap-packages
```

### Available Tags
- `core` - All core components (host, security, users, packages)
- `optional` - All optional components (language, snap, flatpak, settings, dotfiles)
- `host-configuration` - Basic host setup
- `security-services` - Security services
- `user-management` or `users` - User and group management
- `package-management` or `packages` - Package installation
- `language-packages` - Language-specific package managers
- `snap-packages` - Snap package management
- `flatpak-packages` - Flatpak package management
- `system-settings` - System performance tuning
- `dotfiles` - User dotfiles deployment
- `progress` - Progress messages

## Configuration

The role uses Ansible's built-in tag system for execution control:

```bash
# Run everything (default behavior)
ansible-playbook playbook.yml

# Run only what you need
ansible-playbook playbook.yml --tags core
ansible-playbook playbook.yml --tags "users,packages"
ansible-playbook playbook.yml --skip-tags "dotfiles"
```
  fail_on_error: true      # Stop if any role fails
  show_progress: true      # Display progress messages
  respect_tags: true       # Honor tag-based selective execution
```

### Individual Role Variables

All variables for individual roles are passed through unchanged. Configure roles using their native variable structures:

```yaml
# Host configuration
config_common_hostname: "server01"
config_common_timezone: "UTC"

# User management
users_config:
  - name: admin
    groups: [sudo, docker]
    shell: /bin/bash

# Package management
all_packages_install_Ubuntu:
  - git
  - htop
  - nginx

# System settings (when enabled)
system_settings_sysctl:
  enabled: true
  parameters:
    vm.swappiness: 10
    net.ipv4.tcp_keepalive_time: 120

# Dotfiles (when enabled)
dotfiles:
  user: admin
  repository_url: "https://github.com/user/dotfiles"
  method: "stow"
```

## Tags

### Component Tags
- `host-configuration` - Host setup only
- `security-services` - Security services only
- `users` / `user-management` - User management only
- `packages` / `package-management` - Package management only
- `language-packages` - Language package managers only
- `snap-packages` - Snap packages only
- `flatpak-packages` - Flatpak packages only
- `system-settings` - System tuning only
- `dotfiles` - Dotfiles deployment only

### Meta Tags
- `configure-system` - All components
- `always` - Progress messages and summaries

## Examples

### New Server Setup
```yaml
- hosts: new_servers
  become: true
  roles:
    - role: wolskinet.infrastructure.configure_system
      vars:
        # Basic host configuration
        config_common_hostname: "{{ inventory_hostname }}"
        config_common_timezone: "America/New_York"

        # Create admin user
        users:
          - name: admin
            groups: [sudo]
            shell: /bin/bash
            create_home: true

        # Install server packages
        all_packages_install_Ubuntu:
          - git
          - htop
          - nginx
          - certbot

        # Enable system tuning
        configure_system:
          system_settings:
            enabled: true

        system_settings_sysctl:
          enabled: true
          parameters:
            vm.swappiness: 10
            net.core.somaxconn: 65535
```

### Developer Workstation
```yaml
- hosts: workstations
  become: true
  roles:
    - role: wolskinet.infrastructure.configure_system
      vars:
        # Enable all optional components
        configure_system:
          language_packages:
            enabled: true
          system_settings:
            enabled: true
          dotfiles_deployment:
            enabled: true

        # Developer packages
        all_packages_install_Ubuntu:
          - git
          - vim
          - curl
          - build-essential

        # Language package managers
        language_packages:
          nodejs:
            enabled: true
            version: "lts"
          python:
            enabled: true
            pip_packages:
              - requests
              - flask

        # User dotfiles
        dotfiles:
          user: developer
          repository_url: "https://github.com/developer/dotfiles"
          method: "auto"
```

## Dependencies

This role requires all the individual infrastructure roles to be available:
- `wolskinet.infrastructure.configure_host`
- `wolskinet.infrastructure.manage_security_services`
- `wolskinet.infrastructure.manage_users`
- `wolskinet.infrastructure.manage_packages`
- `wolskinet.infrastructure.manage_language_packages`
- `wolskinet.infrastructure.manage_snap_packages`
- `wolskinet.infrastructure.manage_flatpak`
- `wolskinet.infrastructure.manage_system_settings`
- `wolskinet.infrastructure.dotfiles`

See individual role documentation for detailed configuration options.
