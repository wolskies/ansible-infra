# Ansible Tags Reference Guide

This document provides a comprehensive reference for all available tags in the `wolskinet.infrastructure` collection, allowing for selective execution of tasks and playbooks.

## Overview

Tags enable you to run specific subsets of tasks without executing entire playbooks or roles. This is particularly useful for:
- **Selective execution**: Run only specific functionality (e.g., just package updates)
- **Debugging**: Execute only diagnostic tasks
- **Maintenance**: Run only maintenance-related tasks
- **Skip functionality**: Exclude certain tasks (e.g., skip firewall configuration)

## Usage Examples

### Basic Tag Usage
```bash
# Run only package-related tasks
ansible-playbook playbook.yml --tags packages

# Run multiple tag categories
ansible-playbook playbook.yml --tags "packages,security,firewall"

# Skip specific functionality
ansible-playbook playbook.yml --skip-tags "firewall,users"

# Run only always-tagged tasks (critical tasks)
ansible-playbook playbook.yml --tags always

# List all available tags
ansible-playbook playbook.yml --list-tags
```

### Role-Specific Tag Usage
```bash
# Run only basic_setup role validation
ansible-playbook site.yml --tags "validation" --limit server_group

# Update packages across all roles
ansible-playbook site.yml --tags "packages,updates"

# Configure only Docker networks and volumes
ansible-playbook site.yml --tags "networks,volumes"
```

## Tag Categories by Role

### basic_setup Role

#### Core Tags
- `always` - Critical tasks that should always run (validation, debug info)
- `basic-setup` - All basic setup tasks
- `validation` - OS validation and compatibility checks
- `variables` - Variable loading and configuration
- `os-setup` - OS-specific setup tasks

#### Functional Tags
- `debug` - Debug output and informational messages
- `packages` - Package installation and management
- `security` - Security-related configurations
- `users` - User creation and management
- `sudo` - Sudo configuration
- `firewall` - Firewall setup (UFW/firewalld)
- `updates` - System updates and upgrades

#### Specific Tags
- `os-check` - Operating system compatibility validation
- `os-vars` - OS-specific variable loading
- `fallback` - Fallback configuration loading
- `user-creation` - User account creation tasks
- `system-config` - System configuration tasks
- `error-handling` - Error handling and recovery tasks
- `summary` - Summary and completion messages

#### Debian/Ubuntu Specific Tags
- `debian-ubuntu` - Debian/Ubuntu specific tasks
- `ufw` - UFW firewall configuration
- `package-install` - Package installation tasks
- `package-remove` - Package removal tasks
- `cleanup` - System cleanup tasks
- `upgrade` - System upgrade tasks
- `cache` - Package cache management
- `maintenance` - System maintenance tasks

### container_platform Role

#### Core Tags
- `always` - Critical Docker setup tasks
- `docker-setup` - All Docker setup tasks
- `validation` - Docker environment validation
- `install` - Docker installation tasks
- `config` - Docker configuration

#### Installation and Setup Tags
- `docker-install` - Docker engine installation
- `os-specific` - OS-specific installation tasks
- `service` - Docker service management
- `daemon` - Docker daemon configuration
- `systemd` - Systemd service configuration

#### User and Security Tags
- `users` - Docker user management
- `groups` - Docker group management
- `permissions` - Permission configuration
- `user-config` - User-specific configuration
- `registries` - Docker registry authentication
- `authentication` - Authentication and login
- `login` - Registry login tasks
- `security` - Security-related tasks

#### Infrastructure Tags
- `compose` - Docker Compose installation and setup
- `tools` - Docker tooling installation
- `symlink` - Symlink creation
- `download` - Download tasks
- `directories` - Directory structure creation
- `filesystem` - Filesystem operations

#### Networking and Storage Tags
- `networks` - Docker network management
- `networking` - Network configuration
- `volumes` - Docker volume management
- `storage` - Storage configuration
- `data-persistence` - Data persistence setup

#### Service Management Tags
- `services` - Docker service deployment
- `deployment` - Container deployment
- `containers` - Container management
- `workloads` - Workload deployment

#### Maintenance Tags
- `maintenance` - Docker maintenance tasks
- `cron` - Cron job setup
- `cleanup` - System cleanup
- `automation` - Automated tasks
- `logs` - Log management
- `logrotate` - Log rotation setup
- `disk-management` - Disk space management

#### Verification Tags
- `verification` - Installation and setup verification
- `debug` - Debug information and troubleshooting
- `summary` - Setup summary and completion status

### Infrastructure Discovery Utility

#### Core Discovery Tags
- `always` - Critical discovery tasks
- `setup` - Discovery environment setup
- `discovery` - Main discovery tasks
- `progress` - Progress indicators and status

#### System Discovery Tags
- `packages` - Package discovery and cataloging
- `services` - Service discovery
- `system-info` - System information gathering
- `facts` - Ansible facts gathering

#### Application Discovery Tags
- `docker` - Docker environment discovery
- `version` - Version information gathering
- `commands` - Command execution for discovery
- `host-info` - Host information gathering
- `containers` - Container discovery
- `workloads` - Workload discovery
- `networks` - Network discovery
- `networking` - Network configuration discovery
- `volumes` - Volume discovery
- `storage` - Storage discovery
- `compose` - Docker Compose discovery

#### User and Security Discovery Tags
- `users` - User account discovery
- `groups` - Group discovery
- `security` - Security configuration discovery
- `ssh` - SSH configuration discovery
- `sudo` - Sudo configuration discovery
- `firewall` - Firewall configuration discovery
- `ufw` - UFW firewall discovery
- `firewalld` - Firewalld discovery
- `fail2ban` - Fail2ban discovery
- `permissions` - Permission analysis

#### Environment Discovery Tags
- `desktop` - Desktop environment discovery
- `gui` - GUI environment detection
- `environment` - Environment variable discovery
- `x11` - X11 session detection
- `display` - Display configuration
- `wayland` - Wayland session detection
- `display-manager` - Display manager detection
- `detection` - General detection tasks
- `files` - File existence checks

#### Network Discovery Tags
- `network` - Network configuration discovery
- `interfaces` - Network interface discovery
- `routing` - Routing table discovery
- `ip-config` - IP configuration discovery
- `default-route` - Default route discovery
- `dns` - DNS configuration discovery
- `ports` - Port scanning and discovery

#### Development Discovery Tags
- `development` - Development environment discovery
- `tools` - Development tool discovery
- `package-managers` - Package manager discovery
- `editors` - Editor and IDE discovery
- `config-files` - Configuration file discovery
- `dotfiles` - Dotfiles discovery
- `shell-config` - Shell configuration discovery
- `app-config` - Application configuration discovery
- `window-managers` - Window manager discovery

#### macOS Specific Tags
- `homebrew` - Homebrew discovery
- `macos` - macOS-specific discovery
- `formulae` - Homebrew formulae discovery
- `casks` - Homebrew casks discovery

#### Output Generation Tags
- `generation` - Configuration generation
- `templates` - Template processing
- `reports` - Report generation
- `summary` - Summary generation

#### Error Handling Tags
- `error-handling` - Error handling and recovery
- `check-installation` - Installation verification

## Advanced Tag Usage

### Tag Inheritance and Blocking

Tags are inherited by tasks within blocks. Use this for logical grouping:

```yaml
- name: Security configuration
  block:
    - name: Configure firewall
      # This task has both 'security' and 'firewall' tags
    - name: Setup fail2ban
      # This task has both 'security' and 'fail2ban' tags
  tags:
    - security
```

### Conditional Tag Execution

Combine tags with conditionals for complex execution patterns:

```bash
# Only run on Ubuntu systems
ansible-playbook site.yml --tags "packages" --limit "ubuntu_hosts"

# Run security tasks but skip firewall on development machines
ansible-playbook site.yml --tags "security" --skip-tags "firewall" --limit "dev_group"
```

### Role-Specific Tag Targeting

```bash
# Run only Docker-related tasks across all roles
ansible-playbook site.yml --tags "docker,containers,networks,volumes"

# Run basic setup but skip user creation
ansible-playbook site.yml --tags "basic-setup" --skip-tags "users,user-creation"
```

## Tag Naming Conventions

### General Principles
- Use lowercase with hyphens for multi-word tags
- Use descriptive, clear names
- Group related functionality under similar tag prefixes
- Use specific tags for granular control

### Tag Hierarchies
- **Broad**: `security`, `packages`, `network`
- **Specific**: `firewall`, `package-install`, `network-config`
- **Very Specific**: `ufw`, `apt-packages`, `dns-config`

## Common Use Cases

### 1. Development and Testing
```bash
# Test only validation without making changes
ansible-playbook site.yml --tags "validation,debug" --check

# Run everything except user management
ansible-playbook site.yml --skip-tags "users,user-creation"
```

### 2. Maintenance Operations
```bash
# Update packages only
ansible-playbook site.yml --tags "updates,packages"

# Docker maintenance only
ansible-playbook site.yml --tags "maintenance,cleanup"
```

### 3. Security Hardening
```bash
# Run all security-related tasks
ansible-playbook site.yml --tags "security,firewall,sudo"

# Security without firewall changes
ansible-playbook site.yml --tags "security" --skip-tags "firewall"
```

### 4. Infrastructure Discovery
```bash
# Discover only package information
ansible-playbook discover.yml --tags "packages,system-info"

# Full discovery except Docker (for non-Docker hosts)
ansible-playbook discover.yml --skip-tags "docker,containers"

# Quick system overview
ansible-playbook discover.yml --tags "always,summary,progress"
```

### 5. Selective Service Deployment
```bash
# Deploy only Docker services
ansible-playbook site.yml --tags "services,deployment,containers"

# Setup infrastructure without service deployment
ansible-playbook site.yml --skip-tags "services,deployment"
```

## Best Practices

### 1. Always Use 'always' Tag for Critical Tasks
Critical tasks (validation, essential setup) should use the `always` tag to ensure they run even with tag filtering.

### 2. Tag Block Boundaries
Use tags on blocks rather than individual tasks when possible for cleaner organization.

### 3. Error Handling Tags
Include `error-handling` tags on rescue blocks for debugging failed runs.

### 4. Progress and Debug Tags
Use `debug` and `progress` tags for informational output that can be skipped in production.

### 5. Conditional Tag Application
Apply OS-specific tags (`debian-ubuntu`, `macos`) for platform-specific tasks.

## Tag Reference Quick Guide

| Category | Common Tags | Purpose |
|----------|-------------|---------|
| **Core** | `always`, `debug`, `summary` | Essential and informational tasks |
| **System** | `packages`, `updates`, `services` | System-level operations |
| **Security** | `security`, `firewall`, `users`, `sudo` | Security configuration |
| **Docker** | `docker-setup`, `containers`, `networks`, `volumes` | Docker ecosystem |
| **Discovery** | `discovery`, `system-info`, `config-files` | Infrastructure discovery |
| **Maintenance** | `maintenance`, `cleanup`, `logs` | System maintenance |
| **OS-Specific** | `debian-ubuntu`, `macos`, `archlinux` | Platform-specific tasks |

## Troubleshooting with Tags

### Common Issues and Solutions

1. **Task not running with expected tag**:
   ```bash
   ansible-playbook site.yml --tags "target-tag" --list-tasks
   ```

2. **Too many tasks running**:
   ```bash
   ansible-playbook site.yml --tags "specific-tag" --skip-tags "broad-tag"
   ```

3. **Finding tasks with specific functionality**:
   ```bash
   ansible-playbook site.yml --list-tags | grep -i "keyword"
   ```

This comprehensive tagging system provides fine-grained control over playbook execution while maintaining logical organization and clear naming conventions.