# manage_flatpak

Simple Flatpak package management for Ubuntu and Debian systems.

## Description

This role provides straightforward Flatpak package management:
- Install/remove individual Flatpak packages
- Enable Flathub repository
- Optional desktop integration plugins (GNOME/KDE)

## Role Variables

```yaml
infrastructure:
  host:
    flatpak:
      enabled: false          # Enable flatpak package management
      packages:
        install: []          # List of flatpak packages to install
        remove: []           # List of flatpak packages to remove
      flathub: true          # Enable Flathub repository
      plugins:
        gnome: false         # Install GNOME Software flatpak plugin
        plasma: false        # Install KDE Discover flatpak plugin
```

## Usage Examples

### Install Flatpak Packages

```yaml
- name: Install flatpak packages
  include_role:
    name: wolskinet.infrastructure.manage_flatpak
  vars:
    infrastructure:
      host:
        flatpak:
          enabled: true
          packages:
            install:
              - org.mozilla.firefox
              - com.visualstudio.code
              - org.libreoffice.LibreOffice
          plugins:
            gnome: true  # Enable GNOME Software integration
```

### Remove Specific Packages

```yaml
- name: Remove specific flatpak packages
  include_role:
    name: wolskinet.infrastructure.manage_flatpak
  vars:
    infrastructure:
      host:
        flatpak:
          enabled: true
          packages:
            remove:
              - old-package
              - unused-app
```

### Minimal Setup

```yaml
# Just enable flatpak with Flathub
infrastructure:
  host:
    flatpak:
      enabled: true
```

## What the Role Does

When `infrastructure.host.flatpak.enabled: true`:

1. **Installs flatpak** system package
2. **Enables Flathub repository** (if `flathub: true`)
3. **Installs desktop plugins** (if requested)
4. **Removes specified packages** (if any)
5. **Installs specified packages** (if any)

## Integration with Infrastructure Collection

```yaml
# group_vars/workstations.yml
infrastructure:
  host:
    flatpak:
      enabled: true
      packages:
        install:
          - org.mozilla.firefox
          - org.gimp.GIMP
      plugins:
        gnome: true
```

## Platform Support

- **Ubuntu 22.04+**: Full support
- **Debian 12+**: Full support
- **Arch Linux**: Full support
- **Other systems**: Gracefully skipped

## Dependencies

- `community.general` collection (for flatpak modules)
- Standard Ansible modules (`apt`, etc.)

## Tags

This role does not use specific tags - it runs based on the `infrastructure.host.flatpak.enabled` configuration.

This role is designed for desktop/workstation environments where Flatpak provides additional application options alongside traditional package management.
