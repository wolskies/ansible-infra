# nodejs

Node.js installation and user-level npm package management.

## What It Does

Installs Node.js system packages and user-level npm packages:
- **Node.js installation** - System packages via package manager (NodeSource for Ubuntu/Debian)
- **User packages** - npm packages in user's `~/.npm-global` directory
- **Cross-platform** - Ubuntu, Debian, Arch Linux, macOS support

## Usage

### Basic Package Installation
```yaml
- hosts: developers
  become: true
  roles:
    - wolskies.infrastructure.nodejs
  vars:
    node_user: developer
    node_packages:
      - typescript
      - eslint
      - prettier
      - "@vue/cli"
```

### With Version Specifications
```yaml
node_user: developer
node_packages:
  # Simple string format (latest version)
  - typescript
  - "@angular/cli"
  # Object format with version specification
  - name: eslint
    version: "8.0.0"
  - name: webpack
    version: "^5.0.0"
```

### Integration with configure_user
```yaml
target_user:
  name: developer
  nodejs:
    packages:
      - typescript
      - eslint
      - prettier
      - "@nestjs/cli"
```

## Variables

### Role Variables
| Variable                 | Type   | Required | Default           | Description                                                               |
|--------------------------|--------|----------|-------------------|---------------------------------------------------------------------------|
| `node_user`              | string | Yes      | -                 | Target username for npm package installation                              |
| `node_packages`          | list   | No       | `[]`              | npm packages to install (see format below)                                |
| `nodejs_version`         | string | No       | `"20"`            | Major version of Node.js to install (Ubuntu/Debian NodeSource)            |
| `npm_config_prefix`      | string | No       | `"~/.npm-global"` | Directory for npm global installations                                    |
| `npm_config_unsafe_perm` | string | No       | `"true"`          | Suppress UID/GID switching when running package scripts                   |

### Package Format
Supports both string and object formats:
```yaml
node_packages:
  # String format (installs latest)
  - "package-name"
  - "@scoped/package"

  # Object format with version
  - name: "package-name"
    version: "1.0.0"
  - name: "@scoped/package"
    version: "^2.0.0"
```

## Installation Behavior

1. **Node.js Installation Check** - Verifies if Node.js/npm exists
2. **System Installation** - Installs Node.js via package manager:
   - **Ubuntu/Debian** - NodeSource repository for specified version
   - **Arch Linux** - Official `nodejs` and `npm` packages
   - **macOS** - Homebrew `node` package
3. **User Directory Setup** - Creates `~/.npm-global` directory
4. **Package Installation** - Installs packages with user-local configuration
5. **PATH Configuration** - Updates user's `.profile` for npm binaries

## Platform-Specific Features

### Ubuntu/Debian
- Uses NodeSource repository for current Node.js versions
- Configurable Node.js version (default: v20)
- Automatic GPG key and repository setup

### Arch Linux
- Uses official repository packages
- Always current versions from Arch repos

### macOS
- Uses Homebrew for Node.js installation
- Integrates with existing Homebrew setup

## User-Level Package Management

All npm packages install to user directories:
- **Packages**: `~/.npm-global/lib/node_modules/`
- **Binaries**: `~/.npm-global/bin/`
- **Configuration**: `NPM_CONFIG_PREFIX=~/.npm-global`

Users need to add `~/.npm-global/bin` to their PATH:
```bash
export PATH="$PATH:$HOME/.npm-global/bin"
```

This is automatically added to `~/.profile` by the role.

## Platform Support

- **Ubuntu** 22.04+, 24.04+
- **Debian** 12+, 13+
- **Arch Linux** (Rolling)
- **macOS** 13+ (Ventura)

## Dependencies

- `community.general.npm` (Package installation)
- `ansible.builtin.deb822_repository` (NodeSource repository on Ubuntu/Debian)
