manage_snap_packages
====================

Snap package management and complete system removal for Ubuntu/Debian systems.

.. contents::
   :local:
   :depth: 2

Overview
--------

The ``manage_snap_packages`` role provides Snap package management for Ubuntu and Debian. Supports package installation/removal and complete snapd system removal with APT hold prevention.

Features
~~~~~~~~

- **Snap Package Management** - Install and remove snap packages via snapd
- **Classic Confinement** - Support for classic snap packages
- **Channel Selection** - Install from specific snap channels
- **System Removal** - Complete snapd system removal with APT hold prevention
- **Ubuntu/Debian Only** - Snap support limited to Debian-based distributions

Platform Support
~~~~~~~~~~~~~~~~

- **Ubuntu** 22.04+, 24.04+
- **Debian** 12+, 13+

**Note**: Snap support is limited to Debian-based distributions. This role has no effect on Arch Linux or macOS systems.

Usage
-----

Examples
~~~~~~~~

Install and manage snap packages:

.. code-block:: yaml

   - hosts: ubuntu_servers
     become: true
     roles:
       - wolskies.infrastructure.manage_snap_packages
     vars:
       snap_packages:
         - name: code
           classic: true
         - name: discord
           state: present
         - name: old-package
           state: absent

Package management with channels:

.. code-block:: yaml

   snap_packages:
     - name: code
       classic: true
       state: present
       channel: stable

     - name: kubectl
       classic: true
       channel: latest/stable

     - name: discord
       state: present

     - name: chromium
       state: absent

Remove snapd completely from the system:

.. code-block:: yaml

   - hosts: ubuntu_servers
     become: true
     roles:
       - wolskies.infrastructure.manage_snap_packages
     vars:
       snap:
         remove_completely: true

This will:

1. Remove all installed snap packages
2. Stop and disable snapd services
3. Purge snapd packages from the system
4. Remove snap directories (``/snap``, ``/var/snap``, etc.)
5. Create APT preferences to prevent snapd reinstallation
6. Remove snap paths from system PATH

Variables
---------

Snap Configuration
~~~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 25 15 60

   * - Variable
     - Type
     - Description
   * - ``snap.remove_completely``
     - boolean
     - Completely remove snapd system from Debian/Ubuntu systems. Default: false

Package Management
~~~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 25 15 60

   * - Variable
     - Type
     - Description
   * - ``snap_packages``
     - list
     - Snap packages to manage (see format below). Default: []

Package Format
~~~~~~~~~~~~~~

Each package in ``snap_packages`` is a dictionary:

.. list-table::
   :header-rows: 1
   :widths: 15 15 15 55

   * - Field
     - Type
     - Default
     - Description
   * - ``name``
     - string
     - Required
     - Snap package name (e.g., "code", "discord", "kubectl")
   * - ``state``
     - string
     - "present"
     - Package state: "present" or "absent"
   * - ``classic``
     - boolean
     - false
     - Enable classic confinement (required for some packages)
   * - ``channel``
     - string
     - "stable"
     - Snap channel: "stable", "candidate", "beta", "edge", or track/risk

Package Configuration Examples
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   snap_packages:
     # Simple installation (uses defaults)
     - name: discord

     # With state specification
     - name: code
       state: present

     # Classic confinement (required for some packages)
     - name: code
       classic: true

     # Specific channel
     - name: kubectl
       classic: true
       channel: latest/stable

     # Track and risk level
     - name: lxd
       channel: 4.0/stable

     # Remove package
     - name: old-package
       state: absent

Installation Behavior
---------------------

Normal Operation (``snap.remove_completely: false``)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

When managing snap packages normally:

1. **Snapd Installation** - Ensures snapd is installed via APT
2. **Service Management** - Starts and enables snapd services
3. **System Readiness** - Waits for snapd to be fully operational
4. **Package Management** - Installs/removes packages as specified

Complete System Removal (``snap.remove_completely: true``)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

When removing the snap system entirely:

1. **Package Enumeration** - Lists all installed snap packages
2. **Package Removal** - Removes all snap packages (including core snaps)
3. **Service Shutdown** - Stops and disables all snapd services:

   - ``snapd.service``
   - ``snapd.socket``
   - ``snapd.seeded.service``

4. **System Purge** - Removes snapd packages via APT:

   - ``snapd``
   - ``squashfuse``

5. **Directory Cleanup** - Removes snap directories:

   - ``/snap``
   - ``/var/snap``
   - ``/var/lib/snapd``
   - ``/var/cache/snapd``
   - ``~/snap`` (per-user directories)

6. **Reinstallation Prevention** - Creates APT preferences file:

   - Location: ``/etc/apt/preferences.d/no-snapd``
   - Blocks snapd reinstallation via APT

7. **PATH Cleanup** - Removes snap paths from system PATH

After complete removal, snapd cannot be reinstalled without removing the APT preferences file.

Tags
----

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - Tag
     - Description
   * - ``snap-packages``
     - All snap package management operations

Dependencies
------------

**Ansible Collections:**

This role uses modules from the following collections:

- ``community.general`` - Included with Ansible package

Install collection dependencies:

.. code-block:: bash

   ansible-galaxy collection install -r requirements.yml

**System Packages (managed automatically by role):**

- ``snapd`` - Snap daemon (installed if managing packages, removed if purging)
- ``squashfuse`` - Snap filesystem support

Limitations
-----------

**Platform Restrictions:**

- Only Ubuntu and Debian are supported
- Arch Linux and macOS have no snap support

**Complete Removal:**

- Irreversible without manual intervention
- Requires removing APT preferences to reinstall
- May affect system packages that depend on snap

**Package Availability:**

- Some applications only available as snaps
- Official support may be snap-only
- Consider alternatives before removal

Troubleshooting
---------------

Snap Package Won't Install
~~~~~~~~~~~~~~~~~~~~~~~~~~~

If a package fails to install, check if it requires classic confinement:

.. code-block:: bash

   snap info package-name

Add ``classic: true`` if required.

Snapd Service Won't Start
~~~~~~~~~~~~~~~~~~~~~~~~~~

Ensure snapd is installed and seeded:

.. code-block:: bash

   sudo apt install snapd
   sudo systemctl enable --now snapd.socket
   snap wait system seed.loaded

Snap Command Not Found After Installation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Logout and login again, or manually add to PATH:

.. code-block:: bash

   export PATH="/snap/bin:$PATH"

Cannot Remove Snap Due to Dependencies
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Some Ubuntu packages depend on snapd. Identify dependencies:

.. code-block:: bash

   apt-cache rdepends snapd

Remove dependent packages before running ``snap.remove_completely: true``.

See Also
--------

- :doc:`manage_flatpak` - Flatpak package management (snap alternative)
- :doc:`manage_packages` - System package management via APT
- :doc:`/reference/variables-reference` - Complete variable reference
- `Snapcraft <https://snapcraft.io/>`_ - Snap package directory
