# manage_system_settings

System performance tuning and hardware configurations for gaming, GPU support, network optimization, and service management.

## Description

This role provides system-level performance tuning and hardware configurations that require root privileges. It's designed to be standalone and focuses on optional system optimizations beyond basic host configuration.

## Features

- **Network Performance Tuning**: BBR congestion control, sysctl optimizations
- **Gaming Optimizations**: VM parameters for gaming workloads
- **GPU Support**: NVIDIA driver configurations and kernel module loading
- **Hardware Support**: Camera (uvcvideo), Bluetooth configurations
- **Service Management**: Enable/disable systemd services
- **Custom Configurations**: Support for custom sysctl parameters

## Role Variables

### Core Settings
- `system_settings_network_enabled: true` - Enable network optimizations
- `system_settings_gaming_enabled: false` - Enable gaming optimizations  
- `system_settings_gpu_enabled: false` - Enable GPU configurations
- `system_settings_services_enabled: true` - Enable service management
- `system_settings_hardware_enabled: true` - Enable hardware support

### Network Optimization
- `system_settings_network_optimizations` - Network sysctl parameters
- `system_settings_custom_sysctl: {}` - Custom sysctl parameters

### Gaming Support  
- `system_settings_gaming_optimizations` - Gaming-specific sysctl parameters

### GPU Configuration
- `system_settings_gpu_nvidia_enabled: false` - Enable NVIDIA support
- `system_settings_gpu_nvidia_modules` - NVIDIA kernel modules to load

### Service Management
- `system_settings_services_enable: []` - Services to enable
- `system_settings_services_disable: []` - Services to disable

### Hardware Support
- `system_settings_camera_support_enabled: false` - Enable camera support
- `system_settings_bluetooth_enabled: false` - Enable Bluetooth support

## Dependencies

None. This role is designed to be fully standalone.

## Example Playbook

```yaml
- hosts: gaming_workstations
  roles:
    - role: wolskinet.infrastructure.manage_system_settings
      vars:
        system_settings_gaming_enabled: true
        system_settings_gpu_enabled: true
        system_settings_gpu_nvidia_enabled: true
        system_settings_camera_support_enabled: true
        system_settings_services_enable:
          - bluetooth
        system_settings_custom_sysctl:
          vm.swappiness: "10"
```

## Supported Platforms

- Ubuntu 24.04+
- Debian 12+  
- Arch Linux (latest)

## License

GPL-3.0-or-later

## Author Information

Ed Wolski - wolskinet