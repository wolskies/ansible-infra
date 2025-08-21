# Discovery Workflow Guide

## Overview

The discovery role is a neutral utility that captures the current state of existing machines without making organizational assumptions. It generates host-specific variables that you can then organize into your infrastructure as you see fit.

## Assumptions

- You're running from your Ansible home directory (where `ansible.cfg` is located)
- Standard directory structure: `inventory/`, `playbooks/`, etc.
- You have an existing inventory file with the target hosts

## Use Cases

### Use Case 1: Single Server Discovery

```bash
# 1. Create/update your inventory with the target server
echo "production_servers:" >> inventory/hosts.yml
echo "  hosts:" >> inventory/hosts.yml  
echo "    web-01:" >> inventory/hosts.yml
echo "      ansible_host: 192.168.1.100" >> inventory/hosts.yml

# 2. Run discovery against that specific host
ansible-playbook -i inventory/hosts.yml \
  --limit web-01 \
  collections/ansible_collections/wolskinet/infrastructure/utilities/playbooks/discover-infrastructure.yml

# 3. Discovery creates a neutral output structure:
# ✓ ./inventory/inventory.yml                ← Simple inventory with discovered host
# ✓ ./inventory/host_vars/web-01/settings.yml ← All discovered configuration
# ✓ ./inventory/playbooks/new_machine.yml    ← Template playbook (customize as needed)
```

### Use Case 2: Multiple Servers Discovery

```bash
# 1. Your existing inventory might look like:
# inventory/hosts.yml:
# production_servers:
#   hosts:
#     web-01:
#       ansible_host: 192.168.1.100
#     db-01:  
#       ansible_host: 192.168.1.101
#     cache-01:
#       ansible_host: 192.168.1.102

# 2. Run discovery against all hosts
ansible-playbook -i inventory/hosts.yml \
  collections/ansible_collections/wolskinet/infrastructure/utilities/playbooks/discover-infrastructure.yml

# 3. Discovery writes variables for each host:
# ✓ inventory/host_vars/web-01.yml          ← Web server vars
# ✓ inventory/host_vars/db-01.yml           ← Database server vars  
# ✓ inventory/host_vars/cache-01.yml        ← Cache server vars
# ✓ playbooks/deploy-web-01.yml             ← Per-host replication playbooks
# ✓ playbooks/deploy-db-01.yml
# ✓ playbooks/deploy-cache-01.yml
```

## Directory Structure Integration

### Before Discovery
```
~/ansible/
├── ansible.cfg
├── inventory/
│   ├── hosts.yml              ← Your existing inventory
│   ├── host_vars/
│   │   └── existing-host.yml  ← Your existing host vars
│   └── group_vars/
│       └── all.yml            ← Your existing global vars  
└── playbooks/
    └── site.yml               ← Your existing playbooks
```

### After Discovery  
```
~/ansible/
├── ansible.cfg
├── inventory/
│   ├── hosts.yml              ← Unchanged
│   ├── host_vars/
│   │   ├── existing-host.yml  ← Unchanged
│   │   └── web-01.yml         ← 🆕 Generated host vars
│   └── group_vars/
│       └── all.yml            ← Unchanged (no group vars generated)
├── playbooks/
│   ├── site.yml               ← Unchanged  
│   └── deploy-web-01.yml      ← 🆕 Functional replication playbook
└── discovery-output/          ← 📋 Reference files
    ├── web-01-profile.yml     ← Raw discovery data
    ├── web-01-secrets-template.yml ← Vault template
    └── DISCOVERY-REPORT.md    ← Analysis report
```

## Key Features

### ✅ Safe Integration
- **Never overwrites existing files** (uses backup for host_vars)
- **Writes directly to standard locations** (`inventory/host_vars/`, `playbooks/`)
- **Preserves your inventory structure** (doesn't create competing inventory files)
- **No group assumptions** (doesn't generate group_vars files)

### ✅ Standard Ansible Patterns
- **Host variables** go to `inventory/host_vars/{hostname}.yml` 
- **Playbooks** are functional replication tools in `playbooks/deploy-{hostname}.yml`
- **Uses collection roles** (`basic_setup`, `container_platform`, etc.)
- **Leverages variable precedence** (natural Ansible hierarchy)

### ✅ Multiple Host Support
- **Parallel discovery** across all hosts in inventory
- **Per-host outputs** (each gets its own host_vars file)  
- **Individual playbooks** (functional replication for each host)
- **Flexible grouping** (users organize hosts into groups as preferred)

## Variable Precedence Integration

Discovery generates variables using standard Ansible naming conventions:

```yaml
# inventory/host_vars/web-01.yml (generated)
# Standard variable names that work with collection roles
system_packages:
  - git
  - curl
  - python3
  - # ... all discovered packages
homebrew_packages:  # macOS only
  - node
  - go
  # ... discovered Homebrew packages
docker_detected: true  # If Docker was found

# Combine with your existing group_vars/all.yml
# inventory/group_vars/all.yml (your existing file)
system_packages:
  - htop  # Global baseline packages

# Result: htop + discovered packages (variable precedence at work)
# Basic_setup role merges: group_vars + host_vars automatically
```

## Next Steps After Discovery

1. **Review generated files** in `inventory/host_vars/{hostname}.yml`
2. **Test replication** with `ansible-playbook playbooks/deploy-{hostname}.yml`
3. **Create vault secrets** using `discovery-output/{host}-secrets-template.yml` if needed
4. **Organize into groups** - add discovered hosts to your preferred inventory groups
5. **Customize variables** - move variables to group_vars if they're common across hosts

## Replication Workflow

After discovery, you have a functional replication system:

```bash
# Run the generated replication playbook on a new machine
ansible-playbook -i inventory/ playbooks/deploy-web-01.yml

# The playbook uses wolskinet.infrastructure collection roles:
# - basic_setup: Installs discovered packages, configures system  
# - container_platform: Sets up Docker if it was detected
# - dotfiles: Configures dotfiles if repository was detected
# - maintenance: System updates and maintenance tools
```

The discovery workflow respects your existing Ansible practices and generates functional replication tools without imposing any group structure assumptions.