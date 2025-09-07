# configure_user

Per-user preference configuration with cross-platform language packages and OS-specific settings.

## Description

Configures individual user preferences and development environments. Runs as the target user (not root) and reads configuration from `infrastructure.domain.users[]`. Handles cross-platform settings (Git, language packages) and OS-specific preferences (shell, dotfiles, GUI settings).

## Features

- **Cross-platform**: Git config, language packages (nodejs, rust, go) with auto-dependency installation
- **OS-specific**: Shell settings, dotfiles (Stow-based), GUI preferences (macOS Dock/Finder)
- **Language ecosystems**: Automatic nodejs/rustup/golang installation when packages requested
- **Dotfiles integration**: Clone and stow dotfiles from user repositories
- **Per-user execution**: Must be called with `target_user` variable and `become_user`

## Role Variables

### Required Variables

This role requires a `target_user` variable specifying which user to configure:

```yaml
target_user: alice  # Must match a user in infrastructure.domain.users[]
```

### User Configuration Structure

User preferences are read from `infrastructure.domain.users[]`:

```yaml
infrastructure:
  domain:
    users:
      - name: alice
        # System account fields (used by manage_users role)
        groups: [sudo]
        ssh_pubkey: "ssh-ed25519 AAAAC3..."
        
        # Cross-platform preferences (used by this role)
        git:
          user_name: "Alice Smith"
          user_email: "alice@company.com"
          editor: "vim"                    # Optional
        nodejs:
          packages: [typescript, eslint, prettier]  # Auto-installs nodejs if missing
        rust:
          packages: [ripgrep, fd-find, bat]         # Auto-installs rustup if missing
        go:
          packages: [github.com/charmbracelet/glow@latest]  # Auto-installs golang if missing
        
        # OS-specific preferences
        Ubuntu:
          shell: /usr/bin/zsh              # Set user's shell
          dotfiles:
            repository: "https://github.com/alice/dotfiles-linux"
            method: stow                   # Currently only stow supported
            packages: [zsh, tmux, vim]     # Stow packages to deploy
        Darwin:
          shell: /opt/homebrew/bin/zsh
          dotfiles:
            repository: "https://github.com/alice/dotfiles-macos"
            method: stow
            packages: [zsh, tmux, vim, macos]
          dock:
            tile_size: 48
            autohide: true
            minimize_to_application: false  # Optional
          finder:
            show_extensions: true
            show_hidden: true
            show_pathbar: true              # Optional
```

## Usage Examples

### Per-User Configuration

```yaml
# Configure a specific user (run as that user)
- name: Configure alice's preferences
  include_role:
    name: wolskinet.infrastructure.configure_user
  vars:
    target_user: alice
  become: true
  become_user: alice
```

### Configure All Domain Users

```yaml
# Configure all users defined in infrastructure.domain.users
- hosts: all
  tasks:
    - name: Configure user preferences
      include_role:
        name: wolskinet.infrastructure.configure_user
      vars:
        target_user: "{{ item }}"
      become: true
      become_user: "{{ item }}"
      loop: "{{ infrastructure.domain.users | map(attribute='name') | list }}"
```

### Language Package Auto-Installation

The role automatically installs language tools when users request packages:

```yaml
infrastructure:
  domain:
    users:
      - name: developer
        nodejs:
          packages: [typescript]  # Will install nodejs if npm not found
        rust:
          packages: [ripgrep]     # Will install rustup if cargo not found
        go:
          packages: [github.com/charmbracelet/glow@latest]  # Will install golang if go not found
```

**Installation behavior**:
- Checks if tool exists (`npm`, `cargo`, `go`)
- If missing, installs via system package manager (`nodejs`, `rustup`, `golang`)
- Then installs user packages (`npm -g`, `cargo install`, `go install`)

## Architecture

### Execution Flow

1. **Validation**: Ensures `target_user` is defined and exists in `infrastructure.domain.users[]`
2. **User lookup**: Finds the target user's configuration 
3. **Cross-platform config**: Applies Git settings and language packages
4. **OS-specific config**: Applies shell, dotfiles, GUI preferences

### Task Organization

- `configure-cross-platform.yml`: Git config, nodejs/rust/go packages
- `configure-Linux.yml`: Shell, dotfiles (stow), Linux-specific settings
- `configure-Darwin.yml`: Shell, dotfiles (stow), Dock, Finder preferences

## Requirements

- **All platforms**: Must be called with `target_user` variable and `become_user`
- **Language packages**: System package manager access (for auto-installation)
- **Dotfiles**: Git access to dotfiles repositories
- **macOS GUI**: User session (for defaults changes to apply)
- **Linux dotfiles**: Stow package (auto-installed)
- **macOS dotfiles**: Stow via Homebrew (auto-installed)

## Dependencies

- `community.general` - Git config, npm module, osx_defaults, homebrew
- `ansible.builtin` - User management, command execution

## Integration

Works seamlessly with `manage_users` role:
1. `manage_users` creates accounts (sudo)
2. `configure_user` configures preferences (per-user)

## License

MIT