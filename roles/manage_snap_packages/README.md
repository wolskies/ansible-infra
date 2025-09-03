# manage_snap_packages

**Primary Purpose**: Completely disable and remove snap from Ubuntu/Debian systems
**Secondary Purpose**: Thin wrapper around `community.general.snap` for occasional snap package installation

## Description

This role addresses the common need to **completely remove snap** from Ubuntu systems, while also providing a simple wrapper for the rare occasions when you need to install a specific snap package.

### Design Philosophy

1. **Default behavior**: Disable and remove snap entirely from the system
2. **Override when needed**: Simple configuration to install specific snap packages (like `minio`)
3. **Safety first**: Even if you accidentally configure snap packages to install, the removal takes precedence

## Role Variables

### Primary Configuration

```yaml
snap:
  disable_and_remove: true  # Remove snap entirely (default)
  packages:
    install: []            # Only used when disable_and_remove: false
    remove: []             # Packages to remove
```

## Usage Examples

### Default Usage (Remove Snap Entirely)

```yaml
# Default behavior - no configuration needed
- name: Remove snap from system
  include_role:
    name: wolskinet.infrastructure.manage_snap_packages
  tags: snap-packages
```

### Install Specific Snap (Rare Case)

```yaml
# When you need minio or another specific snap
- name: Install minio snap
  include_role:
    name: wolskinet.infrastructure.manage_snap_packages
  vars:
    snap:
      disable_and_remove: false
      packages:
        install:
          - minio
          - core    # Often needed as dependency
  tags: snap-packages
```

### Install Multiple Snap Packages

```yaml
- name: Install multiple snap packages
  include_role:
    name: wolskinet.infrastructure.manage_snap_packages
  vars:
    snap:
      disable_and_remove: false
      packages:
        install:
          - minio
          - helm
        remove:
          - outdated-snap
  tags: snap-packages
```

## What the Role Does

### When `snap.disable_and_remove: true` (Default)

1. **Removes all installed snap packages** (including core snaps)
2. **Stops and disables all snapd services**
3. **Removes snapd APT packages** (purge)
4. **Cleans up all snap directories** (`/snap`, `/var/snap`, etc.)
5. **Removes snap from system PATH**
6. **Prevents snapd reinstallation** via APT preferences
7. **Ignores any package configuration** (safety feature)

### When `snap.disable_and_remove: false`

1. **Installs snapd** if not present
2. **Starts snapd services**
3. **Removes specified packages** (if any)
4. **Installs specified packages**
5. **Simple wrapper** around `community.general.snap`

## Integration with Infrastructure Collection

### In `configure_system` Role

The role is called with tags, allowing selective execution:

```yaml
# Will disable snap by default
- name: Manage Snap Packages
  ansible.builtin.include_role:
    name: "wolskinet.infrastructure.manage_snap_packages"
  tags:
    - snap-packages
    - optional
```

### Inventory Configuration

```yaml
# group_vars/all.yml - Disable snap everywhere (default)
snap:
  disable_and_remove: true

# host_vars/media-server.yml - Exception for specific hosts
snap:
  disable_and_remove: false
  packages:
    install:
      - minio
      - jellyfin
```

## Platform Support

- **Ubuntu 22.04+**: Primary target platform
- **Debian 12+**: Supported
- **Other OS families**: Gracefully skipped

## Dependencies

- `community.general` collection (only when installing packages)
- Standard Ansible modules (`apt`, `systemd`, `file`, etc.)

## Safety Features

- **Removal takes precedence**: If `snap.disable_and_remove: true`, package lists are ignored
- **Graceful failures**: All operations handle missing snap gracefully
- **APT preferences**: Prevents accidental snapd reinstallation
- **OS family detection**: Only runs on Debian-family systems

## Tags

- `snap-packages`: All snap operations

```bash
# Run snap role
ansible-playbook -t snap-packages site.yml
```

This role reflects the reality that most users want snap **gone**, with occasional exceptions for specific use cases.
