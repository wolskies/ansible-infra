manage_flatpak
==============

.. warning::
   **EXPERIMENTAL - Limited Testing**

   This role is functional but has not been extensively tested. It is included in v1.2.0 as experimental. Use with caution and report any issues.

   - ✅ Basic functionality tested in containers
   - ❌ Not tested in real desktop environments
   - ❌ User-level installation not tested
   - ⚠️ Consider this a preview for v1.3.0

Flatpak package management and desktop integration for Linux systems.

.. contents::
   :local:
   :depth: 2

Overview
--------

The ``manage_flatpak`` role provides basic Flatpak support: installs the flatpak runtime, enables Flathub repository, optionally installs desktop environment plugins, and manages flatpak package installation.

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

Basic Usage
~~~~~~~~~~~

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

Configure Desktop Integration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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

Simple Package Format
~~~~~~~~~~~~~~~~~~~~~

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

Install Runtime Without Packages
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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

Control which features are configured:

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

Examples
--------

Install Flatpak Without Desktop Integration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   ansible-playbook --skip-tags flatpak-plugins playbook.yml

Configure System Without Installing Packages
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   ansible-playbook --skip-tags flatpak-packages playbook.yml

Development Workstation
~~~~~~~~~~~~~~~~~~~~~~~

Complete desktop setup with development tools:

.. code-block:: yaml

   - hosts: workstations
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
         - name: com.visualstudio.code
         - name: org.mozilla.firefox
         - name: com.google.Chrome
         - name: org.gimp.GIMP
         - name: org.inkscape.Inkscape
         - name: com.slack.Slack
         - name: us.zoom.Zoom
         - name: org.videolan.VLC

Minimal Server with GUI Apps
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Server environment with select graphical tools:

.. code-block:: yaml

   - hosts: gui_servers
     become: true
     roles:
       - wolskies.infrastructure.manage_flatpak
     vars:
       flatpak:
         enabled: true
         flathub: true

       flatpak_packages:
         - name: org.mozilla.firefox
         - name: org.remmina.Remmina

Multi-User Workstation
~~~~~~~~~~~~~~~~~~~~~~

System-wide installation for shared workstations:

.. code-block:: yaml

   - hosts: shared_workstations
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
         - name: org.libreoffice.LibreOffice
         - name: org.gimp.GIMP
         - name: org.videolan.VLC
         - name: com.slack.Slack

Comparison with Snap
--------------------

Flatpak vs. Snap Packages:

.. list-table::
   :header-rows: 1
   :widths: 20 40 40

   * - Feature
     - Flatpak
     - Snap
   * - Distribution Support
     - Most Linux distributions
     - Ubuntu/Debian focused
   * - Sandboxing
     - Bubblewrap
     - AppArmor/Seccomp
   * - Repository
     - Flathub (community-driven)
     - Snap Store (Canonical)
   * - Desktop Integration
     - Excellent
     - Good
   * - Performance
     - Native-like
     - Slower startup
   * - Open Source
     - Fully open
     - Server proprietary

Use Flatpak when:

- Supporting multiple distributions
- Desktop application focus
- Community-driven ecosystem preferred
- Open-source infrastructure required

Use Snap when:

- Ubuntu/Debian exclusive
- Server applications and services
- Official Ubuntu support needed

Dependencies
------------

**Required:**

- ``ansible.builtin.apt`` - Ubuntu/Debian package installation
- ``community.general.pacman`` - Arch Linux package installation
- ``community.general.flatpak_remote`` - Repository management
- ``community.general.flatpak`` - Package management

**System Packages (installed automatically):**

- ``flatpak`` - Flatpak runtime
- ``gnome-software-plugin-flatpak`` - GNOME integration (Ubuntu/Debian)
- ``plasma-discover-backend-flatpak`` - KDE integration (Ubuntu/Debian)

Install Ansible dependencies:

.. code-block:: bash

   ansible-galaxy collection install -r requirements.yml

Limitations
-----------

**Experimental Status:**

- Limited testing on actual desktop environments
- User-level installation (``method: user``) not tested
- May have edge cases not covered by container testing

**Known Issues:**

- Desktop integration requires logout/login to take effect
- Some applications may need additional permissions configuration

Troubleshooting
---------------

Flatpak Not Found After Installation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Logout and login again, or run:

.. code-block:: bash

   export PATH="/var/lib/flatpak/exports/bin:$HOME/.local/share/flatpak/exports/bin:$PATH"

Applications Don't Appear in Launcher
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Update desktop database:

.. code-block:: bash

   update-desktop-database ~/.local/share/applications/

Flathub Repository Already Exists
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If repository configuration fails, remove and re-add:

.. code-block:: bash

   flatpak remote-delete flathub
   flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

Permissions Issues
~~~~~~~~~~~~~~~~~~

Flatpak applications are sandboxed. Grant additional permissions:

.. code-block:: bash

   flatpak override --user --filesystem=home org.mozilla.firefox

See Also
--------

- :doc:`manage_snap_packages` - Snap package management
- :doc:`manage_packages` - System package management
- :doc:`/reference/variables-reference` - Complete variable reference
- `Flathub <https://flathub.org/>`_ - Flatpak application repository
