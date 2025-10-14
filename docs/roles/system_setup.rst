system_setup
============

Meta-role demonstrating the **System → Software → Users** pattern for complete infrastructure setup.

.. contents::
   :local:
   :depth: 2

Overview
--------

The ``system_setup`` role orchestrates the three major "muscle-mover" roles in the collection, demonstrating the recommended pattern for complete system configuration.

Execution Order (Three-Phase Pattern)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Roles are executed in this sequence:

1. ``configure_operating_system`` - Phase 1: OS-level configuration
2. ``configure_software`` - Phase 2: Package management across all package managers
3. ``configure_users`` - Phase 3: User preferences and development environments

Usage
-----

Examples
~~~~~~~~

Complete Ubuntu system setup:

.. code-block:: yaml

   - hosts: all
     become: true
     roles:
       - wolskies.infrastructure.system_setup
     vars:
       domain_timezone: "America/New_York"
       host_hostname: "{{ inventory_hostname }}"

       # Phase 1: Operating System Configuration
       firewall:
         enabled: true
         rules:
           - port: 22
             protocol: tcp

       # Phase 2: Software Packages
       manage_packages_all:
         Ubuntu: [git, curl, vim, build-essential]

       # Phase 3: User Configuration
       users:
         - name: developer
           git:
             user_name: "Developer Name"
             user_email: "dev@example.com"
           nodejs:
             packages: [typescript, eslint]
           rust:
             packages: [ripgrep, bat]

Layered configuration using inventory structure:

.. code-block:: yaml

   # group_vars/all.yml - Base configuration for all hosts
   domain_timezone: "America/New_York"
   domain_locale: "en_US.UTF-8"

   # Phase 1: OS Configuration
   firewall:
     enabled: true
     rules:
       - port: 22
         protocol: tcp

   # Phase 2: Base packages
   manage_packages_all:
     Ubuntu: [git, curl, vim, htop, tmux]
     Debian: [git, curl, vim, htop, tmux]
     Archlinux: [git, curl, vim, htop, tmux]

   # Phase 3: User configuration
   users:
     - name: developer
       git:
         user_name: "Developer Name"
         user_email: "developer@example.com"
       nodejs:
         packages: [typescript, eslint, prettier]

   # group_vars/webservers.yml - Web server specific packages
   manage_packages_group:
     Ubuntu: [nginx, certbot, postgresql]
     Debian: [nginx, certbot, postgresql]

   firewall:
     rules:
       - port: 80,443
         protocol: tcp

   # host_vars/web01.yml - Host-specific configuration
   host_hostname: "web01"
   manage_packages_host:
     Ubuntu: [redis-server]

Variables
---------

This role uses collection-wide variables from all orchestrated roles. See :doc:`/reference/variables-reference` for the complete interface.

**Key variable groups:**

- **Phase 1 (Operating System)**: ``domain_timezone``, ``domain_locale``, ``host_hostname``, ``firewall.*``, ``fail2ban.*``, ``apt.*``, ``pacman.*``
- **Phase 2 (Software)**: ``manage_packages_all``, ``manage_packages_group``, ``manage_packages_host``, ``snap.*``, ``flatpak.*``
- **Phase 3 (Users)**: ``users[]`` with nested tool configuration (git, nodejs, rust, go, neovim, dotfiles, terminal_entries)

Tags
----

- ``operating-system`` - OS-level configuration (Phase 1)
- ``software`` - Package management (Phase 2)
- ``users`` - User preferences and environments (Phase 3)

Dependencies
------------

**Role Dependencies:**

This role orchestrates the following roles from this collection:

- :doc:`configure_operating_system` - Phase 1: OS configuration
- :doc:`configure_software` - Phase 2: Package management
- :doc:`configure_users` - Phase 3: User environments

**Ansible Collections:**

All Ansible collection dependencies are installed via:

.. code-block:: bash

   ansible-galaxy collection install -r requirements.yml

Platform Support
----------------

Supports the same platforms as the underlying roles:

- **Ubuntu** 22.04+, 24.04+
- **Debian** 12+, 13+
- **Arch Linux** (Rolling)
- **macOS** 13+ (Ventura) - limited testing

See Also
--------

- :doc:`configure_operating_system` - Phase 1 documentation
- :doc:`configure_software` - Phase 2 documentation
- :doc:`configure_users` - Phase 3 documentation
- :doc:`/user-guide/configuration` - Configuration strategies
- :doc:`/reference/variables-reference` - Complete variable reference
- :doc:`/quickstart` - Quick start guide
