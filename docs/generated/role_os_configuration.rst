Os Configuration Role
=====================

Configure fundamental operating system settings

* Handles cross-platform system configuration including hostname, timezone, locale, and security
* Manages Linux-specific features like systemd services, kernel modules, udev rules, and NTP
* Applies security hardening via devsec.hardening roles when enabled
* Configures macOS system preferences and automatic updates
* Uses collection-wide variables for consistent configuration across roles

.. contents::
   :local:
   :depth: 2

Overview
========

:Author: wolskies.infrastructure
:License: MIT
:Minimum Ansible Version: 2.15

This role provides configure fundamental operating system settings.

Variables
=========

Role Variables
--------------

==================== =============== ========== ================== =============================================================================================================================================================================
Name                 Type            Required   Default            Description
==================== =============== ========== ================== =============================================================================================================================================================================
apt                  object          No         ``{}``             APT package manager configuration options Controls proxy, recommends, and unattended upgrades
domain_language      string          No         ``en_US.UTF-8``    System language setting (same format as locale) Used for system language configuration
domain_locale        string          No         ``en_US.UTF-8``    System locale in language_COUNTRY.encoding format Used for locale generation on Linux systems
domain_name          string          No         *(empty string)*   Organization domain name used in /etc/hosts entries Required when host_update_hosts is true Must be RFC 1035 compliant format
domain_ntp           object          No         ``{}``             Network time synchronization configuration Configures systemd-timesyncd for basic SNTP client functionality
domain_timezone      string          No         *(empty string)*   System timezone in IANA format When defined and non-empty, system timezone will be configured
host_hostname        string          No         *(empty string)*   System hostname to set Must be RFC 1123 compliant (alphanumeric + hyphens, max 253 chars) When defined and non-empty, hostname will be configured
host_modules         object          No         ``{}``             Kernel module management configuration Controls loading and blacklisting of kernel modules
host_security        object          No         ``{}``             Security hardening configuration options Used to control devsec.hardening role behavior
host_services        object          No         ``{}``             Systemd service management configuration Controls enable/disable/mask operations for systemd units
host_sysctl          object          No         ``{}``             Kernel parameter configuration via sysctl Used by security hardening and custom kernel parameter management
host_udev            object          No         ``{}``             Custom udev rules configuration Manages deployment and removal of udev rules
host_update_hosts    boolean         No         ``true``           Whether to update /etc/hosts with hostname entry Requires both host_hostname and domain_name to be defined Entry format: 127.0.0.1 localhost {hostname}.{domain} {hostname}
journal              object          No         ``{}``             Systemd journal configuration options Controls journal settings via configuration file
macosx               object          No         ``{}``             macOS-specific system configuration options Controls automatic updates, gatekeeper, and system preferences
pacman               object          No         ``{}``             Pacman package manager configuration options Controls proxy, no-confirm, and multilib repository
==================== =============== ========== ================== =============================================================================================================================================================================


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
   The system SHALL be capable of configuring NTP time synchronization on macOS systems

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
