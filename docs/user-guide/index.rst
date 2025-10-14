User Guide
==========

Comprehensive guide to using the ``wolskies.infrastructure`` collection.

.. contents::
   :local::
   :depth: 2

Overview
--------

The ``wolskies.infrastructure`` collection provides a structured approach to infrastructure automation following the **System → Software → Users** pattern. This three-phase pattern ensures consistent, repeatable system configuration across Ubuntu, Debian, Arch Linux, and macOS.

**Three-Phase Pattern:**

1. **Phase 1 - Operating System** (:doc:`../roles/configure_operating_system`)

   - OS-level configuration (hostname, timezone, locale)
   - Firewall configuration (UFW/ALF)
   - Intrusion prevention (fail2ban)
   - Package manager configuration (APT/Pacman proxy, mirrors, auto-updates)

2. **Phase 2 - Software** (:doc:`../roles/configure_software`)

   - Package management across APT, Pacman, Homebrew
   - Repository management with automatic GPG key handling
   - Application packaging (Snap, Flatpak)
   - Hierarchical package configuration (all → group → host)

3. **Phase 3 - Users** (:doc:`../roles/configure_users`)

   - Git configuration
   - Development environments (Node.js, Rust, Go, Neovim)
   - Terminal emulator configuration
   - Dotfiles deployment
   - macOS preferences (Dock, Finder, screenshots)

**Meta-Role:**

- :doc:`../roles/system_setup` - Demonstrates the complete three-phase pattern in a single role

**Utility Roles:**

The collection includes utility roles for targeted installations:

- :doc:`../roles/install_nodejs` - Node.js and npm packages
- :doc:`../roles/install_rust` - Rust toolchain and cargo packages
- :doc:`../roles/install_go` - Go toolchain and go packages
- :doc:`../roles/install_neovim` - Neovim with LSP configuration
- :doc:`../roles/install_terminfo` - Terminal emulator terminfo

These utility roles are typically orchestrated by ``configure_users`` but can be used standalone.

Getting Started
---------------

**Quick Start:**

See :doc:`../quickstart` for a rapid introduction with working examples.

**Installation:**

See :doc:`../installation` for detailed installation instructions.

**Role Documentation:**

See :doc:`../roles/index` for comprehensive role documentation.

Configuration Guide
-------------------

See :doc:`configuration` for detailed configuration strategies including:

- Layered configuration (all → group → host)
- Variable organization and precedence
- Platform-specific configuration
- Multi-environment patterns
- Best practices

Variable System
---------------

See :doc:`variables` for understanding the collection's variable system:

- Variable naming conventions
- Hierarchical variable merging
- OS family keys (Ubuntu, Debian, Archlinux, Darwin)
- Variable precedence rules
- Common patterns

Platform Support
----------------

See :doc:`platform-support` for detailed platform information:

- Supported operating systems and versions
- Platform-specific features
- Known limitations
- Testing status

Common Workflows
----------------

Development Workstation Setup
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Complete workstation configuration with development tools:

.. code-block:: yaml

   # playbook.yml
   - hosts: workstations
     become: true
     roles:
       - wolskies.infrastructure.system_setup
     vars:
       # Phase 1: Operating System
       hostname: dev-workstation
       timezone: America/New_York

       firewall:
         enabled: true
         default_policy: deny
         allow_ssh: true

       # Phase 2: Software
       manage_packages_all:
         Ubuntu: [git, curl, vim, htop, tmux, build-essential]
         Darwin: [git, curl, vim, htop, tmux]

       # Phase 3: Users
       users:
         - name: developer
           git:
             user_name: "Developer Name"
             user_email: "dev@company.com"
             editor: "nvim"

           nodejs:
             packages: [typescript, eslint, prettier]

           rust:
             packages: [ripgrep, bat, fd-find]

           go:
             packages:
               - github.com/jesseduffield/lazygit@latest

           neovim:
             deploy_config: true

           terminal_config:
             install_terminfo: [alacritty, kitty]

Server Configuration
~~~~~~~~~~~~~~~~~~~~

Minimal server setup with security hardening:

.. code-block:: yaml

   - hosts: servers
     become: true
     roles:
       - wolskies.infrastructure.configure_operating_system
       - wolskies.infrastructure.configure_software
     vars:
       # Phase 1: Operating System
       hostname: web-server-01
       timezone: UTC

       firewall:
         enabled: true
         default_policy: deny
         allow_ssh: true
         rules:
           - port: 80
             protocol: tcp
             rule: allow
           - port: 443
             protocol: tcp
             rule: allow

       fail2ban:
         enabled: true
         services: [sshd]

       # Phase 2: Software
       manage_packages_all:
         Ubuntu: [nginx, postgresql-14, certbot]

Multi-Environment Configuration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Organize configuration across environments:

.. code-block:: yaml

   # group_vars/all.yml - Base configuration
   manage_packages_all:
     Ubuntu: [git, curl, vim, htop]
     Darwin: [git, curl, vim, htop]

   # group_vars/development.yml - Development packages
   manage_packages_group:
     Ubuntu: [build-essential, python3-dev, nodejs]
     Darwin: [python3, nodejs]

   # group_vars/production.yml - Production packages
   manage_packages_group:
     Ubuntu: [nginx, postgresql-14, redis-server]

   # host_vars/web01.yml - Host-specific
   manage_packages_host:
     Ubuntu: [memcached, varnish]

Advanced Patterns
-----------------

Conditional Configuration
~~~~~~~~~~~~~~~~~~~~~~~~~

Configure based on platform or environment:

.. code-block:: yaml

   # Configure development tools only for workstations
   users:
     - name: developer
       nodejs:
         packages: "{{ dev_nodejs_packages if ansible_host in groups['workstations'] else [] }}"

   vars:
     dev_nodejs_packages:
       - typescript
       - "@vue/cli"
       - eslint

Role Tagging
~~~~~~~~~~~~

Run specific configuration phases:

.. code-block:: bash

   # Only Phase 1 (Operating System)
   ansible-playbook -t os playbook.yml

   # Only Phase 2 (Software)
   ansible-playbook -t packages playbook.yml

   # Only Phase 3 (Users)
   ansible-playbook -t user-git,user-nodejs playbook.yml

   # Skip container-incompatible features
   ansible-playbook --skip-tags no-container,snap,flatpak playbook.yml

Troubleshooting
---------------

Common Issues
~~~~~~~~~~~~~

**PATH not updated after user configuration:**

User must logout and login, or source profile:

.. code-block:: bash

   source ~/.profile

**AUR packages fail on Arch Linux:**

Ensure passwordless sudo for pacman. See :doc:`../installation` for Arch setup.

**Snap/Flatpak fails in containers:**

Skip container-incompatible tags:

.. code-block:: bash

   ansible-playbook --skip-tags no-container,snap,flatpak playbook.yml

**Language servers not available after Neovim setup:**

On Ubuntu/Debian, language servers must be installed separately. See :doc:`../roles/install_neovim` for platform-specific instructions.

Debug Mode
~~~~~~~~~~

Run with verbose output:

.. code-block:: bash

   ansible-playbook -vvv playbook.yml

Check mode (dry run):

.. code-block:: bash

   ansible-playbook --check playbook.yml

Additional Resources
--------------------

**Documentation:**

- :doc:`../quickstart` - Quick start guide
- :doc:`../installation` - Installation guide
- :doc:`../roles/index` - Role documentation
- :doc:`../reference/index` - Technical reference

**Examples:**

- See ``examples/`` directory in collection for complete examples
- See individual role documentation for role-specific examples

**Support:**

- GitHub Issues: https://github.com/wolskies/infrastructure/issues
- Collection Repository: https://github.com/wolskies/infrastructure

Next Steps
----------

1. **Install the collection**: :doc:`../installation`
2. **Try the quick start**: :doc:`../quickstart`
3. **Explore role documentation**: :doc:`../roles/index`
4. **Configure your infrastructure**: :doc:`configuration`

.. toctree::
   :maxdepth: 2
   :caption: User Guide Topics

   configuration
   variables
   platform-support
