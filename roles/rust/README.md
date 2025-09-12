# rust

Internal helper role for Rust toolchain installation and cargo package management.

## Description

Automatically installs rustup (Rust toolchain installer) and cargo packages for users when called by the `configure_user` role. Ensures consistent rustup usage across all platforms to avoid conflicts with standalone rust packages.

## OS Version Requirements

- **Ubuntu 24.04+** (Noble): Reliable rustup package availability
- **Debian 13+** (Trixie): rustup package available in default repositories
- **Arch Linux**: Current rolling release
- **macOS 10.15+**: Via Homebrew

**Critical**: Debian 12 and earlier do NOT include rustup packages. Use Debian 13+ or manually install rustup.

## Features

- Automatic rustup installation when `cargo` not found
- Consistent rustup usage across platforms (avoids rust package conflicts)
- Initializes stable toolchain by default
- Cross-platform PATH handling for cargo binaries
- User-specific installation (installs in user's ~/.cargo directory)

## Usage

This role is called internally by `configure_user` and should not be invoked directly. Use language package configuration in user preferences instead:

```yaml
infrastructure:
  domain:
    users:
      - name: developer
        rust:
          packages: [ripgrep, bat, fd-find]
```

## Dependencies

- System package manager access for rustup installation
- Internet access for cargo package downloads
