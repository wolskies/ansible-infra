# configure_user

User-specific configuration and development environment setup.

## What It Does

Configures user preferences and development tools:
- **Development tools** - Git, Node.js, Rust, Go packages
- **Dotfiles** - Automatic deployment using GNU Stow
- **Terminal** - Modern terminal support (Alacritty, Kitty, WezTerm)
- **macOS GUI** - Dock and Finder preferences

## Usage

### Basic User Configuration
```yaml
- hosts: all
  become: true
  tasks:
    - name: Configure user preferences
      include_role:
        name: wolskies.infrastructure.configure_user
      vars:
        target_user:
          name: developer
          git:
            user_name: "Developer Name"
            user_email: "dev@company.com"
          nodejs:
            packages: [typescript, eslint]
          dotfiles:
            enable: true
            repository: "https://github.com/developer/dotfiles"
      become_user: developer
```

### Development Environment
```yaml
target_user:
  name: developer
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
    branch: main
    dest: ".dotfiles"
```

## Variables

Key configuration options:
- `target_user.name` - Username (required)
- `target_user.git` - Git configuration (user_name, user_email, editor)
- `target_user.nodejs.packages` - Global npm packages to install
- `target_user.rust.packages` - Cargo crates to install
- `target_user.go.packages` - Go packages to install
- `target_user.dotfiles` - Dotfiles repository and configuration
- `target_user.neovim.enabled` - Enable Neovim configuration

## Platform Support

- **Ubuntu** 22.04+, 24.04+
- **Debian** 12+, 13+
- **Arch Linux** (Rolling)
- **macOS** 13+ (Ventura)

## Dependencies

- `community.general` (npm, osx_defaults modules)
- Language roles (nodejs, rust, go) called automatically when packages requested
