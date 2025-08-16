# Opinionated Package Sets

This directory contains example configurations for fuller package sets that were removed from the `basic_setup` role to keep it minimal and focused on OS essentials only.

## Purpose

The `basic_setup` role now only installs essential packages needed for a consistent, predictable starting point across different operating systems. These opinionated package files provide examples of additional packages you might want for development workstations or specific use cases.

## Usage

To use these opinionated package sets:

1. **Copy the relevant file to your inventory structure:**
   ```bash
   # For workstations group
   cp opinionated-packages-ubuntu.yml your-inventory/group_vars/workstations.yml
   
   # For all hosts
   cp opinionated-packages-ubuntu.yml your-inventory/group_vars/all.yml
   
   # For specific host
   cp opinionated-packages-ubuntu.yml your-inventory/host_vars/hostname.yml
   ```

2. **Modify the variable names in your copied file:**
   The example files use `additional_*` prefixes to avoid conflicts. In your actual inventory, you can rename these:
   ```yaml
   # Change from:
   additional_packages_install:
   
   # To:
   packages_install:
   ```

3. **Merge with existing variables:**
   If you already have package lists, merge them appropriately.

## Available Package Sets

- **`opinionated-packages-archlinux.yml`** - Full development setup for Arch Linux
- **`opinionated-packages-ubuntu.yml`** - Comprehensive Ubuntu workstation packages
- **`opinionated-packages-debian.yml`** - Debian development environment
- **`opinionated-packages-macos.yml`** - macOS productivity and development tools

## What's Included

These package sets typically include:

### Terminal & Shell
- Modern terminal emulators (kitty)
- Advanced shells (zsh)
- Shell prompt enhancements (starship)
- Modern CLI tools (eza, fzf, zoxide)

### Development
- Code editors (vim, neovim, VS Code)
- Version control tools
- Language runtimes (Python, Node.js)
- Infrastructure tools (Ansible)

### Productivity
- System monitors (htop, btop)
- File managers and utilities
- Terminal multiplexers (tmux, screen)

### Fonts & Appearance
- Programming fonts with ligatures
- Nerd fonts for icon support
- Powerline symbols

## Customization

Feel free to modify these files to match your preferences:

1. Remove packages you don't need
2. Add packages specific to your workflow
3. Adjust configuration variables
4. Set up additional repositories or package sources

## Integration with basic_setup

The `basic_setup` role will automatically use variables like `packages_install` if they're defined in your inventory, so these opinionated sets will extend the minimal essential packages with your preferred additions.

## Example Integration

```yaml
# group_vars/workstations.yml
---
# Essential packages (handled by basic_setup automatically)
# - git, curl, wget, rsync, unzip, python3, etc.

# Additional opinionated packages
packages_install:
  - kitty
  - zsh
  - starship
  - eza
  - fzf
  - neovim
  - ansible

# Configuration
default_user_shell: /bin/zsh
configure_zsh: true
install_oh_my_zsh: true
```

This approach gives you the flexibility to have minimal servers with just essentials, while workstations get the full development environment.