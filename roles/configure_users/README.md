# configure_users

Configures user preferences and development environments for existing users.

**Features:**
- Development environments: Git, Node.js, Rust, Go, Neovim
- Platform preferences: macOS Dock/Finder, Homebrew PATH
- Dotfiles deployment via GNU Stow
- Skips non-existent users and root automatically

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

## Behavior

- Skips non-existent users (no error)
- Skips root user automatically
- Idempotent
- Language tools installed to user home directories

## Dependencies

Orchestrates: `nodejs`, `rust`, `go`, `neovim`, `terminal_config` roles

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
