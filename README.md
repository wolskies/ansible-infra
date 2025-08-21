# Ansible Collection - wolskinet.infrastructure

Infrastructure automation collection for Ubuntu 24+, Debian 12+, Arch Linux, and macOS using inventory-group-based architecture.

## Architecture

**Group-Based Configuration**: Machines are configured by inventory group membership:
- `servers`: Security hardening + basic setup + maintenance  
- `docker_hosts`: Server features + Docker + container services
- `workstations`: Basic setup + dotfiles + desktop configurations

**Hierarchical Package Variables**: Uses Ansible's variable precedence for OS-specific packages:
1. `all_packages_install_<Distribution>` (group_vars/all)
2. `group_packages_install_<Distribution>` (group_vars/<group>)  
3. `host_packages_install_<Distribution>` (host_vars/<host>)

All lists merge with duplicates removed. Package names are distribution-specific.

## Roles

- **basic_setup**: Essential foundation (packages, users, firewall install)
- **container_platform**: Docker infrastructure management
- **system_security**: Firewall + fail2ban (use with devsec.hardening for SSH/OS)
- **maintenance**: System updates and cleanup
- **dotfiles**: Git-based dotfiles with Stow
- **discovery**: Scan existing machines, generate host_vars
- **system_tuning**: Performance and hardware optimization

## Installation

```bash
ansible-galaxy collection install wolskinet.infrastructure
```

## Quick Start

```yaml
# inventory.yml
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
    ubuntu-desktop:
      ansible_host: 192.168.1.10
```

```yaml
# group_vars/all/Ubuntu.yml
all_packages_install_Ubuntu:
  - git
  - htop
  - vim

# group_vars/servers/Ubuntu.yml  
group_packages_install_Ubuntu:
  - nginx
  - fail2ban
```

```yaml
# site.yml
- hosts: all
  roles:
    - wolskinet.infrastructure.basic_setup

- hosts: docker_hosts
  roles:
    - wolskinet.infrastructure.container_platform

- hosts: servers
  roles:
    - devsec.hardening.os_hardening
    - devsec.hardening.ssh_hardening
    - wolskinet.infrastructure.system_security
```

## Discovery Workflow

```bash
# Scan existing machine
ansible-playbook -i existing-server, playbooks/run-discovery.yml

# Review generated files in ./inventory/
# Copy relevant configs to your inventory
# Deploy to new machines
ansible-playbook -i inventory.yml site.yml
```

## Security Integration

This collection complements devsec.hardening:
- Use `devsec.hardening.os_hardening` for OS-level security
- Use `devsec.hardening.ssh_hardening` for SSH security  
- Use `wolskinet.infrastructure.system_security` for firewall + fail2ban

## Variable Examples

```yaml
# Docker host configuration
docker_users:
  - deploy
container_services:
  - portainer
  - nginx-proxy

# Firewall configuration  
firewall_allowed_ports:
  - "22"
  - "80"
  - "443"
firewall_custom_rules:
  - port: 3306
    protocol: tcp
    source: "10.0.1.0/24"

# Dotfiles configuration
dotfiles_repository_url: "https://github.com/user/dotfiles"
dotfiles_method: "stow"
```

## Dependencies

Required collections:
- `community.general`
- `ansible.posix`

Recommended for comprehensive security:
- `devsec.hardening`

## License

MIT