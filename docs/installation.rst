Installation
============

This guide covers installing the ``wolskies.infrastructure`` collection.

Prerequisites
-------------

* Ansible 2.12 or higher
* Python 3.8 or higher (for control node)
* Supported target platforms (see :doc:`user-guide/platform-support`)

.. Right now, I don't intent to publish to Ansible Galaxy.. this might not be a usefule section. COMMENT

Installing from Ansible Galaxy
-------------------------------

.. code-block:: bash

   ansible-galaxy collection install wolskies.infrastructure

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

.. Isn't "Testing the Installation" redundant with Quickstart? COMMENT

Testing the Installation
-------------------------

Create a simple test playbook:

.. code-block:: yaml

   # test-playbook.yml
   - hosts: localhost
     connection: local
     roles:
       - role: wolskies.infrastructure.manage_packages
         vars:
           manage_packages_all:
             Ubuntu: [curl]
             MacOSX: [curl]

Run the test:

.. code-block:: bash

   ansible-playbook test-playbook.yml --check

Platform-Specific Setup
------------------------

Ubuntu/Debian
~~~~~~~~~~~~~

No additional setup required. APT package manager is supported out of the box.

Arch Linux
~~~~~~~~~~

For AUR support, ensure your user has passwordless sudo for pacman:

.. code-block:: bash

   # Add to /etc/sudoers.d/ansible
   your_user ALL=(ALL) NOPASSWD: /usr/bin/pacman

macOS
~~~~~
.. don't we install homebrew by default?  COMMENT

Install Homebrew if not already installed:

.. code-block:: bash

   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

Next Steps
----------

* :doc:`quickstart` - Quick start guide
* :doc:`user-guide/configuration` - Configuration guide
* :doc:`roles/index` - Browse available roles
