# manage_language_packages

Language ecosystem package management for Node.js, Rust, and Go development tools.

## Description

This role manages language-specific package managers for development tools and command-line utilities. It handles dependency validation, tool installation, and package management for multiple language ecosystems in a cross-platform manner.

## Features

- **Node.js packages** via npm (global installation)
- **Rust packages** via cargo (user-scoped)
- **Go packages** via go install (module-aware)
- **Dependency validation** - checks for required tools before installation
- **Auto-installation** of language toolchains when missing
- **Cross-platform support** for Ubuntu, Debian, Arch Linux, and macOS

## Role Variables

### Configuration

```yaml
language_packages:
  # Node.js package management (npm)
  nodejs:
    enable: true                 # Enable Node.js package management
    packages: []                 # List of npm packages to install globally

  # Rust package management (cargo)
  rust:
    enable: false                # Enable Rust package management (requires Rust toolchain)
    packages: []                 # List of Rust packages to install

  # Go package management (go install)
  go:
    enable: false                # Enable Go package management (requires Go toolchain)
    packages: []                 # List of Go packages to install

  # Configuration
  config:
    check_dependencies: true     # Validate required tools before installing packages
    install_missing_tools: true # Auto-install missing language tools
```

## Example Usage

### Development Tools Setup
```yaml
- hosts: workstations
  roles:
    - role: wolskinet.infrastructure.manage_language_packages
      vars:
        language_packages:
          nodejs:
            enable: true
            packages:
              - typescript
              - "@vue/cli"
              - eslint
              - prettier

          rust:
            enable: true
            packages:
              - ripgrep
              - fd-find
              - bat
              - exa

          go:
            enable: true
            packages:
              - github.com/junegunn/fzf@latest
              - golang.org/x/tools/cmd/goimports@latest
```

### Minimal Setup (Node.js only)
```yaml
language_packages:
  nodejs:
    enable: true
    packages:
      - typescript
      - eslint
```

## Dependencies

### System Requirements
- **Ubuntu/Debian**: nodejs, npm, rust/cargo, golang (auto-installed if missing)
- **Arch Linux**: nodejs, npm, rust, go (auto-installed if missing)
- **macOS**: Node.js, Rust, Go (auto-installed via Homebrew if missing)

### Tool Installation
The role can automatically install missing language toolchains:
- **Node.js**: Installed via system package manager
- **Rust**: Installed via rustup.rs installer script
- **Go**: Installed via system package manager

## How It Works

1. **Dependency Check**: Validates that required language tools are installed
2. **Auto-Installation**: Installs missing tools if enabled
3. **Package Installation**: Uses native package managers (npm, cargo, go install)
4. **Cross-Platform**: Works consistently across supported operating systems

## Platform Support

- Ubuntu 22.04+
- Debian 12+
- Arch Linux
- macOS

## Security Features

- **Secure downloads** with certificate validation for installer scripts
- **Temporary file cleanup** after installation
- **Script integrity verification** support
- **User-scoped installations** for Rust and Go packages
- **Global npm packages** require appropriate permissions

## Notes

- **Node.js packages** are installed globally by default (can be configured per-project)
- **Rust packages** are installed to user's `~/.cargo/bin` directory
- **Go packages** are installed to user's `~/go/bin` directory
- Language toolchains are installed automatically if missing and `install_missing_tools` is enabled
- Set `check_dependencies: false` to skip dependency validation (not recommended)
