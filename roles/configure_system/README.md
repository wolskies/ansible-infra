# configure_system

Meta-role that orchestrates complete system configuration by calling multiple collection roles in the correct order.

## What It Does

Configures a complete system from OS-level settings through user preferences:

1. **os_configuration** - System settings (hostname, timezone, locale, services)
2. **manage_packages** - Package installation and repository management
3. **manage_security_services** - Firewall and fail2ban configuration
4. **manage_snap_packages** - Snap package management (optional)
5. **manage_flatpak** - Flatpak package management (optional)
6. **configure_users** - User-specific configuration (dotfiles, development tools)

## Usage

### Basic Configuration
```yaml
- hosts: all
  become: true
  roles:
    - wolskies.infrastructure.configure_system
  vars:
    domain_timezone: "America/New_York"
    host_hostname: "{{ inventory_hostname }}"
    users:
      - name: admin
        groups: [sudo]
        ssh_keys:
          - "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5..."
    packages:
      present:
        all:
          Ubuntu: [git, curl, vim]
    firewall:
      enabled: true
      rules:
        - port: 22
          protocol: tcp
```

### Advanced Configuration
```yaml
# group_vars/all.yml
domain_timezone: "America/New_York"
domain_locale: "en_US.UTF-8"

users:
  - name: developer
    groups: [sudo]
    ssh_keys:
      - "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5..."

packages:
  present:
    all:
      Ubuntu: [git, curl, vim, htop]
      Debian: [git, curl, vim, htop]

# group_vars/webservers.yml
packages:
  present:
    group:
      Ubuntu: [nginx, certbot]

firewall:
  enabled: true
  rules:
    - port: 80,443
      protocol: tcp

# host_vars/web01.yml
host_hostname: "web01"
packages:
  present:
    host:
      Ubuntu: [redis-server]
```

## Variables

Uses collection-wide variables. See collection README for complete variable reference.

Key variables:
- `domain_timezone` - System timezone
- `host_hostname` - System hostname
- `users` - User account definitions
- `packages` - Package management configuration
- `firewall` - Firewall rules and settings
- `snap` - Snap package management settings
- `flatpak` - Flatpak package management settings

## Tags

Control which components run:

- `os-configuration` - OS settings only
- `packages` - Package management only
- `security-services` - Firewall/fail2ban only
- `snap-packages` - Snap packages only
- `flatpak-packages` - Flatpak packages only
- `user-configuration` - User preferences only

Example:
```bash
# Skip optional package systems
ansible-playbook --skip-tags snap-packages,flatpak-packages playbook.yml

# Run only core system setup
ansible-playbook -t os-configuration,packages,security-services playbook.yml
```

## Dependencies

All required roles are included in the collection:
- `wolskies.infrastructure.os_configuration`
- `wolskies.infrastructure.manage_packages`
- `wolskies.infrastructure.manage_security_services`
- `wolskies.infrastructure.manage_snap_packages`
- `wolskies.infrastructure.manage_flatpak`
- `wolskies.infrastructure.configure_users`
