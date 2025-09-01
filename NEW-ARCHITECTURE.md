# Infrastructure Collection - New Architecture

## Overview

The collection has been redesigned with a clean separation of concerns using **standalone roles** coordinated by a **master orchestration role**.

## Architecture Philosophy

### Master + Standalone Pattern
- **`configure_system`**: Full-meal-deal orchestration role for new machines
- **Individual roles**: Standalone, focused, can be used independently

### Role Hierarchy
```
configure_system (master orchestration)
├── os_configuration (OS setup after fresh install)
├── manage_users (user/group management)  
├── manage_packages (package installation)
└── manage_third_party (development tools)

Standalone utility roles:
├── manage_firewall_rules (firewall rule management)
├── dotfiles (user dotfiles deployment)
├── discovery (infrastructure scanning)
└── manage_language_packages (language-specific tools)
```

## Role Purposes

### 🎯 **configure_system** - Master Orchestration
**Purpose**: Complete new machine setup in proper order
**When to use**: Fresh OS installation, full system configuration
**Dependencies**: Calls other roles in sequence

```yaml
- role: wolskinet.infrastructure.configure_system
  vars:
    # All configuration passed through to individual roles
    config_common_hostname: "web-server"
    users_config: [...]
    all_packages_install_Ubuntu: [...]
```

### 🔧 **os_configuration** - Post-Install OS Setup  
**Purpose**: OS-level configuration after fresh install
**When to use**: Right after OS installation, basic system setup
**What it does**:
- Hostname and domain configuration
- Timezone and locale setup
- **Firewall installation and enabling**
- NTP synchronization
- System limits and kernel parameters
- OS-specific optimizations

```yaml
- role: wolskinet.infrastructure.os_configuration
  vars:
    config_common_hostname: "server-01"
    config_common_domain: "example.com"
    config_common_timezone: "America/New_York"
    config_linux_ntp:
      enabled: true
    # Firewall gets ENABLED here
```

### 👥 **manage_users** - User Management
**Purpose**: Create/manage users and groups  
**When to use**: User administration, team onboarding
**What it does**:
- User creation with SSH keys
- Group management
- Home directory setup
- Dotfiles integration

```yaml
- role: wolskinet.infrastructure.manage_users
  vars:
    users_config:
      - name: developer
        groups: [sudo, docker]
        ssh_pubkey: "ssh-rsa AAAA..."
        dotfiles_repository_url: "https://github.com/dev/dotfiles"
```

### 📦 **manage_packages** - Package Management
**Purpose**: Install OS packages via system package managers
**When to use**: Package installation, system software
**What it does**:
- APT/Pacman/Homebrew packages
- Hierarchical package variables (all/group/host)
- Repository management

```yaml
- role: wolskinet.infrastructure.manage_packages
  vars:
    all_packages_install_Ubuntu:
      - git
      - curl
      - htop
    group_packages_install_Ubuntu:
      - nginx
      - certbot
```

### 🛠️ **manage_third_party** - Development Tools  
**Purpose**: Install third-party tools and development environments
**When to use**: Development setup, specific toolchains
**What it does**:
- Docker, Node.js, Python, Rust, Go
- IDEs (VS Code, JetBrains)
- Infrastructure tools (Terraform, kubectl, Helm)
- Version-specific installations

```yaml
- role: wolskinet.infrastructure.manage_third_party
  vars:
    manage_third_party_tools:
      docker: true
      nodejs: true
      vscode: true
    manage_third_party_docker:
      users: [developer, admin]
```

### 🔥 **manage_firewall_rules** - Firewall Rules
**Purpose**: Add/remove firewall rules (NOT enable firewall)
**When to use**: Service deployment, port management, security rules
**What it does**:
- Add specific port rules
- Service-based rules (HTTP, SSH, custom)
- fail2ban configuration
- **Assumes firewall already enabled by os_configuration**

```yaml
- role: wolskinet.infrastructure.manage_firewall_rules
  vars:
    firewall_rules:
      - port: 80
        protocol: tcp
        rule: allow
        comment: "HTTP traffic"
      - port: 443  
        protocol: tcp
        rule: allow
        comment: "HTTPS traffic"
```

## Usage Patterns

### Pattern 1: Full New Machine Setup
```yaml
- hosts: new_servers
  roles:
    - role: wolskinet.infrastructure.configure_system
      vars:
        # OS configuration
        config_common_hostname: "{{ inventory_hostname }}"
        config_common_domain: "production.example.com"
        
        # Users
        users_config:
          - name: admin
            groups: [sudo]
            ssh_pubkey: "{{ admin_ssh_key }}"
            
        # Packages  
        all_packages_install_Ubuntu:
          - git
          - htop
          - nginx
          
        # Third-party tools
        manage_third_party_tools:
          docker: true
          nodejs: true
```

### Pattern 2: Specific Task (Standalone)
```yaml
# Just add a new user
- hosts: web_servers
  roles:
    - role: wolskinet.infrastructure.manage_users
      vars:
        users_config:
          - name: developer
            groups: [docker]

# Just open firewall ports for a web service  
- hosts: web_servers
  roles:
    - role: wolskinet.infrastructure.manage_firewall_rules
      vars:
        firewall_rules:
          - port: 80
            rule: allow
          - port: 443
            rule: allow
```

### Pattern 3: Service-Specific Configuration
```yaml
# Set up a web server
- hosts: web_servers
  tasks:
    # Install and configure nginx
    - name: Install nginx
      ansible.builtin.include_role:
        name: wolskinet.infrastructure.manage_packages
      vars:
        group_packages_install_Ubuntu: [nginx]
        
    # Configure nginx...
    
    # Open firewall ports
    - name: Configure firewall for web server
      ansible.builtin.include_role:
        name: wolskinet.infrastructure.manage_firewall_rules
      vars:
        firewall_rules:
          - port: 80
            rule: allow
            comment: "HTTP"
          - port: 443
            rule: allow  
            comment: "HTTPS"
```

## Benefits of New Architecture

### 🎯 **Clear Separation of Concerns**
- OS setup ≠ User management ≠ Package installation ≠ Firewall rules
- Each role has one focused responsibility
- Easy to test and debug individual components

### 🔄 **Flexibility**
- Use full orchestration OR individual roles
- Perfect for both "new machine setup" and "specific changes"
- Can call roles multiple times with different parameters

### 🚀 **Maintainability**  
- Add new functionality to specific roles
- Easy to extend without breaking existing workflows
- Clear documentation per role

### 📈 **Scalability**
- Roles can be developed independently
- Team members can own specific roles
- Easy to add new third-party tool support

## Migration from Old Architecture

### Before (Monolithic)
```yaml
- role: configure_host  # Did everything
  vars:
    config_hostname: "server"
    # Mixed: OS + users + packages + firewall
```

### After (Modular)
```yaml
# Option 1: Use orchestration (recommended for new machines)
- role: configure_system
  vars:
    config_common_hostname: "server"
    users_config: [...]
    
# Option 2: Use individual roles (specific tasks)
- role: os_configuration
- role: manage_users  
- role: manage_firewall_rules
```

## Implementation Status

### ✅ Completed
- ✅ `configure_system` - Master orchestration role
- ✅ `os_configuration` - Renamed and refactored from configure_host
- ✅ `manage_users` - Verified standalone-ready
- ✅ `manage_packages` - Verified standalone-ready  
- ✅ `manage_third_party` - Created with Docker example
- ✅ `manage_firewall_rules` - Renamed from manage_firewall

### 🚧 In Progress
- 🚧 Complete `manage_third_party` task implementations
- 🚧 Update all README files
- 🚧 Create example playbooks

### 📋 Next Steps  
1. Test master orchestration with all roles
2. Create comprehensive examples
3. Update collection documentation
4. Add molecule tests for new architecture

The collection now provides both the "full-meal-deal" experience AND granular control for specific tasks! 🎉