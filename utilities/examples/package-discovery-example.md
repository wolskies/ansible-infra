# Package Discovery Example

This example shows how the discovery utility comprehensively scans and categorizes all installed packages for replication.

## Example: Discovering an Arch Linux Workstation

### 1. Run Discovery

```bash
# Create temporary inventory for existing machine
cat > temp-inventory.yml << EOF
target_machines:
  hosts:
    arch-workstation:
      ansible_host: 192.168.1.100
EOF

# Run discovery
ansible-playbook -i temp-inventory.yml \
  utilities/playbooks/discover-infrastructure.yml
```

### 2. Generated Package Configuration

The discovery creates a comprehensive package file: `host_vars/arch-workstation-packages.yml`

```yaml
# Package Replication Configuration for arch-workstation
# Total packages discovered: 847

discovered_packages:
  # Core system packages (essential for functionality)
  essential:
    - git
    - curl
    - wget
    - vim
    - htop
    - tree
    - unzip
    - rsync
    - openssh-server

  # Development tools
  development:
    - python3
    - python3-pip
    - nodejs
    - npm
    - go
    - rust
    - cargo
    - docker
    - docker-compose
    - code
    - cmake
    - gcc

  # System administration
  admin_tools:
    - fail2ban
    - ufw
    - chrony
    - rsyslog
    - logrotate

  # Desktop environment packages
  desktop_environment:
    - gnome
    - gdm3
    - xorg
    - wayland

  # Multimedia and desktop applications
  desktop:
    - firefox
    - libreoffice
    - vlc
    - gimp
    - obs-studio

  # All other packages (comprehensive list of 800+ packages)
  other:
    - acl
    - alsa-utils
    - base
    - bash
    - bluez
    - bzip2
    # ... (all other 800+ packages)

# Package installation strategy
package_installation_strategy:
  priority_order:
    - essential      # Install these first
    - admin_tools    # Then admin tools
    - development    # Then dev tools
    - desktop_environment  # Then desktop
    - desktop        # Then desktop apps
    - other          # Finally everything else

  # Arch-specific configuration
  pacman_packages: [combined list of all packages]
  
  # AUR packages detected
  aur_packages:
    - yay
    - visual-studio-code-bin
    - google-chrome
    - discord

# Package exclusions (auto-detected)
exclude_packages:
  - linux-firmware
  - systemd
  - nvidia-driver-515  # Hardware-specific
```

### 3. Generated Replication Playbook

The replication playbook installs packages in priority order:

```yaml
# replicate-arch-workstation.yml
- name: Replicate discovered infrastructure for arch-workstation
  hosts: arch-workstation
  vars_files:
    - "host_vars/arch-workstation-packages.yml"
  
  tasks:
    # Install essential packages first
    - name: Install essential packages first
      ansible.builtin.package:
        name: "{{ discovered_packages.essential }}"
        state: present
      become: true

    # Install development tools
    - name: Install development packages
      ansible.builtin.package:
        name: "{{ discovered_packages.development }}"
        state: present
      become: true

    # Install AUR packages (requires yay)
    - name: Install AUR packages
      ansible.builtin.command: yay -S --noconfirm {{ item }}
      loop: "{{ aur_packages }}"
      become: false
```

## Example: Discovering a macOS System

### macOS Package Discovery

```yaml
# host_vars/macbook-pro-packages.yml
homebrew_configuration:
  # Command-line tools (87 packages)
  formulae:
    - git
    - python@3.11
    - node
    - go
    - rust
    - docker
    - kubectl
    - terraform
    - ansible
    - vim
    - tmux
    - fzf
    # ... 75 more packages

  # GUI applications (23 apps)
  casks:
    - visual-studio-code
    - firefox
    - google-chrome
    - docker
    - slack
    - discord
    - vlc
    - spotify
    - notion
    # ... 14 more apps

  # Categorized for easier management
  categorized_formulae:
    essential: [git, curl, wget, vim, htop]
    development: [python, node, go, rust, docker]
    productivity: [tmux, fzf, ripgrep, bat, jq]

  categorized_casks:
    browsers: [firefox, google-chrome]
    development: [visual-studio-code, docker, postman]
    productivity: [slack, discord, notion]
    multimedia: [vlc, spotify]
```

## Package Installation Strategies

### 1. Priority-Based Installation

```yaml
# Install in order of importance
package_installation_strategy:
  priority_order:
    1. essential       # Core system tools
    2. admin_tools     # System administration
    3. development     # Development environment
    4. desktop_environment  # GUI framework
    5. desktop         # User applications
    6. other          # Everything else
```

### 2. Category-Based Installation

```yaml
# Install by function/category
- name: Install by category
  ansible.builtin.package:
    name: "{{ discovered_packages[item] }}"
    state: present
  loop:
    - essential
    - development
    - admin_tools
  become: true
```

### 3. Smart Exclusions

The discovery automatically excludes problematic packages:

```yaml
exclude_packages:
  # System packages (auto-managed)
  - linux-firmware
  - kernel
  - systemd

  # Hardware-specific
  - nvidia-driver-*
  - amd64-microcode

  # Dependencies (auto-installed)
  - libc6
  - libssl*
```

## Validation and Testing

### Package Validation

```bash
# Validate package installation
ansible-playbook -i discovered-infrastructure/inventory.yml \
  utilities/playbooks/validate-discovery.yml

# Check package differences
cat discovered-infrastructure/validation-report.yml
```

Example validation output:

```yaml
validation_summary:
  hostname: arch-workstation
  differences_found:
    packages:
      missing: []  # No packages missing
      added: ["new-package"]  # New package since discovery
  recommendations:
    - "Package installation successful"
    - "Consider updating discovery for new packages"
```

## Advanced Package Management

### Custom Package Lists

```yaml
# Create custom package groups
custom_package_groups:
  security_tools:
    - fail2ban
    - ufw
    - clamav
    - rkhunter
  
  media_production:
    - obs-studio
    - kdenlive
    - audacity
    - gimp
    - blender
```

### Version Pinning

```yaml
# Pin specific versions for stability
pinned_versions:
  python: "3.11.5"
  docker: "24.0.7"
  nodejs: "18.17.0"
```

### Conditional Installation

```yaml
# Install packages based on conditions
- name: Install GPU packages
  ansible.builtin.package:
    name: "{{ gpu_packages[detected_gpu] }}"
    state: present
  when: detected_gpu in gpu_packages
  vars:
    gpu_packages:
      nvidia: ["nvidia-driver", "cuda"]
      amd: ["mesa", "vulkan-radeon"]
```

## Summary

The package discovery utility provides:

✅ **Complete package inventory** (all installed packages)  
✅ **Smart categorization** (essential, development, desktop, etc.)  
✅ **Priority-based installation** (critical packages first)  
✅ **Multi-package-manager support** (apt, pacman, homebrew, snap, AUR)  
✅ **Intelligent exclusions** (hardware-specific, system packages)  
✅ **Validation and testing** (verify successful replication)  

This ensures you can replicate any machine's software environment with confidence!