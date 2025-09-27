Go Role
=======

Install Go development toolchain and manage packages for individual users

* Installs Go compiler, built-in tools, and package management capabilities
* Configures user PATH to include Go binary directory
* Manages Go package installation using go install command
* Supports cross-platform installation on Debian/Ubuntu, Arch Linux, and macOS

.. contents::
   :local:
   :depth: 2

Overview
========

:Author: wolskies.infrastructure
:License: MIT
:Minimum Ansible Version: 2.12

This role provides install go development toolchain and manage packages for individual users.

Variables
=========

Role Variables
--------------

==================== =============== ========== =============== =======================================================================
Name                 Type            Required   Default         Description
==================== =============== ========== =============== =======================================================================
go_user              string          Yes        *(required)*    Target username for Go installation
go_packages          list[string]    No         ``[]``          Go package URLs to install (e.g., ["github.com/user/package@latest"])
==================== =============== ========== =============== =======================================================================


Formal Requirements
===================

This role implements the following formal requirements from the Software Requirements Document:

**REQ-GO-001**
   The system SHALL install Go development toolchain including compiler, built-in tools (go fmt, go test, go build), and package management capabilities for the specified user

**REQ-GO-002**
   The system SHALL install go packages for the specified user



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
       - wolskies.infrastructure.go

Example Playbook
----------------

.. code-block:: yaml

   - hosts: all
     become: true
     roles:
       - role: wolskies.infrastructure.go
         vars:
           # Add your variable overrides here

Testing
=======

This role includes comprehensive molecule tests. To run the tests:

.. code-block:: bash

   cd roles/go
   molecule test

License
=======

MIT

Author Information
==================

This role is maintained by wolskies.infrastructure.
