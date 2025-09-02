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

### Default Configuration (Core Components Only)
```yaml
- hosts: servers
  roles:
    - wolskinet.infrastructure.configure_system
```

### Enable Optional Components
```yaml
- hosts: workstations
  roles:
    - role: wolskinet.infrastructure.configure_system
      vars:
        configure_system:
          language_packages:
            enabled: true
          system_settings:
            enabled: true
          dotfiles_deployment:
            enabled: true
```

### Selective Execution with Tags
```yaml
# Run only core system setup
- hosts: servers
  roles:
    - role: wolskinet.infrastructure.configure_system
      tags: [host-configuration, security-services, users, packages]

# Run only optional components
- hosts: workstations
  roles:
    - role: wolskinet.infrastructure.configure_system
      tags: [language-packages, system-settings, dotfiles]
```

### Disable Specific Components
```yaml
- hosts: servers
  roles:
    - role: wolskinet.infrastructure.configure_system
      vars:
        configure_system:
          security_services:
            enabled: false  # Skip security services
          user_management:
            enabled: false  # Skip user management
```

## Configuration

### Role Control Variables

```yaml
configure_system:
  # Core components (enabled by default)
  host_configuration:
    enabled: true
  security_services:
    enabled: true
  user_management:
    enabled: true
  package_management:
    enabled: true

  # Optional components (disabled by default)
  language_packages:
    enabled: false
  snap_packages:
    enabled: false
  flatpak_packages:
    enabled: false
  system_settings:
    enabled: false
  dotfiles_deployment:
    enabled: false

# Execution settings
configure_system_settings:
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
        users_config:
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
