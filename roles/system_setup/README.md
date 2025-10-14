# system_setup

Meta-role demonstrating the **System → Software → Users** pattern for complete infrastructure setup.

**Execution order:**
1. `configure_operating_system` - OS-level configuration (Phase 1)
2. `configure_software` - Package management across all package managers (Phase 2)
3. `configure_users` - User preferences and development environments (Phase 3)

## Usage

### Basic Configuration
```yaml
- hosts: all
  become: true
  roles:
    - wolskies.infrastructure.system_setup
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

- `operating-system` - OS-level configuration
- `software` - Software package management
- `users` - User preferences and environments

## Dependencies

Orchestrates: `configure_operating_system`, `configure_software`, `configure_users`
