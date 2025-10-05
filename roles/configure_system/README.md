# configure_system

Meta-role orchestrating system configuration via collection roles.

**Execution order:**
1. `os_configuration` - System settings
2. `manage_packages` - Package management
3. `manage_security_services` - Firewall/fail2ban
4. `manage_snap_packages` - Snap packages
5. `manage_flatpak` - Flatpak packages
6. `configure_users` - User preferences

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
        git:
          user_name: "Admin User"
          user_email: "admin@example.com"
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
    git:
      user_name: "Developer Name"
      user_email: "developer@example.com"
    nodejs:
      packages: [typescript, eslint]

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

Uses collection-wide variables. See collection README for reference.

## Tags

- `os-configuration` - OS settings
- `packages` - Package management
- `security-services` - Firewall/fail2ban
- `snap-packages` - Snap packages
- `flatpak-packages` - Flatpak packages
- `user-configuration` - User preferences

## Dependencies

Orchestrates: `os_configuration`, `manage_packages`, `manage_security_services`, `manage_snap_packages`, `manage_flatpak`, `configure_users`
