# configure_user

User account management and development environment configuration.

## What It Does

Configures a single user account and their preferences:
- **User Account** - Create/manage user with groups, shell, SSH keys
- **Development Environment** - Git, Node.js, Rust, Go, Neovim
- **Platform-Specific** - Dock/Finder preferences (macOS), Homebrew PATH
- **Dotfiles** - Automatic deployment using GNU Stow

## Usage

### Basic User Configuration
```yaml
- hosts: all
  become: true
  tasks:
    - name: Configure user account
      include_role:
        name: wolskies.infrastructure.configure_user
      vars:
        target_user:
          name: developer
          comment: "Developer Account"
          groups: [sudo, docker]
          shell: /bin/bash
          ssh_keys:
            - key: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5..."
              comment: "developer@workstation"
      become_user: developer
```

### Development Environment Setup
```yaml
target_user:
  name: developer
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

### macOS-Specific Configuration
```yaml
target_user:
  name: developer
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

### target_user Object Schema
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
