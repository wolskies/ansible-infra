# manage_flatpak

Comprehensive Flatpak package management for Ubuntu and Debian systems. Supports installing, removing, or completely purging Flatpak packages from the system.

## Description

This role provides complete Flatpak package lifecycle management:

- **Install**: Set up Flatpak, enable Flathub, and install Flatpak packages
- **Remove**: Remove Flatpak packages while keeping the system intact  
- **Purge**: Complete Flatpak removal including system packages, repositories, and directories

The role includes safety mechanisms for destructive operations and supports both individual package management and system-wide Flatpak removal.

## Features

- **📦 Package Management**: Install/remove individual Flatpak packages
- **🗑️ Complete Purge**: Comprehensive Flatpak system removal
- **🔒 Safety Controls**: Confirmation required for destructive operations
- **🌍 Flathub Integration**: Automatic Flathub repository setup
- **🧹 System Cleanup**: Directory and repository cleanup
- **🏷️ Tag-Based Control**: Fine-grained execution control

## Role Variables

See `defaults/main.yml` for complete configuration options.

### Basic Configuration

```yaml
flatpak_management_action: "install"            # "install", "remove", "purge"
```

### Install Options

```yaml
flatpak_enable_flathub: true                    # Enable Flathub repository
flatpak_packages_install:                       # Flatpak packages to install
  - org.mozilla.firefox
  - com.visualstudio.code
  - org.libreoffice.LibreOffice
```

### Remove/Purge Options

```yaml
flatpak_remove_all_packages: true               # Remove all installed packages
flatpak_remove_system_packages: true            # Remove Flatpak APT packages
flatpak_cleanup_directories: true               # Remove Flatpak directories
flatpak_cleanup_repositories: true              # Remove Flatpak repositories
```

### Safety Controls

```yaml
flatpak_purge_confirm: false                    # Must be true for complete purge
```

## Example Usage

### Install Flatpak Packages

```yaml
- name: Install Flatpak packages
  include_role:
    name: wolskinet.infrastructure.manage_flatpak
  vars:
    flatpak_management_action: "install"
    flatpak_packages_install:
      - org.mozilla.firefox
      - com.visualstudio.code
      - org.libreoffice.LibreOffice
  tags: flatpak-packages
```

### Remove All Flatpak Packages

```yaml
- name: Remove all Flatpak packages
  include_role:
    name: wolskinet.infrastructure.manage_flatpak
  vars:
    flatpak_management_action: "remove"
  tags: flatpak-packages
```

### Complete Flatpak Purge (Destructive)

```yaml
- name: Completely remove Flatpak from system
  include_role:
    name: wolskinet.infrastructure.manage_flatpak
  vars:
    flatpak_management_action: "purge"
    flatpak_purge_confirm: true  # Required for safety
  tags: flatpak-packages
```

### Tag-Based Execution

```bash
# Install only
ansible-playbook -t install-flatpak playbook.yml

# Remove only  
ansible-playbook -t remove-flatpak playbook.yml

# Complete purge
ansible-playbook -t purge-flatpak playbook.yml
```

## Architecture Integration

This role integrates with the infrastructure collection architecture:

1. **configure_host**: Can call this role for Flatpak management during host setup
2. **manage_system_settings**: Can call this role for Flatpak management in system configuration

### Integration Example

```yaml
# In configure_host role
- name: Manage Flatpak packages
  include_role:
    name: wolskinet.infrastructure.manage_flatpak
  vars:
    flatpak_management_action: "install"
    flatpak_packages_install: "{{ host_flatpak_packages | default([]) }}"
  when: host_flatpak_packages is defined
  tags: flatpak
```

## Safety Features

**Confirmation Required**: Complete purge operations require explicit confirmation via `flatpak_purge_confirm: true`

**Graceful Failures**: All operations use `failed_when: false` to handle systems where Flatpak isn't installed

**Validation**: OS version validation ensures compatibility

## Platform Support

- **Ubuntu 22+**: Full Flatpak management support
- **Debian 12+**: Full Flatpak management support

## Requirements

- **Ubuntu/Debian**: APT package manager
- **All platforms**: Appropriate sudo/admin privileges

## Dependencies

- `community.general` collection (for flatpak modules)

## License

MIT

## Author Information

This role is part of the `wolskinet.infrastructure` Ansible collection.
