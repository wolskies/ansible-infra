# manage_flatpak

Flatpak package management and desktop integration for Debian and Arch Linux systems.

## What It Does

Manages flatpak system and packages:
- **Flatpak Runtime** - System installation and repository management
- **Desktop Integration** - GNOME Software and Plasma Discover plugins
- **Package Management** - Install and remove flatpak applications
- **Cross-platform** - Debian, Ubuntu, Arch Linux support

## Usage

### Basic Flatpak Management
```yaml
- hosts: linux_desktops
  become: true
  roles:
    - wolskies.infrastructure.manage_flatpak
  vars:
    flatpak:
      enabled: true
      flathub: true
      plugins:
        gnome: true
    flatpak_packages:
      - name: org.mozilla.firefox
        state: present
      - name: com.spotify.Client
        state: present
```

### System Installation Only
```yaml
- hosts: servers
  become: true
  roles:
    - wolskies.infrastructure.manage_flatpak
  vars:
    flatpak:
      enabled: true
      flathub: true
      method: system
```

## Variables

Uses collection-wide variables - see collection README for complete reference.

### Flatpak Configuration
| Variable | Type | Required | Default | Description |
| -------- | ---- | -------- | ------- | ----------- |
| `flatpak.enabled` | boolean | No | `false` | Install flatpak runtime on Debian and Arch Linux systems |
| `flatpak.flathub` | boolean | No | `false` | Enable Flathub repository |
| `flatpak.method` | enum | No | `"system"` | Installation method ("system" or "user") |
| `flatpak.user` | string | No | none | Target username for user-level operations |
| `flatpak.plugins.gnome` | boolean | No | `false` | Install GNOME Software plugin (Debian/Ubuntu only) |
| `flatpak.plugins.plasma` | boolean | No | `false` | Install Plasma Discover plugin (Debian/Ubuntu only) |

### Package Management
| Variable | Type | Required | Default | Description |
| -------- | ---- | -------- | ------- | ----------- |
| `flatpak_packages` | list[object] | No | `[]` | Flatpak packages to manage (see format below) |

### Package Format
Supports flatpak package configuration:
```yaml
flatpak_packages:
  # Simple installation
  - name: "org.mozilla.firefox"

  # With state specification
  - name: "com.spotify.Client"
    state: present         # present or absent
```

## Installation Behavior

1. **Flatpak Installation** - Installs flatpak runtime:
   - **Ubuntu/Debian** - APT `flatpak` package
   - **Arch Linux** - Pacman `flatpak` package
2. **Desktop Integration** - Installs plugins (Ubuntu/Debian only):
   - **GNOME** - `gnome-software-plugin-flatpak` package
   - **Plasma** - `plasma-discover-backend-flatpak` package
3. **Repository Management** - Enables Flathub when configured
4. **Package Management** - Installs/removes packages as specified

## Platform-Specific Features

### Ubuntu/Debian
- Separate desktop integration plugins required
- GNOME Software plugin: `gnome-software-plugin-flatpak`
- Plasma Discover plugin: `plasma-discover-backend-flatpak`

### Arch Linux
- Desktop integration built into desktop packages
- No separate plugins required for GNOME Software or Plasma Discover

## Installation Methods

### System-wide Installation (default)
```yaml
flatpak:
  method: system
```
- Installs packages for all users
- Requires root privileges
- Packages available system-wide

### User-level Installation
```yaml
flatpak:
  method: user
  user: developer
```
- Installs packages for specific user
- No root privileges required for package operations
- Packages available only to specified user

## Tags

Control which features are enabled:
- `flatpak-system` - Flatpak runtime and repository installation
- `flatpak-plugins` - Desktop environment integration plugins
- `flatpak-packages` - Individual package management

Example:
```bash
# Install flatpak without desktop integration
ansible-playbook --skip-tags flatpak-plugins playbook.yml

# Configure system without installing packages
ansible-playbook --skip-tags flatpak-packages playbook.yml
```

## Platform Support

- **Ubuntu** 22.04+, 24.04+
- **Debian** 12+, 13+
- **Arch Linux** (Rolling)

**Note**: Flatpak support is limited to Linux distributions. This role has no effect on macOS systems.

## Dependencies

- `ansible.builtin.apt` (Ubuntu/Debian package installation)
- `community.general.pacman` (Arch Linux package installation)
- `community.general.flatpak_remote` (Repository management)
- `community.general.flatpak` (Package management)
