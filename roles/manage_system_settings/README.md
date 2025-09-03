# manage_system_settings

Comprehensive system configuration management for Linux and macOS systems.

## Description

This role provides system-level configuration management for:
- Kernel parameters (sysctl) and system tuning
- PAM limits and resource controls
- Kernel module loading and blacklisting
- Hardware service management
- Font installation (Nerd Fonts)
- macOS system preferences (Dock, Finder, security)

## Role Variables

### Linux Configuration

```yaml
system_settings_linux:
  sysctl:
    enabled: false
    file: /etc/sysctl.d/99-ansible-managed.conf
    parameters: {}
    # Example parameters:
    # parameters:
    #   net.core.default_qdisc: "fq"
    #   net.ipv4.tcp_congestion_control: "bbr"
    #   vm.swappiness: 10
    #   vm.max_map_count: 2097152  # Required for Steam
    #   fs.file-max: 2097152

  limits:
    enabled: false
    limits: []
    # Example limits:
    # limits:
    #   - domain: '*'
    #     limit_type: soft
    #     limit_item: nofile
    #     value: 65536

  modules:
    load: []
    blacklist: []
    options: {}
    # Example:
    # load: [uvcvideo, btusb]
    # blacklist: [nouveau]

  services:
    enable: []
    disable: []
    mask: []
    # Example:
    # enable: [bluetooth.service, cups.service]
    # disable: [ModemManager.service]

  fonts:
    nerd_fonts:
      enabled: false
      install_dir: /usr/share/fonts/nerd-fonts
      fonts: []
      # Example fonts:
      # fonts:
      #   - name: CascadiaCode
      #     url: "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/CascadiaCode.zip"
```

### macOS Configuration

```yaml
system_settings_macos:
  dock:
    enabled: false
    settings: {}
    # Example: tile-size: 48, autohide: false

  finder:
    enabled: false
    settings: {}
    # Example: ShowExtensions: true, ShowHidden: false

  system:
    enabled: false
    settings: {}
    # Example: KeyRepeat: 2, ApplePressAndHoldEnabled: false

  security:
    enabled: false
    settings: {}
    # Example: require_password_after_sleep: true
```

## Usage Examples

### Linux Performance Tuning

```yaml
- name: Configure system settings
  include_role:
    name: wolskinet.infrastructure.manage_system_settings
  vars:
    system_settings_linux:
      sysctl:
        enabled: true
        parameters:
          net.core.default_qdisc: "fq"
          net.ipv4.tcp_congestion_control: "bbr"
          vm.swappiness: 10
          vm.max_map_count: 2097152
      services:
        enable:
          - bluetooth.service
        disable:
          - ModemManager.service
      fonts:
        nerd_fonts:
          enabled: true
          fonts:
            - name: CascadiaCode
              url: "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/CascadiaCode.zip"
```

### macOS System Configuration

```yaml
- name: Configure macOS settings
  include_role:
    name: wolskinet.infrastructure.manage_system_settings
  vars:
    system_settings_macos:
      dock:
        enabled: true
        settings:
          tile-size: 48
          autohide: true
          show-recents: false
      finder:
        enabled: true
        settings:
          ShowExtensions: true
          ShowHidden: true
      security:
        enabled: true
        settings:
          require_password_after_sleep: true
```

### Gaming Workstation Setup

```yaml
- name: Gaming workstation optimization
  include_role:
    name: wolskinet.infrastructure.manage_system_settings
  vars:
    system_settings_linux:
      sysctl:
        enabled: true
        parameters:
          vm.max_map_count: 2097152  # Required for Steam
          vm.swappiness: 1           # Reduce swap usage
          net.core.default_qdisc: "fq"
          net.ipv4.tcp_congestion_control: "bbr"
      modules:
        blacklist:
          - nouveau  # Disable for NVIDIA
      services:
        enable:
          - bluetooth.service
        disable:
          - ModemManager.service
```

## Platform Support

- **Ubuntu 22.04+**: Full support
- **Debian 12+**: Full support
- **Arch Linux**: Full support
- **macOS**: Full support

## Tags

This role uses context-specific tags:
- `sysctl`, `kernel`, `performance` - Linux kernel tuning
- `limits`, `pam` - Resource limits
- `modules` - Kernel module management
- `services`, `hardware` - Service management
- `fonts`, `nerd-fonts` - Font installation
- `macos`, `dock`, `finder`, `security` - macOS settings

```bash
# Run specific components
ansible-playbook -t sysctl site.yml
ansible-playbook -t macos site.yml
```

## Dependencies

- `community.general` collection (for PAM limits and macOS defaults)
- `ansible.posix` collection (for sysctl module)

This role is designed to complement security hardening roles and focuses on system optimization and configuration.
