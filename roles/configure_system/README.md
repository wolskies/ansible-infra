# Configure System Role

Master orchestration role for complete new machine setup.

## Purpose

Executes system configuration roles in order:
1. OS Configuration - Basic system setup (hostname, NTP, locale)
2. Security Services - Install and enable firewall, fail2ban
3. User Management - Create users and groups  
4. Package Management - Install system packages
5. Third-party Tools - Install development tools

## Usage

### Complete Setup
```yaml
- hosts: new_servers
  roles:
    - role: wolskinet.infrastructure.configure_system
      vars:
        config_common_hostname: "{{ inventory_hostname }}"
        config_common_domain: "example.com"
        users_config:
          - name: admin
            groups: [sudo, docker]
        all_packages_install_Ubuntu:
          - git
          - htop
          - nginx
        manage_third_party_tools:
          docker: true
```

### Selective Execution
```yaml
# Run only OS configuration and users
- hosts: servers
  roles:
    - role: wolskinet.infrastructure.configure_system
      tags: [os-configuration, users]

# Skip third-party tools
- hosts: servers  
  roles:
    - role: wolskinet.infrastructure.configure_system
      tags: [os-configuration, users, packages]
```

## Variables

All variables are passed through to individual roles:

- **OS Configuration**: `config_common_*`, `config_linux_*`, `config_ubuntu_*`
- **User Management**: `users_config`
- **Package Management**: `all_packages_install_*`, `group_packages_install_*`
- **Third-party Tools**: `manage_third_party_*`

See individual role documentation for complete variable lists.

## Tags

- `os-configuration` - OS setup only
- `users` - User management only
- `packages` - Package installation only
- `third-party` - Third-party tools only
- `configure-system` - All phases

## Alternative Approach

Use individual roles for maximum control:

```yaml
- hosts: servers
  roles:
    - wolskinet.infrastructure.os_configuration
    - wolskinet.infrastructure.manage_users
    - wolskinet.infrastructure.manage_packages
```