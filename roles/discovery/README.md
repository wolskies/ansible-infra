# Discovery Role

Automatically discovers installed packages, services, Docker containers, users, and system configuration from existing machines to generate Ansible inventory and deployment playbooks. This role is the foundation of infrastructure-as-code migration, allowing you to capture existing setups and recreate them consistently.

## Quick Start

```bash
# Basic discovery - outputs to ./inventory and ./playbooks
ansible-playbook playbooks/run-discovery.yml -i inventory/hosts.yml -l target-host
```

**Generated files:**
- `inventory/host_vars/target-host.yml` - Discovered configuration
- `playbooks/target-host_discovered.yml` - Ready-to-deploy playbook

## Core Features

### 🔍 **Comprehensive System Discovery**
- **Packages**: Native packages (apt/pacman/homebrew), language packages (pip/npm/cargo)
- **Services**: Docker containers with automatic role mapping
- **Users**: Account details, shells, groups, dotfiles repositories
- **System**: Configuration, repositories, security settings
- **Cross-platform**: Ubuntu 22+, Debian 12+, Arch Linux, macOS (Intel/Apple Silicon)

### 🎯 **Smart Package Filtering**
Automatically filters out noise to focus on user-installed software:
- Excludes system packages, drivers, kernels, base libraries
- Preserves explicitly installed user applications
- Distribution-specific intelligence (base groups, priority packages)

### 🐳 **Docker Service Intelligence**
- Scans configurable paths: `/opt`, `/srv`, `/home/*/docker`
- Maps container images to collection roles automatically:
  - `gitlab/gitlab-ce` → `gitlab` role
  - `jc21/nginx-proxy-manager` → `nginx_proxy_manager` role
  - `jellyfin/jellyfin` → `jellyfin` role
- Copies compose files and environment variables

### 👤 **User & Dotfiles Discovery**
- Detects user accounts, shells, group memberships
- Identifies dotfiles repositories and management tools
- Compatible with `basic_setup` and `dotfiles` role integration

## Usage Patterns

### Basic Discovery
```yaml
- name: Discover infrastructure
  hosts: target_machines
  roles:
    - wolskinet.infrastructure.discovery
```

### Custom Output Paths
```yaml
- name: Discovery with custom paths
  hosts: target_machines
  vars:
    discovery:
      inventory_dir: "/path/to/my/inventory"
      playbooks_dir: "/path/to/my/playbooks"
  roles:
    - wolskinet.infrastructure.discovery
```

### Selective Discovery with Tags
```bash
# Full discovery
ansible-playbook playbooks/run-discovery.yml -l target-host

# Only packages and Docker services
ansible-playbook playbooks/run-discovery.yml -l target-host --tags packages,docker

# Skip desktop environment detection
ansible-playbook playbooks/run-discovery.yml -l target-host --skip-tags desktop
```

## Configuration Options

### Docker Discovery
```yaml
# Override Docker search paths
discovery_docker_compose_paths:
  - "/opt/containers"
  - "/home/user/services"
  - "/srv/docker-compose"

# Add custom service mappings
discovery_docker_service_mapping:
  "myorg/custom-app": "custom_app_role"
  "postgres:15": "database_postgresql"
```

### Output Control
```yaml
discovery:
  generate_configs: true    # Generate playbooks and inventory
  timeout: 300             # Discovery task timeout (seconds)
  debug: false             # Enable detailed output
```

### Shell and Dotfiles Detection
```yaml
# Customize shell detection
discovery_shell_configuration:
  supported_shells: [/bin/bash, /bin/zsh, /usr/bin/fish]

# Dotfiles detection patterns
discovery_dotfiles_detection:
  repository_indicators: [.dotfiles, .config]
  management_tools: [Makefile, install.sh, stow]
```

## Generated Output Structure

### Host Variables (`inventory/host_vars/hostname.yml`)
```yaml
# Hierarchical package variables (for basic_setup merging)
host_packages_install_Ubuntu: [discovered, packages, list]
host_additional_repositories:
  apt:
    sources: ["deb [arch=amd64] https://..."]
    apt_keys: ["https://keyserver/key.gpg"]

# User configuration (for basic_setup user management)
discovered_users_config:
  - name: username
    uid: 1001
    shell: /bin/bash
    groups: [sudo, docker]
    dotfiles_repository_url: "https://github.com/user/dotfiles"
    dotfiles_uses_stow: true
    dotfiles_stow_packages: ["zsh", "git"]

# Docker services (for container_platform role)
install_docker_services:
  - role: gitlab
    name: gitlab-ce
    # ... service configuration
```

### Deployment Playbook (`playbooks/hostname_discovered.yml`)
Ready-to-use playbook with:
- Pre-configured role order and dependencies
- Host-specific variables from discovery
- Comments explaining customization options
- Integration with collection roles

## Integration Workflow

### 1. Discovery → Basic Setup
```bash
# Discover existing machine
ansible-playbook playbooks/run-discovery.yml -i inventory/hosts.yml -l source-host

# Deploy to new machine using discovered config
ansible-playbook playbooks/source-host_discovered.yml -i inventory/hosts.yml -l target-host
```

### 2. Role Integration
Discovery output maps directly to collection roles:

- **basic_setup**: Uses `host_packages_install_*`, `discovered_users_config`, `host_additional_repositories`
- **container_platform**: Uses `install_docker_services` with compose files
- **dotfiles**: Integrated via basic_setup when `install_dotfiles_support=true`
- **system_security**: Uses discovered firewall and security settings

### 3. Customization Workflow
1. **Discover**: Run discovery on source machine
2. **Review**: Examine generated `host_vars` and playbook
3. **Customize**: Modify variables, add group_vars, adjust roles
4. **Deploy**: Use generated playbook for consistent deployments
5. **Iterate**: Re-run discovery after changes, merge differences

## Advanced Features

### System Tuning Templates
Discovery generates commented system tuning templates:
```yaml
# Uncomment and customize for specific hardware
system_tuning:
  gaming:
    enabled: false
    kernel_params: ["mitigations=off"]
  gpu:
    nvidia_support: false
    amd_support: false
```

### Multi-Platform Support
- **Linux**: Full package and service discovery
- **macOS**: Homebrew packages, system preferences detection
- **Cross-platform**: Language packages (pip, npm, cargo, go)

### Security Considerations
- Read-only discovery (no system modifications)
- Safe for production - no password or sensitive data in output
- Preserves file permissions and ownership
- User discovery excludes authentication data

## Troubleshooting

### Common Issues
- **Permission denied**: Ensure SSH access and sudo privileges on target
- **Missing packages**: Some package managers require specific permissions
- **Docker access**: Discovery user needs docker group membership for container inspection
- **Output paths**: Verify write permissions to inventory and playbooks directories

### Debug Mode
```yaml
# Enable detailed discovery output
discovery:
  debug: true
```

### Selective Re-discovery
```bash
# Re-discover only specific components
ansible-playbook playbooks/run-discovery.yml -l host --tags packages
ansible-playbook playbooks/run-discovery.yml -l host --tags docker
```

## Requirements

- **Target System**: SSH access, Python 2.7+/3.6+
- **Discovery Machine**: Ansible 2.9+, network access to targets
- **Permissions**: Sudo access for comprehensive system inspection
- **Storage**: Write access to inventory and playbooks directories

---

**Next Steps**: After discovery, review generated files and customize the deployment playbook before running it against target machines.
