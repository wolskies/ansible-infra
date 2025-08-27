# manage_users

User account and group management with automated dotfiles deployment across multiple platforms.

## Description

This role manages system users and groups with integrated dotfiles deployment. It handles user creation, modification, and removal while automatically deploying dotfiles configurations using GNU Stow. The role supports cross-platform user management for Linux distributions and macOS with platform-specific defaults.

## Features

- **👤 User Management**: Create, modify, and remove system users
- **🔑 Authentication**: Password management and account locking
- **👥 Group Assignment**: Add users to system and custom groups
- **🏠 Home Directories**: Automatic home directory creation with proper permissions
- **🎨 Dotfiles Integration**: Automatic dotfiles deployment via GNU Stow
- **🔄 Repository Management**: Clone and update user dotfiles repositories
- **🌐 Cross-Platform**: Linux and macOS user management support
- **⚙️ Discovery Integration**: Works with discovered user configurations

## Role Variables

### User Configuration
- `users_config: []` - List of users to manage (see format below)
- `users_remove: []` - List of usernames to remove from system
- `users_default_shell: "/bin/bash"` - Default shell for new users
- `users_create_home: true` - Create home directories by default

### Platform-Specific Groups
- `users_default_groups_linux: []` - Default groups for Linux users
- `users_default_groups_macos: []` - Default groups for macOS users

### Dotfiles Integration
- `users_default_dotfiles_uses_stow: true` - Use GNU Stow for dotfiles
- `users_default_dotfiles_stow_packages: []` - Default stow packages (empty = all)

### User Configuration Format
```yaml
users_config:
  - name: username                    # Required: username
    uid: 1001                        # Optional: specific UID
    shell: /bin/bash                 # Optional: user shell
    groups: [sudo, docker]          # Optional: additional groups
    password: "*"                    # Optional: password hash or "*" (locked)
    create_home: true                # Optional: create home directory
    # Dotfiles configuration (optional)
    dotfiles_repository_url: https://github.com/user/dotfiles
    dotfiles_uses_stow: true         # Optional: use GNU Stow
    dotfiles_stow_packages: [zsh, git, tmux]  # Optional: specific packages
    dotfiles_update_repo: false      # Optional: update existing repo
```

## Dependencies

- **Dotfiles Integration**: Calls `wolskinet.infrastructure.dotfiles` role for users with dotfiles configuration
- **System Packages**: Requires stow package for dotfiles deployment (auto-installed on Linux)

## Example Playbook

### Basic User Management
```yaml
- hosts: all
  roles:
    - role: wolskinet.infrastructure.manage_users
      vars:
        users_config:
          - name: developer
            shell: /bin/zsh
            groups: [sudo]
            password: "$6$rounds=656000$salt$hash..."
          - name: service
            shell: /bin/bash
            password: "*"  # Locked account
```

### Users with Dotfiles
```yaml
- hosts: workstations
  roles:
    - role: wolskinet.infrastructure.manage_users
      vars:
        users_config:
          - name: developer
            shell: /bin/zsh
            groups: [sudo, docker]
            dotfiles_repository_url: "https://github.com/developer/dotfiles"
            dotfiles_uses_stow: true
            dotfiles_stow_packages: [zsh, git, tmux, vim]
```

### Discovery Integration
```yaml
- hosts: discovered_systems
  roles:
    - role: wolskinet.infrastructure.manage_users
      vars:
        # Use discovered user configuration
        users_config: "{{ discovered_users_config }}"
```

### Platform-Specific Configuration
```yaml
# Linux systems
- hosts: linux
  roles:
    - role: wolskinet.infrastructure.manage_users
      vars:
        users_default_groups_linux: [sudo]
        users_config:
          - name: admin
            groups: [sudo, adm]

# macOS systems  
- hosts: darwin
  roles:
    - role: wolskinet.infrastructure.manage_users
      vars:
        users_default_groups_macos: [admin]
        users_config:
          - name: developer
            groups: [admin, staff]
```

### User Removal
```yaml
- hosts: all
  roles:
    - role: wolskinet.infrastructure.manage_users
      vars:
        users_remove:
          - old_user
          - temporary_account
```

## Platform Support

- **Ubuntu 24.04+**: Full support with automatic stow installation
- **Debian 12+**: Full support with automatic stow installation  
- **Arch Linux**: Full support with automatic stow installation
- **macOS**: Full support (requires manual stow installation: `brew install stow`)

## Integration with Other Roles

### With Discovery Role
```yaml
# Discovery generates discovered_users_config variable
- hosts: all
  roles:
    - wolskinet.infrastructure.discovery  # Generates user configurations
    - role: wolskinet.infrastructure.manage_users
      vars:
        users_config: "{{ discovered_users_config }}"
```

### With Package Management
```yaml
- hosts: workstations
  roles:
    - wolskinet.infrastructure.manage_packages  # Install stow and dependencies
    - wolskinet.infrastructure.manage_users     # Create users with dotfiles
```

## Dotfiles Integration

The role automatically integrates with the `dotfiles` role for users that have `dotfiles_repository_url` defined:

1. **Automatic Deployment**: Calls dotfiles role per-user
2. **Conflict Resolution**: Backs up existing files before deployment  
3. **Stow Management**: Uses GNU Stow for symlink-based dotfiles
4. **Repository Updates**: Optionally updates existing dotfiles repositories

### Dotfiles Repository Structure
```
dotfiles-repo/
├── zsh/
│   ├── .zshrc
│   └── .zshenv  
├── git/
│   └── .gitconfig
├── tmux/
│   └── .tmux.conf
└── vim/
    └── .vimrc
```

## Discovery Variables

When used with the discovery role, the following variables are automatically populated:

```yaml
discovered_users_config:
  - name: detected_user
    shell: /bin/zsh
    groups: [sudo, docker]
    dotfiles_repository_url: "https://github.com/user/dotfiles"
    dotfiles_uses_stow: true
    dotfiles_stow_packages: [zsh, git, tmux]
```

## Security Considerations

- **Password Handling**: Supports password hashes and account locking
- **Group Management**: Adds users to appropriate system groups
- **File Permissions**: Sets proper ownership on home directories
- **Dotfiles Security**: Uses HTTPS for repository cloning (no SSH keys required)

## License

MIT

## Author Information

Ed Wolski - wolskinet