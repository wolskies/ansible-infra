# manage_snap_packages

Snap package management and system removal for Ubuntu/Debian systems.

## What It Does

Manages snap packages and the snap system:
- **Snap Package Management** - Install and remove snap packages via snapd
- **System Removal** - Complete snapd system removal with prevention of reinstallation
- **Ubuntu/Debian Only** - Snap support limited to Debian-based distributions

## Usage

### Basic Snap Package Management
```yaml
- hosts: ubuntu_servers
  become: true
  roles:
    - wolskies.infrastructure.manage_snap_packages
  vars:
    snap_packages:
      - name: code
        classic: true
      - name: discord
        state: present
      - name: old-package
        state: absent
```

### Complete Snap System Removal
```yaml
- hosts: ubuntu_servers
  become: true
  roles:
    - wolskies.infrastructure.manage_snap_packages
  vars:
    snap:
      remove_completely: true
```

## Variables

Uses collection-wide variables - see collection README for complete reference.

### Snap Configuration
| Variable | Type | Required | Default | Description |
| -------- | ---- | -------- | ------- | ----------- |
| `snap.remove_completely` | boolean | No | `false` | Completely remove snapd system from Debian/Ubuntu systems |

### Package Management
| Variable | Type | Required | Default | Description |
| -------- | ---- | -------- | ------- | ----------- |
| `snap_packages` | list[object] | No | `[]` | Snap packages to manage (see format below) |

### Package Format
Supports comprehensive snap package configuration:
```yaml
snap_packages:
  # Simple installation
  - name: "package-name"

  # With options
  - name: "code"
    classic: true          # Enable classic confinement
    state: present         # present or absent
    channel: "stable"      # Channel specification
```

## Installation Behavior

### When `snap.remove_completely` is false (default):
1. **Snapd Installation** - Ensures snapd is installed via APT
2. **Service Management** - Starts and enables snapd services
3. **System Readiness** - Waits for snapd to be ready
4. **Package Management** - Installs/removes packages as specified

### When `snap.remove_completely` is true:
1. **Package Removal** - Removes all installed snap packages
2. **Service Shutdown** - Stops and disables snapd services
3. **System Purge** - Removes snapd packages via APT
4. **Directory Cleanup** - Removes snap directories
5. **Reinstallation Prevention** - Creates APT preferences to block snapd

## Complete System Removal

When removing the snap system entirely:
- All snap packages are removed (including core packages)
- Snapd services are stopped and disabled
- Snapd packages are purged from the system
- Snap directories (`/snap`, `/var/snap`, etc.) are removed
- APT preferences prevent snapd reinstallation
- Snap paths are removed from system PATH

## Tags

Control which operations run:
- `snap-packages` - All snap package management operations

Example:
```bash
# Skip all snap operations
ansible-playbook --skip-tags snap-packages playbook.yml
```

## Platform Support

- **Ubuntu** 22.04+, 24.04+
- **Debian** 12+, 13+

**Note**: Snap support is limited to Debian-based distributions. This role has no effect on Arch Linux or macOS systems.

## Dependencies

- `ansible.builtin.apt` (Package installation and removal)
- `ansible.builtin.systemd` (Service management)
- `community.general.snap` (Snap package management)
- `ansible.builtin.command` (System operations)
- `ansible.builtin.file` (Directory cleanup)
- `ansible.builtin.copy` (APT preferences creation)
