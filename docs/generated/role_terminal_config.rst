Terminal Config Role
====================

Configure terminfo entries for modern terminal emulators

* Downloads and compiles terminfo entries for modern terminals like Alacritty, Kitty, and WezTerm
* Installs terminfo in user-specific ~/.terminfo directory
* Enables proper terminal capabilities and rendering for modern terminal emulators
* Prevents "unknown terminal type" errors when using modern terminals

.. contents::
   :local:
   :depth: 2

Overview
========

:Author: wolskies
:License: MIT
:Minimum Ansible Version: 2.15

This role provides configure terminfo entries for modern terminal emulators.

Variables
=========

Role Variables
--------------

==================== =============== ========== ============================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================ =========================================================================================================================================================================================================
Name                 Type            Required   Default                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      Description
==================== =============== ========== ============================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================ =========================================================================================================================================================================================================
terminal_entries     list[string]    Yes        ``[]``                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       List of terminal emulators to configure Each entry must correspond to a key in terminal_configs variable Available terminals: alacritty, kitty, wezterm Choices: ``alacritty``, ``kitty``, ``wezterm``.
terminal_user        string          Yes        *(required)*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 Target username for terminal configuration All terminfo operations will be performed as this user Terminfo entries will be installed in this user's ~/.terminfo directory
terminal_configs     object          No         ``{'alacritty': {'terminfo_url': 'https://raw.githubusercontent.com/alacritty/alacritty/master/extra/alacritty.info', 'entries': ['alacritty', 'alacritty-direct'], 'tic_options': '-x'}, 'kitty': {'terminfo_url': 'https://raw.githubusercontent.com/kovidgoyal/kitty/master/terminfo/kitty.terminfo', 'entries': ['xterm-kitty'], 'tic_options': '-x'}, 'wezterm': {'terminfo_url': 'https://raw.githubusercontent.com/wez/wezterm/main/termwiz/data/wezterm.terminfo', 'entries': ['wezterm'], 'tic_options': '-x'}}``   Configuration mapping for terminal emulators Contains terminfo URLs, entries, and compilation options Usually not overridden - uses sensible defaults
==================== =============== ========== ============================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================ =========================================================================================================================================================================================================


Formal Requirements
===================

This role implements the following formal requirements from the Software Requirements Document:

**REQ-TERMINAL-001**
   The system SHALL install terminfo entries for modern terminal emulators for the specified user in ~/.terminfo directory



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
       - wolskies.infrastructure.terminal_config

Example Playbook
----------------

.. code-block:: yaml

   - hosts: all
     become: true
     roles:
       - role: wolskies.infrastructure.terminal_config
         vars:
           # Add your variable overrides here

Testing
=======

This role includes comprehensive molecule tests. To run the tests:

.. code-block:: bash

   cd roles/terminal_config
   molecule test

License
=======

MIT

Author Information
==================

This role is maintained by wolskies.
