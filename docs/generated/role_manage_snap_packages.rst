Manage Snap Packages Role
=========================

Manage snapd system and snap packages on Debian/Ubuntu systems

* Manages snap package system installation and complete removal
* Handles individual snap package installation and removal
* Supports classic confinement and channel specification
* Prevents snap system reinstallation after removal
* Uses collection-wide variables for consistent snap management

.. contents::
   :local:
   :depth: 2

Overview
========

:Author: wolskies.infrastructure
:License: MIT
:Minimum Ansible Version: 2.15

This role provides manage snapd system and snap packages on debian/ubuntu systems.

Variables
=========

Role Variables
--------------

==================== =============== ========== =============== =================================================================================================================
Name                 Type            Required   Default         Description
==================== =============== ========== =============== =================================================================================================================
snap                 object          No         ``{}``          Snap package system configuration options Controls complete system removal and package management
snap_packages        list[object]    No         ``[]``          List of snap package definitions to install or remove Each package can specify state, classic mode, and channel
==================== =============== ========== =============== =================================================================================================================


Formal Requirements
===================

This role implements the following formal requirements from the Software Requirements Document:

**REQ-MSP-001**
   The system SHALL be capable of completely removing the snap package system from Debian/Ubuntu systems

**REQ-MSP-002**
   The system SHALL prevent snap packages from being reinstalled after removal

**REQ-MSP-003**
   The system SHALL be capable of managing individual snap packages when snap system is enabled



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
       - wolskies.infrastructure.manage_snap_packages

Example Playbook
----------------

.. code-block:: yaml

   - hosts: all
     become: true
     roles:
       - role: wolskies.infrastructure.manage_snap_packages
         vars:
           # Add your variable overrides here

Testing
=======

This role includes comprehensive molecule tests. To run the tests:

.. code-block:: bash

   cd roles/manage_snap_packages
   molecule test

License
=======

MIT

Author Information
==================

This role is maintained by wolskies.infrastructure.
