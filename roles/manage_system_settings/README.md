# manage_system_settings

Performance tuning and hardware configurations for gaming, GPU support, and network optimization.

## Description

This role provides performance-focused system tuning and hardware configurations. Security hardening is handled by `devsec.hardening` collection - this role focuses purely on performance optimization.

## Features

- **Network Performance Tuning**: BBR congestion control, connection optimizations
- **Gaming Optimizations**: VM parameters for gaming workloads
- **GPU Support**: NVIDIA driver configurations and kernel module loading
- **Hardware Support**: Camera (uvcvideo), Bluetooth configurations
- **Nerd Fonts Installation**: Downloads and installs Nerd Fonts for development environments
- **Custom Performance Configurations**: Support for custom performance sysctl parameters

## Role Variables

### Core Settings
- `system_settings_network_enabled: false` - Enable network performance optimizations
- `system_settings_gaming_enabled: false` - Enable gaming optimizations
- `system_settings_gpu_enabled: false` - Enable GPU configurations
- `system_settings_hardware_enabled: true` - Enable hardware support

### Network Optimization
- `system_settings_network_optimizations` - Network sysctl parameters
- `system_settings_custom_sysctl: {}` - Custom sysctl parameters

### Gaming Support
- `system_settings_gaming_optimizations` - Gaming-specific sysctl parameters

### GPU Configuration
- `system_settings_gpu_nvidia_enabled: false` - Enable NVIDIA support
- `system_settings_gpu_nvidia_modules` - NVIDIA kernel modules to load

### Hardware Services
- `system_settings_services_enable: []` - Hardware services to enable

### Hardware Support
- `system_settings_camera_support_enabled: false` - Enable camera support
- `system_settings_bluetooth_enabled: false` - Enable Bluetooth support

## Dependencies

None. This role is designed to be fully standalone and complements `devsec.hardening` collection.

## Example Playbook

```yaml
- hosts: gaming_workstations
  roles:
    # Security first
    - devsec.hardening.os_hardening
    # Then performance tuning
    - role: wolskinet.infrastructure.manage_system_settings
      vars:
        system_settings_gaming_enabled: true
        system_settings_gpu_enabled: true
        system_settings_gpu_nvidia_enabled: true
        system_settings_camera_support_enabled: true
        system_settings_nerd_fonts_enabled: true
        system_settings_nerd_fonts_list:
          - "CascadiaCode"
          - "FiraCode"
          - "JetBrainsMono"
        system_settings_custom_sysctl:
          vm.swappiness: "10"
```

### Nerd Fonts Installation (Ubuntu/Debian)

Quick utility for Ubuntu/Debian systems (Arch/macOS use package managers):

```yaml
- hosts: ubuntu_workstations
  roles:
    - role: wolskinet.infrastructure.manage_system_settings
      vars:
        system_config_nf_enable: true
        system_config_nf_links:
          - "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/CascadiaCode.zip"
          - "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/FiraCode.zip"
          - "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip"
```

**Note**: Use package managers for other OS:
- **Arch Linux**: `group_packages_install_Archlinux: [ttf-cascadia-code-nerd, ttf-fira-code-nerd]`
- **macOS**: `host_packages_homebrew_casks: [font-cascadia-code-nerd-font, font-fira-code-nerd-font]`

## Supported Platforms

- Ubuntu 22+
- Debian 12+
- Arch Linux (latest)

## License

GPL-3.0-or-later

## Author Information

Ed Wolski - wolskinet
