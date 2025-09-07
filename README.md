# Ansible Collection - wolskinet.infrastructure

Multi-OS infrastructure automation with unified variable taxonomy for Ubuntu 22+, Debian 12+, Arch Linux, and macOS. Provides declarative configuration through a domain/host/distribution hierarchy.

## Architecture Overview

### Unified Variable Structure
Infrastructure is configured through a three-tier hierarchy that separates concerns cleanly:

```yaml
infrastructure:
  # Domain-level: shared across all hosts in your environment
  domain:
    name: "company.com"           # Domain name
    timezone: "America/New_York"  # Shared timezone
    locale: "en_US.UTF-8"         # Shared locale/language
    ntp:                          # NTP configuration
      enabled: true
      servers: [0.pool.ntp.org, 1.pool.ntp.org]
    users: []                     # Domain users (consistent across hosts)
    
  # Host-level: per-host settings  
  host:
    hostname: "web01"             # Individual hostname
    update_hosts: true            # /etc/hosts management
    
  # Distribution-specific: OS-specific settings
  Ubuntu:
    packages: { all: [git, curl], repositories: {...} }
    snap: { disable_and_remove: true, packages: {...} }
    firewall: { enabled: false, rules: [] }
  Darwin:
    packages: { all: [git, curl] }
    # macOS-specific settings...
```

**Key Insight**: Users set variables declaratively at any inventory level (group_vars, host_vars) without being forced into specific group structures. The `{{ ansible_distribution }}` fact drives OS-specific behavior.

## Core Roles

### **configure_system** - Orchestration
Entry point that applies appropriate roles based on inventory membership. Handles role sequencing without forcing specific group structures.

### **os_configuration** - System Foundation  
Essential OS-level configuration using the domain/host separation:
- **Domain settings**: timezone, locale, NTP (consistent across environment)
- **Host settings**: hostname, /etc/hosts management
- **Distribution settings**: journal, services, unattended upgrades, platform specifics

### **manage_users** - System Account Management
System-level user account creation and management (requires sudo):
- **Domain users**: `infrastructure.domain.users[]` - consistent accounts across hosts
- **SSH key deployment**: automated authorized_key management
- **Password handling**: automatic SHA-512 hashing for plaintext passwords
- **Account lifecycle**: creation, removal, group membership

### **configure_user** - User Preference Configuration
Per-user preference configuration (executed as target user):
- **Cross-platform**: Git config, language packages (nodejs, rust, go)
- **OS-specific**: Shell settings, dotfiles deployment, GUI preferences
- **Auto-dependency installation**: installs nodejs/rustup/golang if packages requested
- **Dotfiles integration**: Stow-based dotfiles deployment from repositories

### **manage_packages** - Package Management
Distribution-specific package installation with hierarchical merging:
- **Package categories**: `all`, `group`, `host` - merged in precedence order  
- **Repository management**: APT sources, Homebrew taps, AUR helpers
- **Multi-package-manager**: handles APT, pacman, Homebrew transparently

### **manage_security_services** - Security Configuration
Firewall and intrusion prevention using distribution detection:
- **UFW** (Ubuntu/Debian), **firewalld** (Arch), **macOS firewall**
- **fail2ban**: intrusion detection with distribution-specific jails
- **Rule management**: declarative firewall rule configuration

### **manage_snap_packages** / **manage_flatpak** - Alternative Package Systems
- **Snap**: Ubuntu/Debian snap management (install/remove or complete system removal)
- **Flatpak**: Linux flatpak management with repository and plugin handling


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
# inventory/group_vars/all.yml - Domain-wide configuration
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
        
        # Cross-platform user preferences
        git:
          user_name: "Deploy User"
          user_email: "deploy@company.com"
        nodejs:
          packages: [pm2, typescript]
        rust:
          packages: [ripgrep, bat]
          
        # OS-specific preferences
        Ubuntu:
          shell: /usr/bin/zsh
          dotfiles:
            repository: "https://github.com/deploy/dotfiles-linux"
            method: stow
            packages: [zsh, tmux]
        Darwin:
          shell: /opt/homebrew/bin/zsh
          dotfiles:
            repository: "https://github.com/deploy/dotfiles-macos"
            method: stow
            packages: [zsh, tmux, macos]
        
  Ubuntu:
    packages:
      all: [git, curl, htop, vim]
    snap:
      disable_and_remove: true
      
# inventory/group_vars/webservers.yml - Web server group
infrastructure:
  Ubuntu:
    packages:
      group: [nginx, certbot]
    firewall:
      enabled: true
      rules:
        - { port: 80, protocol: tcp }
        - { port: 443, protocol: tcp }
        
# inventory/host_vars/web01.yml - Individual host  
infrastructure:
  host:
    hostname: "web01"
  Ubuntu:
    packages:
      host: [redis-server]
```

### Basic Playbook
```yaml
# playbooks/site.yml
- hosts: all
  roles:
    - wolskinet.infrastructure.os_configuration
    - wolskinet.infrastructure.manage_users        # Creates user accounts
    - wolskinet.infrastructure.manage_packages

- hosts: webservers  
  roles:
    - wolskinet.infrastructure.manage_security_services

# Configure user preferences (runs as each user)
- hosts: all
  vars:
    target_user: "{{ item }}"
  include_role:
    name: wolskinet.infrastructure.configure_user
  become: true
  become_user: "{{ item }}"
  loop: "{{ infrastructure.domain.users | map(attribute='name') | list }}"
```

## Advanced Configuration

### Multi-OS Package Management
```yaml
infrastructure:
  Ubuntu:
    packages:
      all: [git, curl, htop]
      repositories:
        all:
          - name: docker
            types: deb
            uris: https://download.docker.com/linux/ubuntu
            suites: "{{ ansible_distribution_release }}"
            components: stable
            signed_by: https://download.docker.com/linux/ubuntu/gpg
            
  Darwin:
    packages:
      all: [git, curl, htop]  # Installed via Homebrew
      
  Archlinux:
    packages:
      all: [git, curl, htop]  # Installed via pacman
```

### Firewall Configuration
```yaml
infrastructure:
  Ubuntu:
    firewall:
      enabled: true
      rules:
        - port: 22
          protocol: tcp
          src: "192.168.1.0/24"
          comment: "SSH from local network"
        - port: [80, 443]
          protocol: tcp  
          comment: "HTTP/HTTPS"
    fail2ban:
      enabled: true
      jails:
        - name: sshd
          enabled: true
          bantime: 3600
```

### Alternative Package Systems
```yaml
infrastructure:
  Ubuntu:
    snap:
      disable_and_remove: true  # Complete snap removal
      # OR for managed snap usage:
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
        # Cross-platform language packages (auto-installs tools if missing)
        nodejs:
          packages: [typescript, eslint, prettier]  # Auto-installs nodejs
        rust:
          packages: [ripgrep, fd-find, bat]         # Auto-installs rustup
        go:
          packages: [github.com/charmbracelet/glow@latest]  # Auto-installs golang
        
        Ubuntu:
          shell: /usr/bin/zsh
        Darwin:
          shell: /opt/homebrew/bin/zsh
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

**Arch Linux**  
- Pacman package management
- Flatpak support  
- firewalld configuration
- systemd journal/service management

**macOS (Intel/Apple Silicon)**
- Homebrew package management
- System preference automation
- Built-in firewall configuration  
- Xcode Command Line Tools requirement

## Variable Hierarchy & Merging

The `infrastructure` structure supports flexible configuration patterns:

```yaml
# Variables merge by precedence: all < group < host
# inventory/group_vars/all.yml
infrastructure:
  Ubuntu:
    packages:
      all: [git, curl]

# inventory/group_vars/webservers.yml  
infrastructure:
  Ubuntu:
    packages:
      group: [nginx]

# inventory/host_vars/web01.yml
infrastructure:
  Ubuntu:
    packages:
      host: [redis-server]

# Final result: [git, curl, nginx, redis-server]
```

**Key Point**: Variable names like `infrastructure.Ubuntu.packages.all` vs `infrastructure.Ubuntu.packages.group` indicate *scope* not *precedence*. Ansible's standard variable precedence (group_vars < host_vars) still applies.

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
- **Domain/Host/Distribution** separation eliminates configuration duplication
- **Distribution fact-driven** OS detection - no forced inventory structure  
- **Declarative configuration** - users specify desired state, roles handle implementation
- **Multi-platform** with unified variable taxonomy across Ubuntu/Debian/Arch/macOS
