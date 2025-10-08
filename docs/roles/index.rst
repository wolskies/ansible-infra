Roles
=====

The ``wolskies.infrastructure`` collection includes the following roles.

.. contents::
   :local:
   :depth: 1

Meta-Role
---------

:doc:`configure_system`
    High-level role that Orchestrates other roles for a full setup.  Provided as a convenience, but not required to use any role in this collection.

System Configuration
--------------------

:doc:`os_configuration`
    Core operating system configuration including hostname, timezone, locale, time syncronization, systemd services, and OS-specific settings.

:doc:`manage_packages`
    Cross-platform package management (APT, Pacman, Homebrew) with repository management and layered configuration.

:doc:`manage_security_services`
    Firewall (UFW/ALF) and intrusion prevention (fail2ban) configuration across Linux and macOS.

:doc:`manage_flatpak`
    Flatpak package system management for Linux distributions.

:doc:`manage_snap_packages`
    Snap package system management and optional complete removal on Ubuntu/Debian.

User Environment
----------------

:doc:`configure_users`
    User preference configuration and development environment orchestration. Configures git, development tools, terminal, and dotfiles for existing users.

Development Tools
-----------------

:doc:`nodejs`
    Node.js installation and npm package management for user environments.

:doc:`rust`
    Rust toolchain installation via rustup and cargo package management.

:doc:`go`
    Go installation and go package management for development tools.

:doc:`neovim`
    Neovim installation and comprehensive configuration deployment.

:doc:`terminal_config`
    Terminal emulator terminfo installation (Alacritty, Kitty, WezTerm) for proper terminal support.

Role Comparison
---------------

Choosing the Right Role
~~~~~~~~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 20 40 40

   * - Use Case
     - Role
     - Notes
   * - System hostname
     - ``os_configuration``
     - System-level config
   * - Install system packages
     - ``manage_packages``
     - APT/Pacman/Homebrew
   * - Configure firewall
     - ``manage_security_services``
     - UFW/ALF/fail2ban
   * - Configure user dev environment
     - ``configure_users``
     - Orchestrates other roles
   * - Install Node.js for user
     - ``nodejs``
     - Via ``configure_users``
   * - Install Rust for user
     - ``rust``
     - Via ``configure_users``
   * - GUI applications (Linux)
     - ``manage_flatpak``
     - Flatpak apps
   * - Snap packages
     - ``manage_snap_packages``
     - Or remove snap entirely

Role Dependencies
~~~~~~~~~~~~~~~~~

Some roles work together:

* ``configure_users`` → orchestrates ``nodejs``, ``rust``, ``go``, ``neovim``, ``terminal_config``
* ``manage_packages`` → should run before ``manage_security_services`` (firewall packages)
* ``os_configuration`` → foundation, run first in most playbooks

Common Patterns
---------------

Basic Server Setup
~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   roles:
     - wolskies.infrastructure.os_configuration
     - wolskies.infrastructure.manage_packages
     - wolskies.infrastructure.manage_security_services

Developer Workstation
~~~~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   roles:
     - wolskies.infrastructure.os_configuration
     - wolskies.infrastructure.manage_packages
     - wolskies.infrastructure.configure_users

Complete System Configuration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   roles:
     - wolskies.infrastructure.os_configuration
     - wolskies.infrastructure.manage_packages
     - wolskies.infrastructure.manage_security_services
     - wolskies.infrastructure.manage_flatpak
     - wolskies.infrastructure.configure_users

Role Documentation
------------------

.. toctree::
   :maxdepth: 1

   configure_users
   manage_packages
   os_configuration
   manage_security_services
   manage_flatpak
   manage_snap_packages
   nodejs
   rust
   go
   neovim
   terminal_config
