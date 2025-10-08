manage_packages Role
====================

Cross-platform package management for APT (Ubuntu/Debian), Pacman (Arch Linux), and Homebrew (macOS).

.. contents::
   :local:
   :depth: 2

Overview
--------

The ``manage_packages`` role provides unified package management across Linux and macOS platforms:

* **Multi-platform support**: APT, Pacman, Homebrew with single variable structure
* **Layered configuration**: Apply packages at all/group/host inventory levels
* **Repository management**: Add external APT repositories, Homebrew taps
* **AUR support**: Install packages from Arch User Repository
* **System upgrades**: Configure automatic security updates

:Minimum Ansible Version: 2.12
:Platforms: Ubuntu 22.04+, Debian 12+, Arch Linux, macOS 13+

Quick Start
-----------

Basic package installation:

.. code-block:: yaml

   - hosts: all
     become: true
     roles:
       - wolskies.infrastructure.manage_packages
     vars:
       manage_packages_all:
         Ubuntu:
           - name: git
           - name: curl
           - name: vim
         Archlinux:
           - name: git
           - name: curl
           - name: vim
         MacOSX:
           - name: git
           - name: curl
           - name: vim

Key Concepts
------------

Layered Package Management
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Packages are merged from three inventory levels, allowing flexible configuration from global to host-specific:

**Level 1: Base (all hosts)**

.. code-block:: yaml

   # group_vars/all.yml
   manage_packages_all:
     Ubuntu:
       - name: git
       - name: curl
       - name: vim

**Level 2: Group (inventory group)**

.. code-block:: yaml

   # group_vars/webservers.yml
   manage_packages_group:
     Ubuntu:
       - name: nginx
       - name: postgresql

**Level 3: Host (specific host)**

.. code-block:: yaml

   # host_vars/web01.yml
   manage_packages_host:
     Ubuntu:
       - name: redis-server

**Result**: Host ``web01`` in group ``webservers`` gets all 6 packages merged together.

Distribution-Specific Keys
~~~~~~~~~~~~~~~~~~~~~~~~~~

Package lists use ``ansible_distribution`` as keys:

* ``Ubuntu`` - Ubuntu-specific packages
* ``Debian`` - Debian-specific packages
* ``Archlinux`` - Arch Linux packages
* ``MacOSX`` - macOS packages

This allows different package names across platforms in a single configuration.

Usage
-----

Examples
~~~~~~~~

Package list with default state (present):

.. code-block:: yaml

   manage_packages_all:
     Ubuntu:
       - name: git
       - name: curl
       - name: vim

Remove packages with state: absent:

.. code-block:: yaml

   manage_packages_all:
     Ubuntu:
       - name: nginx
         state: present  # Install (default, can be omitted)
       - name: telnet
         state: absent   # Remove package

APT Repository Management
~~~~~~~~~~~~~~~~~~~~~~~~~

Add external repositories (uses modern deb822 format):

.. code-block:: yaml

   apt_repositories_host:
     Ubuntu:
       - name: docker
         uris: "https://download.docker.com/linux/ubuntu"
         suites: "{{ ansible_distribution_release }}"
         components: "stable"
         signed_by: "https://download.docker.com/linux/ubuntu/gpg"

   manage_packages_host:
     Ubuntu:
       - name: docker-ce

Configure APT behavior:

.. code-block:: yaml

   apt:
     system_upgrade:
       enable: true
       type: "safe"  # or "full"
     proxy: "http://proxy.example.com:8080"

Arch Linux AUR Support
~~~~~~~~~~~~~~~~~~~~~~

Enable AUR package installation via paru:

.. code-block:: yaml

   pacman:
     enable_aur: true
     multilib:
       enabled: true  # Enable 32-bit packages

   manage_packages_all:
     Archlinux:
       - name: yay  # From AUR
       - name: paru  # From AUR

Without AUR (official repos only):

.. code-block:: yaml

   pacman:
     enable_aur: false

   manage_packages_all:
     Archlinux:
       - name: base-devel
       - name: git

macOS Homebrew Support
~~~~~~~~~~~~~~~~~~~~~~

Install formulae and casks:

.. code-block:: yaml

   homebrew:
     taps:
       - homebrew/cask-fonts
     cleanup_cache: true

   manage_packages_all:
     MacOSX:
       - name: git
       - name: curl

   manage_casks:
     MacOSX:
       - name: visual-studio-code
       - name: docker
       - name: firefox

Platform-Specific Notes
-----------------------

Ubuntu/Debian
~~~~~~~~~~~~~

* Uses ``apt`` module for package management
* Repository format: deb822 (modern format)
* GPG keys downloaded automatically from ``signed_by`` URLs
* Supports unattended security upgrades

Arch Linux
~~~~~~~~~~

* Official packages via ``pacman`` module
* AUR packages via ``kewlfft.aur`` collection (uses paru helper)
* Requires ``enable_aur: true`` for AUR support
* System upgrade runs ``pacman -Syu`` when enabled

macOS
~~~~~

* Uses ``geerlingguy.mac.homebrew`` collection
* Casks for GUI applications (installed to /Applications)
* Taps for additional repositories
* Cache cleanup optional via ``cleanup_cache``

Variables Reference
-------------------

Package Variables
~~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 20 10 10 60

   * - Variable
     - Type
     - Default
     - Description
   * - ``manage_packages_all``
     - dict
     - ``{}``
     - Base-level packages, merged first
   * - ``manage_packages_group``
     - dict
     - ``{}``
     - Group-level packages, merged second
   * - ``manage_packages_host``
     - dict
     - ``{}``
     - Host-level packages, merged last

Package Object Format
~~~~~~~~~~~~~~~~~~~~~~

Each package in the list is a dictionary with the following structure:

.. list-table::
   :header-rows: 1
   :widths: 20 10 10 60

   * - Field
     - Type
     - Default
     - Description
   * - ``name``
     - string
     - Required
     - Package name
   * - ``state``
     - string
     - ``present``
     - Package state: ``present`` (install) or ``absent`` (remove)

**Example:**

.. code-block:: yaml

   manage_packages_all:
     Ubuntu:
       - name: git           # Installs git (state: present is default)
       - name: curl
         state: present      # Explicit install
       - name: telnet
         state: absent       # Remove package

Repository Variables
~~~~~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 20 10 10 60

   * - Variable
     - Type
     - Default
     - Description
   * - ``apt_repositories_all``
     - dict
     - ``{}``
     - Base-level APT repositories
   * - ``apt_repositories_group``
     - dict
     - ``{}``
     - Group-level APT repositories
   * - ``apt_repositories_host``
     - dict
     - ``{}``
     - Host-level APT repositories

Package Manager Configuration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 20 10 10 60

   * - Variable
     - Type
     - Default
     - Description
   * - ``apt``
     - dict
     - ``{}``
     - APT configuration options
   * - ``pacman``
     - dict
     - ``{}``
     - Pacman configuration options
   * - ``homebrew``
     - dict
     - ``{}``
     - Homebrew configuration options
   * - ``manage_casks``
     - dict
     - ``{}``
     - macOS cask definitions

For detailed variable schemas, see :doc:`../reference/variables-reference`.

Tags
----

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - Tag
     - Description
   * - ``packages``
     - Package installation/removal only
   * - ``repositories``
     - Repository management only
   * - ``apt``
     - APT-specific tasks
   * - ``pacman``
     - Pacman-specific tasks
   * - ``aur``
     - AUR-specific tasks
   * - ``homebrew``
     - Homebrew-specific tasks
   * - ``no-container``
     - Tasks requiring host capabilities (skip in containers)

Dependencies
------------

**Ansible Collections:**

This role uses modules from the following collections:

- ``community.general`` - Included with Ansible package
- ``geerlingguy.mac.homebrew`` - macOS Homebrew support
- ``kewlfft.aur`` - Arch Linux AUR support

Install collection dependencies:

.. code-block:: bash

   ansible-galaxy collection install -r requirements.yml

**System Requirements:**

* **Ubuntu/Debian**: ``python3-debian`` (installed automatically)
* **Arch Linux**: ``base-devel`` (for AUR building)
* **macOS**: Homebrew pre-installed

Troubleshooting
---------------

Common Issues
~~~~~~~~~~~~~

**Packages not installing**

Check that you're using the correct distribution key:

.. code-block:: bash

   # Verify your distribution name
   ansible all -m setup -a 'filter=ansible_distribution'

**APT repository failures**

Ensure GPG key URLs are accessible and repository suite matches your release:

.. code-block:: yaml

   # Use ansible_distribution_release variable
   suites: "{{ ansible_distribution_release }}"  # e.g., "noble", "jammy"

**AUR failures in containers**

AUR requires fakeroot and user privileges. Skip AUR in containers:

.. code-block:: bash

   ansible-playbook playbook.yml --skip-tags aur

Testing
-------

This role includes Molecule tests covering:

* Basic package installation (Ubuntu, Arch)
* Layered package combining
* Repository management
* AUR support
* Edge cases

Run tests:

.. code-block:: bash

   cd roles/manage_packages
   molecule test

See :doc:`../testing/running-tests` for more details.

See Also
--------

* :doc:`os_configuration` - System-level configuration
* :doc:`manage_security_services` - Security service management
* :doc:`../testing/running-tests` - Testing guide
