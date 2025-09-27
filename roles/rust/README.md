# rust

Rust toolchain installation and user-level cargo package management.

## What It Does

Installs Rust toolchain and user-level cargo packages:
- **Rustup installation** - System packages via package manager
- **User packages** - Cargo packages in user's `~/.cargo` directory
- **Cross-platform** - Ubuntu, Debian, Arch Linux, macOS support

## Usage

### Basic Package Installation
```yaml
- hosts: developers
  become: true
  roles:
    - wolskies.infrastructure.rust
  vars:
    rust_user: developer
    rust_packages:
      - ripgrep
      - bat
      - fd-find
```

### Integration with configure_user
```yaml
target_user:
  name: developer
  rust:
    packages:
      - ripgrep
      - bat
      - fd-find
      - cargo-watch
```

## Variables

Key configuration options:
- `rust_user` - Target username (required)
- `rust_packages` - List of cargo packages to install

## Platform Support

- **Ubuntu** 22.04+, 24.04+
- **Debian** 12+, 13+
- **Arch Linux** (Rolling)
- **macOS** 13+ (Ventura)

## Dependencies

- System package manager (apt, pacman, homebrew)
- `ansible.builtin.command` (For cargo install execution)
