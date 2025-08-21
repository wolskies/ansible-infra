# Infrastructure Discovery Utility

This utility scans existing machines and generates Ansible configuration files that can replicate those machines using the wolskinet.infrastructure collection.

## Overview

The discovery utility consists of:

1. **Discovery Playbook** - Scans target machines and analyzes their configuration
2. **Configuration Generator** - Creates inventory, group_vars, host_vars, and playbooks
3. **Validation Playbook** - Compares generated configs against original machines
4. **Comprehensive Reporting** - Detailed analysis and recommendations

## Quick Start

### 1. Discover Infrastructure

```bash
# Create temporary inventory for existing machines
cat > temp-inventory.yml << EOF
existing_machines:
  hosts:
    arch-workstation:
      ansible_host: 192.168.1.50
    ubuntu-server:
      ansible_host: 192.168.1.51
EOF

# Run discovery
ansible-playbook -i temp-inventory.yml \
  utilities/playbooks/discover-infrastructure.yml
```

### 2. Review Generated Configuration

The discovery process creates:

```
discovered-infrastructure/
├── inventory.yml                    # Generated inventory with detected groups
├── host_vars/
│   ├── arch-workstation.yml        # Host-specific variables
│   └── ubuntu-server.yml
├── group_vars/
│   ├── servers.yml                  # Group configurations
│   ├── workstations.yml
│   └── archlinux_hosts.yml
├── replicate-arch-workstation.yml  # Replication playbooks
├── replicate-ubuntu-server.yml
├── arch-workstation-profile.yml    # Raw discovery data
├── ubuntu-server-profile.yml
└── DISCOVERY-REPORT.md             # Comprehensive analysis
```

### 3. Configure Secrets

```bash
# Set up vault password
echo "your-secure-vault-password" > ~/.ansible-vault-pass
chmod 600 ~/.ansible-vault-pass

# Create encrypted secrets file
ansible-vault create discovered-infrastructure/group_vars/all/vault.yml
```

### 4. Test and Deploy

```bash
# Validate generated configuration
ansible-playbook -i discovered-infrastructure/inventory.yml \
  utilities/playbooks/validate-discovery.yml

# Deploy to new machines
ansible-playbook -i discovered-infrastructure/inventory.yml \
  discovered-infrastructure/replicate-arch-workstation.yml
```

## Detailed Usage

### Discovery Options

The discovery playbook supports several configuration options:

```yaml
# In your playbook or as extra vars
vars:
  discovery_output_dir: "./my-infrastructure"  # Output directory
  generate_configs: true                       # Generate config files
  include_sensitive: false                     # Include user hashes (use vault!)
```

### What Gets Discovered

#### System Information
- OS, distribution, version, architecture
- Memory, CPU, Python version
- Network interfaces and IP addresses
- Hostname and FQDN

#### Software Configuration
- Installed packages (all package managers)
- Running and enabled services
- Docker containers, networks, volumes
- Homebrew packages and casks (macOS)

#### Development Environment
- Development tools (git, docker, code, etc.)
- Dotfiles repository detection
- Shell configuration (zsh, bash)
- Desktop environment detection

#### Security Configuration
- Firewall status (UFW, firewalld)
- SSH configuration analysis
- User account enumeration
- Service security posture

### Machine Classification

The discovery utility automatically classifies machines into groups:

#### Servers
**Criteria:** SSH service running + no GUI detected
**Configuration:**
- Security hardening enabled
- Firewall configuration
- Automatic updates
- Service monitoring

#### Docker Hosts  
**Criteria:** Docker installed and running
**Configuration:**
- Docker service management
- Container deployment
- Network and volume management
- Registry authentication

#### Workstations
**Criteria:** GUI desktop environment detected
**Configuration:**
- Desktop environment setup
- Development tools
- Dotfiles management
- User-friendly configurations

### Generated Configurations

#### Inventory Structure
```yaml
# Auto-generated based on discovered characteristics
servers:
  hosts:
    ubuntu-server:
      ansible_host: UPDATE_WITH_ACTUAL_IP

docker_hosts:
  hosts:
    ubuntu-server:  # Can be in multiple groups

workstations:
  hosts:
    arch-workstation:
      ansible_host: UPDATE_WITH_ACTUAL_IP

ubuntu_hosts:
  hosts:
    ubuntu-server:

archlinux_hosts:
  hosts:
    arch-workstation:
```

#### Host Variables
```yaml
# host_vars/ubuntu-server.yml
ansible_user: "admin"
system_memory_mb: 8192
system_cpu_cores: 4
primary_network_interface: "eth0"

# Docker configuration (if detected)
docker_detected: true
discovered_containers:
  - "nginx:latest"
  - "postgres:13"

# Development tools (if detected)
development_tools_detected:
  - "git"
  - "docker"
  - "code"
```

#### Group Variables
```yaml
# group_vars/docker_hosts.yml
group_roles_install:
  - basic_setup
  - maintenance
  - container_platform

docker_services_deploy:
  - portainer      # Based on discovered containers
  - nginx-proxy
  - monitoring

docker_users:
  - "{{ ansible_user }}"
```

## Advanced Features

### Custom Discovery Logic

You can extend the discovery playbook with custom tasks:

```yaml
# Add to discover-infrastructure.yml
- name: Custom application discovery
  ansible.builtin.shell: |
    if systemctl is-active --quiet myapp; then
      echo "myapp_installed=true"
    fi
  register: custom_discovery
  changed_when: false

- name: Include custom discovery in profile
  ansible.builtin.set_fact:
    discovery_profile: "{{ discovery_profile | combine({'custom': {'myapp': custom_discovery.stdout}}) }}"
```

### Template Customization

Modify the Jinja2 templates to customize generated configurations:

```jinja2
{# roles/discovery/templates/discovered-host-vars.yml.j2 #}
# Add custom variables based on discovery
{% if 'nginx' in discovery_profile.services.running %}
web_server_detected: true
web_server_type: "nginx"
{% endif %}
```

### Validation Customization

Extend the validation playbook for specific requirements:

```yaml
# Add to validate-discovery.yml
- name: Validate custom application
  ansible.builtin.uri:
    url: "http://localhost:8080/health"
  register: app_health
  when: discovery_profile.custom.myapp | default(false)
```

## Integration Patterns

### CI/CD Integration

```yaml
# .github/workflows/infrastructure-sync.yml
name: Infrastructure Sync
on:
  schedule:
    - cron: '0 2 * * 0'  # Weekly

jobs:
  discover:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Discover infrastructure changes
        run: |
          ansible-playbook -i production-inventory.yml \
            utilities/playbooks/discover-infrastructure.yml
      - name: Check for changes
        run: |
          if git diff --quiet; then
            echo "No infrastructure changes detected"
          else
            echo "Infrastructure changes detected"
            git add discovered-infrastructure/
            git commit -m "Update infrastructure discovery"
            git push
          fi
```

### Multi-Environment Discovery

```bash
# Discover multiple environments
for env in dev staging prod; do
  ansible-playbook -i inventories/${env}/inventory.yml \
    utilities/playbooks/discover-infrastructure.yml \
    -e discovery_output_dir="./discovered-${env}"
done
```

### Selective Discovery

```bash
# Discover only specific host groups
ansible-playbook -i inventory.yml \
  utilities/playbooks/discover-infrastructure.yml \
  --limit docker_hosts

# Discover with custom output
ansible-playbook -i inventory.yml \
  utilities/playbooks/discover-infrastructure.yml \
  -e discovery_output_dir="./docker-infrastructure" \
  -e generate_configs=true
```

## Troubleshooting

### Common Issues

#### Permission Errors
```bash
# Ensure proper SSH access
ansible all -i temp-inventory.yml -m ping

# Check sudo privileges
ansible all -i temp-inventory.yml -m setup -b
```

#### Docker Discovery Fails
```bash
# Verify Docker access
ansible docker_hosts -i temp-inventory.yml \
  -m command -a "docker --version" -b
```

#### Incomplete Package Discovery
```bash
# Update package cache first
ansible all -i temp-inventory.yml \
  -m package -a "update_cache=yes" -b
```

### Debug Mode

Enable verbose output for troubleshooting:

```bash
ansible-playbook -vvv -i inventory.yml \
  utilities/playbooks/discover-infrastructure.yml
```

### Manual Profile Review

Examine raw discovery data:

```bash
# View discovery profile
cat discovered-infrastructure/hostname-profile.yml

# Check specific sections
yq '.docker' discovered-infrastructure/hostname-profile.yml
yq '.services.running' discovered-infrastructure/hostname-profile.yml
```

## Limitations

### What Cannot Be Discovered

1. **Sensitive Data**: Passwords, API keys, private keys
2. **Custom Configurations**: Application-specific settings
3. **Historical Data**: Changes made since last boot
4. **External Dependencies**: DNS, load balancer configurations
5. **Business Logic**: Application workflows and processes

### Manual Configuration Required

After discovery, you must still:

1. Configure vault secrets
2. Set up SSH key authentication  
3. Review and adjust firewall rules
4. Validate application configurations
5. Test service dependencies

## Best Practices

### Regular Discovery

Run discovery regularly to keep configurations updated:

```bash
# Monthly discovery
ansible-playbook -i inventory.yml \
  utilities/playbooks/discover-infrastructure.yml \
  -e discovery_output_dir="./discovery-$(date +%Y-%m)"
```

### Version Control

Track discovery results in version control:

```bash
git add discovered-infrastructure/
git commit -m "Infrastructure discovery - $(date)"
git tag "discovery-$(date +%Y%m%d)"
```

### Documentation

Always review the generated `DISCOVERY-REPORT.md`:

1. Verify machine classifications
2. Review missing role recommendations  
3. Check security configurations
4. Validate network settings

### Testing

Test generated configurations in development:

```bash
# Deploy to test environment first
ansible-playbook -i test-inventory.yml \
  discovered-infrastructure/replicate-hostname.yml \
  --check --diff
```

## Security Considerations

### Data Safety

The discovery utility is designed to be safe:

- ✅ No sensitive data captured
- ✅ No modifications made to target systems
- ✅ Read-only operations only
- ✅ Local file generation

### Access Requirements

Discovery requires:

- SSH access to target machines
- Sudo privileges for system information
- Docker access (if detecting containers)
- Package manager access

### Output Security

Secure the generated configurations:

```bash
# Set proper permissions
chmod 700 discovered-infrastructure/
chmod 600 discovered-infrastructure/host_vars/*
chmod 600 discovered-infrastructure/group_vars/*

# Use vault for any sensitive additions
ansible-vault encrypt discovered-infrastructure/group_vars/all/vault.yml
```

## Examples

See the `examples/` directory for complete usage examples:

- `examples/discovery-scenarios/` - Different discovery use cases
- `examples/integration/` - CI/CD integration examples  
- `examples/validation/` - Custom validation scenarios

## Support

For issues with the discovery utility:

1. Check the troubleshooting section above
2. Review generated logs and reports
3. Submit issues with discovery profiles attached
4. Include target OS and environment details