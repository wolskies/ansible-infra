Rust Role
=========

Install Rust toolchain and manage cargo packages for individual users

* Installs rustup toolchain manager for complete Rust development environment
* Supports Debian 13+, Ubuntu 24+, Arch Linux, and macOS only
* Initializes stable toolchain and configures user PATH
* Manages cargo package installation in user space
* Fails with clear error on unsupported platforms

.. contents::
   :local:
   :depth: 2

Overview
========

:Author: wolskies.infrastructure
:License: MIT
:Minimum Ansible Version: 2.12

This role provides install rust toolchain and manage cargo packages for individual users.

Variables
=========

Role Variables
--------------

==================== =============== ========== =============== ===============================================================
Name                 Type            Required   Default         Description
==================== =============== ========== =============== ===============================================================
rust_user            string          Yes        *(required)*    Target username for Rust installation
rust_packages        list[string]    No         ``[]``          Cargo package names to install (e.g., ["ripgrep", "fd-find"])
==================== =============== ========== =============== ===============================================================


Formal Requirements
===================

This role implements the following formal requirements from the Software Requirements Document:

**REQ-RUST-001**
   The system SHALL install rustup toolchain manager for the specified user to enable Rust development with multiple toolchain versions and cross-compilation capabilities

**REQ-RUST-002**
   The system SHALL install cargo packages for the specified user



Platform Support
================

This role has been tested on the following platforms:

* **Ubuntu**: 22.04, 24.04
* **Debian**: 12, 13
* **ArchLinux**: all
* **MacOSX**: all

Usage
=====

Basic Usage
-----------

Include this role in your playbook:

.. code-block:: yaml

   - hosts: all
     roles:
       - wolskies.infrastructure.rust

Example Playbook
----------------

.. code-block:: yaml

   - hosts: all
     become: true
     roles:
       - role: wolskies.infrastructure.rust
         vars:
           # Add your variable overrides here

Testing
=======

This role includes comprehensive molecule tests. To run the tests:

.. code-block:: bash

   cd roles/rust
   molecule test

License
=======

MIT

Author Information
==================

This role is maintained by wolskies.infrastructure.
