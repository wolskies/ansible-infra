Manage Packages Role
====================

Manage packages across different operating systems and package managers

* Handles cross-platform package management (APT, Pacman, Homebrew)
* Supports layered package configuration (all → group → host)
* Manages APT repositories using deb822 format
* Provides AUR package support via paru helper on Arch Linux
* Manages Homebrew packages and casks on macOS
* Uses collection-wide variables for consistent package management

.. contents::
   :local:
   :depth: 2

Overview
========

:Author: wolskies.infrastructure
:License: MIT
:Minimum Ansible Version: 2.15

This role provides manage packages across different operating systems and package managers.

Variables
=========

Role Variables
--------------

======================== =============== ========== =============== =====================================================================================================
Name                     Type            Required   Default         Description
======================== =============== ========== =============== =====================================================================================================
apt                      object          No         ``{}``          APT package manager configuration options Controls repositories, upgrades, and system behavior
apt_repositories_all     object          No         ``{}``          Base-level APT repository definitions merged first Combined with group and host level repositories
apt_repositories_group   object          No         ``{}``          Group-level APT repository definitions merged second Combined with base and host level repositories
apt_repositories_host    object          No         ``{}``          Host-level APT repository definitions merged last Final layer in repository combination hierarchy
homebrew                 object          No         ``{}``          Homebrew package manager configuration options Controls taps and cache management
manage_casks             object          No         ``{}``          macOS Homebrew cask management configuration Platform-specific cask specifications
manage_packages_all      object          No         ``{}``          Base-level package definitions merged first Combined with group and host level packages
manage_packages_group    object          No         ``{}``          Group-level package definitions merged second Combined with base and host level packages
manage_packages_host     object          No         ``{}``          Host-level package definitions merged last Final layer in package combination hierarchy
packages                 object          No         ``{}``          Base package management definitions Combined with layered variables for final package list
pacman                   object          No         ``{}``          Pacman package manager configuration options Controls AUR support and package management behavior
======================== =============== ========== =============== =====================================================================================================


Formal Requirements
===================

This role implements the following formal requirements from the Software Requirements Document:

**REQ-MP-001**
   The manage_packages role SHALL combine packages from different inventory levels before processing for all package managers (apt, pacman/AUR, homebrew)

**REQ-MP-002**
   The manage_packages role SHALL combine APT repositories from different inventory levels before processing repository management tasks

**REQ-MP-003**
   The system SHALL be capable of managing APT repositories using deb822 format

**REQ-MP-004**
   (MERGED INTO REQ-MP-003): ~~The system SHALL ensure APT repository dependencies are present whenever managing repositories

**REQ-MP-005**
   (DELETED): ~~The system SHALL update the APT cache before attempting to install packages

**REQ-MP-006**
   The system SHALL be capable of managing packages via APT

**REQ-MP-007**
   (MERGED INTO REQ-MP-006): ~~The system SHALL be capable of installing packages via APT

**REQ-MP-008**
   The system SHALL be capable of performing system upgrades via APT

**REQ-MP-009**
   (DELETED): ~~The system SHALL be capable of updating Pacman package cache

**REQ-MP-010**
   (MERGED INTO REQ-MP-009a): ~~The system SHALL be capable of removing packages via Pacman

**REQ-MP-011**
   The system SHALL be capable of upgrading all Pacman packages

**REQ-MP-012**
   The system SHALL be capable of disabling AUR package installation

**REQ-MP-013**
   The system SHALL be capable of managing AUR packages when enabled

**REQ-MP-014**
   The system SHALL be capable of managing Homebrew packages and casks

**REQ-MP-015**
   The system SHALL be capable of managing Homebrew taps



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
       - wolskies.infrastructure.manage_packages

Example Playbook
----------------

.. code-block:: yaml

   - hosts: all
     become: true
     roles:
       - role: wolskies.infrastructure.manage_packages
         vars:
           # Add your variable overrides here

Testing
=======

This role includes comprehensive molecule tests. To run the tests:

.. code-block:: bash

   cd roles/manage_packages
   molecule test

License
=======

MIT

Author Information
==================

This role is maintained by wolskies.infrastructure.
