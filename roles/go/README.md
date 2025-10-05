# go

Go language installation and user-level package management.

## What It Does

Installs Go toolchain and user-level packages:
- **Go Development Toolchain** - Compiler, built-in tools (go fmt, go test, go build)
- **Package Management** - go install capabilities for third-party tools
- **User packages** - Go packages in user's `~/go` directory
- **Cross-platform** - Ubuntu, Debian, Arch Linux, macOS support

## Usage

### Basic Package Installation
```yaml
- hosts: developers
  become: true
  roles:
    - wolskies.infrastructure.go
  vars:
    go_user: developer
    go_packages:
      - github.com/charmbracelet/glow@latest
      - github.com/junegunn/fzf@latest
```

### Integration with configure_users
```yaml
target_user:
  name: developer
  go:
    packages:
      - github.com/charmbracelet/glow@latest
      - github.com/junegunn/fzf@latest
      - github.com/cli/cli/v2/cmd/gh@latest
```

## Variables

### Role Variables
| Variable      | Type         | Required | Default | Description                                                           |
| ------------- | ------------ | -------- | ------- | --------------------------------------------------------------------- |
| `go_user`     | string       | Yes      | -       | Target username for Go installation                                   |
| `go_packages` | list[string] | No       | `[]`    | Go package URLs to install (e.g., ["github.com/user/package@latest"]) |

## Installation Behavior

1. **Go Installation** - Installs Go development toolchain:
   - **Ubuntu/Debian** - APT `golang` package
   - **Arch Linux** - Pacman `go` package
   - **macOS** - Homebrew `go` formula
2. **PATH Configuration** - Adds `~/go/bin` to user's `.profile`
3. **Package Installation** - Installs packages via `go install` with user-local installation

## Package Format

Go packages use full import URLs with optional version specifiers:
```yaml
go_packages:
  # With explicit version
  - "github.com/user/package@v1.2.3"
  - "github.com/user/package@latest"

  # Auto-appends @latest if no version specified
  - "github.com/user/package"
```

## User-Level Package Management

All Go packages install to user directories:
- **Packages**: `~/go/pkg/`
- **Binaries**: `~/go/bin/`
- **Source Cache**: `~/go/src/`

Users need `~/go/bin` in their PATH - automatically added to `~/.profile` by the role.

## Platform Support

- **Ubuntu** 22.04+, 24.04+
- **Debian** 12+, 13+
- **Arch Linux** (Rolling)
- **macOS** 13+ (Ventura)

## Dependencies

- `ansible.builtin.apt` (Ubuntu/Debian package installation)
- `community.general.pacman` (Arch Linux package installation)
- `community.general.homebrew` (macOS package installation)
- `ansible.builtin.command` (Go package installation)
