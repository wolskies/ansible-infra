# manage_snap_packages

Comprehensive snap package management for Ubuntu and Debian systems. Supports installing, removing, or completely purging snap packages from the system.

## Description

This role provides complete snap package lifecycle management:

- **Install**: Set up snapd and install snap packages (regular and classic)
- **Remove**: Remove snap packages while keeping the system intact
- **Purge**: Complete snap removal including services, directories, and PATH cleanup

The role includes safety mechanisms for destructive operations and supports both individual package management and system-wide snap removal.

## Features

- **📦 Package Management**: Install/remove individual snap packages
- **🗑️ Complete Purge**: Comprehensive snap system removal
- **🔒 Safety Controls**: Confirmation required for destructive operations
- **🛠️ Service Management**: Proper snapd service handling
- **🧹 System Cleanup**: Directory and PATH cleanup
- **🏷️ Tag-Based Control**: Fine-grained execution control

## Role Variables

See `defaults/main.yml` for complete configuration options.

### Basic Configuration

```yaml
snap_management_action: "remove"            # "install", "remove", "purge"
```

### Remove/Purge Options

```yaml
snap_remove_all_packages: true              # Remove all installed snap packages
snap_disable_services: true                 # Stop and disable snapd services
snap_remove_system_packages: true           # Remove snapd APT packages
snap_cleanup_directories: true              # Remove snap directories
snap_cleanup_path: true                     # Remove snap from system PATH
```

### Install Options

```yaml
snap_packages_install:                      # Regular snap packages
  - code
  - discord

snap_classic_packages:                      # Packages requiring --classic
  - code
  - slack
```

### Safety Controls

```yaml
snap_purge_confirm: false                   # Must be true for complete purge
```

## Example Usage

### Remove All Snap Packages

```yaml
- name: Remove all snap packages
  include_role:
    name: wolskinet.infrastructure.manage_snap_packages
  vars:
    snap_management_action: "remove"
  tags: snap-packages
```

### Complete Snap Purge (Destructive)

```yaml
- name: Completely remove snap from system
  include_role:
    name: wolskinet.infrastructure.manage_snap_packages
  vars:
    snap_management_action: "purge"
    snap_purge_confirm: true  # Required for safety
  tags: snap-packages
```

### Install Specific Packages

```yaml
- name: Install snap packages
  include_role:
    name: wolskinet.infrastructure.manage_snap_packages
  vars:
    snap_management_action: "install"
    snap_packages_install:
      - firefox
      - vlc
    snap_classic_packages:
      - code
      - slack
  tags: snap-packages
```

### Tag-Based Execution

```bash
# Install only
ansible-playbook -t install-snap playbook.yml

# Remove only
ansible-playbook -t remove-snap playbook.yml

# Complete purge
ansible-playbook -t purge-snap playbook.yml
```

## Architecture Integration

This role integrates with the infrastructure collection architecture:

1. **os_configuration**: Calls this role for snap management during OS setup
2. **configure_system**: Can call this role for snap management in system configuration

### Integration Example

```yaml
# In os_configuration role
- name: Manage snap packages
  include_role:
    name: wolskinet.infrastructure.manage_snap_packages
  vars:
    snap_management_action: "purge"
    snap_purge_confirm: "{{ config_debian_family.snap.remove_completely }}"
  when: config_debian_family.snap.remove_completely | default(false)
  tags: snap
```

## Safety Features

**Confirmation Required**: Complete purge operations require explicit confirmation via `snap_purge_confirm: true`

**Graceful Failures**: All operations use `failed_when: false` to handle systems where snap isn't installed

**Validation**: OS version validation ensures compatibility

## Platform Support

- **Ubuntu 22+**: Full snap management support
- **Debian 12+**: Full snap management support

## Requirements

- **Ubuntu/Debian**: APT package manager
- **All platforms**: Appropriate sudo/admin privileges

## Dependencies

- `community.general` collection (for snap module)
- `ansible.posix` collection (for systemd management)

## License

MIT

## Author Information

This role is part of the `wolskinet.infrastructure` Ansible collection.
