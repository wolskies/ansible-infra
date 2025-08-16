# Ansible Collection - wolskinet.infrastructure

A comprehensive collection of Ansible roles for infrastructure management across multiple operating systems including Ubuntu 24+, Debian 12/13, Arch Linux, and macOS.

## Description

This collection provides a set of roles designed to automate the setup and maintenance of infrastructure components across different operating systems. It follows an **inventory-group-based architecture** where different types of machines (servers, docker_hosts, workstations) are configured through group membership, enabling modular and extensible infrastructure management.

## Architecture Overview

The collection is designed around the concept of **configuring machines by inventory group**:

- **`servers`**: Get security hardening + basic setup + system maintenance
- **`docker_hosts`**: Inherit server configuration + add Docker installation + configurable container services  
- **`workstations`**: Get basic setup + dotfiles + desktop-specific configurations
- **Custom groups**: Users can define their own groups with specific role combinations

### Key Principles

1. **Group-Based Configuration**: Machines are configured based on their inventory group membership
2. **Modular Roles**: Each role handles a specific aspect (basic setup, Docker, security, etc.)
3. **Extensible Design**: Users can easily add roles from other collections or create custom roles
4. **Building Blocks**: Roles are designed to be combined and layered for complex configurations

## Supported Operating Systems

- **Ubuntu**: 24.04 LTS and newer
- **Debian**: 12 (Bookworm), 13 (Trixie)  
- **Arch Linux**: Latest rolling release
- **macOS**: Latest versions

## Python Support

All roles support **Python 3.13** as the primary version, with fallbacks to system Python where appropriate.

## Included Roles

### wolskinet.infrastructure.basic_setup
**Minimal, essential foundation** for all machine types:
- Essential packages only (git, curl, build tools, Python, package managers)
- OS-specific feature management (snap removal, AUR helper, Homebrew setup)
- User management and system optimization
- Hierarchical variable integration with discovery system
- Predictable starting point across all supported operating systems

*For additional packages beyond essentials, use the extra_packages role*

### wolskinet.infrastructure.extra_packages
**Additional package management beyond basic_setup essentials**:
- User-defined packages from inventory variables (group_vars, host_vars)
- Discovery-found packages from infrastructure scanning
- Category-based control (development, desktop, media packages)
- Cross-platform language package support (pip, npm, AUR, Homebrew)
- Repository management for additional package sources
- Safe failure handling and fine-grained control

### wolskinet.infrastructure.firewall
**Cross-platform firewall port management**:
- UFW management (Ubuntu/Debian) and firewalld (Arch Linux)
- Centralized port configuration for service roles
- Handler-based efficient firewall reloads
- Integration with Docker service registry
- Works with basic_setup's firewall installation

### wolskinet.infrastructure.docker_setup
Docker infrastructure management:
- Docker and Docker Compose installation
- Container service deployment
- Network and volume management
- Registry authentication
- Service templates (Portainer, Nginx Proxy, Monitoring)

### wolskinet.infrastructure.system_update  
System maintenance and updates:
- Package updates for each OS
- Dotfiles management via Git
- Custom tool installations (starship, oh-my-posh, uv)

### wolskinet.infrastructure.dotfiles
Dotfiles management:
- Git-based dotfiles repository cloning/updating
- Symlink management using GNU Stow
- Shell configuration (zsh, zinit, etc.)

## Installation

### From Ansible Galaxy

```bash
ansible-galaxy collection install wolskinet.infrastructure
```

### From Source

```bash
git clone https://github.com/wolskinet/ansible-infrastructure.git
cd ansible-infrastructure
ansible-galaxy collection build
ansible-galaxy collection install wolskinet-infrastructure-*.tar.gz
```

## Quick Start

### 1. Create Inventory Structure

The inventory defines machine groups and their purposes:

```yaml
# inventory.yml
servers:
  hosts:
    web-server:
      ansible_host: 192.168.1.20
    db-server:
      ansible_host: 192.168.1.21

docker_hosts:
  hosts:
    docker-01:
      ansible_host: 192.168.1.30
    docker-02:
      ansible_host: 192.168.1.31

workstations:
  hosts:
    ubuntu-desktop:
      ansible_host: 192.168.1.10
    macbook-pro:
      ansible_host: 192.168.1.11
```

### 2. Configure Group Variables

Each group gets specific role combinations:

```yaml
# group_vars/all.yml
ansible_user: 'admin'
config_system_timezone: 'America/New_York'

user_details:
  - name: 'admin'
    uid: 1000
    gid: 1000
    password: '$6$EXAMPLE_REPLACE_WITH_REAL_HASH$'
```

```yaml
# group_vars/servers.yml - Hardened servers
group_roles_install:
  - basic_setup
  - system_update
security_hardening_enabled: true
enable_firewall: true

# group_vars/docker_hosts.yml - Docker infrastructure  
group_roles_install:
  - basic_setup
  - system_update
  - docker_setup
docker_services_deploy:
  - portainer
  - nginx-proxy
  - monitoring

# group_vars/workstations.yml - Desktop machines
group_roles_install:
  - basic_setup
  - dotfiles
  - system_update
install_dotfiles: true
```

### 3. Configure Host-Specific Variables

```yaml
# host_vars/ubuntu-desktop.yml
primary_network_interface: "enp0s3"
gpu_driver: "nvidia"
display_manager: "gdm3"
```

```yaml
# host_vars/macbook-pro.yml
homebrew_user: "{{ ansible_user }}"
dev_tools:
  - xcode
  - homebrew
```

### 4. Run Playbooks

```bash
# Setup all infrastructure
ansible-playbook -i inventory.yml examples/playbooks/deploy-full-infrastructure.yml

# Setup servers only
ansible-playbook -i inventory.yml examples/playbooks/setup-servers.yml

# Setup Docker hosts only  
ansible-playbook -i inventory.yml examples/playbooks/setup-docker-hosts.yml
```

## Extended Usage Patterns

### Adding External Collections

The collection is designed to work seamlessly with other collections:

```yaml
# group_vars/docker_hosts.yml
additional_roles_install:
  - name: "community.docker.docker_compose"
    become: true
    when: "{{ ansible_distribution == 'Ubuntu' }}"
  - name: "devsec.hardening.docker_hardening"
    become: true
    vars:
      docker_security_level: "high"
```

### Custom Role Integration

Add your own roles alongside collection roles:

```yaml
# group_vars/web_servers.yml
group_roles_install:
  - basic_setup
  - docker_setup

additional_roles_install:
  - name: "my_company.web.nginx"
    become: true
  - name: "my_company.monitoring.agent"
    become: true
    vars:
      monitoring_endpoint: "https://monitoring.company.com"
```

### Service-Specific Configurations

Define Docker services with custom configurations:

```yaml
# group_vars/docker_hosts.yml
docker_services_deploy:
  - portainer
  - nginx-proxy
  - custom-app

# Custom service template at templates/services/custom-app.yml.j2
service_configs:
  custom-app:
    image: "mycompany/app:latest"
    environment:
      DATABASE_URL: "{{ vault_database_url }}"
      API_KEY: "{{ vault_api_key }}"
```

## Role Details

### Basic Setup Role

The `basic_setup` role handles fundamental system configuration:

**Variables:**
- `user_details`: List of users to create
- `config_system_timezone`: System timezone
- `config_system_locale`: System locale

**OS-Specific Packages:**
- **Ubuntu 24+**: Includes snapd, python3.13, build-essential
- **Debian 12/13**: Includes python3.11, development tools
- **Arch Linux**: Latest packages including AUR support
- **macOS**: Homebrew packages and casks

### System Update Role

Handles system maintenance across all platforms:

**Features:**
- OS-appropriate package managers (apt, pacman, homebrew)
- Dotfiles repository management
- Custom tool installations
- Python 3.13 environment setup

### Dotfiles Role

Manages personal configuration files:

**Features:**
- Git repository cloning/updating
- GNU Stow for symlink management
- Shell configuration (zsh, oh-my-zsh, starship)
- Cross-platform compatibility

## Advanced Configuration

### Multi-OS Support

The collection automatically detects the operating system and loads appropriate variables:

1. OS-specific vars: `vars/{{ ansible_distribution }}.yml`
2. Fallback to OS family: `vars/{{ ansible_os_family }}.yml`

### Version Validation

Roles include validation to ensure supported OS versions:

```yaml
- name: Validate supported OS versions
  ansible.builtin.fail:
    msg: "{{ ansible_distribution }} {{ ansible_distribution_version }} is not supported"
  when:
    - (ansible_distribution == "Ubuntu" and ansible_distribution_major_version | int < 24) or
      (ansible_distribution == "Debian" and ansible_distribution_major_version | int < 12)
```

### Inventory Organization

**Host Variables (`host_vars/`):**
- Machine-specific configurations
- Network interface names
- Hardware-specific settings
- Display/GPU configurations

**Group Variables (`group_vars/`):**
- Role assignments per group
- Service configurations
- Common group settings

## Example Playbooks

The collection includes example playbooks in `examples/playbooks/`:

- `setup-new-machine.yml` - Complete system setup
- `update-systems.yml` - System updates and maintenance  
- `workstation-setup.yml` - Desktop environment configuration

## Security and Secrets Management

**Important**: This collection is designed to work with Ansible Vault for managing sensitive data. Never commit passwords, API keys, or private repository URLs directly to your inventory files.

### Quick Security Setup

1. **Configure your dotfiles repository**:
   ```yaml
   # In group_vars/all/vars.yml or host_vars/
   dotfiles_repository_url: "https://github.com/yourusername/dotfiles.git"
   # Or for private repositories with SSH:
   dotfiles_repository_url: "git@github.com:yourusername/private-dotfiles.git"
   ```

2. **Use Ansible Vault for sensitive data**:
   ```bash
   # Create encrypted secrets file
   ansible-vault create group_vars/all/vault.yml
   ```

3. **Reference vault variables**:
   ```yaml
   # In vault.yml (encrypted)
   vault_user_password: "$6$your_real_password_hash$"
   
   # In vars.yml (plain)
   user_details:
     - name: 'admin'
       password: "{{ vault_user_password }}"
   ```

**📖 For complete secrets management guide, see: [docs/vault-secrets-guide.md](docs/vault-secrets-guide.md)**

## Dependencies

### Required Collections
- `devsec.hardening` (for security hardening)
- `community.general` (for additional modules)

### Python Requirements
- Python 3.13 (preferred) or system Python
- pip, venv support

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Submit a pull request

## License

GPL-3.0-or-later

## Author Information

Created by Ed Wolski (ed@wolskinet.com)

## Support

- Issues: https://github.com/wolskinet/ansible-infrastructure/issues
- Documentation: https://github.com/wolskinet/ansible-infrastructure