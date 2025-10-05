# neovim

Comprehensive Neovim installation and development-ready configuration.

## What It Does

Installs and configures Neovim for development:
- **Neovim Installation** - Latest available version via system package manager
- **Plugin Manager** - lazy.nvim for efficient plugin management
- **LSP Configuration** - Language server protocol support for multiple languages
- **Development Dependencies** - Git and language servers (platform-dependent)
- **Vim Compatibility** - Alias for seamless transition from vim

## Usage

### Basic Installation
```yaml
- hosts: developers
  become: true
  roles:
    - wolskies.infrastructure.neovim
  vars:
    neovim_user: developer
```

### Integration with configure_users
```yaml
target_user:
  name: developer
  neovim:
    enabled: true
```

## Variables

### Role Variables
| Variable | Type | Required | Default | Description |
| -------- | ---- | -------- | ------- | ----------- |
| `neovim_user` | string | Yes | - | Target username for Neovim installation |
| `neovim_config_enabled` | boolean | No | `true` | Enable comprehensive configuration deployment |

## Installation Behavior

1. **Neovim Installation** - Installs Neovim and dependencies:
   - **Ubuntu/Debian** - APT `neovim` and `git` packages
   - **Arch Linux** - Pacman `neovim`, `git`, `lua-language-server`, and `pyright` packages
   - **macOS** - Homebrew `neovim`, `git`, `lua-language-server`, and `pyright` packages
2. **Plugin Manager Setup** - Clones lazy.nvim to `~/.local/share/nvim/lazy/lazy.nvim`
3. **Configuration Deployment** - Creates comprehensive Lua-based configuration
4. **Vim Compatibility** - Creates `~/.local/bin/vim` alias script

## Configuration Features

When `neovim_config_enabled` is true (default):
- **Plugin Management** - lazy.nvim for efficient plugin loading
- **LSP Support** - Configured for lua_ls, rust_analyzer, and pyright
- **Development Bindings** - Essential key mappings for development workflow
- **Modern Configuration** - Lua-based configuration for performance

## Platform-Specific Features

### Arch Linux & macOS
- Enhanced LSP functionality with pre-installed language servers
- `lua-language-server` for Lua development
- `pyright` for Python development

### Ubuntu/Debian
- Base Neovim installation with git support
- LSP servers can be installed separately as needed

## File Locations

- **Configuration**: `~/.config/nvim/`
- **Plugin Manager**: `~/.local/share/nvim/lazy/lazy.nvim`
- **Vim Alias**: `~/.local/bin/vim`
- **User Binaries**: `~/.local/bin/` (added to PATH if needed)

## Vim Compatibility

The role creates a vim compatibility alias that:
- Redirects `vim` commands to `nvim`
- Maintains muscle memory for users transitioning from vim
- Preserves all command-line arguments and options

## Platform Support

- **Ubuntu** 22.04+, 24.04+
- **Debian** 12+, 13+
- **Arch Linux** (Rolling)
- **macOS** 13+ (Ventura)

## Dependencies

- `ansible.builtin.apt` (Ubuntu/Debian package installation)
- `ansible.builtin.package` (Arch Linux package installation)
- `community.general.homebrew` (macOS package installation)
- `ansible.builtin.git` (Plugin manager installation)
- `ansible.builtin.file` (Directory and alias creation)
- `ansible.builtin.copy` (Configuration deployment)
