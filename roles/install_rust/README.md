# install_rust

Utility role for Rust toolchain installation and user-level cargo package management.

## What It Does

Installs Rust toolchain and user-level cargo packages:
- **Rustup Toolchain Manager** - System packages via package manager
- **Stable Toolchain** - Default Rust compiler via rustup
- **User packages** - Cargo packages in user's `~/.cargo` directory
- **Cross-platform** - Ubuntu 24+, Debian 13+, Arch Linux, macOS support

## Usage

### Basic Package Installation
```yaml
- hosts: developers
  become: true
  roles:
    - wolskies.infrastructure.install_rust
  vars:
    rust_user: developer
    rust_packages:
      - ripgrep
      - bat
      - fd-find
```

### Integration with configure_users
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

### Role Variables
| Variable        | Type         | Required | Default | Description                                                   |
| --------------- | ------------ | -------- | ------- | ------------------------------------------------------------- |
| `rust_user`     | string       | Yes      | -       | Target username for Rust installation                         |
| `rust_packages` | list[string] | No       | `[]`    | Cargo package names to install (e.g., ["ripgrep", "fd-find"]) |

## Installation Behavior

1. **Rustup Installation** - Installs rustup toolchain manager:
   - **Ubuntu 24+/Debian 13+** - APT `rustup` package
   - **Arch Linux** - Pacman `rustup` and `base-devel` packages
   - **macOS** - Homebrew `rustup` formula
2. **Toolchain Setup** - Initializes stable Rust toolchain via `rustup default stable`
3. **PATH Configuration** - Adds `~/.cargo/bin` to user's `.profile`
4. **Package Installation** - Installs cargo packages with user-local installation

## Platform Limitations

- **Ubuntu 22/23** - Not supported (rustup not available in repositories)
- **Debian 12** - Not supported (rustup not available in repositories)

For unsupported platforms, the role fails with a clear error message.

## User-Level Package Management

All cargo packages install to user directories:
- **Packages**: `~/.cargo/registry/`
- **Binaries**: `~/.cargo/bin/`
- **Build Cache**: `~/.cargo/target/`

Users need `~/.cargo/bin` in their PATH - automatically added to `~/.profile` by the role.

## Platform Support

- **Ubuntu** 24.04+
- **Debian** 13+
- **Arch Linux** (Rolling)
- **macOS** 13+ (Ventura)

## Dependencies

- `ansible.builtin.apt` (Ubuntu/Debian package installation)
- `community.general.pacman` (Arch Linux package installation)
- `community.general.homebrew` (macOS package installation)
- `ansible.builtin.command` (Rustup and cargo operations)
