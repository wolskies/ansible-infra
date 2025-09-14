# nodejs

Node.js installation and user-level npm package management.

## Description

Installs Node.js and npm, then installs user-specified npm packages globally in the user's home directory. The role automatically handles Node.js installation via system package managers when npm is not found. Uses the `community.general.npm` module for reliable package management.

## Features

- **Automatic Node.js installation**: Installs Node.js and npm if not present via system package manager
- **User-level packages**: Installs packages in user's `~/.npm-global` directory
- **Cross-platform**: Works on Ubuntu, Debian, Arch Linux, and macOS
- **NodeSource repository**: Automatically configures NodeSource repository for latest Node.js (Ubuntu/Debian)
- **PATH configuration**: Sets up npm global directory with proper environment variables
- **Standalone or integrated**: Can be used directly or called by configure_user role

## Role Variables

```yaml
node_user: ""                    # Target username (required)
node_packages: []                # List of npm packages to install globally (required)
nodejs_version: "20"             # Node.js major version (default: 20)
nodejs_update_cache: true        # Update apt cache when adding repository (default: true)
```

### npm Packages Format

Standard npm package names, with optional version specifiers:

```yaml
node_packages:
  - typescript
  - eslint
  - prettier
  - "@vue/cli"
  - "webpack@latest"
  - "@angular/cli@16"
```

## Usage Examples

### Standalone Usage

```yaml
- hosts: developers
  become: true
  roles:
    - role: wolskies.infrastructure.nodejs
      vars:
        node_user: developer
        node_packages:
          - typescript
          - eslint
          - prettier
          - "@vue/cli"
```

### With Variable Files

```yaml
# group_vars/developers.yml
node_user: developer
node_packages:
  - typescript
  - eslint
  - prettier
  - "@vue/cli"
  - "@angular/cli"
  - webpack
  - nodemon

# playbook.yml
- hosts: developers
  become: true
  roles:
    - wolskies.infrastructure.nodejs
```

### Integration with configure_user

This role is automatically called by configure_user when Node.js packages are specified:

```yaml
target_user:
  name: developer
  nodejs:
    packages:
      - typescript
      - eslint
      - prettier
```

## Installation Behavior

1. **Node.js Installation Check**: Verifies if `npm` command exists for the target user
2. **Repository Setup**: Adds NodeSource repository for latest Node.js (Ubuntu/Debian only)
3. **Automatic Installation**: If missing, installs Node.js via system package manager:
   - **Ubuntu/Debian**: `nodejs` and `npm` packages (from NodeSource for v20)
   - **Arch Linux**: `nodejs` and `npm` packages via pacman
   - **macOS**: `node` package via Homebrew
4. **Global Directory Setup**: Creates and configures `~/.npm-global` for user packages
5. **Package Installation**: Installs each package using `npm install -g` as the target user
6. **PATH Integration**: npm binaries are available in `~/.npm-global/bin`

## Common npm Packages

```yaml
node_packages:
  - typescript
  - eslint
  - prettier
  - nodemon
  - webpack
  - "@vue/cli"
  - "@angular/cli"
  - create-react-app
  - "@nestjs/cli"
  - pm2
  - vite
  - parcel
```

## OS Support

- **Ubuntu 22+**: Supported (24.04+ has automatic Node.js installation)
- **Debian 12+**: Supported (13+ has automatic Node.js installation)
- **Arch Linux**: Full support with automatic nodejs/npm package installation
- **macOS 10.15+**: Full support with automatic Homebrew node package installation

**Note**: This collection supports Ubuntu 22+, Debian 12+, Arch Linux, and macOS. For the language toolchain roles (nodejs, go, rust): system packages are only available on **Ubuntu 24.04+** and **Debian 13+**. On older supported versions (Ubuntu 22/23, Debian 12), you must manually install the latest rustup, node, and go before using these language roles.

## Requirements

- Target user must exist on the system
- System package manager access (for Node.js installation if needed)
- Internet access for downloading packages and repository setup
- Sufficient disk space in user's home directory

## File Locations

- **Node.js installation**: System-wide via package manager
- **User packages**: `~/.npm-global/lib/node_modules/` (packages), `~/.npm-global/bin/` (executables)
- **npm configuration**: `~/.npmrc` (configured to use global directory)
- **npm cache**: `~/.npm/` (npm cache directory)

## Integration Notes

### With configure_user Role
This role integrates seamlessly with configure_user for complete development environment setup:

```yaml
target_user:
  name: developer
  nodejs:
    packages: [typescript, eslint]
  go:
    packages: [github.com/charmbracelet/glow@latest]
  rust:
    packages: [ripgrep]
```

### PATH Configuration
npm packages install to `~/.npm-global/bin`. The role configures npm to use this directory, but users may need to add it to their PATH:

```bash
export PATH="$PATH:$HOME/.npm-global/bin"
export NPM_CONFIG_PREFIX="$HOME/.npm-global"
```

This is typically handled by shell configuration or dotfiles.

### NodeSource Repository
For Ubuntu/Debian systems, the role automatically:
- Adds NodeSource GPG key
- Configures NodeSource repository for Node.js v20
- Updates package cache
- Installs current Node.js instead of potentially outdated system packages

## Version Configuration

Control Node.js version via role variables:

```yaml
nodejs_version: "18"             # Install Node.js v18 instead of default v20
nodejs_update_cache: false       # Skip apt cache update
```

## Dependencies

- `community.general`: npm module for package installation
- `ansible.builtin.package`: For Node.js system installation
- `ansible.builtin.apt_repository`: For NodeSource repository (Ubuntu/Debian)

## License

MIT

## Author Information

This role is part of the wolskies.infrastructure collection.
