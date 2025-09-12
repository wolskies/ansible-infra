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
        shell: /bin/zsh                    # Cross-platform shell preference
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
        dotfiles:
          repository: "https://github.com/alice/dotfiles"
          method: stow                     # Currently only stow supported
          packages: [zsh, tmux, vim]       # Stow packages to deploy

        # Only macOS-specific GUI preferences need their own section
        macosx:
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
# Configure a specific user by passing the user object as target_user
- name: Configure alice's preferences
  include_role:
    name: wolskinet.infrastructure.configure_user
  vars:
    target_user: "{{ infrastructure.domain.users | selectattr('name', 'equalto', 'alice') | first }}"
```

### Configure All Domain Users (Recommended Pattern)

```yaml
# Loop at playbook level and pass each user object as target_user
- hosts: all
  tasks:
    - name: Configure user preferences
      include_role:
        name: wolskinet.infrastructure.configure_user
      vars:
        target_user: "{{ user_item }}"
      loop: "{{ infrastructure.domain.users }}"
      loop_control:
        loop_var: user_item
      when: user_item.name != 'root'  # Skip system accounts
```

### Common Mistake: Incorrect Variable Passing

```yaml
# ❌ WRONG: This creates 'user' variable, but role expects 'target_user'
- name: Configure users (incorrect)
  include_role:
    name: wolskinet.infrastructure.configure_user
  loop: "{{ infrastructure.domain.users }}"
  loop_control:
    loop_var: user  # Role can't access this as target_user

# ✅ CORRECT: Pass loop variable as target_user
- name: Configure users (correct)
  include_role:
    name: wolskinet.infrastructure.configure_user
  vars:
    target_user: "{{ user_item }}"  # Explicitly pass as target_user
  loop: "{{ infrastructure.domain.users }}"
  loop_control:
    loop_var: user_item
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

### OS Version Requirements for Language Packages

Language package auto-installation requires specific OS versions due to package availability:

- **Debian**: 13+ (Trixie) - for `rustup` and modern `nodejs` packages
- **Ubuntu**: 24.04+ (Noble) - for reliable `nodejs` and `rustup` package availability
- **Arch Linux**: Current rolling release - all language packages available
- **macOS**: 10.15+ (Catalina) - via Homebrew package manager

**Note**: On older OS versions, language packages (nodejs, rust, go) may fail to auto-install. Users can manually install the language tools (`npm`, `cargo`, `go`) before running this role as a workaround.

## Dependencies

- `community.general` - Git config, npm module, osx_defaults, homebrew
- `ansible.builtin` - User management, command execution

## Integration

Works seamlessly with `manage_users` role:
1. `manage_users` creates accounts (sudo)
2. `configure_user` configures preferences (per-user)

## License

MIT
