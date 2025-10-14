Installation
============

This guide covers installing the ``wolskies.infrastructure`` collection.

Prerequisites
-------------

* Ansible 2.12 or higher
* Python 3.9 or higher (for control node)
* Supported target platforms (see :doc:`user-guide/platform-support`)

Installing from Git Repository
-------------------------------

To install the development version:

.. code-block:: bash

   ansible-galaxy collection install \
     git+https://gitlab.wolskinet.com/ansible/collections/infrastructure.git

Installing from Local Source
-----------------------------

For development or testing:

.. code-block:: bash

   # Clone the repository
   git clone https://gitlab.wolskinet.com/ansible/collections/infrastructure.git
   cd infrastructure

   # Build and install
   ansible-galaxy collection build --force
   ansible-galaxy collection install wolskies-infrastructure-*.tar.gz --force

Installing Collection Dependencies
-----------------------------------

The collection requires several external collections. Install them with:

.. code-block:: bash

   ansible-galaxy collection install -r requirements.yml

The ``requirements.yml`` file includes:

* ``community.general`` - Community-maintained modules
* ``ansible.posix`` - POSIX system modules
* ``community.docker`` - Docker support (for testing)
* ``geerlingguy.mac.homebrew`` - macOS Homebrew support
* ``kewlfft.aur`` - Arch Linux AUR support

Verifying Installation
-----------------------

Check that the collection is installed:

.. code-block:: bash

   ansible-galaxy collection list | grep wolskies.infrastructure

You should see output like:

.. code-block:: text

   wolskies.infrastructure  1.2.0

Platform-Specific Setup
------------------------

Ubuntu/Debian
~~~~~~~~~~~~~

No additional setup required.

Arch Linux
~~~~~~~~~~

AUR package installation (via ``kewlfft.aur`` collection) requires passwordless sudo for pacman:

.. code-block:: bash

   # Add to /etc/sudoers.d/ansible
   your_user ALL=(ALL) NOPASSWD: /usr/bin/pacman

This is required by the paru AUR helper. See :doc:`roles/configure_software` for details.

macOS
~~~~~

Package management uses the ``geerlingguy.mac.homebrew`` collection. Homebrew will be installed automatically if not present.

Next Steps
----------

* :doc:`quickstart` - Quick start guide
* :doc:`user-guide/configuration` - Configuration guide
* :doc:`roles/index` - Browse available roles
