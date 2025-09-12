# Ansible Collection - wolskinet.infrastructure

Ansible infrastructure automation for Ubuntu 22+, Debian 12+, Arch Linux, and macOS.

**Note**: Language packages (nodejs, rust, go) require Ubuntu 24.04+ and Debian 13+ for reliable auto-installation due to package availability.

## Architecture Overview

### Variable Structure

Roles share a common variable structure for interoperability. Most OS differences are handled by task logic. The major exception is for packages, since package names may differ across operating systems. Some functionality has been include in user configuration for operating system specific preferences as well.

```yaml
infrastructure:
  domain:
    name: "company.com"              # Optional: defaults to ""
    timezone: "America/New_York"     # Optional: defaults to "" (system default)
    locale: "en_US.UTF-8"            # Optional: defaults to system locale
    ntp:
      enabled: true                  # Optional: defaults to false (system default)
      servers: [time1.company.com]   # Optional: defaults to [] (system defaults)
    users: []

  host:
    hostname: "web01"                # Optional: individual hostname
    update_hosts: true               # Optional: /etc/hosts management
    packages: # Optional: package management structure documented below
      present:
        all:
          Ubuntu: [git, curl]
          Darwin: [git, curl]
        group:
          Ubuntu: [nginx]
        host:
          Ubuntu: [redis-server]
    firewall:                        # Optional: firewall configuration
      enabled: true                  # When enabled, configures UFW/macOS firewall
      rules: []
    snap:                            # Optional: snap management
      disable_and_remove: false      # Optional: defaults to false (preserve system snap)
    flatpak:                         # Optional: flatpak management
      enabled: false                 # Optional: defaults to false
```

### Complete Variable Schema

```yaml
infrastructure:
  domain:
    name: ""                         # Domain name (optional)
    timezone: ""                     # Timezone (optional, preserves system default)
    locale: "en_US.UTF-8"           # System locale
    language: "en_US.UTF-8"         # System language
    ntp:
      enabled: false                 # NTP configuration (optional)
      servers: []                    # NTP servers (empty = system defaults)
    users: []                        # User definitions (see User Management section)

  host:
    hostname: ""                     # Individual hostname
    update_hosts: true               # /etc/hosts management

    journal:                         # systemd journal configuration (Linux)
      configure: false               # Optional: defaults to false
      max_size: "500M"
      max_retention: "30d"

    services: {}                     # systemd service management
    # services:
    #   enable: [nginx, redis]
    #   disable: [bluetooth]

    sysctl: {}                       # kernel parameter configuration
    # sysctl:
    #   parameters:
    #     vm.swappiness: 10

    modules: {}                      # kernel module management
    # modules:
    #   load: [uvcvideo]
    #   blacklist: [nouveau]

    udev: {}                         # udev rules management
    # udev:
    #   rules:
    #     - name: pico
    #       content: 'SUBSYSTEM=="usb", ATTRS{idVendor}=="2e8a"...'

    packages: {}                     # Package management (see schema below)
    # packages:
    #   present:
    #     all:                       # Packages for all hosts
    #       Ubuntu: [git, curl]
    #       Debian: [git, curl]
    #       Archlinux: [git, curl]
    #       MacOSX: [git, curl]
    #     group:                     # Packages for group
    #       Ubuntu: [nginx]
    #     host:                      # Packages for specific host
    #       Ubuntu: [redis-server]
    #   remove:                      # Packages to remove
    #     all:
    #       Ubuntu: [snapd]
    #   casks_present:               # macOS casks
    #     all: [visual-studio-code]
    #   casks_remove: []
    #   apt:                         # APT-specific settings
    #     apt_cache:
    #       update_cache: false      # No forced cache updates
    #       valid_time: 3600
    #     unattended_upgrades:
    #       enabled: false           # Opt-in automatic updates
    #     repositories: {}           # APT repository management
    #   pacman:                      # Pacman-specific settings
    #     enable_aur: false          # Opt-in AUR enablement
    #     aur_helper: paru
    #   homebrew:                    # Homebrew settings (macOS)
    #     install: true              # Auto-install Homebrew
    #     update_homebrew: true

    firewall:                        # Firewall configuration
      enabled: false                 # Firewall management
      prevent_ssh_lockout: true      # SSH safety
      rules: []
      # rules:
      #   - port: 80
      #     proto: tcp
      #     comment: "HTTP"

    fail2ban:                        # Intrusion detection (Linux)
      enabled: false
      services:
        - name: sshd
          enabled: true
          maxretry: 5
          bantime: 3600

    snap:                            # Snap management (Ubuntu/Debian)
      disable_and_remove: false      # Preserves system snap by default
      packages: {}
      # packages:
      #   install: [hello-world]
      #   remove: [unwanted-snap]

    flatpak:                         # Flatpak management (Linux)
      enabled: false
      packages: {}
      flathub: true                  # Add Flathub repository
      plugins:
        gnome: false
        plasma: false
```

## Core Roles

### **discovery**
Scans systems and generates `host_vars/hostname.yml` files with discovered configuration in collection format.

### **configure_system**
Orchestrates other collection roles. Calls os_configuration, manage_users, manage_packages, manage_security_services, etc. in proper order.

### **os_configuration**
- Configures timezone, locale, NTP servers
- Sets hostname and manages /etc/hosts
- Manages systemd services, journal settings, sysctl parameters
- Platform-specific: APT unattended upgrades, macOS gatekeeper

### **manage_users**
Creates system user accounts, groups, SSH keys. Requires sudo. Reads from `infrastructure.domain.users[]`.

### **configure_user**
Configures per-user preferences (runs as target user):
- Git config, shell preferences
- Language packages: nodejs, rust, go (auto-installs dependencies)
- Dotfiles deployment via stow
- macOS GUI settings (dock, finder)

### **manage_packages**
- System-wide package installation via APT/pacman/Homebrew
- Repository management (APT sources, Homebrew taps, AUR helpers)
- **Package globbing**: Combines `all`/`group`/`host` package lists additively within final variable structure
- Platform detection handles Ubuntu/Debian/Arch/macOS differences

### **manage_security_services**
- UFW firewall (Linux) and macOS application firewall
- fail2ban intrusion detection with service-specific jails
- Declarative firewall rule management

### **manage_snap_packages** / **manage_flatpak**
- **Snap**: Preserves system snap by default, optional package management or complete removal
- **Flatpak**: Optional flatpak management with repository and desktop plugin support

## Installation & Usage

```bash
ansible-galaxy collection install wolskinet.infrastructure

# Create inventory structure (flexible - organize as needed)
mkdir -p inventory/{group_vars/all,host_vars}
mkdir -p playbooks
```

### Declarative Configuration

Variables are set anywhere in your inventory hierarchy:

```yaml
# inventory/group_vars/all.yml
infrastructure:
  domain:
    name: "company.local"
    timezone: "America/New_York"
    ntp:
      servers: [time1.company.com, time2.company.com]
    users:
      - name: deploy
        comment: "Deployment User"
        groups: [sudo]
        ssh_pubkey: "ssh-ed25519 AAAAC3..."
        shell: /bin/zsh              # Cross-platform shell preference

        # Cross-platform user preferences
        git:
          user_name: "Deploy User"
          user_email: "deploy@company.com"
        nodejs:
          packages: [pm2, typescript]
        rust:
          packages: [ripgrep, bat]
        dotfiles:
          repository: "https://github.com/deploy/dotfiles"
          method: stow
          packages: [zsh, tmux]

        # Only macOS-specific GUI preferences need their own section
        macosx:
          dock:
            tile_size: 48
            autohide: true

  host:
    packages:
      present:
        all:
          Ubuntu: [git, curl, htop, vim]
          Darwin: [git, curl, htop, vim]
    snap:
      disable_and_remove: true      # Explicit opt-in for snap removal

# inventory/group_vars/webservers.yml
infrastructure:
  host:
    packages:
      present:
        group:
          Ubuntu: [nginx, certbot]
          Darwin: [nginx, certbot]
    firewall:
      enabled: true
      rules:
        - { port: 80, proto: tcp }
        - { port: 443, proto: tcp }

# inventory/host_vars/web01.yml
infrastructure:
  host:
    hostname: "web01"
    packages:
      present:
        host:
          Ubuntu: [redis-server]
          Darwin: [redis]
```

### Basic Playbook

```yaml
# playbooks/site.yml
- hosts: all
  roles:
    - wolskinet.infrastructure.os_configuration
    - wolskinet.infrastructure.manage_users # Creates user accounts
    - wolskinet.infrastructure.manage_packages

- hosts: webservers
  roles:
    - wolskinet.infrastructure.manage_security_services

# Configure user preferences (runs as each user)
- hosts: all
  tasks:
    - name: Configure user preferences
      include_role:
        name: wolskinet.infrastructure.configure_user
      vars:
        target_user: "{{ user_item }}"
      loop: "{{ infrastructure.domain.users }}"
      loop_control:
        loop_var: user_item
      when: user_item.name != 'root'  # Skip system accounts
```

## Advanced Configuration

### Multi-OS Package Management

```yaml
infrastructure:
  host:
    packages:
      present:
        all:
          Ubuntu: [git, curl, htop]
          Darwin: [git, curl, htop] # Installed via Homebrew
          Archlinux: [git, curl, htop] # Installed via pacman
      apt:
        repositories:
          all:
            Ubuntu:
              - name: docker
                types: deb
                uris: https://download.docker.com/linux/ubuntu
                suites: "{{ ansible_distribution_release }}"
                components: stable
                signed_by: https://download.docker.com/linux/ubuntu/gpg
            Debian:
              - name: docker
                types: deb
                uris: https://download.docker.com/linux/debian
                suites: "{{ ansible_distribution_release }}"
                components: stable
                signed_by: https://download.docker.com/linux/debian/gpg
```

### Firewall Configuration

```yaml
infrastructure:
  host:
    firewall:
      enabled: true
      rules:
        - port: 22
          proto: tcp
          src: "192.168.1.0/24"
          comment: "SSH from local network"
        - port: [80, 443]
          proto: tcp
          comment: "HTTP/HTTPS"
    fail2ban:
      enabled: true
      services:
        - name: sshd
          enabled: true
          bantime: 3600
```

### Alternative Package Systems

```yaml
infrastructure:
  host:
    snap:
      disable_and_remove: true # Opt-in complete snap removal
      # OR for managed snap usage (default preserves system snap):
      # disable_and_remove: false
      # packages:
      #   install: [hello-world]

    flatpak:
      enabled: true
      packages:
        install: [org.mozilla.firefox]
      flathub: true
      plugins:
        gnome: true
```

### User Language Development Environments

User-scoped language packages are configured per-user with automatic dependency installation:

```yaml
infrastructure:
  domain:
    users:
      - name: developer
        shell: /bin/zsh # Cross-platform shell preference
        # Cross-platform language packages (auto-installs tools if missing)
        nodejs:
          packages: [typescript, eslint, prettier] # Auto-installs nodejs
        rust:
          packages: [ripgrep, fd-find, bat] # Auto-installs rustup
        go:
          packages: [github.com/charmbracelet/glow@latest] # Auto-installs golang

        # Only macOS-specific GUI preferences
        macosx:
          dock:
            tile_size: 36
            autohide: false
```

Language tools are installed automatically when user requests packages:

- `nodejs.packages` → installs `nodejs` system package if `npm` not found
- `rust.packages` → installs `rustup` system package if `cargo` not found
- `go.packages` → installs `golang` system package if `go` not found

## Platform Support

**Ubuntu 22+ / Debian 12+**

- APT package management with repository handling
- Snap system management (complete removal or controlled usage)
- UFW firewall with fail2ban integration
- Unattended upgrades configuration

**Language Package Requirements:**
- **Ubuntu 24.04+**: Required for reliable nodejs and rustup package availability
- **Debian 13+**: Required for rustup package (nodejs available in 12+)
- **Older versions**: Language packages may fail to auto-install; manually install tools first

**Arch Linux**

- Pacman package management with AUR support
- Flatpak support
- systemd journal/service management

**macOS (Intel/Apple Silicon)**

- Homebrew package management
- System preference automation
- Built-in application firewall configuration
- Xcode Command Line Tools requirement

## Package Organization & Globbing

The collection allows packages to be defined at different inventory levels and automatically globs them together for installation:

```yaml
# inventory/group_vars/all.yml
infrastructure:
  host:
    packages:
      present:
        all:
          Ubuntu: [git, curl]

# inventory/group_vars/webservers.yml
infrastructure:
  host:
    packages:
      present:
        group:
          Ubuntu: [nginx]

# inventory/host_vars/web01.yml
infrastructure:
  host:
    packages:
      present:
        host:
          Ubuntu: [redis-server]

# Final result on web01: [git, curl, nginx, redis-server]
```

**How it works:**
- Ansible's standard variable precedence applies normally (group_vars < host_vars)
- The `manage_packages` role reads the final merged variable structure
- **Within** that structure, `all`/`group`/`host` categories are globbed together additively
- This allows flexible package organization without precedence override issues

## Dependencies

**Required Collections:**

- `community.general` - firewall, package management, macOS defaults
- `ansible.posix` - sysctl, authorized_key, other POSIX utilities

**System Requirements:**

- **Ansible**: Core 2.12+
- **Target Systems**: Python 3.6+, sudo access
- **macOS**: Xcode Command Line Tools (`xcode-select --install`)

## License

MIT

---

**Architecture Summary:**

- **Domain/Host** separation eliminates configuration duplication
- **Distribution fact-driven** OS detection - no forced inventory structure
- **Declarative configuration** - users specify desired state, roles handle implementation
- **Multi-platform** with unified variable structure across Ubuntu/Debian/Arch/macOS
