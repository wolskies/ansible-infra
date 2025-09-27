Manage Flatpak Role
===================

Manage flatpak packages and desktop integration on Linux systems

* Installs flatpak runtime on Debian and Arch Linux systems
* Manages desktop environment flatpak plugins (GNOME, Plasma)
* Enables Flathub repository when configured
* Handles individual flatpak package installation and removal
* Uses collection-wide variables for consistent flatpak management

.. contents::
   :local:
   :depth: 2

Overview
========

:Author: wolskies.infrastructure
:License: MIT
:Minimum Ansible Version: 2.13

This role provides manage flatpak packages and desktop integration on linux systems.

Variables
=========

Role Variables
--------------

==================== =============== ========== =============== ==============================================================================================================
Name                 Type            Required   Default         Description
==================== =============== ========== =============== ==============================================================================================================
flatpak              object          No         ``{}``          Flatpak package management configuration options Controls flatpak system installation and package management
flatpak_packages     list[object]    No         ``[]``          List of flatpak package definitions to install or remove Each package can specify name and state
==================== =============== ========== =============== ==============================================================================================================


Formal Requirements
===================

This role implements the following formal requirements from the Software Requirements Document:

**REQ-MF-001**
   The system SHALL install flatpak runtime on Debian and Arch Linux systems when enabled

**REQ-MF-002**
   The system SHALL install desktop environment flatpak plugins when configured (Debian/Ubuntu only)

**REQ-MF-003**
   The system SHALL enable Flathub repository when configured

**REQ-MF-004**
   The system SHALL be capable of managing individual flatpak packages when flatpak system is enabled



Platform Support
================

This role has been tested on the following platforms:

* **Ubuntu**: 22.04, 24.04
* **Debian**: 12, 13

Usage
=====

Basic Usage
-----------

Include this role in your playbook:

.. code-block:: yaml

   - hosts: all
     roles:
       - wolskies.infrastructure.manage_flatpak

Example Playbook
----------------

.. code-block:: yaml

   - hosts: all
     become: true
     roles:
       - role: wolskies.infrastructure.manage_flatpak
         vars:
           # Add your variable overrides here

Testing
=======

This role includes comprehensive molecule tests. To run the tests:

.. code-block:: bash

   cd roles/manage_flatpak
   molecule test

License
=======

MIT

Author Information
==================

This role is maintained by wolskies.infrastructure.
