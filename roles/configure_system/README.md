# configure_system

A convenience role for configuring a system - calls multiple roles in this collection.

## Description

## Role Execution Order

1. **os_configuration** - Essential OS-level configuration (timezone, hostname, services)
2. **manage_users** - System-level user account management
3. **manage_packages** - Distribution-specific package installation
4. **manage_security_services** - Firewall and fail2ban configuration
5. **manage_snap_packages** - Snap management (Ubuntu/Debian, optional)
6. **manage_flatpak** - Flatpak management (Linux, optional)
7. **configure_user** - Per-user preferences and dotfiles

## Configuration

See configure_system/defaults/main.yml for complete reference:

```yaml
domain_name: "company.com"
domain_timezone: "America/New_York"
users:
  - name: alice
    groups: [sudo]
    git: { user_name: "Alice", user_email: "alice@company.com" }
    nodejs: { packages: [typescript] }

host_hostname: "web01"
packages:
  present:
    all:
      Ubuntu: [git, curl, htop]
    group:
      Ubuntu: [nginx]
    host:
      Ubuntu: [redis-server]
firewall:
  enabled: true
  rules:
    - { port: 80, proto: tcp }
  snap:
    disable_and_remove: true
```

## Usage Examples

### Basic Server Setup

```yaml
- hosts: servers
  roles:
    - wolskies.infrastructure.configure_system
  vars:
    domain_name: "company.com"
    domain_timezone: "America/New_York"
    users:
      - name: admin
        groups: [sudo]
        ssh_pubkey: "ssh-ed25519 AAAAC3..."
    host_hostname: "{{ inventory_hostname }}"
    packages:
      present:
        all:
          Ubuntu: [git, htop, nginx]
```

### Multi-Group Configuration

```yaml
# inventory/group_vars/all.yml
domain_name: "company.local"
domain_timezone: "America/New_York"
users:
  - name: deploy
    groups: [sudo]
    git: { user_name: "Deploy User", user_email: "deploy@company.com" }
packages:
  present:
    all:
      Ubuntu: [git, curl, vim]

# inventory/group_vars/webservers.yml
packages:
  present:
    group:
      Ubuntu: [nginx, certbot]
firewall:
  enabled: true
  rules:
    - { port: 80, proto: tcp }
    - { port: 443, proto: tcp }

# inventory/host_vars/web01.yml
host_hostname: "web01"
packages:
  present:
    host:
      Ubuntu: [redis-server]
```

### User Configuration

After system setup, configure user preferences:

```yaml
# Configure user preferences (runs as each user)
- hosts: all
  vars:
    target_user: "{{ item }}"
  include_role:
    name: wolskies.infrastructure.configure_user
  loop: "{{ users }}"
  loop_control:
    loop_var: item
  when:
    - item.name is defined
    - item.name != 'root'
```

## Tags

### Component Tags

- `os-configuration` - OS setup only
- `security-services` - Firewall/fail2ban only
- `users` - User management only
- `packages` - Package management only
- `snap-packages` - Snap packages only
- `flatpak-packages` - Flatpak packages only
- `user-preferences` - User configuration only

### Usage

```bash
# Run only core system components
ansible-playbook -t os-configuration,users,packages playbook.yml

# Run only security configuration
ansible-playbook -t security-services playbook.yml

# Skip optional components
ansible-playbook --skip-tags snap-packages,flatpak-packages playbook.yml
```

## Architecture

### Non-Opinionated Group Structure

```yaml

[webservers]
web01
web02

[databases]
db01
db02

[all:vars]
infrastructure.domain.name=company.com
```

### Distribution Detection

Roles use `{{ ansible_distribution }}` and `{{ ansible_os_family }}` facts for OS-specific behavior within the unified variable structure.

## Dependencies

Required roles (all included in collection):

- `wolskies.infrastructure.os_configuration`
- `wolskies.infrastructure.manage_users`
- `wolskies.infrastructure.manage_packages`
- `wolskies.infrastructure.manage_security_services`
- `wolskies.infrastructure.manage_snap_packages`
- `wolskies.infrastructure.manage_flatpak`
- `wolskies.infrastructure.configure_user`

## License

MIT
