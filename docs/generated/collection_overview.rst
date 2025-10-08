wolskies.infrastructure Ansible Collection
==========================================

A comprehensive infrastructure management collection for cross-platform development and production environments.

.. contents:: Contents
   :depth: 3
   :local:

1. Collection Overview
======================

1.1 Purpose
-----------

The ``wolskies.infrastructure`` collection provides infrastructure management automation for cross-platform development and production environments. The collection focuses on configuration management, security hardening, and development environment setup.

1.2 Target Users
----------------

- **Primary**: Moderately experienced system administrators and DevOps engineers
- **Secondary**: Development teams requiring consistent environment setup
- **Design Philosophy**: No excessive warnings or defensive programming; users are expected to understand basic system administration concepts

1.3 Scope
---------

- **In Scope**: OS configuration, package management, user management, security services, development environment setup
- **Out of Scope**: Application deployment, database administration, network infrastructure management

---

2. Collection-Wide Requirements
===============================

2.1 Supported Platforms
-----------------------

2.1.1 Operating Systems
~~~~~~~~~~~~~~~~~~~~~~~

**REQ-INFRA-001**: The collection SHALL support the following operating systems:

| Platform   | Versions       | OS Family | Architecture |
| ---------- | -------------- | --------- | ------------ |
| Ubuntu     | 22.04+, 24.04+ | Debian    | amd64        |
| Debian     | 12+, 13+       | Debian    | amd64        |
| Arch Linux | Rolling        | Archlinux | amd64        |
| macOS      | 13+ (Ventura)  | Darwin    | amd64, arm64 |

2.1.2 Software Environment
~~~~~~~~~~~~~~~~~~~~~~~~~~

**Standards - Tested Software Versions**
The collection is developed and tested with:

- Ansible 2.17 (current stable)
- Python 3.11+ on control and managed nodes
- OpenSSH 8.4+ for remote management

**Standards - Expected Compatibility**
While not explicitly tested, the collection should work with:

- Ansible 2.15+ (uses no features newer than 2.15)
- Python 3.9+ (uses no features newer than 3.9)
- OpenSSH 8.0+ (uses standard SSH features)

2.2 Variable Standards
----------------------

**Standards - Variable Precedence**
Standard Ansible 2.15+ variable precedence rules apply to all collection variables.

**Standards - Naming Conventions**

- **``domain_`` prefix**: Variables typically applied at organizational/domain scope (e.g., ``domain_timezone``)
- **``host_`` prefix**: Variables that typically vary per host (e.g., ``host_hostname``)
- **Role-specific variables**: No prefix, scoped to role context (e.g., ``users``, ``packages``)
- **Boolean variables**: Use ``true``/``false``, never ``yes``/``no`` or ``1``/``0``

**Standards - Configuration Management Behavior**

Collection variables follow standard Ansible configuration patterns:

- **Variable defined/non-empty**: Feature is configured/enabled, configuration files are created/updated
- **Variable undefined/empty**: Feature is left in current state (not modified)
- **Explicit removal**: Use role-specific removal mechanisms when cleanup is needed
- **Additive behavior**: Most features add to existing configuration rather than replacing it

This follows established Ansible conventions and prevents accidental removal of existing configurations.

**Standards - Variable Structure and Layering**

This collection uses standard Ansible variable precedence (host_vars > group_vars > role defaults) for configuration. Where layered configuration is needed (such as package management), roles implement explicit merging using the ``combine`` filter to ensure predictable, portable behavior.

For complex merging scenarios, roles use the ``combine`` filter with appropriate list merge strategies:

Roles Overview
==============

The collection provides the following roles for infrastructure management:

Core System Configuration
--------------------------

* **os_configuration** - Base OS configuration (timezone, locale, firewall, repositories)
* **manage_packages** - Cross-platform package management (APT, Pacman/AUR, Homebrew)
* **manage_security_services** - Security services (UFW, fail2ban, macOS firewall)
* **manage_snap_packages** - Snap package management and removal
* **manage_flatpak** - Flatpak package management

User Environment Setup
-----------------------

* **configure_user** - Complete user account and environment configuration
* **terminal_config** - Modern terminal emulator support (Alacritty, Kitty, WezTerm)

Development Environments
-------------------------

* **nodejs** - Node.js runtime and npm package management
* **rust** - Rust toolchain and cargo package management
* **go** - Go development environment and package management
* **neovim** - Neovim installation and comprehensive configuration

Each role provides comprehensive documentation with formal requirements, platform support matrices, and usage examples.

4. Known Issues and Limitations
===============================

4.1 Current Known Issues
------------------------

4.1.1 User Management Dependencies
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- **Issue**: Users with package-dependent groups (e.g., ``docker``) fail when groups don't exist yet
- **Impact**: User creation fails in ``os_configuration`` when packages haven't been installed
- **Workaround**: Remove package-dependent groups from user definitions
- **Resolution**: Moving user management to ``configure_users`` role (v1.2.0)

4.1.2 External Repository Management
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- **Issue**: External repositories (Docker CE, NodeJS) fail due to timing and GPG key management
- **Impact**: Package installation failures for non-distribution packages
- **Workaround**: Use distribution packages instead of external repositories
- **Resolution**: Implement proper repository management in v1.2.0

4.1.3 Validation Logic
~~~~~~~~~~~~~~~~~~~~~~

- **Issue**: User validation reads discovery output instead of configuration input
- **Impact**: Validation reports wrong users as missing/present
- **Workaround**: Manual verification of user creation
- **Resolution**: Refactor validation to preserve input configuration variables

4.2 Platform-Specific Limitations
---------------------------------

4.2.1 Container Testing
~~~~~~~~~~~~~~~~~~~~~~~

- Hostname changes not supported in containers (use ``skip-tags: hostname``)
- Systemd service management limited in containers
- Firewall configuration not testable in containers

4.2.2 macOS Limitations
~~~~~~~~~~~~~~~~~~~~~~~

- Requires elevated privileges for system configuration
- Some Linux-specific modules not available
- Package management differs significantly from Linux

4.2.3 Arch Linux Considerations
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- Firewall/iptables kernel modules may be missing in cloud images
- AUR package support requires special handling
- Rolling release model requires flexible version handling
- **Testing Status**: REQ-OS-021/021a/021b tests written but awaiting Arch Linux container implementation
- **Required Containers**: arch-full-positive, arch-partial-enabled, arch-negative-empty, arch-edge-cases for complete Pacman testing

---

5. Future Requirements
======================

5.2 Long-term Requirements
--------------------------

5.2.1 Platform Expansion
~~~~~~~~~~~~~~~~~~~~~~~~

- Move services enable/disable to package management
- Nerd Fonts functionality moved to configure_users role or dedicated role (removed from os_configuration due to role boundary violation - fonts are user preferences, not system configuration, and implementation was platform-specific stopgap)
- Configuration of time synchronization server

- Configuration of Remote logging (rsyslog)
- Additional Linux distributions (RHEL, CentOS Stream, Fedora)
- Container platform support (Docker, Podman configuration)

5.2.2 Advanced Features
~~~~~~~~~~~~~~~~~~~~~~~

- Configuration templating and environments
- Secrets management integration
- Infrastructure as Code integration (Terraform, CloudFormation)

---

Getting Started
===============

Installation
------------

Install the collection using ansible-galaxy:

.. code-block:: bash

   ansible-galaxy collection install wolskies.infrastructure

Basic Usage
-----------

Use roles individually in your playbooks:

.. code-block:: yaml

   - hosts: all
     become: true
     roles:
       - wolskies.infrastructure.os_configuration
       - wolskies.infrastructure.manage_packages
       - wolskies.infrastructure.configure_user

Or use the comprehensive configure_system playbook:

.. code-block:: yaml

   - hosts: all
     become: true
     tasks:
       - include_role:
           name: wolskies.infrastructure.configure_system
         vars:
           # Your configuration variables

Platform Support
=================

The collection supports:

* **Ubuntu** 22.04+ and 24.04+
* **Debian** 12+ and 13+
* **Arch Linux** (rolling release)
* **macOS** 13+ (Ventura) on amd64 and arm64

Requirements
------------

* Ansible 2.15+
* Python 3.9+ on control and managed nodes
* OpenSSH 8.0+ for remote management

Testing
=======

The collection includes comprehensive testing with:

* **Molecule** for role-level testing with Docker containers
* **CI/CD pipeline** with parallel testing across platforms
* **Integration tests** for role interactions
* **Platform-specific validation** for OS differences

Run tests locally:

.. code-block:: bash

   # Test individual roles
   cd roles/nodejs && molecule test

   # Test integration
   molecule test -s test-integration

Contributing
============

See the collection repository for contribution guidelines, development setup, and testing procedures.

License
=======

MIT

Author Information
==================

This collection is maintained by the wolskies infrastructure team.
