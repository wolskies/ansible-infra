# manage_snap_packages

Snap package management for Ubuntu/Debian systems with optional complete removal.

## Description

Manages snap packages on Ubuntu/Debian systems. By default, preserves existing snap installation and provides package management. Optionally can completely remove snap from the system if desired.

## Role Variables

```yaml
snap:
  remove_completely: false      # Preserve snap system (default)
  packages:
    install: []                 # Snap packages to install
    remove: []                  # Snap packages to remove
```

## Usage Examples

### Standalone Usage

```yaml
- hosts: ubuntu_servers
  become: true
  roles:
    - role: wolskies.infrastructure.manage_snap_packages
      vars:
        snap:
          packages:
            install:
              - hello-world
              - core
```

### With Variable Files

```yaml
# group_vars/servers.yml
snap:
  packages:
    install:
      - microk8s
      - helm

# host_vars/media-server.yml
snap:
  packages:
    install:
      - jellyfin
      - plex-media-server

# playbook.yml
- hosts: all
  become: true
  roles:
    - wolskies.infrastructure.manage_snap_packages
```

### Complete Snap Removal

```yaml
snap:
  remove_completely: true       # Completely remove snap from system
  # packages are ignored when remove_completely is true
```

### Default Behavior (Preserve Snap)

```yaml
# Default - no configuration needed
snap:
  remove_completely: false      # This is the default
```

## Installation Behavior

### Default Mode (`snap.remove_completely: false`)
1. **Installs snapd**: If packages are requested and snapd not present
2. **Starts snapd services**: Ensures snap daemon is running
3. **Removes packages**: Uninstalls packages in `packages.remove` list
4. **Installs packages**: Installs packages in `packages.install` list

### Removal Mode (`snap.remove_completely: true`)
1. **Removes all snap packages**: Including core snaps and dependencies
2. **Stops snapd services**: Disables all snap-related services
3. **Removes snapd packages**: Purges snapd from system via apt
4. **Cleans directories**: Removes `/snap`, `/var/snap`, etc.
5. **Prevents reinstallation**: Sets APT preferences to block snapd
6. **Ignores package lists**: Safety feature - package configuration ignored

## Common Snap Packages

```yaml
snap:
  packages:
    install:
      - core
      - snapd
      - hello-world
      - discord
      - code
      - microk8s
      - helm
      - kubectl
```

## OS Support

- **Ubuntu 22+**: Full support (primary target)
- **Debian 12+**: Full support
- **Other OS**: Role skips gracefully

## Requirements

- Debian-family operating system (Ubuntu/Debian)
- System package manager access (for snapd installation/removal)
- Internet access for downloading snap packages

## Integration Notes

### With configure_system Role
This role integrates with system configuration:

```yaml
- hosts: all
  become: true
  roles:
    - wolskies.infrastructure.os_configuration          # System settings
    - wolskies.infrastructure.manage_snap_packages      # Snap management
```

### Safety Features
- **Removal precedence**: When `remove_completely: true`, package lists are ignored
- **Graceful handling**: All operations handle missing snap gracefully
- **APT prevention**: After removal, prevents accidental snapd reinstallation
- **OS detection**: Only runs on supported Debian-family systems

## File Locations

- **Snap packages**: `/snap/` (when installed)
- **Snap data**: `/var/snap/` (user data and configurations)
- **Snap cache**: `/var/lib/snapd/`
- **APT preferences**: `/etc/apt/preferences.d/snapd` (when removed)

## Use Cases

### Keep Snap (Default)
Most systems where snap is already present and working:
```yaml
# No configuration needed - snap is preserved by default
```

### Install Specific Applications
When you need specific snap packages:
```yaml
snap:
  packages:
    install: [discord, code, microk8s]
```

### Remove Snap Completely
For minimal systems or when snap conflicts with other package management:
```yaml
snap:
  remove_completely: true
```

## Dependencies

- `community.general`: snap module for package management
- `ansible.builtin.systemd`: Service management
- `ansible.builtin.apt`: Package removal and APT preferences

## License

MIT

## Author Information

This role is part of the wolskies.infrastructure collection.
