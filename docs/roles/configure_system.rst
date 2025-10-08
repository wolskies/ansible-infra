configure_system
================

Orchestrator role that executes os_configuration, manage_packages, manage_security_services, manage_snap_packages, manage_flatpak, and configure_users in dependency order.

.. contents::
   :local:
   :depth: 2

Overview
--------

The ``configure_system`` role executes other collection roles in dependency order. Individual roles can be run directly for granular control, or use tags to run specific subsets.

Execution Order
~~~~~~~~~~~~~~~

Roles are executed in this sequence:

1. ``os_configuration`` - Core system settings (hostname, timezone, locale, services)
2. ``manage_packages`` - System package installation and repository management
3. ``manage_security_services`` - Firewall and intrusion prevention configuration
4. ``manage_snap_packages`` - Snap package management (or removal)
5. ``manage_flatpak`` - Flatpak application installation
6. ``configure_users`` - User environment and development tool configuration

Usage
-----

Examples
~~~~~~~~

Complete Ubuntu system setup:

.. code-block:: yaml

   - hosts: all
     become: true
     roles:
       - wolskies.infrastructure.configure_system
     vars:
       domain_timezone: "America/New_York"
       host_hostname: "{{ inventory_hostname }}"
       users:
         - name: admin
           git:
             user_name: "Admin User"
             user_email: "admin@example.com"
       packages:
         present:
           all:
             Ubuntu: [git, curl, vim]
       firewall:
         enabled: true
         rules:
           - port: 22
             protocol: tcp

Layered configuration using inventory structure:

.. code-block:: yaml

   # group_vars/all.yml - Base configuration for all hosts
   domain_timezone: "America/New_York"
   domain_locale: "en_US.UTF-8"

   users:
     - name: developer
       git:
         user_name: "Developer Name"
         user_email: "developer@example.com"
       nodejs:
         packages: [typescript, eslint, prettier]
       rust:
         packages: [ripgrep, fd-find, bat]

   packages:
     present:
       all:
         Ubuntu: [git, curl, vim, htop, tmux]
         Debian: [git, curl, vim, htop, tmux]
         Archlinux: [git, curl, vim, htop, tmux]

   # group_vars/webservers.yml - Web server specific packages
   packages:
     present:
       group:
         Ubuntu: [nginx, certbot, postgresql]
         Debian: [nginx, certbot, postgresql]

   firewall:
     enabled: true
     rules:
       - port: 80,443
         protocol: tcp
         comment: "HTTP/HTTPS traffic"
       - port: 22
         protocol: tcp
         source: "10.0.0.0/8"
         comment: "SSH from internal network"

   # host_vars/web01.yml - Host-specific configuration
   host_hostname: "web01"
   packages:
     present:
       host:
         Ubuntu: [redis-server, nodejs]

Variables
---------

This role uses collection-wide variables from all orchestrated roles. See :doc:`/reference/variables-reference` for the complete interface.

**Key variable groups:**

- **System Configuration**: ``domain_timezone``, ``domain_locale``, ``host_hostname``
- **Package Management**: ``packages.present.all``, ``packages.present.group``, ``packages.present.host``
- **Security Services**: ``firewall.enabled``, ``firewall.rules``, ``fail2ban.*``
- **Snap Packages**: ``snap_packages.*``, ``snap.purge``
- **Flatpak Applications**: ``flatpak_packages.*``
- **User Configuration**: ``users[]`` with nested tool configuration

Tags
----

- ``os-configuration`` - OS settings (hostname, timezone, locale, services)
- ``packages`` - Package management and repositories
- ``security-services`` - Firewall and fail2ban configuration
- ``snap-packages`` - Snap package management
- ``flatpak-packages`` - Flatpak application management
- ``user-configuration`` - User preferences and development tools

Dependencies
------------

**Role Dependencies:**

This role orchestrates the following roles from this collection:

- :doc:`os_configuration` - Core system configuration
- :doc:`manage_packages` - Package management
- :doc:`manage_security_services` - Security services
- :doc:`manage_snap_packages` - Snap packages
- :doc:`manage_flatpak` - Flatpak applications
- :doc:`configure_users` - User environments

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

- :doc:`/user-guide/configuration` - Configuration strategies
- :doc:`/reference/variables-reference` - Complete variable reference
- :doc:`/quickstart` - Quick start guide
