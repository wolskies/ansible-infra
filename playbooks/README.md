# Playbooks

Collection-level playbooks for the wolskies.infrastructure collection.

## Main Playbooks

- **configure_system.yml** - Full system configuration using all roles
- **run-discovery.yml** - Discover current system configuration

## Example Playbooks

- **setup-server-example.yml** - Example server setup
- **setup-workstation-example.yml** - Example workstation setup
- **example-host.yml.example** - Comprehensive example configuration
- **workstation.yml.example** - Legacy workstation example

## Testing Playbooks

- **test-hostname-config.yml** - Hostname configuration testing
- **test-hostname-scenarios.yml** - Hostname edge case testing
- **validate_vm_configuration.yml** - VM infrastructure validation

## Usage

```bash
# Run the main system configuration playbook
ansible-playbook -i inventory/hosts.yml playbooks/configure_system.yml

# Discover current system configuration
ansible-playbook -i inventory/hosts.yml playbooks/run-discovery.yml
```

## Note

Per Ansible Galaxy standards, playbooks should be at the collection level (not role level).
Role-specific testing should use molecule in `roles/<role-name>/molecule/`.
