# configure_users

Configure user preferences and development environments.

## What It Does

Configures preferences and development environments for existing users:
- **Development Environment** - Git, Node.js, Rust, Go, Neovim
- **Platform-Specific** - Dock/Finder preferences (macOS), Homebrew PATH
- **Dotfiles** - Automatic deployment using GNU Stow

## Key Features

- **Mass Configuration** - Configure preferences for multiple users
- **Skips Missing Users** - No errors if user doesn't exist
- **Root User Protection** - Skips root user automatically
- **Development Tools** - Orchestrates language toolchain installation per user

## Usage

### Basic User Preferences
```yaml
- hosts: all
  become: true
  roles:
    - name: wolskies.infrastructure.configure_users

  vars:
    users:
      - name: developer
        git:
          user_name: "Developer Name"
          user_email: "developer@company.com"
          editor: "nvim"

      - name: deployment
        git:
          user_name: "Deploy Bot"
          user_email: "deploy@company.com"
```

### Development Environment Setup
```yaml
users:
  - name: developer
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

### Terminal Configuration
```yaml
users:
  - name: developer
    terminal_entries:
      - alacritty
      - kitty
      - wezterm
```

### macOS Preferences
```yaml
users:
  - name: developer
    Darwin:
      dock:
        tile_size: 48
        autohide: true
        minimize_to_application: true
        show_recents: false
      finder:
        show_extensions: true
        show_hidden: true
        show_pathbar: true
      screenshots:
        directory: "Screenshots"
        format: "png"
```

### Complete Example
```yaml
- hosts: all
  become: true
  roles:
    - name: wolskies.infrastructure.configure_users
      vars:
        users:
          - name: developer
            git:
              user_name: "Developer Name"
              user_email: "developer@company.com"
              editor: "nvim"
            nodejs:
              packages: [typescript, "@angular/cli"]
            rust:
              packages: [ripgrep, fd-find]
            neovim:
              enabled: true
            dotfiles:
              enable: true
              repository: "https://github.com/developer/dotfiles"
```

## Variables

See `defaults/main.yml` for the complete variable structure. Key variables:

- `users` - List of user preference configurations
  - `name` - Username (must already exist)
  - `git` - Git configuration (user_name, user_email, editor)
  - `nodejs` - Node.js packages to install
  - `rust` - Rust packages to install
  - `go` - Go packages to install
  - `neovim` - Neovim configuration
  - `terminal_entries` - Terminal emulators to configure
  - `dotfiles` - Dotfiles deployment settings
  - `Darwin` - macOS-specific preferences

## Role Behavior

- **Skips Missing Users** - If user doesn't exist, skips configuration (no error)
- **Skips Root** - Root user automatically skipped
- **Idempotent** - Safe to run multiple times
- **Per-User Installation** - Language tools installed to user home directories

## Dependencies

This role orchestrates other collection roles:
- `wolskies.infrastructure.nodejs` - Node.js environment
- `wolskies.infrastructure.rust` - Rust environment
- `wolskies.infrastructure.go` - Go environment
- `wolskies.infrastructure.neovim` - Neovim configuration
- `wolskies.infrastructure.terminal_config` - Terminal configuration

## Example Playbook

```yaml
---
- name: Configure development environment
  hosts: workstations
  become: true
  roles:
    - role: wolskies.infrastructure.configure_users
      vars:
        users:
          - name: alice
            git:
              user_name: "Alice Developer"
              user_email: "alice@company.com"
            nodejs:
              packages: [typescript, eslint]
            neovim:
              enabled: true

          - name: bob
            git:
              user_name: "Bob Engineer"
              user_email: "bob@company.com"
            rust:
              packages: [ripgrep, bat]
            dotfiles:
              enable: true
              repository: "https://github.com/bob/dotfiles"
```

## License

MIT

## Author Information

Part of the `wolskies.infrastructure` Ansible collection.
