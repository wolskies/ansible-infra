# nodejs

Node.js installation and user-level npm package management.

## What It Does

Installs Node.js system packages and user-level npm packages:
- **Node.js installation** - System packages via package manager
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

### Integration with configure_user
```yaml
target_user:
  name: developer
  nodejs:
    packages:
      - typescript
      - eslint
      - prettier
      - "@angular/cli"
```

## Variables

Key configuration options:
- `node_user` - Target username (required)
- `node_packages` - List of npm packages to install globally
- `nodejs_version` - Node.js major version (default: "20")

## Platform Support

- **Ubuntu** 22.04+, 24.04+
- **Debian** 12+, 13+
- **Arch Linux** (Rolling)
- **macOS** 13+ (Ventura)

## Dependencies

- `community.general.npm` (Package installation)
- `ansible.builtin.deb822_repository` (NodeSource repository on Ubuntu/Debian)
