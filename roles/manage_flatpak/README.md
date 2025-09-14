# manage_flatpak

Flatpak package management for desktop systems.

## Description

Manages Flatpak package installation and removal on desktop systems. Automatically installs flatpak, configures Flathub repository, and manages application packages. Includes optional desktop integration plugins for GNOME and KDE environments.

## Role Variables

```yaml
flatpak:
  enabled: false                 # Enable flatpak package management
  remotes: []                    # Additional flatpak remotes to add
  packages:
    install: []                  # List of flatpak packages to install
    remove: []                   # List of flatpak packages to remove
```

## Usage Examples

### Standalone Usage

```yaml
- hosts: workstations
  become: true
  roles:
    - role: wolskies.infrastructure.manage_flatpak
      vars:
        flatpak:
          enabled: true
          packages:
            install:
              - org.mozilla.firefox
              - com.visualstudio.code
              - org.libreoffice.LibreOffice
```

### With Variable Files

```yaml
# group_vars/workstations.yml
flatpak:
  enabled: true
  packages:
    install:
      - org.mozilla.firefox
      - org.gimp.GIMP
      - com.spotify.Client
      - org.signal.Signal
    remove:
      - old-package

# playbook.yml
- hosts: workstations
  become: true
  roles:
    - wolskies.infrastructure.manage_flatpak
```

### Minimal Setup

```yaml
flatpak:
  enabled: true                  # Just enable flatpak with Flathub
```

## Installation Behavior

When `flatpak.enabled: true`:

1. **Installs flatpak**: System flatpak package via package manager
2. **Configures Flathub**: Adds Flathub repository automatically
3. **Installs plugins**: Desktop integration for GNOME/KDE (automatic detection)
4. **Removes packages**: Uninstalls packages in `packages.remove` list
5. **Installs packages**: Installs packages in `packages.install` list

## Common Flatpak Applications

```yaml
flatpak:
  packages:
    install:
      - org.mozilla.firefox
      - com.visualstudio.code
      - org.libreoffice.LibreOffice
      - org.gimp.GIMP
      - com.spotify.Client
      - org.signal.Signal
      - com.discordapp.Discord
      - org.videolan.VLC
```

## Package Management

### Adding Applications
```yaml
flatpak:
  packages:
    install:
      - new.application.Name     # Will be installed
```

### Removing Applications
```yaml
flatpak:
  packages:
    remove:
      - unwanted.app.Name        # Will be uninstalled
```

### Finding Package Names
Flatpak uses reverse-DNS naming (e.g., `org.mozilla.firefox`). Use `flatpak search` to find package names.

## OS Support

- **Ubuntu 22+**: Full support
- **Debian 12+**: Full support
- **Arch Linux**: Full support
- **macOS**: Not supported (role skips gracefully)

## Requirements

- Desktop environment (GNOME, KDE, or similar)
- System package manager access (for flatpak installation)
- Internet access for downloading packages

## Integration Notes

### With configure_system Role
This role integrates with the collection's system configuration:

```yaml
- hosts: workstations
  become: true
  roles:
    - wolskies.infrastructure.configure_system    # System setup
    - wolskies.infrastructure.manage_flatpak      # Application management
```

### Desktop Integration
The role automatically:
- Detects desktop environment (GNOME/KDE)
- Installs appropriate integration plugins
- Configures Flathub repository
- Sets up application launchers

## File Locations

- **System installation**: `/usr/bin/flatpak`
- **User applications**: `~/.local/share/flatpak/`
- **System applications**: `/var/lib/flatpak/`
- **Repository configuration**: `/var/lib/flatpak/repo/`

## Dependencies

- `community.general`: flatpak module for package management
- `ansible.builtin.package`: For flatpak system installation

## License

MIT

## Author Information

This role is part of the wolskies.infrastructure collection.
