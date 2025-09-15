# neovim

Neovim installation and user-level configuration with lazy.nvim plugin manager.

## Description

Installs neovim system-wide if not present, then configures per-user neovim setup with lazy.nvim plugin manager, LSP support, and a comprehensive configuration. Creates a vim alias for seamless transition from vim to neovim.

## Features

- **System installation**: Installs neovim via system package manager if missing
- **User configuration**: Sets up per-user neovim config with lazy.nvim
- **LSP support**: Includes lua-language-server and pyright on Arch Linux and macOS
- **Vim compatibility**: Creates vim alias script for easy transition
- **Plugin management**: Lazy.nvim for modern plugin management
- **Cross-platform**: Works on Ubuntu, Debian, Arch Linux, and macOS

## Role Variables

```yaml
neovim_user: ""                    # Target username (required)
neovim_config_enabled: true        # Whether to install user configuration
```

## Usage Examples

### Standalone Usage

```yaml
- hosts: developers
  become: true
  roles:
    - role: wolskies.infrastructure.neovim
      vars:
        neovim_user: developer
```

### With Variable Files

```yaml
# group_vars/developers.yml
neovim_user: developer
neovim_config_enabled: true

# playbook.yml
- hosts: developers
  become: true
  roles:
    - wolskies.infrastructure.neovim
```

### Integration with configure_user

This role is automatically called by configure_user when neovim configuration is specified:

```yaml
target_user:
  name: developer
  neovim:
    enabled: true
```

## Installation Behavior

1. **Neovim Check**: Verifies if `nvim` command exists
2. **System Installation**: If missing, installs neovim via package manager:
   - **Ubuntu/Debian**: `neovim`, `lua-language-server`, `pyright` via apt
   - **Arch Linux**: `neovim`, `lua-language-server`, `pyright` via pacman
   - **macOS**: `neovim`, `lua-language-server`, `pyright` via Homebrew
3. **User Configuration**: As the target user:
   - Creates `~/.local/bin/vim` alias script
   - Installs lazy.nvim plugin manager
   - Copies comprehensive neovim configuration files

## Configuration Features

### Included Configuration
- **Lazy.nvim**: Modern plugin manager with lazy loading
- **LSP Integration**: Built-in language server protocol support
- **Clipboard**: Unified clipboard integration (`unnamedplus`)
- **Leader Key**: Space as leader key for custom mappings
- **Plugin Categories**: UI, LSP, configuration, and support plugins

### File Structure
```
~/.config/nvim/
├── init.lua                      # Main configuration entry point
├── lua/
│   ├── config/
│   │   └── lazy.lua             # Lazy.nvim setup and plugin loading
│   └── plugins/
│       ├── configuration.lua     # General vim configuration
│       ├── lsp.lua              # Language server setup
│       ├── support.lua          # Supporting utilities
│       └── ui.lua               # User interface plugins
```

### Vim Alias
Creates `~/.local/bin/vim` script that executes `nvim "$@"` for seamless transition.

## OS Support

- **Ubuntu 22+**: Neovim installation only (LSP packages not available in repos)
- **Debian 12+**: Neovim installation only (LSP packages not available in repos)
- **Arch Linux**: Full support with LSP packages (lua-language-server, pyright)
- **macOS 10.15+**: Full support with LSP packages via Homebrew

**LSP Setup on Ubuntu/Debian**: LSP packages (lua-language-server, pyright) are not available in Ubuntu/Debian repositories. After running this role, manually install LSP servers:
- Use `:Mason` in neovim to install language servers
- Or manually install lua-language-server and pyright via their binary releases

## Requirements

- Target user must exist on the system
- System package manager access (for neovim installation if needed)
- Internet access for downloading lazy.nvim and plugins
- Git (for lazy.nvim and plugin installation)

## File Locations

- **Neovim installation**: System-wide via package manager
- **User configuration**: `~/.config/nvim/` (XDG config standard)
- **Plugin manager**: `~/.local/share/nvim/lazy/lazy.nvim`
- **Plugins**: `~/.local/share/nvim/lazy/` (managed by lazy.nvim)
- **Vim alias**: `~/.local/bin/vim`

## Integration Notes

### With configure_user Role
This role integrates seamlessly with configure_user for complete development environment setup:

```yaml
target_user:
  name: developer
  neovim:
    enabled: true
  nodejs:
    packages: [typescript]
  rust:
    packages: [rust-analyzer]
```

### PATH Configuration
The vim alias is installed to `~/.local/bin/vim`. Ensure `~/.local/bin` is in the user's PATH for the alias to work.

## Plugin Management

The included configuration uses lazy.nvim for plugin management. Users can:
- Add plugins by editing `~/.config/nvim/lua/plugins/` files
- Lazy.nvim automatically manages plugin installation and loading
- Run `:Lazy` in neovim to manage plugins interactively

## Dependencies

- System package manager (apt, pacman, homebrew)
- Git (for plugin management)
- `ansible.builtin.command` - For neovim detection
- `community.general.homebrew` - For macOS installation

## License

MIT

## Author Information

This role is part of the wolskies.infrastructure collection.
