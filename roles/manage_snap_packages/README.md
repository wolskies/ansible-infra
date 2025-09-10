# manage_snap_packages

Snap package management for Ubuntu/Debian systems. Preserves existing snap installation by default.

## Description

- **Default behavior**: Takes no action - preserves system snap installation
- **Package management**: Install/remove specific snap packages via `community.general.snap`
- **Complete removal**: Optionally disable and remove snap entirely from system

## Role Variables

### Primary Configuration

```yaml
infrastructure:
  host:
    snap:
      disable_and_remove: false  # Preserve system snap (default)
      packages: {}               # Package management (optional)
        # install: [hello-world]  # Packages to install
        # remove: [unwanted]      # Packages to remove
```

## Usage Examples

### Default Usage (Preserve System Snap)

```yaml
# Default behavior - no configuration needed, preserves existing snap
- name: Manage snap packages
  include_role:
    name: wolskinet.infrastructure.manage_snap_packages
  tags: snap-packages
```

### Remove Snap Entirely (Opt-in)

```yaml
# Explicitly opt-in to snap removal
- name: Remove snap from system
  include_role:
    name: wolskinet.infrastructure.manage_snap_packages
  vars:
    infrastructure:
      host:
        snap:
          disable_and_remove: true
  tags: snap-packages
```

### Install Specific Snap

```yaml
# When you need minio or another specific snap
- name: Install minio snap
  include_role:
    name: wolskinet.infrastructure.manage_snap_packages
  vars:
    infrastructure:
      host:
        snap:
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
    infrastructure:
      host:
        snap:
          packages:
            install:
              - minio
              - helm
            remove:
              - outdated-snap
  tags: snap-packages
```

## What the Role Does

### When `infrastructure.host.snap.disable_and_remove: false` (Default)

Takes no action - preserves existing snap installation and packages.

### When `infrastructure.host.snap.disable_and_remove: true` (Opt-in)

1. **Removes all installed snap packages** (including core snaps)
2. **Stops and disables all snapd services**
3. **Removes snapd APT packages** (purge)
4. **Cleans up all snap directories** (`/snap`, `/var/snap`, etc.)
5. **Removes snap from system PATH**
6. **Prevents snapd reinstallation** via APT preferences
7. **Ignores any package configuration** (safety feature)

### When `infrastructure.host.snap.packages` is configured

1. **Installs snapd** if not present and packages are requested
2. **Starts snapd services** if needed
3. **Removes specified packages** (if any)
4. **Installs specified packages**
5. **Simple wrapper** around `community.general.snap`

## Integration with Infrastructure Collection

### In `configure_system` Role

The role is called with tags, allowing selective execution:

```yaml
# Will preserve snap by default
- name: Manage Snap Packages
  ansible.builtin.include_role:
    name: "wolskinet.infrastructure.manage_snap_packages"
  tags:
    - snap-packages
    - optional
```

### Inventory Configuration

```yaml
# group_vars/all.yml (default - no configuration needed)
# Snap is preserved by default

# host_vars/media-server.yml (install specific packages)
infrastructure:
  host:
    snap:
      packages:
        install:
          - minio
          - jellyfin

# host_vars/desktop.yml (remove snap entirely)
infrastructure:
  host:
    snap:
      disable_and_remove: true
```

## Platform Support

- **Ubuntu 22.04+**: Primary target platform
- **Debian 12+**: Supported
- **Other OS families**: Gracefully skipped

## Dependencies

- `community.general` collection (only when installing packages)
- Standard Ansible modules (`apt`, `systemd`, `file`, etc.)

## Safety Features

- **Removal takes precedence**: If `infrastructure.host.snap.disable_and_remove: true`, package lists are ignored
- **Graceful failures**: All operations handle missing snap gracefully
- **APT preferences**: Prevents accidental snapd reinstallation
- **OS family detection**: Only runs on Debian-family systems

## Tags

- `snap-packages`: All snap operations

```bash
# Run snap role
ansible-playbook -t snap-packages site.yml
```

Provides snap management with system-preserving defaults and optional complete removal.
