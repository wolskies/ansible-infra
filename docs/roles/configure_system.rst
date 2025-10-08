configure_system
================

Meta-role that orchestrates a complete system configuration by executing other collection roles in the proper order.

.. contents::
   :local:
   :depth: 2

Overview
--------

The ``configure_system`` role provides a high-level interface for configuring entire systems. It executes collection roles in a specific order to ensure dependencies are satisfied and configuration is applied correctly.

**This role is provided as a convenience** - individual roles are designed to be run directly for more granular control.

Execution Order
~~~~~~~~~~~~~~~

Roles are executed in this sequence:

1. ``os_configuration`` - Core system settings (hostname, timezone, locale, services)
2. ``manage_packages`` - System package installation and repository management
3. ``manage_security_services`` - Firewall and intrusion prevention configuration
4. ``manage_snap_packages`` - Snap package management (or removal)
5. ``manage_flatpak`` - Flatpak application installation
6. ``configure_users`` - User environment and development tool configuration

This order ensures that:

- System foundation is configured first
- Required packages are installed before services that depend on them
- Security services are configured after packages are available
- User environments are configured last after all system components are ready

Usage
-----

Basic Configuration
~~~~~~~~~~~~~~~~~~~

Example playbook for complete Ubuntu system setup:

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

Advanced Configuration
~~~~~~~~~~~~~~~~~~~~~~

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

Selective Role Execution
~~~~~~~~~~~~~~~~~~~~~~~~~
.. Does this add anything useful?  Won't an ansible user understand what tags do? COMMENT
Use tags to run only specific roles:

.. code-block:: bash

   # Only configure OS settings
   ansible-playbook -i inventory configure_system.yml --tags os-configuration

   # Only manage packages
   ansible-playbook -i inventory configure_system.yml --tags packages

   # Configure OS and packages, skip security
   ansible-playbook -i inventory configure_system.yml --tags os-configuration,packages

   # Everything except user configuration
   ansible-playbook -i inventory configure_system.yml --skip-tags user-configuration

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

Each orchestrated role can be targeted independently:

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

.. What do these examples bring?  COMMENT
Examples
--------

Minimal Server
~~~~~~~~~~~~~~

.. code-block:: yaml

   - hosts: servers
     become: true
     roles:
       - wolskies.infrastructure.configure_system
     vars:
       domain_timezone: "UTC"
       host_hostname: "{{ inventory_hostname }}"
       packages:
         present:
           all:
             Ubuntu: [vim, git, htop]
       firewall:
         enabled: true
         default_policy:
           incoming: deny
           outgoing: allow
         rules:
           - port: 22
             protocol: tcp

Developer Workstation
~~~~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   - hosts: workstations
     become: true
     roles:
       - wolskies.infrastructure.configure_system
     vars:
       domain_timezone: "America/New_York"
       host_hostname: "{{ inventory_hostname }}"

       packages:
         present:
           all:
             Ubuntu: [git, curl, vim, neovim, tmux, htop, build-essential]

       flatpak_packages:
         flathub:
           - com.visualstudio.code
           - org.mozilla.firefox

       users:
         - name: developer
           git:
             user_name: "John Developer"
             user_email: "john@example.com"
           nodejs:
             version: "20.x"
             packages: [typescript, eslint, prettier, npm-check-updates]
           rust:
             packages: [ripgrep, fd-find, bat, exa]
           go:
             packages:
               - github.com/jesseduffield/lazygit@latest
           neovim:
             deploy_config: true
           terminal_config:
             install_terminfo: [alacritty, kitty]

Secure Web Server
~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   - hosts: webservers
     become: true
     roles:
       - wolskies.infrastructure.configure_system
     vars:
       domain_timezone: "UTC"
       host_hostname: "{{ inventory_hostname }}"

       # Harden the OS
       hardening:
         os_hardening_enabled: true
         ssh_hardening_enabled: true
         os_auth_pw_max_age: 60
         ssh_server_ports: ["2222"]
         sftp_enabled: false

       packages:
         present:
           all:
             Ubuntu: [nginx, certbot, fail2ban, ufw]

       firewall:
         enabled: true
         default_policy:
           incoming: deny
           outgoing: allow
         rules:
           - port: 80,443
             protocol: tcp
             comment: "HTTP/HTTPS"
           - port: 2222
             protocol: tcp
             source: "10.0.0.0/8"
             comment: "SSH from internal only"

       fail2ban:
         enabled: true
         jails:
           - name: sshd
             enabled: true
             maxretry: 3
             bantime: 3600

See Also
--------

- :doc:`/user-guide/configuration` - Configuration strategies
- :doc:`/reference/variables-reference` - Complete variable reference
- :doc:`/quickstart` - Quick start guide
