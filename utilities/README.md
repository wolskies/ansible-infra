# Infrastructure Discovery Utility

This utility scans existing machines and generates Ansible configuration files that can replicate those machines using the wolskinet.infrastructure collection.

## Overview

The discovery utility provides a streamlined approach to infrastructure replication:

1. **Essential Discovery** - Scans target machines for packages, services, and core configuration
2. **Host Variables Generation** - Creates OS-specific hierarchical variables
3. **Replication Playbooks** - Generates functional playbooks using basic_setup role
4. **Ansible Integration** - Output integrates with standard Ansible directory structure

## Architecture

Discovery generates variables that integrate seamlessly with the collection's hierarchical package system:

- **Discovery Output**: `host_packages_install_<Distribution>` variables in host_vars files
- **User Flexibility**: Can add `group_packages_install_<Distribution>` and `all_packages_install_<Distribution>`  
- **Hierarchical Merging**: All levels merge together automatically in basic_setup role
- **OS-Specific**: Package names are distribution-specific (Ubuntu vs Archlinux vs Darwin)

## Quick Start

### 1. Run Discovery on Target Machine

```bash
# Scan a single machine (adjust inventory as needed)
ansible-playbook -i "target-host," utilities/playbooks/discover-essential.yml --ask-become-pass
```

### 2. Review Generated Output

Discovery creates:

```
utilities/playbooks/
├── inventory/
│   └── host_vars/
│       └── target-host.yml     # OS-specific variables
└── playbooks/
    └── deploy-target-host.yml  # Replication playbook
```

### 3. Deploy to New Machine

```bash
# Use generated playbook to replicate configuration
ansible-playbook -i "new-host," utilities/playbooks/playbooks/deploy-target-host.yml
```

## What Gets Discovered

### System Information
- Operating system, distribution, version, architecture
- Memory, CPU cores, hostname, network configuration
- Primary network interface and IP address

### Package Discovery  
- **OS Packages**: Explicitly installed packages only (not dependencies)
  - Ubuntu/Debian: `apt-mark showmanual` 
  - Arch Linux: `pacman -Qqe`
  - macOS: `brew list --formulae`
- **AUR Packages**: Arch Linux user repository packages (`paru -Qm`)
- **Python Packages**: User pip packages only (`pip list --user`)
- **Node.js Packages**: Global npm packages (`npm list -g`, excluding system packages)

### System Configuration
- **Docker**: Installation detection for container_platform role
- **Shell**: Preferred shell configuration (zsh/bash)
- **Dotfiles**: Repository detection for dotfiles role

## Generated Files

### Host Variables File

```yaml
# utilities/playbooks/inventory/host_vars/web-01.yml
# System Information
ansible_user: "admin"
system_memory_mb: 8192
system_cpu_cores: 4
system_architecture: "x86_64"
primary_network_interface: "eth0"
primary_ip_address: "192.168.1.100"

# OS-specific packages (integrates with hierarchical system)
host_packages_install_Ubuntu:
  - nginx
  - redis-server
  - curl
  - git
  # ... all discovered packages

# Language-specific packages (for dedicated roles)
aur_packages:           # Handled by basic_setup (OS-specific)
  - paru
  - visual-studio-code-bin
  
pip_packages:           # For third_party_packages role (user packages only)
  - ansible-lint
  - black
  
npm_packages:           # For third_party_packages role (global CLI tools)
  - prettier
  - typescript

# System features
docker_detected: true
dotfiles_detected: true
detected_preferred_shell: "/usr/bin/zsh"

# Discovery metadata
discovery_completed_at: "2025-01-20T10:30:00Z"
discovery_source_os: "Ubuntu 24.04"
```

### Replication Playbook

```yaml
# utilities/playbooks/playbooks/deploy-web-01.yml
- name: Replicate discovered configuration for web-01
  hosts: web-01
  gather_facts: true
  become: true
  
  collections:
    - wolskinet.infrastructure
    - community.general
    - community.docker
    
  roles:
    # Core system setup with discovered packages
    - name: wolskinet.infrastructure.basic_setup
    
    # Container platform (Docker detected)
    - name: wolskinet.infrastructure.container_platform
      when: docker_detected | default(false)
    
    # Dotfiles (repository detected)  
    - name: wolskinet.infrastructure.dotfiles
      become: false
      when: dotfiles_detected | default(false)
    
    # System maintenance
    - name: wolskinet.infrastructure.maintenance
```

## Hierarchical Integration

Discovery variables integrate with the collection's hierarchical system:

### Discovery Output (Host Level)
```yaml
# Generated in host_vars/web-01.yml
host_packages_install_Ubuntu:
  - nginx
  - redis-server
  - curl
  # ... discovered packages
```

### User Additions (Group Level)
```yaml
# User creates group_vars/servers/Ubuntu.yml
group_packages_install_Ubuntu:
  - certbot
  - ufw
```

### User Additions (Global Level)
```yaml
# User creates group_vars/all/Ubuntu.yml  
all_packages_install_Ubuntu:
  - htop
  - vim
```

### Final Result
When basic_setup runs, it merges: **all** + **group** + **host** (discovery) = complete package list

## Usage Examples

### Basic Discovery and Replication

```bash
# 1. Discover existing Ubuntu server
ansible-playbook -i "prod-web-01," \
  utilities/playbooks/discover-essential.yml \
  --ask-become-pass

# 2. Review generated host_vars
cat utilities/playbooks/inventory/host_vars/prod-web-01.yml

# 3. Deploy to new server  
ansible-playbook -i "new-web-01," \
  utilities/playbooks/playbooks/deploy-prod-web-01.yml
```

### Discovery with Additional Hierarchical Packages

```bash
# 1. Run discovery (generates host-level packages)
ansible-playbook -i "workstation," utilities/playbooks/discover-essential.yml

# 2. Add group-level packages for all workstations
mkdir -p inventory/group_vars/workstations
cat > inventory/group_vars/workstations/Ubuntu.yml << EOF
group_packages_install_Ubuntu:
  - code
  - nodejs
  - python3-dev
EOF

# 3. Add global packages for all machines
mkdir -p inventory/group_vars/all  
cat > inventory/group_vars/all/Ubuntu.yml << EOF
all_packages_install_Ubuntu:
  - htop
  - vim
  - curl
EOF

# 4. Deploy with merged packages (discovery + group + all)
ansible-playbook -i inventory/hosts deploy-workstation.yml
```

### Cross-OS Package Mapping

Discovery is OS-specific, but users can map packages across distributions:

```bash
# 1. Discover Ubuntu machine
ansible-playbook -i "ubuntu-host," discover-essential.yml
# Generates: host_packages_install_Ubuntu

# 2. Create equivalent Arch packages manually
cat > inventory/host_vars/arch-host.yml << EOF
# Equivalent packages for Arch Linux
host_packages_install_Archlinux:
  - nginx        # (Ubuntu: nginx)  
  - redis        # (Ubuntu: redis-server)
  - curl         # (same)
  - git          # (same)
EOF

# 3. Deploy to Arch machine
ansible-playbook -i "arch-host," deploy-arch.yml
```

## Discovery Playbook Details

### Command Structure
```bash
ansible-playbook -i "<target>," utilities/playbooks/discover-essential.yml [options]
```

### Key Options
- `--ask-become-pass`: Prompt for sudo password (recommended)
- `-e discovery_output_host=<name>`: Override detected hostname
- `-v`: Verbose output for debugging

### Discovery Process
1. **System Detection**: OS, architecture, memory, network
2. **Package Scanning**: OS-specific package discovery commands
3. **Service Detection**: Docker, systemd services, shell configuration
4. **Template Generation**: Create host_vars and replication playbook
5. **File Output**: Write to utilities/playbooks/ directory structure

## Integration with Collection

### With basic_setup Role
Discovery generates `host_packages_install_<Distribution>` variables that basic_setup consumes automatically through hierarchical merging. Also detects AUR packages for Arch Linux.

### With third_party_packages Role
Discovery detects user-installed pip packages (via `pip list --user`) and globally installed npm packages, and includes the third_party_packages role in replication playbooks when these packages are found. It also identifies packages from third-party repositories and provides repository configuration guidance.

### With container_platform Role  
Discovery sets `docker_detected: true` when Docker is found, enabling conditional role inclusion in replication playbooks.

### With dotfiles Role
Discovery detects dotfiles repositories and sets `dotfiles_detected: true` for conditional role inclusion.

### With maintenance Role
All replication playbooks include the maintenance role for ongoing system updates.

## Supported Operating Systems

### Ubuntu/Debian
- Package discovery via `apt-mark showmanual`
- Detects explicitly installed packages only
- Generates `host_packages_install_Ubuntu` or `host_packages_install_Debian`

### Arch Linux  
- Package discovery via `pacman -Qqe` (explicit installs)
- AUR package detection via `paru -Qm` or `yay -Qm`
- Generates `host_packages_install_Archlinux`

### macOS
- Package discovery via `brew list --formulae` 
- Cask detection via `brew list --casks`
- Generates `homebrew_packages` and `homebrew_casks`

## Limitations

### What Cannot Be Discovered
1. **Sensitive Data**: Passwords, API keys, certificates
2. **Custom Configurations**: Application-specific settings  
3. **Manual Modifications**: Files changed outside package managers
4. **Network Configuration**: External DNS, firewall rules
5. **Service Dependencies**: Database connections, API endpoints

### Manual Steps After Discovery
1. **Review Variables**: Check generated host_vars for accuracy
2. **Add Secrets**: Use Ansible Vault for sensitive data
3. **Customize Hierarchy**: Add group/all level packages as needed
4. **Test Deployment**: Verify replication playbook works
5. **Update Inventory**: Integrate with existing Ansible structure

## Troubleshooting

### Permission Issues
```bash
# Test SSH access
ansible -i "target," all -m ping

# Test sudo access  
ansible -i "target," all -m setup -b --ask-become-pass
```

### Package Discovery Problems
```bash
# Check package manager access
ansible -i "target," all -m command -a "apt list --installed" -b  # Ubuntu
ansible -i "target," all -m command -a "pacman -Q" -b              # Arch
ansible -i "target," all -m command -a "brew list" -b              # macOS
```

### Output Issues
```bash
# Check discovery output directory
ls -la utilities/playbooks/inventory/host_vars/
ls -la utilities/playbooks/playbooks/

# Review discovery debug output
ansible-playbook -vv -i "target," discover-essential.yml
```

## Best Practices

### Before Discovery
1. Ensure SSH key authentication is working
2. Test sudo access with --ask-become-pass
3. Update package managers on target systems
4. Choose meaningful hostnames for inventory

### After Discovery
1. Review generated host_vars for completeness
2. Test replication playbook with --check --diff
3. Add hierarchical packages at group/all levels as needed
4. Version control the generated configurations
5. Document any manual post-deployment steps

### Regular Updates
1. Re-run discovery when systems change significantly
2. Keep discovery output in version control
3. Test replication playbooks against clean systems
4. Update hierarchical packages as needs evolve

## Example Workflows

### Development Machine Replication
```bash
# Discover development workstation
ansible-playbook -i "dev-machine," discover-essential.yml

# Add development-specific packages at group level
mkdir -p inventory/group_vars/developers
echo "group_packages_install_Ubuntu:" > inventory/group_vars/developers/Ubuntu.yml
echo "  - nodejs" >> inventory/group_vars/developers/Ubuntu.yml  
echo "  - python3-dev" >> inventory/group_vars/developers/Ubuntu.yml

# Replicate to new developer machine
ansible-playbook -i "new-dev," deploy-dev-machine.yml
```

### Server Infrastructure Discovery
```bash
# Discover production server
ansible-playbook -i "prod-web," discover-essential.yml

# Add server hardening packages  
mkdir -p inventory/group_vars/servers
echo "group_packages_install_Ubuntu:" > inventory/group_vars/servers/Ubuntu.yml
echo "  - fail2ban" >> inventory/group_vars/servers/Ubuntu.yml
echo "  - ufw" >> inventory/group_vars/servers/Ubuntu.yml

# Deploy to staging for testing
ansible-playbook -i "staging-web," deploy-prod-web.yml --check
```

## Output File Reference

Discovery creates these files in `utilities/playbooks/`:

```
utilities/playbooks/
├── inventory/
│   └── host_vars/
│       └── <hostname>.yml          # OS-specific hierarchical variables
└── playbooks/  
    └── deploy-<hostname>.yml       # Replication playbook with basic_setup
```

The generated files integrate with standard Ansible directory structure and can be moved to your main inventory as needed.