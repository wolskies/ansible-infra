Os Configuration Role
=====================

OS configuration management role

Handles fundamental operating system configuration including hostname, timezone,
locale, NTP, systemd services/modules, journal, security hardening, and OS-specific
configurations.


.. contents::
   :local:
   :depth: 2

Overview
========

:Author: wolskies.infrastructure
:License: MIT
:Minimum Ansible Version: 2.15

This role provides os configuration management role.

Variables
=========

Role Variables
--------------

==================== =============== ========== ================== ===================================================================================
Name                 Type            Required   Default            Description
==================== =============== ========== ================== ===================================================================================
apt                  object          No         ``{}``             APT package manager configuration
domain_language      string          No         ``en_US.UTF-8``    System language (locale format, e.g., "en_US.UTF-8", "de_DE.UTF-8")
domain_locale        string          No         ``en_US.UTF-8``    System locale (format: language_COUNTRY.encoding, e.g., en_US.UTF-8, fr_FR.UTF-8)
domain_name          string          No         *(empty string)*   Organization domain name (RFC 1035 format, e.g., "example.com")
domain_timesync      object          No         ``{}``             Time synchronization configuration via systemd-timesyncd
domain_timezone      string          No         *(empty string)*   System timezone (IANA format, e.g., "America/New_York", "Europe/London")
hardening            object          No         ``{}``             Security hardening configuration
host_hostname        string          No         *(empty string)*   System hostname (RFC 1123 format, alphanumeric + hyphens, max 253 chars)
host_modules         object          No         ``{}``             Kernel module management configuration
host_services        object          No         ``{}``             Systemd service management configuration
host_udev_rules      list[object]    No         ``[]``             Custom udev rules definitions
host_update_hosts    boolean         No         ``true``           Update /etc/hosts with hostname entry
journal              object          No         ``{}``             Systemd journal configuration management
macosx               object          No         ``{}``             macOS system configuration
pacman               object          No         ``{}``             Pacman package manager configuration
==================== =============== ========== ================== ===================================================================================


Formal Requirements
===================

This role implements the following formal requirements from the Software Requirements Document:

**REQ-OS-001**
   The system SHALL be capable of setting the system hostname

**REQ-OS-002**
   The system SHALL be capable of updating the ``/etc/hosts`` file with hostname entries

**REQ-OS-003**
   The system SHALL be capable of setting the system timezone

**REQ-OS-004**
   The system SHALL be capable of applying OS security hardening on Linux systems

**REQ-OS-005**
   The system SHALL be capable of applying SSH security hardening on Linux systems

**REQ-OS-006**
   The system SHALL be capable of setting the system locale on Linux systems

**REQ-OS-007**
   DELETED - Merged into REQ-OS-006 (locale and language are part of same locale configuration)

**REQ-OS-008**
   The system SHALL be capable of configuring basic time synchronization on Linux systems

**REQ-OS-009**
   The system SHALL be capable of configuring systemd journal settings on Linux systems

**REQ-OS-010**
   DELETED - Remote logging capabilities moved to dedicated logging role (future work)

**REQ-OS-011**
   The system SHALL be capable of controlling systemd units (services, timers, and so on) on Linux systems

**REQ-OS-012**
   DELETED - Consolidated into REQ-OS-011 (systemd unit control)

**REQ-OS-013**
   DELETED - Consolidated into REQ-OS-011 (systemd unit control)

**REQ-OS-014**
   The system SHALL be capable of managing kernel modules on Linux systems

**REQ-OS-015**
   DELETED - Consolidated into REQ-OS-014 (kernel module management)

**REQ-OS-016**
   The system SHALL be capable of deploying custom udev rules on Linux systems

**REQ-OS-017**
   The system SHALL be capable of configuring APT proxy on Debian/Ubuntu systems

**REQ-OS-018**
   The system SHALL be capable of configuring APT unattended upgrades on Debian/Ubuntu systems

**REQ-OS-021**
   The system SHALL be capable of configuring Pacman proxy on Arch Linux systems

**REQ-OS-022**
   The system SHALL be capable of setting the system locale on macOS systems

**REQ-OS-023**
   The system SHALL be capable of setting the system language on macOS systems

**REQ-OS-024**
   The system SHALL be capable of configuring time synchronization time synchronization on macOS systems

**REQ-OS-025**
   The system SHALL be capable of configuring macOS automatic updates

**REQ-OS-026**
   The system SHALL be capable of configuring macOS Gatekeeper security

**REQ-OS-027**
   The system SHALL be capable of configuring macOS system preferences

**REQ-OS-028**
   The system SHALL be capable of configuring AirDrop over Ethernet



Platform Support
================

This role has been tested on the following platforms:

* **Ubuntu**: 24.04
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
       - wolskies.infrastructure.os_configuration

Example Playbook
----------------

.. code-block:: yaml

   - hosts: all
     become: true
     roles:
       - role: wolskies.infrastructure.os_configuration
         vars:
           # Add your variable overrides here

Testing
=======

This role includes comprehensive molecule tests. To run the tests:

.. code-block:: bash

   cd roles/os_configuration
   molecule test

License
=======

MIT

Author Information
==================

This role is maintained by wolskies.infrastructure.
