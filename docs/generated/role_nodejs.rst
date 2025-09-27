Nodejs Role
===========

Install Node.js runtime and manage npm packages for individual users

* Installs Node.js system-wide from NodeSource repositories (Debian/Ubuntu)
* Installs Node.js from official repositories (Arch Linux, macOS)
* Manages npm packages in user-local directories to avoid permission issues
* Supports both simple string and object format for package specifications
* Configures user PATH to include npm global directory

.. contents::
   :local:
   :depth: 2

Overview
========

:Author: wolskies.infrastructure
:License: MIT
:Minimum Ansible Version: 2.12

This role provides install node.js runtime and manage npm packages for individual users.

Variables
=========

Role Variables
--------------

======================== =============== ========== =================== =========================================================================================================================
Name                     Type            Required   Default             Description
======================== =============== ========== =================== =========================================================================================================================
node_user                string          Yes        *(required)*        Target username for npm package installation
node_packages            list[raw]       No         ``[]``              npm packages to install for the specified user Supports both string format and object format with version specification
nodejs_version           string          No         ``20``              Major version of Node.js to install (Debian/Ubuntu only, from NodeSource)
npm_config_prefix        string          No         ``~/.npm-global``   Directory for npm global installations (user-specific)
npm_config_unsafe_perm   string          No         ``true``            Whether to suppress UID/GID switching when running package scripts
======================== =============== ========== =================== =========================================================================================================================


Formal Requirements
===================

This role implements the following formal requirements from the Software Requirements Document:

**REQ-NODE-001**
   The system SHALL install Node.js runtime and npm package manager system-wide

**REQ-NODE-002**
   The system SHALL install npm packages in user-local directories for the specified user



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
       - wolskies.infrastructure.nodejs

Example Playbook
----------------

.. code-block:: yaml

   - hosts: all
     become: true
     roles:
       - role: wolskies.infrastructure.nodejs
         vars:
           # Add your variable overrides here

Testing
=======

This role includes comprehensive molecule tests. To run the tests:

.. code-block:: bash

   cd roles/nodejs
   molecule test

License
=======

MIT

Author Information
==================

This role is maintained by wolskies.infrastructure.
