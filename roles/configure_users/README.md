# configure_users

Mass user account management and development environment configuration.

## What It Does

Manages multiple user accounts and their preferences:
- **User Account** - Create/manage users with passwords, groups, shell, SSH keys
- **Development Environment** - Git, Node.js, Rust, Go, Neovim
- **Platform-Specific** - Dock/Finder preferences (macOS), Homebrew PATH
- **Dotfiles** - Automatic deployment using GNU Stow

## Key Features

- **Mass Management** - Configure rosters of users in one playbook run
- **Password Required** - Users must have passwords defined (prevents lockouts)
- **ansible_user Protection** - Skips ansible_user by default (set `manage_ansible_user: true` to override)
- **Existing User Support** - Configures preferences for existing users without touching authentication
- **Safe Group Management** - Groups append by default (`append: true`)

## Usage

### Basic User Roster
```yaml
- hosts: all
  become: true
  roles:
    - name: wolskies.infrastructure.configure_users

  vars:
    users:
      - name: developer
        password: "{{ vault_developer_password }}"  # REQUIRED
        comment: "Developer Account"
        groups: [sudo, docker]
        append: true  # Default: append groups instead of replacing
        shell: /bin/bash
        ssh_keys:
          - key: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5..."
            comment: "developer@workstation"

      - name: deployment
        password: "{{ vault_deployment_password }}"  # REQUIRED
        shell: /bin/bash
        superuser: true
        ssh_keys:
          - key: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQAB..."
            comment: "deployment@ci"
```

### Development Environment Setup
```yaml
users:
  - name: developer
    password: "{{ vault_developer_password }}"  # REQUIRED
    superuser: true
    superuser_passwordless: true
    git:
      user_name: "Developer Name"
      user_email: "developer@company.com"
      editor: "nvim"
    nodejs:
      packages: [typescript, eslint, prettier]
    rust:
      packages: [ripgrep, bat, fd-find]
    go:
      packages: [github.com/charmbracelet/glow@latest]
    neovim:
      enabled: true
    dotfiles:
      enable: true
      repository: "https://github.com/developer/dotfiles"
      dest: ".dotfiles"
```

### Managing ansible_user
```yaml
users:
  - name: "{{ ansible_user }}"  # e.g., "ubuntu" or "root"
    manage_ansible_user: true  # REQUIRED to manage ansible_user
    password: "{{ vault_ansible_user_password }}"
    git:
      user_name: "System Admin"
      user_email: "admin@example.com"
    dotfiles:
      enable: true
      repository: "https://github.com/admin/dotfiles"
```

### Configuring Existing Users (No Password Needed)
```yaml
# Configure preferences for users that already exist on the system
# Password not required - only preferences will be configured
users:
  - name: existinguser  # Already exists on system
    # No password - account creation skipped
    git:
      user_name: "Existing User"
      user_email: "existing@example.com"
    neovim:
      enabled: true
```

### macOS-Specific Configuration
```yaml
users:
  - name: developer
    password: "{{ vault_developer_password }}"
    Darwin:
      dock:
        tile_size: 48
        autohide: true
        minimize_to_application: false
        show_recents: false
      finder:
        show_extensions: true
        show_hidden: true
        show_pathbar: true
        show_statusbar: true
      screenshots:
        directory: "Screenshots"
        format: "png"
      iterm2:
        prompt_on_quit: false
```

## Variables

### User Object Schema

The role processes the `users` list variable. Each user object in the list has the following schema:
| Field                    | Type         | Required | Default       | Description                                                                  |
|--------------------------|--------------|----------|---------------|------------------------------------------------------------------------------|
| `name`                   | string       | Yes      | -             | Username (alphanumeric + underscore/hyphen, max 32 chars)                    |
| `groups`                 | list[string] | No       | `[]`          | Secondary groups (automatically uses append: true when defined)              |
| `shell`                  | string       | No       | `/bin/bash`   | Login shell                                                                  |
| `comment`                | string       | No       | `""`          | GECOS field (user description)                                               |
| `password`               | string       | No       | none          | Password hash (use ansible-vault for security)                               |
| `ssh_keys`               | list[object] | No       | `[]`          | SSH authorized keys (see SSH key schema below)                               |
| `state`                  | enum         | No       | `"present"`   | User state ("present" or "absent")                                           |
| `superuser`              | boolean      | No       | `false`       | Grant sudo access via platform admin group                                   |
| `superuser_passwordless` | boolean      | No       | `false`       | Enable passwordless sudo (requires superuser: true)                          |
| `git.user_name`          | string       | No       | none          | Git global user.name setting                                                 |
| `git.user_email`         | string       | No       | none          | Git global user.email setting                                                |
| `git.editor`             | string       | No       | none          | Git global core.editor setting                                               |
| `nodejs.packages`        | list[string] | No       | `[]`          | npm package names to install globally                                        |
| `rust.packages`          | list[string] | No       | `[]`          | Cargo package names to install                                               |
| `go.packages`            | list[string] | No       | `[]`          | Go package URLs to install                                                   |
| `neovim.enabled`         | boolean      | No       | `false`       | Install and configure Neovim                                                 |
| `dotfiles.enable`        | boolean      | No       | `false`       | Enable dotfiles deployment                                                    |
| `dotfiles.repository`    | string       | No       | none          | Git repository URL for dotfiles                                              |
| `dotfiles.dest`          | string       | No       | `".dotfiles"` | Destination directory name in user's home                                    |

### SSH Key Object Schema
| Field       | Type    | Required | Default     | Description                                                |
|-------------|---------|----------|-------------|------------------------------------------------------------|
| `key`       | string  | Yes      | -           | SSH public key content (full key string)                   |
| `comment`   | string  | No       | none        | Override key comment                                       |
| `options`   | string  | No       | none        | Key options (e.g., "no-port-forwarding,from='10.0.0.0/8'") |
| `exclusive` | boolean | No       | `false`     | Remove all other keys if true                              |
| `state`     | enum    | No       | `"present"` | Key state ("present" or "absent")                          |

## Platform-Specific Features

### Cross-Platform
- User account creation and management
- SSH key management with ansible.posix.authorized_key
- Git configuration (user.name, user.email, core.editor)
- Development environment setup (Node.js, Rust, Go, Neovim)
- Dotfiles deployment using GNU Stow

### macOS-Specific
- Homebrew PATH configuration in ~/.zprofile
- Dock preferences (tile size, autohide, minimize behavior)
- Finder preferences (extensions, hidden files, pathbar)
- Screenshot preferences (directory, format)
- iTerm2 preferences (prompt on quit)

### Linux-Specific
- Standard user account management
- Platform-appropriate admin groups (sudo for Ubuntu/Debian, wheel for Arch)

## Superuser Configuration

When `superuser: true`:
- Automatically adds user to platform admin group:
  - Ubuntu/Debian: `sudo` group
  - Arch Linux: `wheel` group
  - macOS: `admin` group

When both `superuser: true` AND `superuser_passwordless: true`:
- Creates `/etc/sudoers.d/{{ username }}` with passwordless sudo rule
- Uses proper validation with visudo

## Dotfiles Integration

When `dotfiles.enable: true`:
1. Clones repository to `~/{{ dotfiles.dest }}`
2. Installs GNU Stow package
3. Performs conflict detection with `stow --no`
4. Backs up conflicting files with timestamp
5. Deploys dotfiles using `stow .`

Expected dotfiles repository structure:
```
dotfiles/
├── bash/
│   └── .bashrc
├── git/
│   └── .gitconfig
└── vim/
    └── .vimrc
```

## Role Dependencies

Automatically calls these collection roles when configured:
- `nodejs` - When `nodejs.packages` is defined
- `rust` - When `rust.packages` is defined
- `go` - When `go.packages` is defined
- `neovim` - When `neovim.enabled` is true
- `terminal_config` - When `terminal_entries` is defined

## Platform Support

- **Ubuntu** 22.04+, 24.04+
- **Debian** 12+, 13+
- **Arch Linux** (Rolling)
- **macOS** 13+ (Ventura)

## Dependencies

- `ansible.posix.authorized_key` (SSH key management)
- `community.general.git_config` (Git configuration)
- `community.general.osx_defaults` (macOS preferences)
