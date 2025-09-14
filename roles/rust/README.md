# rust

Rust toolchain installation and user-level cargo package management.

## Description

Installs rustup (Rust toolchain installer) and cargo packages for users. The role automatically handles rustup installation via system package managers when cargo is not found. Packages are installed in the user's `~/.cargo` directory using `cargo install`.

## Features

- **Automatic rustup installation**: Installs rustup if not present via system package manager
- **User-level packages**: Installs packages in user's `~/.cargo` directory
- **Cross-platform**: Works on Ubuntu, Debian, Arch Linux, and macOS
- **Standalone or integrated**: Can be used directly or called by configure_user role

## Role Variables

```yaml
rust_user: ""                    # Target username (required)
rust_packages: []                # List of cargo packages to install (required)
```

## Usage Examples

### Standalone Usage

```yaml
- hosts: developers
  become: true
  roles:
    - role: wolskies.infrastructure.rust
      vars:
        rust_user: developer
        rust_packages:
          - ripgrep
          - bat
          - fd-find
```

### With Variable Files

```yaml
# group_vars/developers.yml
rust_user: developer
rust_packages:
  - ripgrep
  - bat
  - fd-find
  - cargo-watch

# playbook.yml
- hosts: developers
  become: true
  roles:
    - wolskies.infrastructure.rust
```

### Integration with configure_user

This role is automatically called by configure_user when Rust packages are specified:

```yaml
target_user:
  name: developer
  rust:
    packages:
      - ripgrep
      - bat
      - fd-find
```

## Installation Behavior

1. **Rust Installation Check**: Verifies if `cargo` command exists for the target user
2. **Automatic Installation**: If missing, installs rustup via system package manager:
   - **Ubuntu/Debian**: `rustup` package via apt
   - **Arch Linux**: `rustup` package via pacman
   - **macOS**: `rustup` package via Homebrew
3. **Toolchain Setup**: Initializes stable Rust toolchain via `rustup default stable`
4. **Package Installation**: Installs each package using `cargo install` as the target user
5. **PATH Integration**: Cargo binaries are available in `~/.cargo/bin`

## Common Packages

```yaml
rust_packages:
  - ripgrep
  - bat
  - fd-find
  - exa
  - cargo-watch
  - tokei
  - hyperfine
```

## OS Support

- **Ubuntu 22+**: Supported (24.04+ has automatic rustup installation)
- **Debian 12+**: Supported (13+ has automatic rustup installation)
- **Arch Linux**: Full support with automatic rustup package installation
- **macOS 10.15+**: Full support with automatic Homebrew rustup package installation

**Note**: This collection supports Ubuntu 22+, Debian 12+, Arch Linux, and macOS. For the language toolchain roles (nodejs, go, rust): system packages are only available on **Ubuntu 24.04+** and **Debian 13+**. On older supported versions (Ubuntu 22/23, Debian 12), you must manually install the latest rustup, node, and go before using these language roles.

## Requirements

- Target user must exist on the system
- System package manager access (for rustup installation if needed)
- Internet access for downloading Rust toolchain and cargo packages
- Sufficient disk space in user's home directory

## File Locations

- **Rustup installation**: `~/.rustup/` (toolchain management)
- **Cargo packages**: `~/.cargo/bin/` (executables), `~/.cargo/registry/` (package cache)
- **Rust toolchain**: `~/.rustup/toolchains/stable-*/` (compiler and libraries)

## Integration Notes

### With configure_user Role
This role integrates with configure_user for development environment setup:

```yaml
target_user:
  name: developer
  rust:
    packages: [ripgrep, bat]
  nodejs:
    packages: [typescript]
  go:
    packages: [github.com/charmbracelet/glow@latest]
```

### PATH Configuration
Cargo packages install to `~/.cargo/bin`. Users may need to add this to their PATH:

```bash
export PATH="$PATH:$HOME/.cargo/bin"
```

This is typically handled by shell configuration or dotfiles.

## Dependencies

- System package manager (apt, pacman, homebrew)
- `ansible.builtin.command` - For cargo install execution
- `ansible.builtin.package` - For rustup installation

## License

MIT

## Author Information

This role is part of the wolskies.infrastructure collection.
