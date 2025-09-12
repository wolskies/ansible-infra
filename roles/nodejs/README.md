# nodejs

Internal helper role for Node.js installation and npm package management.

## Description

Automatically installs Node.js and npm packages for users when called by the `configure_user` role. Handles cross-platform installation via system package managers and uses the `community.general.npm` module for package management.

## OS Version Requirements

- **Ubuntu 24.04+** (Noble): Reliable nodejs package availability via NodeSource repository
- **Debian 13+** (Trixie): Modern nodejs package support
- **Arch Linux**: Current rolling release
- **macOS 10.15+**: Via Homebrew

**Note**: On older OS versions, nodejs installation may fail. Manually install `nodejs` and `npm` before using this role as a workaround.

## Features

- Automatic Node.js system installation when `npm` not found
- Uses `community.general.npm` module (not shell commands)
- Configures npm global directory with proper environment variables
- Cross-platform PATH handling for installed packages
- NodeSource repository setup for Debian/Ubuntu (Node.js v20)

## Usage

This role is called internally by `configure_user` and should not be invoked directly. Use language package configuration in user preferences instead:

```yaml
infrastructure:
  domain:
    users:
      - name: developer
        nodejs:
          packages: [typescript, eslint, prettier]
```

## Dependencies

- `community.general` - npm module for package installation
- System package manager access for nodejs installation
