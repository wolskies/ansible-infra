# go

Go toolchain installation and user-level package management.

## Description

Installs the Go compiler and development tools, then installs user-specified Go packages. The role automatically handles Go installation via system package managers when the `go` command is not found. Packages are installed in the user's Go workspace using `go install`.

## Features

- **Automatic Go installation**: Installs Go compiler if not present via system package manager
- **User-level packages**: Installs packages in user's `~/go` directory
- **Cross-platform**: Works on Ubuntu, Debian, Arch Linux, and macOS
- **Version support**: Supports versioned package installation (e.g., `package@latest`)
- **Standalone or integrated**: Can be used directly or called by configure_user role

## Role Variables

```yaml
go_user: ""                      # Target username (required)
go_packages: []                  # List of Go packages to install (required)
```

### Go Packages Format

Go packages use full module paths with optional version specifiers:

```yaml
go_packages:
  - github.com/charmbracelet/glow@latest
  - github.com/golangci/golangci-lint/cmd/golangci-lint@v1.54.2
  - golang.org/x/tools/cmd/goimports
  - github.com/air-verse/air@latest
```

## Usage Examples

### Standalone Usage

```yaml
- hosts: developers
  become: true
  roles:
    - role: wolskies.infrastructure.go
      vars:
        go_user: developer
        go_packages:
          - github.com/charmbracelet/glow@latest
          - github.com/golangci/golangci-lint/cmd/golangci-lint@latest
          - golang.org/x/tools/cmd/goimports
```

### With Variable Files

```yaml
# group_vars/developers.yml
go_user: developer
go_packages:
  - github.com/charmbracelet/glow@latest
  - github.com/air-verse/air@latest
  - golang.org/x/tools/cmd/goimports
  - github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# playbook.yml
- hosts: developers
  become: true
  roles:
    - wolskies.infrastructure.go
```

### Integration with configure_user

This role is automatically called by configure_user when Go packages are specified:

```yaml
target_user:
  name: developer
  go:
    packages:
      - github.com/charmbracelet/glow@latest
      - golang.org/x/tools/cmd/goimports
```

## Installation Behavior

1. **Go Installation Check**: Verifies if `go` command exists for the target user
2. **Automatic Installation**: If missing, installs Go via system package manager:
   - **Ubuntu/Debian**: `golang-go` package via apt
   - **Arch Linux**: `go` package via pacman
   - **macOS**: `go` package via Homebrew
3. **Package Installation**: Installs each package using `go install` as the target user
4. **PATH Integration**: Go binaries are available in `~/go/bin` (add to PATH manually if needed)

## Common Go Packages

```yaml
go_packages:
  - golang.org/x/tools/cmd/goimports
  - github.com/golangci/golangci-lint/cmd/golangci-lint@latest
  - github.com/air-verse/air@latest
  - github.com/charmbracelet/glow@latest
  - github.com/junegunn/fzf@latest
  - github.com/jesseduffield/lazygit@latest
  - github.com/antonmedv/fx@latest
```

## OS Support

- **Ubuntu 22+**: Supported (24.04+ has automatic Go installation)
- **Debian 12+**: Supported (13+ has automatic Go installation)
- **Arch Linux**: Full support with automatic go package installation
- **macOS 10.15+**: Full support with automatic Homebrew go package installation

**Note**: This collection supports Ubuntu 22+, Debian 12+, Arch Linux, and macOS. For the language toolchain roles (nodejs, go, rust): system packages are only available on **Ubuntu 24.04+** and **Debian 13+**. On older supported versions (Ubuntu 22/23, Debian 12), you must manually install the latest rustup, node, and go before using these language roles.

## Requirements

- Target user must exist on the system
- System package manager access (for Go installation if needed)
- Internet access for downloading Go packages
- Sufficient disk space in user's home directory

## File Locations

- **Go installation**: System-wide via package manager
- **User packages**: `~/go/bin/` (executables), `~/go/pkg/` (compiled packages)
- **Go workspace**: `~/go/` (GOPATH, though modules don't require this)
- **Module cache**: `~/go/pkg/mod/`

## Integration Notes

### With configure_user Role
This role integrates seamlessly with configure_user for complete development environment setup:

```yaml
target_user:
  name: developer
  go:
    packages: [github.com/charmbracelet/glow@latest]
  nodejs:
    packages: [typescript]
  rust:
    packages: [ripgrep]
```

### PATH Configuration
Go binaries install to `~/go/bin`. Users may need to add this to their PATH:

```bash
export PATH="$PATH:$HOME/go/bin"
```

This is typically handled by shell configuration or dotfiles.

## Dependencies

- System package manager (apt, pacman, homebrew)
- `ansible.builtin.command` - For go install execution
- `ansible.builtin.package` - For Go compiler installation

## License

MIT

## Author Information

This role is part of the wolskies.infrastructure collection.
