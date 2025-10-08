Configure Users Role
====================

Configure user preferences and development environments

* Configures user preferences for existing users
* Orchestrates development environment setup via collection roles
* Configures platform-specific preferences (macOS dock, finder, etc.)
* Deploys dotfiles using GNU stow when configured

.. contents::
   :local:
   :depth: 2

Overview
========

:Author: wolskies.infrastructure
:License: MIT
:Minimum Ansible Version: 2.12

This role provides configure user preferences and development environments.

Variables
=========

Role Variables
--------------

==================== =============== ========== =============== ==============================================================================================================================
Name                 Type            Required   Default         Description
==================== =============== ========== =============== ==============================================================================================================================
users                list[object]    No         ``[]``          List of user preference configuration objects Configures development tools, git settings, dotfiles, and platform preferences
==================== =============== ========== =============== ==============================================================================================================================


Formal Requirements
===================

This role implements the following formal requirements from the Software Requirements Document:

**REQ-CU-001**
   The system SHALL create and configure user accounts using ansible.builtin.user

**REQ-CU-002**
   The system SHALL remove user accounts when state is absent

**REQ-CU-003**
   The system SHALL manage platform-appropriate admin group assignments with security filtering

**REQ-CU-004**
   The system SHALL grant cross-platform sudo access through platform admin group membership

**REQ-CU-005**
   The system SHALL support passwordless sudo configuration for superusers

**REQ-CU-006**
   The system SHALL be capable of managing SSH authorized keys for users

**REQ-CU-007**
   The system SHALL configure Node.js development environment for users

**REQ-CU-008**
   The system SHALL configure Rust development environment for users

**REQ-CU-009**
   The system SHALL configure Go development environment for users

**REQ-CU-010**
   The system SHALL configure Neovim for users

**REQ-CU-011**
   The system SHALL configure terminal emulators for users

**REQ-CU-012**
   The system SHALL be capable of configuring Git settings for users

**REQ-CU-019**
   The system SHALL deploy user dotfiles using GNU stow

**REQ-CU-013**
   The system SHALL be capable of setting user shell preferences on Linux systems

**REQ-CU-014**
   The system SHALL configure Homebrew PATH for macOS users

**REQ-CU-015**
   The system SHALL configure Dock preferences for macOS users

**REQ-CU-016**
   The system SHALL configure Finder preferences for macOS users

**REQ-CU-017**
   The system SHALL configure screenshot preferences for macOS users

**REQ-CU-018**
   The system SHALL configure iTerm2 preferences for macOS users



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
       - wolskies.infrastructure.configure_users

Example Playbook
----------------

.. code-block:: yaml

   - hosts: all
     become: true
     roles:
       - role: wolskies.infrastructure.configure_users
         vars:
           # Add your variable overrides here

Testing
=======

This role includes comprehensive molecule tests. To run the tests:

.. code-block:: bash

   cd roles/configure_users
   molecule test

License
=======

MIT

Author Information
==================

This role is maintained by wolskies.infrastructure.
