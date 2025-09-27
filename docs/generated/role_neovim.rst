Neovim Role
===========

Install and configure Neovim with plugin management and LSP support

* Installs Neovim and development dependencies across platforms
* Deploys comprehensive configuration with lazy.nvim plugin manager
* Configures LSP support for multiple languages (Lua, Rust, Python)
* Creates vim compatibility alias for seamless transition
* Provides batteries-included development-ready editor setup

.. contents::
   :local:
   :depth: 2

Overview
========

:Author: wolskies
:License: MIT
:Minimum Ansible Version: 2.15

This role provides install and configure neovim with plugin management and lsp support.

Variables
=========

Role Variables
--------------

======================= =============== ========== =============== ===============================================
Name                    Type            Required   Default         Description
======================= =============== ========== =============== ===============================================
neovim_user             string          Yes        *(required)*    Target username for Neovim installation
neovim_config_enabled   boolean         No         ``true``        Enable comprehensive configuration deployment
======================= =============== ========== =============== ===============================================


Formal Requirements
===================

This role implements the following formal requirements from the Software Requirements Document:

**REQ-NEOVIM-001**
   The system SHALL install Neovim and development dependencies for the specified user

**REQ-NEOVIM-002**
   The system SHALL deploy comprehensive Neovim configuration with plugin manager and LSP setup for the specified user

**REQ-NEOVIM-003**
   The system SHALL create vim compatibility alias for enhanced user experience



Platform Support
================

This role has been tested on the following platforms:

* **Ubuntu**: 22.04, 24.04
* **Debian**: 12, 13
* **ArchLinux**: any
* **MacOSX**: 10.15, 11, 12, 13, 14

Usage
=====

Basic Usage
-----------

Include this role in your playbook:

.. code-block:: yaml

   - hosts: all
     roles:
       - wolskies.infrastructure.neovim

Example Playbook
----------------

.. code-block:: yaml

   - hosts: all
     become: true
     roles:
       - role: wolskies.infrastructure.neovim
         vars:
           # Add your variable overrides here

Testing
=======

This role includes comprehensive molecule tests. To run the tests:

.. code-block:: bash

   cd roles/neovim
   molecule test

License
=======

MIT

Author Information
==================

This role is maintained by wolskies.
