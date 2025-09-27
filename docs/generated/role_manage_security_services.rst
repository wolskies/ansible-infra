Manage Security Services Role
=============================

Configure firewall and intrusion prevention services

* Handles firewall configuration on Linux (UFW) and macOS (Application Layer Firewall)
* Manages intrusion prevention services (fail2ban on Linux)
* Automatically detects and protects SSH access during firewall operations
* Configures firewall rules, stealth mode, and logging options
* Uses collection-wide variables for consistent security configuration

.. contents::
   :local:
   :depth: 2

Overview
========

:Author: wolskies.infrastructure
:License: MIT
:Minimum Ansible Version: 2.12

This role provides configure firewall and intrusion prevention services.

Variables
=========

Role Variables
--------------

==================== =============== ========== =============== =============================================================================================================
Name                 Type            Required   Default         Description
==================== =============== ========== =============== =============================================================================================================
fail2ban             object          No         ``{}``          Fail2ban intrusion prevention configuration Linux-only service for protecting against brute force attacks
firewall             object          No         ``{}``          Firewall configuration and management options Controls UFW on Linux and Application Layer Firewall on macOS
==================== =============== ========== =============== =============================================================================================================


Formal Requirements
===================

This role implements the following formal requirements from the Software Requirements Document:

**REQ-SS-001**
   The system SHALL be capable of installing and configuring UFW firewall package on Linux systems

**REQ-SS-002**
   The system SHALL automatically detect and protect SSH access during firewall operations

**REQ-SS-004**
   The system SHALL be capable of enabling or disabling UFW firewall service based on configuration

**REQ-SS-005**
   The system SHALL be capable of installing fail2ban on Linux systems

**REQ-SS-006**
   The system SHALL be capable of configuring fail2ban jails on Linux systems

**REQ-SS-007**
   The system SHALL be capable of managing fail2ban service state on Linux systems

**REQ-SS-008**
   The system SHALL be capable of checking firewall state on macOS systems

**REQ-SS-009**
   The system SHALL be capable of enabling/disabling Application Layer Firewall on macOS systems

**REQ-SS-010**
   The system SHALL be capable of configuring stealth mode on macOS systems

**REQ-SS-011**
   The system SHALL be capable of configuring block all setting on macOS systems

**REQ-SS-012**
   The system SHALL be capable of configuring firewall logging on macOS systems



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
       - wolskies.infrastructure.manage_security_services

Example Playbook
----------------

.. code-block:: yaml

   - hosts: all
     become: true
     roles:
       - role: wolskies.infrastructure.manage_security_services
         vars:
           # Add your variable overrides here

Testing
=======

This role includes comprehensive molecule tests. To run the tests:

.. code-block:: bash

   cd roles/manage_security_services
   molecule test

License
=======

MIT

Author Information
==================

This role is maintained by wolskies.infrastructure.
