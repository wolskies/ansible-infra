wolskies.infrastructure Collection
===================================

A comprehensive Ansible collection for system configuration and user environment management across Linux and macOS platforms.

.. image:: https://img.shields.io/badge/License-MIT-blue.svg
   :target: LICENSE
   :alt: License: MIT

.. image:: https://img.shields.io/badge/Ansible-2.12+-green.svg
   :target: https://docs.ansible.com/
   :alt: Ansible Version

Overview
--------

The ``wolskies.infrastructure`` collection provides a complete solution for:

* **System Configuration**: Hostname, timezone, locale, NTP, systemd services, and OS-specific settings
* **Package Management**: Multi-platform package installation (APT, Pacman, Homebrew) with repository management
* **Security Services**: Firewall (UFW/ALF) and intrusion prevention (fail2ban) configuration
* **User Environments**: Development tool installation (Node.js, Rust, Go), terminal configuration, and dotfiles
* **Application Packaging**: Flatpak and Snap package system management

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
   roles/configure_users
   roles/manage_packages
   roles/os_configuration
   roles/manage_security_services
   roles/manage_flatpak
   roles/manage_snap_packages
   roles/nodejs
   roles/rust
   roles/go
   roles/neovim
   roles/terminal_config

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
