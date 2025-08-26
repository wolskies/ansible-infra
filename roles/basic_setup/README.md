# Basic Setup Role

Essential system foundation providing core packages, user management, and OS-specific configuration for all machine types. This role establishes a consistent, secure baseline across Ubuntu 24+, Debian 12+, Arch Linux, and macOS platforms.

## Quick Start

```yaml
- name: Basic infrastructure setup
  hosts: all
  roles:
    - wolskinet.infrastructure.basic_setup
```

**Core Functions:**
- Hierarchical package management with distribution-specific variables
- System configuration (locale, timezone, firewall)
- User account management with dotfiles integration
- Platform-specific optimizations and tools

## Key Features

### 🔧 **Hierarchical Package Management**
Smart package variable merging from multiple levels:
```yaml
# Example variable structure:
all_packages_install_Ubuntu: [git, curl, htop]        # All machines
group_packages_install_Ubuntu: [nginx, certbot]       # Server group  
host_packages_install_Ubuntu: [redis-server]          # Single host
# Result: [git, curl, htop, nginx, certbot, redis-server]
```

### 🖥️ **System Configuration**
- **Locale & Timezone**: Configurable system locale and timezone
- **Firewall Setup**: Platform-appropriate firewall installation (UFW/macOS)
- **Automatic Updates**: Configurable security update automation
- **Shell Enhancements**: Optional modern shell tools (zsh, starship, zoxide, eza, fzf)

### 👤 **User Management & Dotfiles**
- User account creation with proper shell, groups, and permissions
- Integrated dotfiles deployment via GNU Stow
- Discovery-driven user configuration from existing systems

### 🍎 **macOS System Preferences** 
Comprehensive macOS customization inspired by geerlingguy/mac-dev-playbook:
- **Dock**: Size, position, auto-hide configuration
- **Finder**: File extensions, status bar, default view
- **Keyboard**: Key repeat rates, full keyboard access
- **Security**: Password requirements, Gatekeeper settings

### 🐧 **Linux Platform Features**
- **Ubuntu**: Optional snap removal with complete cleanup
- **Arch Linux**: Automated mirror optimization with reflector
- **Debian/Ubuntu**: Additional repository management

## Configuration Options

### System Settings
```yaml
# Locale and timezone
config_system_locale: 'en_US.UTF-8'     # System locale
config_system_timezone: 'UTC'           # System timezone

# Core features
install_firewall: true                  # Install platform firewall
enable_system_updates: true             # Enable automatic security updates
install_shell_enhancements: false       # Modern shell tools
install_dotfiles_support: false         # Enable dotfiles integration
```

### Platform-Specific Options
```yaml
# Ubuntu settings
ubuntu_disable_snap: false              # Remove snap packages completely

# macOS settings  
macos_configure_dock: true              # Enable Dock customization
macos_dock_tile_size: 64                # Dock icon size (16-128)
macos_finder_show_extensions: true      # Show file extensions
macos_enable_full_keyboard_access: true # Tab through all UI controls
```

### Package Management
```yaml
# Hierarchical package variables (merged in order)
all_packages_install_Ubuntu: []         # Global packages
group_packages_install_Ubuntu: []       # Group-specific packages  
host_packages_install_Ubuntu: []        # Host-specific packages (from discovery)
```

## Usage Patterns

### Standard Server Setup
```yaml
- name: Configure servers
  hosts: servers
  vars:
    install_firewall: true
    enable_system_updates: true
    config_system_timezone: 'America/New_York'
    all_packages_install_Ubuntu:
      - git
      - curl
      - htop
      - fail2ban
  roles:
    - wolskinet.infrastructure.basic_setup
```

### Development Workstation  
```yaml
- name: Setup development environment
  hosts: workstations
  vars:
    install_shell_enhancements: true     # zsh, starship, etc.
    install_dotfiles_support: true       # Enable dotfiles management
    discovered_users_config:
      - name: developer
        shell: /bin/zsh
        groups: [sudo, docker]
        dotfiles_repository_url: "https://github.com/user/dotfiles"
        dotfiles_uses_stow: true
  roles:
    - wolskinet.infrastructure.basic_setup
```

### macOS Customization
```yaml
- name: Configure macOS preferences
  hosts: macos_machines
  vars:
    macos_configure_dock: true
    macos_dock_tile_size: 48
    macos_dock_autohide: true
    macos_finder_show_extensions: true
    macos_enable_full_keyboard_access: true
  roles:
    - wolskinet.infrastructure.basic_setup
```

## Integration with Other Roles

### Discovery Integration
The discovery role automatically populates variables consumed by basic_setup:
```yaml
# Discovery generates these variables:
host_packages_install_Ubuntu: [discovered, packages]
discovered_users_config:
  - name: user1
    dotfiles_repository_url: "https://github.com/user1/dotfiles"
    dotfiles_uses_stow: true
```

### Dotfiles Integration  
When `install_dotfiles_support=true`, basic_setup calls the dotfiles role per-user:
```yaml
# User configuration with dotfiles
discovered_users_config:
  - name: myuser
    dotfiles_repository_url: "https://github.com/myuser/dotfiles"
    dotfiles_stow_packages: ["zsh", "git", "tmux"]
```

### Role Dependencies
- **container_platform**: Inherits merged package variables
- **system_security**: Uses firewall installation from basic_setup
- **dotfiles**: Called by basic_setup for dotfiles deployment

## Platform Support

### Ubuntu 24+ / Debian 12+
- Full package management with APT
- Optional snap removal with complete cleanup
- UFW firewall installation
- Automatic security updates

### Arch Linux
- Native pacman packages + AUR via paru
- Automated mirror optimization with reflector  
- firewalld installation
- Pacman configuration optimization

### macOS (Intel/Apple Silicon)
- Homebrew package management
- Comprehensive system preferences automation
- Xcode Command Line Tools installation
- Platform-specific firewall configuration

## Advanced Features

### Shell Enhancement Packages
When `install_shell_enhancements=true`, automatically adds platform-specific packages:
- **Linux**: zoxide, fzf, zsh, fastfetch, eza, starship
- **macOS**: Same tools via Homebrew

### Conditional Package Injection
Smart package addition based on feature flags without per-OS maintenance:
```yaml
# Automatic package injection via merge logic
install_shell_enhancements: true  # Adds shell tools
install_dotfiles_support: true    # Adds stow package (Linux only)
```

### Variable Structure Compatibility
Supports both direct consumption and hierarchical merging:
- Discovery outputs use `host_` prefix for hierarchical merge
- Direct role usage supports standard variable names
- Automatic variable structure detection and handling

## Troubleshooting

### Package Installation Issues
- Check distribution-specific variable names (`packages_install_Ubuntu` vs `packages_install_Archlinux`)
- Verify repository access and package availability
- Review hierarchical merge results in debug output

### macOS Preferences Not Applied
- Restart affected applications (Dock, Finder) after preference changes
- Check user permissions for system preference modifications
- Some preferences require logout/login to take effect

### Snap Removal Problems (Ubuntu)
- Ensure no critical snap packages are installed before enabling `ubuntu_disable_snap`
- Review snap package list and remove manually if needed
- Snap removal is irreversible - consider carefully

## Requirements

- **Ansible**: 2.9+ (tested with ansible-core 2.12+)
- **Python**: 2.7+ or 3.6+ on target systems  
- **Privileges**: Sudo access for package installation and system configuration
- **macOS**: Homebrew installation for package management

---

**Integration Notes**: This role serves as the foundation for all other collection roles. Configure it first, then layer additional roles for specific functionality (Docker, services, etc.).