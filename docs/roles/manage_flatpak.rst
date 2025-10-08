manage_flatpak
==============

Flatpak package management and desktop integration for Linux systems.

.. contents::
   :local:
   :depth: 2

Overview
--------

The ``manage_flatpak`` role installs the flatpak runtime, enables Flathub repository, optionally installs desktop environment plugins (GNOME Software, Plasma Discover), and manages flatpak package installation.

What It Does
~~~~~~~~~~~~

- Installs flatpak runtime (Ubuntu, Debian, Arch Linux)
- Enables Flathub repository
- Installs GNOME Software or Plasma Discover plugins (optional)
- Installs/removes flatpak packages from Flathub

Platform Support
~~~~~~~~~~~~~~~~

- **Ubuntu** 22.04+, 24.04+
- **Debian** 12+, 13+
- **Arch Linux** (Rolling)

Usage
-----

Examples
~~~~~~~~

Install flatpak runtime and some applications from Flathub:

.. code-block:: yaml

   - hosts: linux_desktops
     become: true
     roles:
       - wolskies.infrastructure.manage_flatpak
     vars:
       flatpak:
         enabled: true
         flathub: true
         plugins:
           gnome: true
       flatpak_packages:
         - name: org.mozilla.firefox
           state: present
         - name: com.spotify.Client
           state: present
         - name: org.gimp.GIMP
           state: present

Configure desktop integration:

.. code-block:: yaml

   # For GNOME desktop
   flatpak:
     enabled: true
     flathub: true
     plugins:
       gnome: true

   # For KDE Plasma desktop
   flatpak:
     enabled: true
     flathub: true
     plugins:
       plasma: true

Simple package format with state management:

.. code-block:: yaml

   flatpak:
     enabled: true
     flathub: true

   flatpak_packages:
     # Simple format with name only (defaults to state: present)
     - name: org.mozilla.firefox
     - name: com.visualstudio.code
     - name: org.videolan.VLC

     # Explicit state management
     - name: org.gimp.GIMP
       state: present
     - name: old-application
       state: absent

Install flatpak system without installing any packages:

.. code-block:: yaml

   - hosts: servers
     become: true
     roles:
       - wolskies.infrastructure.manage_flatpak
     vars:
       flatpak:
         enabled: true
         flathub: true
       # Leave flatpak_packages empty or omit it

Variables
---------

Flatpak Configuration
~~~~~~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 25 15 60

   * - Variable
     - Type
     - Description
   * - ``flatpak.enabled``
     - boolean
     - Install flatpak runtime. Default: false
   * - ``flatpak.flathub``
     - boolean
     - Enable Flathub repository. Default: false
   * - ``flatpak.method``
     - string
     - Installation method: "system" only. Default: "system"
   * - ``flatpak.plugins.gnome``
     - boolean
     - Install GNOME Software plugin (Ubuntu/Debian only). Default: false
   * - ``flatpak.plugins.plasma``
     - boolean
     - Install Plasma Discover plugin (Ubuntu/Debian only). Default: false

Package Management
~~~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 25 15 60

   * - Variable
     - Type
     - Description
   * - ``flatpak_packages``
     - list
     - List of flatpak packages to manage (see format below)

Package Format
~~~~~~~~~~~~~~

Simple list structure:

.. code-block:: yaml

   flatpak_packages:
     # Minimal format (state defaults to present)
     - name: org.mozilla.firefox
     - name: com.spotify.Client

     # With explicit state
     - name: org.gimp.GIMP
       state: present

     # Remove package
     - name: old-application
       state: absent

     # Specific version/branch
     - name: org.freedesktop.Platform//23.08
       state: present

Behavior
--------

The role installs flatpak system-wide:

1. Installs flatpak runtime via system package manager
2. Enables Flathub repository system-wide
3. Installs desktop plugins if requested (Ubuntu/Debian only)
4. Installs specified packages from Flathub
5. Packages installed in ``/var/lib/flatpak/`` and available to all users

Platform Differences
--------------------

Ubuntu/Debian
~~~~~~~~~~~~~

- Flatpak installed via: ``apt install flatpak``
- Desktop plugins available: ``gnome-software-plugin-flatpak``, ``plasma-discover-backend-flatpak``
- Plugins installed when requested via ``flatpak.plugins.gnome`` or ``flatpak.plugins.plasma``

Arch Linux
~~~~~~~~~~

- Flatpak installed via: ``pacman -S flatpak``
- Desktop plugins built into GNOME Software and Plasma Discover packages
- ``flatpak.plugins`` settings ignored (plugins already present)

Tags
----

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - Tag
     - Description
   * - ``flatpak-system``
     - Flatpak runtime and repository installation
   * - ``flatpak-plugins``
     - Desktop environment integration plugins
   * - ``flatpak-packages``
     - Individual package management

Dependencies
------------

**Ansible Collections:**

This role uses modules from the following collections:

- ``community.general`` - Included with Ansible package

Install collection dependencies:

.. code-block:: bash

   ansible-galaxy collection install -r requirements.yml

**System Packages (installed automatically by role):**

- ``flatpak`` - Flatpak runtime
- ``gnome-software-plugin-flatpak`` - GNOME integration (Ubuntu/Debian)
- ``plasma-discover-backend-flatpak`` - KDE integration (Ubuntu/Debian)

Limitations
-----------

**Desktop Integration:**

- Desktop plugin integration requires logout/login to take effect
- Some applications may need additional permissions configuration via ``flatpak override``

Troubleshooting
---------------

Flatpak Command Not Found
~~~~~~~~~~~~~~~~~~~~~~~~~~

If flatpak command isn't found after installation, logout and login again to reload PATH.

See Also
--------

- :doc:`manage_snap_packages` - Snap package management
- :doc:`manage_packages` - System package management
- :doc:`/reference/variables-reference` - Complete variable reference
- `Flathub <https://flathub.org/>`_ - Flatpak application repository
