# Discovery Role

Discovers installed packages, services, Docker containers, and system configuration from existing machines to generate Ansible host_vars and deployment playbooks.

## Usage

### Basic Discovery

```yaml
- name: Run infrastructure discovery
  hosts: target_hosts
  roles:
    - wolskinet.infrastructure.discovery
```

### Controlling Output Location

By default, discovery outputs to `./inventory` and `./playbooks` relative to where you run `ansible-playbook`. To control the output location:

```yaml
- name: Run infrastructure discovery with custom paths
  hosts: target_hosts
  vars:
    discovery:
      inventory_dir: "{{ playbook_dir }}/inventory"  # Output relative to playbook
      playbooks_dir: "{{ playbook_dir }}/playbooks" # Output relative to playbook
  roles:
    - wolskinet.infrastructure.discovery
```

Or use absolute paths:

```yaml
- name: Run infrastructure discovery to specific directory
  hosts: target_hosts
  vars:
    discovery:
      inventory_dir: "/home/{{ ansible_user }}/my-ansible/inventory"
      playbooks_dir: "/home/{{ ansible_user }}/my-ansible/playbooks"
  roles:
    - wolskinet.infrastructure.discovery
```

### Selective Discovery with Tags

```bash
# Full discovery
ansible-playbook discovery.yml

# Only packages and services
ansible-playbook discovery.yml --tags packages,services

# Skip desktop environment scanning
ansible-playbook discovery.yml --skip-tags desktop
```

### Available Tags

- `system` - Basic system information
- `packages` - Installed packages and repositories
- `services` - Running services and configurations
- `docker` - Docker containers and networks
- `users` - User accounts and shell configurations
- `dotfiles` - Dotfiles and configuration management
- `desktop` - Desktop environment and GUI applications
- `security` - Security configurations (firewall, SSH, etc.)

## Configuration

### Output Paths

By default, discovery outputs to (following standard Ansible directory layout):
- Host variables: `./inventory/host_vars/{hostname}.yml`
- Deployment playbook: `./playbooks/{hostname}_discovered.yml`

To use different paths (e.g., to match your ansible.cfg settings):

```yaml
- name: Run discovery with custom paths
  hosts: target_hosts
  vars:
    discovery:
      inventory_dir: "/path/to/your/inventory"
      playbooks_dir: "/path/to/your/playbooks"
  roles:
    - wolskinet.infrastructure.discovery
```

### Common Configurations

```yaml
# Standard Ansible layout (default)
discovery:
  inventory_dir: "./inventory"
  playbooks_dir: "./playbooks"

# Inventory in current directory (alternative layout)
discovery:
  inventory_dir: "."
  playbooks_dir: "./playbooks"

# Use absolute paths
discovery:
  inventory_dir: "/home/user/ansible/inventory"
  playbooks_dir: "/home/user/ansible/playbooks"
```

## Generated Files

1. **`inventory/host_vars/{hostname}.yml`** - Host-specific variables including:
   - Discovered packages list
   - Docker configuration
   - User settings
   - Service configurations

2. **`{hostname}_discovered.yml`** - Deployment playbook with:
   - Recommended roles based on discovered services
   - Comments for customization
   - Integration with collection roles

3. **`README_{hostname}_discovery.md`** - Discovery report with:
   - Summary of findings
   - File locations
   - Next steps

## Integration with Collection Roles

Discovery generates variables compatible with collection roles:

- `host_packages_install_{Distribution}` → `basic_setup` role
- `docker_*` variables → `container_platform` role  
- `dotfiles_*` variables → `dotfiles` role
- Security settings → `system_security` role

## Example Workflow

1. Run discovery on existing machine:
   ```bash
   ansible-playbook -i inventory.yml discovery.yml
   ```

2. Review generated files:
   ```bash
   # Check discovered configuration
   cat inventory/host_vars/server01.yml
   
   # Review deployment playbook
   cat playbooks/server01_discovered.yml
   ```

3. Deploy to new machine:
   ```bash
   # Customize the playbook first, then:
   ansible-playbook playbooks/server01_discovered.yml
   ```

## Requirements

- Target machine accessible via SSH
- Python installed on target
- Appropriate permissions for system inspection