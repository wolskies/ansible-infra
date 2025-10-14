configure_software
==================

**Phase 2** of the System → Software → Users pattern. Handles software package management across APT, Pacman, Homebrew, Snap, and Flatpak with hierarchical configuration support.

.. contents::
   :local:
   :depth: 2

Overview
--------

The ``configure_software`` role manages software packages across all major package managers on Linux and macOS. This is Phase 2 in the three-phase infrastructure pattern, executed after operating system configuration and before user environment setup.

**Key Features:**

- **Hierarchical Package Management** - Merge packages from all/group/host scopes
- **Cross-Platform** - APT, Pacman, Homebrew with unified variable structure
- **Repository Management** - Add custom repositories with automatic GPG key handling
- **Application Packaging** - Snap and Flatpak support
- **Cask Management** - macOS GUI applications via Homebrew Cask

Platform Support
~~~~~~~~~~~~~~~~

- **Ubuntu** 22.04+, 24.04+
- **Debian** 12+, 13+
- **Arch Linux** (Rolling)
- **macOS** 13+ (Ventura)

Usage
-----

Basic Package Installation
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Install common packages across platforms:

.. code-block:: yaml

   - hosts: all
     become: true
     roles:
       - wolskies.infrastructure.configure_software
     vars:
       manage_packages_all:
         Ubuntu: [git, curl, vim, htop]
         Debian: [git, curl, vim, htop]
         Archlinux: [git, curl, vim, htop]
         Darwin: [git, curl, vim, htop]

Layered Package Management
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Use inventory hierarchy for flexible package management:

.. code-block:: yaml

   # group_vars/all.yml - Base packages for all hosts
   manage_packages_all:
     Ubuntu: [git, curl, vim, htop, tmux]
     Archlinux: [git, curl, vim, htop, tmux]
     Darwin: [git, curl, vim, htop, tmux]

   # group_vars/webservers.yml - Web server packages
   manage_packages_group:
     Ubuntu: [nginx, postgresql-14, certbot]
     Debian: [nginx, postgresql, certbot]
     Archlinux: [nginx, postgresql, certbot]

   # host_vars/web01.yml - Host-specific packages
   manage_packages_host:
     Ubuntu: [redis-server, memcached]

APT Repository Management
~~~~~~~~~~~~~~~~~~~~~~~~~~

Add custom APT repositories (Ubuntu/Debian):

.. code-block:: yaml

   apt_repositories_all:
     Ubuntu:
       - name: nodejs
         uris: "https://deb.nodesource.com/node_20.x"
         suites: "nodistro"
         components: "main"
         signed_by: "https://deb.nodesource.com/gpgkey/nodesource.gpg.key"

       - name: docker
         uris: "https://download.docker.com/linux/ubuntu"
         suites: "{{ ansible_distribution_release }}"
         components: "stable"
         signed_by: "https://download.docker.com/linux/ubuntu/gpg"

   # Group-specific repositories
   apt_repositories_group:
     Ubuntu:
       - name: postgresql
         uris: "http://apt.postgresql.org/pub/repos/apt"
         suites: "{{ ansible_distribution_release }}-pgdg"
         components: "main"
         signed_by: "https://www.postgresql.org/media/keys/ACCC4CF8.asc"

macOS Homebrew Configuration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Manage Homebrew taps and casks:

.. code-block:: yaml

   homebrew:
     taps:
       - homebrew/cask-fonts
       - homebrew/cask-versions
     cleanup_cache: true

   manage_casks:
     Darwin:
       - name: visual-studio-code
         state: present
       - name: docker
         state: present
       - name: firefox
         state: present
       - name: google-chrome
         state: present

Arch Linux AUR Support
~~~~~~~~~~~~~~~~~~~~~~~

Enable AUR packages via paru helper:

.. code-block:: yaml

   pacman:
     enable_aur: true
     multilib:
       enabled: true

   manage_packages_all:
     Archlinux:
       - base-devel
       - yay  # AUR helper will be installed

Snap Package Management
~~~~~~~~~~~~~~~~~~~~~~~~

Manage Snap packages or remove Snap completely:

.. code-block:: yaml

   # Install Snap packages
   snap_packages:
     - name: code
       state: present
       classic: true
     - name: discord
       state: present
     - name: spotify
       state: present

   # Or remove Snap completely (Ubuntu/Debian)
   snap:
     remove_completely: true

Flatpak Application Management
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Enable Flatpak with Flathub:

.. code-block:: yaml

   flatpak:
     enabled: true
     flathub: true
     plugins:
       gnome: true
       plasma: false

   flatpak_packages:
     - name: org.mozilla.firefox
       state: present
     - name: org.gimp.GIMP
       state: present
     - name: com.spotify.Client
       state: present
     - name: org.libreoffice.LibreOffice
       state: present

Complete Multi-Platform Example
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   # group_vars/all.yml
   # Phase 2: Software Package Management

   # Base packages for all platforms
   manage_packages_all:
     Ubuntu: [git, curl, vim, htop, tmux, build-essential]
     Debian: [git, curl, vim, htop, tmux, build-essential]
     Archlinux: [git, curl, vim, htop, tmux, base-devel]
     Darwin: [git, curl, vim, htop, tmux]

   # APT repositories
   apt_repositories_all:
     Ubuntu:
       - name: docker
         uris: "https://download.docker.com/linux/ubuntu"
         suites: "{{ ansible_distribution_release }}"
         components: "stable"
         signed_by: "https://download.docker.com/linux/ubuntu/gpg"

   # Homebrew configuration
   homebrew:
     taps: [homebrew/cask-fonts]
     cleanup_cache: true

   manage_casks:
     Darwin:
       - name: visual-studio-code
       - name: docker

   # Flatpak for Linux desktops
   flatpak:
     enabled: true
     flathub: true

   flatpak_packages:
     - name: org.mozilla.firefox
     - name: com.spotify.Client

Variables
---------

Package Management Variables
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 30 15 55

   * - Variable
     - Type
     - Description
   * - ``manage_packages_all``
     - dict
     - Base-level packages by OS family (merged first)
   * - ``manage_packages_group``
     - dict
     - Group-level packages by OS family (merged second)
   * - ``manage_packages_host``
     - dict
     - Host-level packages by OS family (merged last)

**OS Family Keys:** ``Ubuntu``, ``Debian``, ``Archlinux``, ``Darwin``

Package Hierarchy
~~~~~~~~~~~~~~~~~

Packages are merged in order:

1. **all** - Applied to all hosts
2. **group** - Applied to inventory groups
3. **host** - Applied to specific hosts

This allows flexible management from global to host-specific needs.

APT Repository Variables (Ubuntu/Debian)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 30 15 55

   * - Variable
     - Type
     - Description
   * - ``apt_repositories_all``
     - dict
     - Base-level APT repositories by OS
   * - ``apt_repositories_group``
     - dict
     - Group-level APT repositories by OS
   * - ``apt_repositories_host``
     - dict
     - Host-level APT repositories by OS

**Repository Structure:**

.. code-block:: yaml

   apt_repositories_all:
     Ubuntu:
       - name: repository-name
         uris: "https://repo.example.com/ubuntu"
         suites: "{{ ansible_distribution_release }}"
         components: "main"
         signed_by: "https://repo.example.com/gpg"

Homebrew Variables (macOS)
~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 30 15 55

   * - Variable
     - Type
     - Description
   * - ``homebrew.taps``
     - list
     - Additional Homebrew tap repositories
   * - ``homebrew.cleanup_cache``
     - boolean
     - Clean download cache after operations. Default: true
   * - ``manage_casks.Darwin``
     - list
     - macOS GUI applications (casks)

**Cask Structure:**

.. code-block:: yaml

   manage_casks:
     Darwin:
       - name: application-name
         state: present  # or absent

Pacman Variables (Arch Linux)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 30 15 55

   * - Variable
     - Type
     - Description
   * - ``pacman.enable_aur``
     - boolean
     - Enable AUR support via paru helper. Default: false
   * - ``pacman.multilib.enabled``
     - boolean
     - Enable 32-bit package support. Default: false

Snap Variables
~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 30 15 55

   * - Variable
     - Type
     - Description
   * - ``snap.remove_completely``
     - boolean
     - Completely remove Snap system. Default: false
   * - ``snap_packages``
     - list
     - Snap packages to manage

**Snap Package Structure:**

.. code-block:: yaml

   snap_packages:
     - name: package-name
       state: present  # or absent
       classic: false  # true for classic confinement

Flatpak Variables
~~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 30 15 55

   * - Variable
     - Type
     - Description
   * - ``flatpak.enabled``
     - boolean
     - Enable Flatpak package manager. Default: false
   * - ``flatpak.flathub``
     - boolean
     - Enable Flathub repository. Default: false
   * - ``flatpak.plugins.gnome``
     - boolean
     - Install GNOME Flatpak plugin. Default: false
   * - ``flatpak.plugins.plasma``
     - boolean
     - Install KDE Plasma plugin. Default: false
   * - ``flatpak_packages``
     - list
     - Flatpak applications to manage

**Flatpak Package Structure:**

.. code-block:: yaml

   flatpak_packages:
     - name: org.mozilla.firefox
       state: present  # or absent

Platform-Specific Features
---------------------------

Ubuntu/Debian (APT)
~~~~~~~~~~~~~~~~~~~

- Modern deb822 format for repository definitions
- Automatic GPG key installation and management
- Repository component specification (main, contrib, non-free)
- Distribution release variable support

**Note:** APT proxy and unattended-upgrades are configured in Phase 1 (configure_operating_system).

Arch Linux (Pacman/AUR)
~~~~~~~~~~~~~~~~~~~~~~~

- Official repository packages via pacman
- Optional AUR support using paru helper
- Multilib repository for 32-bit packages
- Automatic dependency resolution

**AUR Requirements:** Requires passwordless sudo for pacman. See installation documentation.

macOS (Homebrew)
~~~~~~~~~~~~~~~~

- Formula packages (command-line tools)
- Cask packages (GUI applications)
- Tap repository management
- Automatic cache cleanup
- Applications installed to /Applications

Snap (Ubuntu/Debian)
~~~~~~~~~~~~~~~~~~~~

- Containerized applications with automatic updates
- Classic confinement mode for unrestricted access
- Optional complete removal of Snap system
- Per-package confinement control

Flatpak (Linux)
~~~~~~~~~~~~~~~

- Sandboxed applications across distributions
- Flathub repository for thousands of applications
- Desktop environment plugin integration
- User-level and system-level installation support

Tags
----

Control which package managers run:

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - Tag
     - Description
   * - ``apt``
     - APT package management (Ubuntu/Debian)
   * - ``pacman``
     - Pacman package management (Arch Linux)
   * - ``aur``
     - AUR package management (Arch Linux)
   * - ``homebrew``
     - Homebrew package management (macOS)
   * - ``snap``
     - Snap package management
   * - ``flatpak``
     - Flatpak package management
   * - ``repositories``
     - Repository management only
   * - ``packages``
     - Package installation only
   * - ``no-container``
     - Tasks requiring host capabilities

Examples:

.. code-block:: bash

   # Skip AUR packages in containers
   ansible-playbook --skip-tags aur,no-container playbook.yml

   # Only manage repositories
   ansible-playbook -t repositories playbook.yml

   # Only install packages (skip repository setup)
   ansible-playbook -t packages playbook.yml

Dependencies
------------

**Ansible Collections:**

- ``community.general`` - Pacman and npm modules
- ``geerlingguy.mac`` - Homebrew management on macOS
- ``kewlfft.aur`` - AUR package management on Arch Linux

Install dependencies:

.. code-block:: bash

   ansible-galaxy collection install -r requirements.yml

Limitations
-----------

**Container Environments:**

Package installation in containers may have limitations:

- Snap requires systemd and may not work in all containers
- Flatpak requires D-Bus and systemd
- Some packages may require privileged mode

Use ``--skip-tags no-container,snap,flatpak`` when running in basic containers.

**AUR on Arch Linux:**

AUR support requires:

- Passwordless sudo for pacman
- Internet access for package downloads
- Build dependencies (base-devel)

See :doc:`/installation` for Arch Linux setup details.

See Also
--------

- :doc:`configure_operating_system` - Phase 1: OS configuration (includes APT/Pacman proxy and auto-updates)
- :doc:`configure_users` - Phase 3: User environments
- :doc:`system_setup` - Meta-role demonstrating all three phases
- :doc:`/reference/variables-reference` - Complete variable reference
- :doc:`/user-guide/configuration` - Configuration strategies
