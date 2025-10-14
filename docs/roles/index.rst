Roles
=====

The ``wolskies.infrastructure`` collection follows the **System → Software → Users** pattern with three major "muscle-mover" roles and supporting utility roles.

.. contents::
   :local:
   :depth: 1

Meta-Role
---------

:doc:`system_setup`
    Demonstrates the System → Software → Users pattern. Orchestrates configure_operating_system, configure_software, and configure_users for complete system setup.

Major Roles (Three-Phase Pattern)
----------------------------------

:doc:`configure_operating_system`
    **Phase 1 - Operating System**: OS-level configuration including hostname, timezone, locale, NTP, systemd services, kernel modules, firewall, fail2ban, and package manager configuration (APT/Pacman mirrors and auto-updates).

:doc:`configure_software`
    **Phase 2 - Software**: Package management across APT, Pacman, Homebrew, Snap, and Flatpak with hierarchical configuration and repository management.

:doc:`configure_users`
    **Phase 3 - Users**: User preferences and development environments. Orchestrates install_nodejs, install_rust, install_go, install_neovim, and install_terminfo. Configures Git, dotfiles, and platform-specific preferences (macOS Dock/Finder).

Utility Roles (install_*)
--------------------------

:doc:`install_nodejs`
    Node.js installation and npm package management for user environments.

:doc:`install_rust`
    Rust toolchain installation via rustup and cargo package management.

:doc:`install_go`
    Go installation and go package management for development tools.

:doc:`install_neovim`
    Neovim installation with optional LSP configuration deployment.

:doc:`install_terminfo`
    Terminal emulator terminfo installation (Alacritty, Kitty, WezTerm) for proper terminal support.

Role Relationships
------------------

**System → Software → Users Pattern:**

* ``system_setup`` → configure_operating_system, configure_software, configure_users

**User configuration orchestration:**

* ``configure_users`` → install_nodejs, install_rust, install_go, install_neovim, install_terminfo

**Recommended execution order** (when using individual roles):

1. ``configure_operating_system`` - OS settings, firewall, fail2ban, package manager configuration
2. ``configure_software`` - Install packages across all package managers
3. ``configure_users`` - User environments (requires packages from Phase 2 for language toolchains)

Role Documentation
------------------

.. toctree::
   :maxdepth: 1

   system_setup
   configure_operating_system
   configure_software
   configure_users
   install_nodejs
   install_rust
   install_go
   install_neovim
   install_terminfo
