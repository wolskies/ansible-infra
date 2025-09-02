# manage_users

User account and group management with automated dotfiles deployment across multiple platforms.

## Description

This role manages system users and groups with integrated dotfiles deployment. It handles user creation, modification, and removal while automatically deploying dotfiles configurations using GNU Stow. The role supports cross-platform user management for Linux distributions and macOS with platform-specific defaults.

## Features

- **👤 User Management**: Create, modify, and remove system users
- **🔑 Authentication**: Password management, account locking, and SSH key deployment
- **👥 Group Assignment**: Add users to system and custom groups with flexible GID support
- **🏠 Home Directories**: Custom home directory paths with automatic creation
- **🎨 Dotfiles Integration**: Automatic dotfiles deployment via GNU Stow with nested configuration
- **🔄 Repository Management**: Clone and update user dotfiles repositories with branch control
- **🌐 Cross-Platform**: Linux and macOS user management support
- **⚙️ Discovery Integration**: Works with discovered user configurations
- **🔄 Backward Compatibility**: Supports both new nested format and legacy configuration

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

**Enhanced Format (Recommended):**
```yaml
users_config:
  - name: ed                                    # Required: username
    uid: "1000"                                # Optional: specific UID (string or int)
    gid: "1000"                                # Optional: primary group ID (string or int)
    home: /home/ed                             # Optional: home directory path
    shell: /bin/bash                           # Optional: user shell
    groups: [sudo, docker]                    # Optional: additional groups
    ssh_pubkey: var_users_config_ed_ssh_pubkey # Optional: SSH public key (variable reference)
    password: var_users_config_ed_password     # Optional: plaintext or hash (variable reference)
    dotfiles:                                  # Optional: dotfiles configuration
      enable: true                             # Required if dotfiles block present
      repo: "https://github.com/user/dotfiles" # Required: git repository URL
      branch: "main"                           # Optional: git branch (default: main)
      directory: "/home/ed/.dotfiles"          # Optional: clone directory (default: ~/.dotfiles)

  - name: shelly
    uid: "1001"
    gid: "1001"
    home: /home/shelly
    ssh_pubkey: var_users_config_shelly_ssh_pubkey
    password: var_users_config_shelly_password  # Optional: plaintext or hash (variable reference)
    dotfiles:
      enable: true
      repo: "https://github.com/shelly/dotfiles"
      branch: "main"
      directory: "/home/shelly/.dotfiles"
```

**Legacy Format (Still Supported):**
```yaml
users_config:
  - name: username                    # Required: username
    uid: 1001                        # Optional: specific UID
    shell: /bin/bash                 # Optional: user shell
    groups: [sudo, docker]          # Optional: additional groups
    password: "*"                    # Optional: plaintext, hash, or "*" (locked)
    create_home: true                # Optional: create home directory
    # Legacy dotfiles configuration
    dotfiles_repository_url: https://github.com/user/dotfiles
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
            password: "MySecurePassword123!"  # Will be hashed automatically
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

- **Ubuntu 22+**: Full support with automatic stow installation
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

### Password Handling

The role intelligently handles both plaintext and pre-hashed passwords:
- **Plaintext passwords**: Automatically hashed using SHA-512 when detected (recommended when using Ansible Vault)
- **Pre-hashed passwords**: Passed through unchanged (must start with `$`)
- **Account locking**: Use `"*"` to create locked accounts

Example with Ansible Vault:
```yaml
# group_vars/all/vault.yml (encrypted with ansible-vault)
vault_user_password: "MySecurePassword123!"

# group_vars/all/users.yml
users_config:
  - name: alice
    password: "{{ vault_user_password }}"  # Will be automatically hashed
```

### Other Security Features

- **Group Management**: Adds users to appropriate system groups
- **File Permissions**: Sets proper ownership on home directories
- **Dotfiles Security**: Uses HTTPS for repository cloning (no SSH keys required)

## License

MIT

## Author Information

Ed Wolski - wolskinet
