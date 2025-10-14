wolskies.infrastructure Collection
===================================

An Ansible collection for system configuration and user environment management across Linux and macOS platforms.

.. image:: https://img.shields.io/badge/License-MIT-blue.svg
   :target: LICENSE
   :alt: License: MIT

.. image:: https://img.shields.io/badge/Ansible-2.12+-green.svg
   :target: https://docs.ansible.com/
   :alt: Ansible Version

Overview
--------

The ``wolskies.infrastructure`` collection follows the **System → Software → Users** pattern for infrastructure setup:

* **Phase 1 - Operating System**: Configure OS-level settings (hostname, timezone, locale, NTP, systemd services, kernel modules, firewall, fail2ban, package manager configuration)
* **Phase 2 - Software**: Manage software packages across APT, Pacman, Homebrew, Snap, and Flatpak with hierarchical configuration
* **Phase 3 - Users**: Configure user preferences and development environments (Git, Node.js, Rust, Go, Neovim, dotfiles, terminal configuration)

**Key Roles:**

* ``system_setup`` - Meta-role demonstrating the complete System → Software → Users pattern
* ``configure_operating_system`` - OS-level configuration (Phase 1)
* ``configure_software`` - Package management across all package managers (Phase 2)
* ``configure_users`` - User preferences and development environments (Phase 3)
* ``install_*`` utility roles - Targeted installation of specific tools (nodejs, rust, go, neovim, terminfo)

**Supported Platforms:**

* Ubuntu 22.04+, 24.04+ - fully tested
* Debian 12+, 13+ - fully tested
* Arch Linux (Rolling) - fully tested
* macOS 13+ (Ventura) - limited testing (see :doc:`user-guide/platform-support`)

Quick Links
-----------

* :doc:`installation` - Get started with installation
* :doc:`quickstart` - 5-minute quick start guide
* :doc:`roles/index` - Browse available roles
* :doc:`testing/index` - Testing documentation
* :doc:`reference/index` - Technical reference

Table of Contents
-----------------

.. toctree::
   :maxdepth: 2
   :caption: Getting Started

   installation
   quickstart

.. toctree::
   :maxdepth: 2
   :caption: User Guide

   user-guide/index
   user-guide/configuration
   user-guide/variables
   user-guide/platform-support

.. toctree::
   :maxdepth: 2
   :caption: Roles

   roles/index
   roles/system_setup
   roles/configure_operating_system
   roles/configure_software
   roles/configure_users
   roles/install_nodejs
   roles/install_rust
   roles/install_go
   roles/install_neovim
   roles/install_terminfo

.. toctree::
   :maxdepth: 2
   :caption: Testing

   testing/index
   testing/running-tests
   testing/molecule-architecture
   testing/vm-testing
   testing/writing-tests

.. toctree::
   :maxdepth: 2
   :caption: Development

   development/index
   development/contributing
   development/workflow
   development/tdd-process

.. toctree::
   :maxdepth: 2
   :caption: Reference

   reference/index
   reference/requirements
   reference/variables-reference

Indices and Search
------------------

* :ref:`genindex`
* :ref:`search`

License
-------

MIT License - see LICENSE file for details.

Authors
-------

wolskies infrastructure team

Contributing
------------

See :doc:`development/contributing` for contribution guidelines.

Support
-------

* **Issues**: https://gitlab.wolskinet.com/ansible/collections/infrastructure/-/issues
* **Repository**: https://gitlab.wolskinet.com/ansible/collections/infrastructure
