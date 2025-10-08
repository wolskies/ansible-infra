Roles
=====

The ``wolskies.infrastructure`` collection includes the following roles.

.. contents::
   :local:
   :depth: 1

Orchestrator Roles
------------------

:doc:`configure_system`
    Orchestrates os_configuration, manage_packages, manage_security_services, manage_flatpak, manage_snap_packages, and configure_users for complete system setup.

:doc:`configure_users`
    Orchestrates nodejs, rust, go, neovim, and terminal_config for user environment configuration. Skips non-existent users and root automatically.

System Configuration
--------------------

:doc:`os_configuration`
    Core operating system configuration including hostname, timezone, locale, time synchronization, systemd services, kernel modules, sysctl parameters, and udev rules.

:doc:`manage_packages`
    Cross-platform package management (APT, Pacman, Homebrew) with repository management and layered configuration.

:doc:`manage_security_services`
    Firewall (UFW/ALF) and intrusion prevention (fail2ban) configuration across Linux and macOS.

:doc:`manage_flatpak`
    Flatpak package system management for Ubuntu, Debian, and Arch Linux. Supports Flathub repository and desktop integration plugins.

:doc:`manage_snap_packages`
    Snap package system management and optional complete removal on Ubuntu/Debian.

Development Tools
-----------------

:doc:`nodejs`
    Node.js installation and npm package management for user environments.

:doc:`rust`
    Rust toolchain installation via rustup and cargo package management.

:doc:`go`
    Go installation and go package management for development tools.

:doc:`neovim`
    Neovim installation with optional LSP configuration deployment.

:doc:`terminal_config`
    Terminal emulator terminfo installation (Alacritty, Kitty, WezTerm) for proper terminal support.

Role Relationships
------------------

**Orchestrator roles** invoke other roles:

* ``configure_system`` → os_configuration, manage_packages, manage_security_services, manage_flatpak, manage_snap_packages, configure_users
* ``configure_users`` → nodejs, rust, go, neovim, terminal_config

**Execution order** (when using individual roles):

1. ``os_configuration`` - system-level settings
2. ``manage_packages`` - install packages (including firewall packages)
3. ``manage_security_services`` - configure firewall and fail2ban
4. ``manage_flatpak`` / ``manage_snap_packages`` - application packages
5. ``configure_users`` - user environments (requires language runtimes from manage_packages if using system-wide installs)

Role Documentation
------------------

.. toctree::
   :maxdepth: 1

   configure_system
   configure_users
   os_configuration
   manage_packages
   manage_security_services
   manage_flatpak
   manage_snap_packages
   nodejs
   rust
   go
   neovim
   terminal_config
