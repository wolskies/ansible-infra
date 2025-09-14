# terminal_config

Terminal emulator configuration and terminfo setup for modern terminals.

## Description

Configures terminfo entries for modern terminal emulators to ensure proper terminal capabilities and display. This role downloads and compiles terminfo definitions for supported terminals, installing them to the user's `~/.terminfo` directory for proper terminal functionality.

## Features

- **Multi-terminal support**: Supports Alacritty, Kitty, WezTerm, and extensible for others
- **Automatic terminfo compilation**: Downloads and compiles terminfo sources as needed
- **User-level installation**: Installs to `~/.terminfo` without requiring system-wide changes
- **Idempotent**: Only downloads and compiles when terminfo entries are missing
- **Cross-platform**: Works on Linux and macOS systems

## Role Variables

```yaml
terminal_user: ""                     # Target username (required)
terminal_entries: []                  # List of terminals to configure (required)
```

## Supported Terminals

### Currently Supported

- **alacritty**: Modern GPU-accelerated terminal emulator
- **kitty**: Fast, feature-rich, cross-platform terminal
- **wezterm**: GPU-accelerated cross-platform terminal emulator

### Terminal Configuration

Each terminal has predefined configuration including:
- Terminfo source URL (GitHub raw files)
- Terminal entry names for compilation
- TIC compilation options

## Usage Examples

### Standalone Usage

```yaml
- hosts: workstations
  become: true
  roles:
    - role: wolskies.infrastructure.terminal_config
      vars:
        terminal_user: developer
        terminal_entries:
          - alacritty
          - kitty
```

### With Variable Files

```yaml
# group_vars/developers.yml
terminal_user: developer
terminal_entries:
  - alacritty
  - wezterm

# playbook.yml
- hosts: developers
  become: true
  roles:
    - wolskies.infrastructure.terminal_config
```

### Integration with configure_user

This role integrates with the configure_user role when terminal configuration is specified:

```yaml
users:
  - name: developer
    terminal_entries:
      - alacritty
      - kitty
```

## Installation Behavior

1. **Validation**: Checks required variables (user and terminal list)
2. **Terminfo Check**: Uses `infocmp` to check existing terminfo entries
3. **Compilation Decision**: Determines which terminals need terminfo compilation
4. **Directory Creation**: Ensures `~/.terminfo` directory exists if needed
5. **Per-terminal Processing**: For each terminal requiring setup:
   - Downloads terminfo source from official repository
   - Compiles using `tic` with appropriate options
   - Installs to user's `~/.terminfo` directory
   - Cleans up temporary files

## File Locations

- **Terminfo installation**: `~/.terminfo/` (user-specific)
- **Temporary files**: System temp directory (cleaned up automatically)

## Requirements

- Target user must exist on the system
- `tic` command available (part of ncurses-utils/ncurses-bin)
- Internet access for downloading terminfo sources
- Write access to user's home directory

## OS Support

- **Ubuntu 22+**: Full support
- **Debian 12+**: Full support
- **Arch Linux**: Full support
- **macOS 10.15+**: Full support

## Adding New Terminals

To add support for additional terminals, extend the `terminal_configs` mapping in defaults:

```yaml
terminal_configs:
  new_terminal:
    terminfo_url: "https://example.com/terminal.terminfo"
    entries: [terminal-name, terminal-variant]
    tic_options: "-x"
```

## Integration Notes

### With configure_user Role

This role integrates seamlessly with configure_user for complete development environment setup:

```yaml
users:
  - name: developer
    terminal_entries: [alacritty, kitty]
    nodejs:
      packages: [typescript]
    neovim:
      enabled: true
```

## Dependencies

- System package: ncurses-utils (Ubuntu/Debian) or ncurses (Arch/macOS)
- Commands: `tic`, `infocmp`
- Internet access for terminfo source downloads

## License

MIT

## Author Information

This role is part of the wolskies.infrastructure collection.
