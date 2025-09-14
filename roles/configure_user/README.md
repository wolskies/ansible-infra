# configure_user

Configures individual user preferences and development environments.

## Description

This role configures user-specific preferences and development tools. It handles cross-platform settings (Git configuration, language packages) and OS-specific preferences (shell, dotfiles). The role runs as the target user and automatically installs language toolchains when packages are requested.

## Features

- **Cross-platform**: Git configuration, language packages (nodejs, rust, go, neovim)
- **OS-specific**: Shell settings, dotfiles management, GUI preferences (macOS)
- **Language ecosystems**: Automatic nodejs/rustup/golang installation when packages requested
- **Dotfiles integration**: Clone and deploy dotfiles using stow
- **User-level execution**: Runs as the target user, not root

## Role Variables

### User Configuration Structure

Users are defined in the main `users` array with all preferences included:

```yaml
users:
  - name: alice                    # Username (required)
    comment: "Alice Developer"     # User description
    group: alice                   # Primary group
    groups: [docker, sudo]         # Additional groups
    shell: /bin/bash              # Login shell
    ssh_keys:                     # SSH public keys
      - "ssh-ed25519 AAAAC3N..."
    state: present                # User state
    # Development environment preferences
    nodejs:                        # Optional: Node.js packages to install
      packages: [typescript, eslint, prettier]
    rust:                          # Optional: Rust packages to install
      packages: [ripgrep, fd-find, bat]
    go:                            # Optional: Go packages to install
      packages: [github.com/charmbracelet/glow@latest]
    neovim:                        # Optional: Neovim configuration
      enabled: true
    dotfiles:                     # Optional: Dotfiles configuration
      enable: true
      repository: "https://github.com/alice/dotfiles"
      branch: main                # Optional: defaults to main
      packages: [zsh, tmux, vim]  # Stow packages to deploy
    Darwin:                       # Optional: macOS-specific settings
      dock:
        tile_size: 48
        autohide: true
      finder:
        show_extensions: true
        show_hidden: true
```

### Internal Role Variable

This role is called automatically by configure_system and receives a `target_user` variable containing the individual user configuration.

```yaml
users:
  - name: alice
    comment: "Alice Smith"
    groups: [sudo, docker]
    shell: /bin/bash
    ssh_keys:
      - "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGrT..."
    state: present
```

## Usage Examples

### Configure Single User

```yaml
- hosts: workstations
  become: true
  tasks:
    - name: Configure alice's development environment
      include_role:
        name: wolskies.infrastructure.configure_user
      vars:
        target_user:
          name: alice
          nodejs:
            packages: [typescript, eslint, prettier]
          rust:
            packages: [ripgrep, bat]
          shell: /bin/zsh
          dotfiles:
            enable: true
            repository: "https://github.com/alice/dotfiles"
            packages: [zsh, vim]
      become_user: alice
```

### Configure All Users (Recommended Pattern)

```yaml
- hosts: all
  become: true
  tasks:
    - name: Configure user preferences
      include_role:
        name: wolskies.infrastructure.configure_user
      vars:
        target_user: "{{ item }}"
      loop: "{{ users }}"
      when: item.name != 'root'
      become_user: "{{ item.name }}"
```

### Language Package Configuration

Configure development environments with automatic toolchain installation:

```yaml
target_user:
  name: developer
  nodejs:
    packages:
      - typescript
      - eslint
      - prettier
      - "@vue/cli"
  rust:
    packages:
      - ripgrep      # Modern grep replacement
      - bat          # Modern cat replacement
      - fd-find      # Modern find replacement
      - cargo-watch  # Auto-rebuild on changes
  go:
    packages:
      - github.com/charmbracelet/glow@latest
      - github.com/golangci/golangci-lint/cmd/golangci-lint@latest
```

**Installation behavior**:
- Checks if language tool exists (`npm`, `cargo`, `go`)
- If missing, includes appropriate language role to install system packages
- Then installs user packages in user's home directory

### Dotfiles Configuration

Deploy dotfiles using GNU Stow:

```yaml
target_user:
  name: alice
  dotfiles:
    enable: true
    repository: "https://github.com/alice/dotfiles"
    branch: main                    # Optional: defaults to main
    packages: [zsh, tmux, vim]      # Stow packages to deploy
```

**Dotfiles structure expected**:
```
dotfiles/
├── zsh/
│   └── .zshrc
├── tmux/
│   └── .tmux.conf
└── vim/
    └── .vimrc
```

### macOS GUI Configuration

Configure macOS Dock and Finder preferences:

```yaml
target_user:
  name: alice
  Darwin:
    dock:
      tile_size: 48              # Dock icon size
      autohide: true             # Auto-hide dock
      minimize_to_application: false
    finder:
      show_extensions: true      # Show file extensions
      show_hidden: true          # Show hidden files
      show_pathbar: true         # Show path bar
```

## Variable Structure Details

### Language Packages

Each language section follows the same pattern:

```yaml
nodejs:
  packages: []                   # Array of npm packages to install globally

rust:
  packages: []                   # Array of cargo crates to install

go:
  packages: []                   # Array of Go packages (full module paths)
```

### Cross-Platform Settings

Settings that work on all supported platforms:

```yaml
shell: /bin/zsh                  # Preferred shell (if available)
dotfiles:                        # Dotfiles deployment
  enable: true
  repository: "https://github.com/user/dotfiles"
  branch: main
  packages: [package1, package2]
```

### OS-Specific Settings

Platform-specific settings use the OS name as the key:

```yaml
Darwin:                          # macOS settings
  dock: {}
  finder: {}
Linux:                           # Linux settings (future expansion)
  # Linux-specific settings would go here
```

## Architecture

### Execution Flow

1. **Validation**: Ensures `target_user` is defined with required fields
2. **Language toolchains**: Installs nodejs, rust, go packages (if requested)
3. **Cross-platform**: Applies shell and dotfiles configuration
4. **OS-specific**: Applies platform-specific preferences

### Task Organization

- `main.yml`: Validation and orchestration
- `configure-cross-platform.yml`: Git config, language packages
- `configure-Linux.yml`: Linux-specific settings and dotfiles
- `configure-Darwin.yml`: macOS-specific settings, Dock, Finder

## Requirements

### All Platforms
- User must exist on the system (use manage_users role first)
- Role must be called with `become_user: {{ target_user.name }}`

### Language Packages
- System package manager access for automatic toolchain installation
- Network access for downloading packages

### Dotfiles
- Git access to dotfiles repositories
- GNU Stow (automatically installed if missing)

### macOS GUI Settings
- User must be logged in for Dock/Finder changes to take effect
- May require logout/login for some settings

## Integration with Other Roles

This role works with other collection roles:

1. **manage_users**: Creates user accounts and SSH keys (run first)
2. **nodejs/rust/go**: Language toolchain installation (called automatically)
3. **configure_user**: User preferences (this role)

Example playbook order:
```yaml
- hosts: all
  become: true
  roles:
    - wolskies.infrastructure.manage_users        # Create accounts

  tasks:
    - name: Configure user preferences
      include_role:
        name: wolskies.infrastructure.configure_user
      vars:
        target_user: "{{ item }}"
      loop: "{{ users }}"
      when: item.name != 'root'
      become_user: "{{ item.name }}"               # Run as target user
```

## Dependencies

- `community.general`: npm, osx_defaults, homebrew modules
- `ansible.builtin`: Core modules for file operations
- Language roles (nodejs, rust, go): Called automatically when packages requested

## OS Support

- **Ubuntu 22+**: Full support with automatic language toolchain installation
- **Debian 12+**: Full support with automatic language toolchain installation
- **Arch Linux**: Full support with AUR package installation
- **macOS 10.15+**: Full support including GUI preferences

## License

MIT

## Author Information

This role is part of the wolskies.infrastructure collection.
