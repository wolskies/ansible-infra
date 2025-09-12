# go

Internal helper role for Go toolchain installation and package management.

## Description

Automatically installs Go compiler and packages for users when called by the `configure_user` role. Handles cross-platform installation via system package managers.

## OS Version Requirements

- **Ubuntu 22+**: Go packages available in default repositories
- **Debian 12+**: Go packages available in default repositories
- **Arch Linux**: Current rolling release
- **macOS 10.15+**: Via Homebrew

**Note**: Go has broader OS version compatibility than nodejs/rust since it's been in repositories longer.

## Features

- Automatic Go installation when `go` command not found
- Cross-platform package installation using `go install`
- User-specific installation (installs in user's ~/go directory)
- Supports versioned package installation (e.g., `package@latest`)

## Usage

This role is called internally by `configure_user` and should not be invoked directly. Use language package configuration in user preferences instead:

```yaml
infrastructure:
  domain:
    users:
      - name: developer
        go:
          packages: [github.com/charmbracelet/glow@latest]
```

## Dependencies

- System package manager access for Go installation
- Internet access for go package downloads
