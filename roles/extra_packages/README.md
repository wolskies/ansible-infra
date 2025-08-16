# Ansible Role: Extra Packages

Manages additional packages beyond the minimal set provided by `basic_setup`. Uses standard Ansible inventory variables that can be populated manually or by the discovery system.

## Description

This role provides **flexible package management** for systems after the essential foundation has been established by `basic_setup`. It handles multiple package sources and categories while maintaining clear separation between essential and optional packages.

## Philosophy

- **Separation of concerns**: `basic_setup` handles essentials, `extra_packages` handles everything else
- **Unified approach**: All packages use standard inventory variables regardless of source
- **Discovery integration**: Discovery system populates the same variables users would define manually
- **Category-based**: Organized by development, desktop, media, etc. for fine-grained control
- **Cross-platform**: Works consistently across Ubuntu, Debian, Arch Linux, and macOS
- **Safety-first**: Failed packages don't stop the entire installation

## Package Sources

All packages use standard Ansible inventory variables that follow normal precedence rules:

### Manual Definition
Define packages in group_vars or host_vars:

```yaml
# group_vars/workstations.yml
development_packages:
  - vim
  - neovim
  - code

desktop_packages:
  - firefox
  - thunderbird

# host_vars/my-workstation.yml
host_development_packages:
  - terraform  # Additional packages for this specific host
```

### Discovery Integration
The discovery role populates the same variables:

```yaml
# Generated in host_vars/ by discovery role
system_packages:
  - htop
  - tree
  - jq

# development_packages:
#   - nodejs  # Commented out, uncomment to install
#   - npm
```

### Variable Merging
Packages are merged from multiple sources using Ansible precedence:

```
final_development_packages = development_packages + group_development_packages + host_development_packages
```

## Usage

### Basic Usage
After `basic_setup` has run:

```yaml
- hosts: workstations
  roles:
    - wolskinet.infrastructure.basic_setup    # Essentials first
    - wolskinet.infrastructure.extra_packages # Additional packages
```

### Category Control
Enable/disable package categories:

```yaml
- hosts: servers
  vars:
    install_development_packages: true
    install_desktop_packages: false    # No GUI on servers
    install_media_packages: false      # Large packages skipped
  roles:
    - wolskinet.infrastructure.extra_packages
```

### Discovery Integration
With infrastructure discovery:

```yaml
- hosts: all
  vars:
    enable_additional_repositories: true
    process_additional_services: false
  roles:
    - wolskinet.infrastructure.discovery      # Populates standard variables
    - wolskinet.infrastructure.basic_setup
    - wolskinet.infrastructure.extra_packages # Uses same variables
```

### Workstation Setup Example
Full workstation with opinionated packages:

```yaml
- hosts: workstations
  vars_files:
    - examples/inventory/group_vars/opinionated-packages-ubuntu.yml
  vars:
    install_development_packages: true
    install_desktop_packages: true
    install_media_packages: true
    development_packages:
      - ansible
      - terraform
    desktop_packages:
      - slack
      - discord
  roles:
    - wolskinet.infrastructure.basic_setup
    - wolskinet.infrastructure.extra_packages
```

## Package Categories

### System Packages
Core system utilities and tools:
- Text editors, file managers, system monitors
- Installed via native package manager (APT, pacman, Homebrew)

### Development Packages  
Programming and development tools:
- Compilers, interpreters, build tools, IDEs
- Language runtimes, version control systems

### Desktop Packages
GUI applications and desktop tools:
- Web browsers, communication apps, office suites
- Themes, icons, desktop environments

### Media Packages
Large multimedia applications:
- Video/audio editors, media players, graphics tools
- Often large downloads - disabled by default

### Language-Specific Packages

#### Python Packages (pip)
```yaml
python_packages:
  - requests
  - flask
  - django
```

#### Node.js Packages (npm)
```yaml
nodejs_packages:
  - "@angular/cli"
  - "create-react-app"
  - "typescript"
```

#### Arch Linux AUR Packages
```yaml
aur_packages:
  - "visual-studio-code-bin"
  - "discord"
  - "spotify"
```

#### macOS Homebrew Casks
```yaml
homebrew_casks:
  - "visual-studio-code"
  - "discord"
  - "spotify"
```

## Variables

### Repository Control
- `enable_additional_repositories` (default: `true`) - Setup additional package repositories

### Category Control
- `install_development_packages` (default: `true`) - Development tools
- `install_desktop_packages` (default: `true`) - GUI applications
- `install_media_packages` (default: `false`) - Large media packages
- `install_productivity_packages` (default: `true`) - Editors, terminals

### Package Manager Control
- `install_aur_packages` (default: `true`) - Arch AUR packages
- `install_pip_packages` (default: `true`) - Python packages
- `install_npm_packages` (default: `true`) - Node.js packages
- `install_homebrew_casks` (default: `true`) - macOS GUI apps

### Safety and Performance
- `skip_failed_packages` (default: `true`) - Continue if packages fail
- `update_package_cache` (default: `true`) - Update cache before install
- `require_package_confirmation` (default: `false`) - Prompt for large sets

### Service Processing
- `process_additional_services` (default: `false`) - Configure additional services

## Variable Structure

### Standard Package Variables
All packages use the same variable structure, populated manually or by discovery:

```yaml
# System packages (installed via native package manager)
system_packages: []
group_system_packages: []     # Additional packages for this group
host_system_packages: []      # Additional packages for this host

# Category-specific packages
development_packages: []
group_development_packages: []
host_development_packages: []

desktop_packages: []
group_desktop_packages: []
host_desktop_packages: []

media_packages: []
group_media_packages: []
host_media_packages: []

# Language-specific packages
python_packages: []
group_python_packages: []
host_python_packages: []

nodejs_packages: []
group_nodejs_packages: []
host_nodejs_packages: []

# Platform-specific packages
aur_packages: []              # Arch Linux only
group_aur_packages: []
host_aur_packages: []

homebrew_packages: []         # macOS
homebrew_casks: []            # macOS GUI apps
group_homebrew_packages: []
group_homebrew_casks: []
host_homebrew_packages: []
host_homebrew_casks: []

# Additional repositories
additional_repositories:
  apt:
    sources: []               # APT repository URLs
    keys: []                  # APT signing keys
  homebrew:
    taps: []                  # Homebrew taps
  flatpak:
    remotes: []               # Flatpak repositories
```

## Integration Examples

### With Docker Setup
```yaml
- hosts: docker_hosts
  vars:
    install_desktop_packages: false  # Server environment
    development_packages:
      - docker-compose-plugin
      - ctop
  roles:
    - wolskinet.infrastructure.basic_setup
    - wolskinet.infrastructure.extra_packages
    - wolskinet.infrastructure.docker_setup
```

### With Firewall Role
```yaml
- hosts: workstations  
  vars:
    development_packages:
      - nodejs
      - nginx
  roles:
    - wolskinet.infrastructure.basic_setup
    - wolskinet.infrastructure.extra_packages
    - wolskinet.infrastructure.firewall  # May open ports for installed services
```

## Platform-Specific Notes

### Ubuntu/Debian
- Uses APT package manager
- Supports PPA repositories from discovery
- Snap packages can be enabled but are disabled by default

### Arch Linux
- Uses pacman for official packages
- Uses paru for AUR packages (installed by basic_setup)
- AUR packages require build tools (provided by basic_setup)

### macOS
- Uses Homebrew for packages and casks
- System packages mapped to Homebrew equivalents
- Cask installation for GUI applications

## Tags

- `extra-packages` - All extra package tasks
- `packages` - Package installation tasks
- `repositories` - Repository configuration
- `system-packages` - System package category
- `development-packages` - Development package category  
- `desktop-packages` - Desktop package category
- `media-packages` - Media package category
- `python-packages` - Python/pip packages
- `nodejs-packages` - Node.js/npm packages
- `merge` - Package source merging
- `summary` - Installation summaries

## Dependencies

- `basic_setup` role (provides essential foundation)
- `community.general` collection (for package managers)
- Native package managers (APT, pacman, Homebrew)

## License

MIT

## Author Information

Part of the wolskinet.infrastructure Ansible collection for cross-platform infrastructure management.