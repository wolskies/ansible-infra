Quick Start Guide
=================

Get started with ``wolskies.infrastructure`` in 5 minutes.

Installation
------------

Install the collection and its dependencies:

.. code-block:: bash

   ansible-galaxy collection install wolskies.infrastructure
   ansible-galaxy collection install -r requirements.yml

Basic Usage
-----------

Example 1: Package Management
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Install packages across multiple platforms:

.. code-block:: yaml

   # playbook.yml
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

Run the playbook:

.. code-block:: bash

   ansible-playbook -i inventory playbook.yml

Example 2: System Configuration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Configure hostname, timezone, and locale:

.. code-block:: yaml

   # playbook.yml
   - hosts: all
     become: true
     roles:
       - wolskies.infrastructure.os_configuration
     vars:
       host_hostname: "myserver"
       domain_name: "example.com"
       domain_timezone: "America/New_York"
       domain_locale: "en_US.UTF-8"
       host_update_hosts: true

Example 3: User Development Environment
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Configure a user's development environment:

.. code-block:: yaml

   # playbook.yml
   - hosts: workstations
     become: true
     roles:
       - wolskies.infrastructure.configure_users
     vars:
       users:
         - name: developer
           shell: /bin/bash
           git:
             user_name: "Developer Name"
             user_email: "dev@example.com"
             editor: "vim"
           nodejs:
             packages:
               - typescript
               - eslint
           rust:
             packages:
               - ripgrep
               - bat
           neovim:
             enabled: true

Example 4: Firewall Configuration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Enable and configure the firewall:

.. code-block:: yaml

   # playbook.yml
   - hosts: servers
     become: true
     roles:
       - wolskies.infrastructure.manage_security_services
     vars:
       firewall:
         enabled: true
         default_policy:
           incoming: deny
           outgoing: allow
         rules:
           - port: 22
             protocol: tcp
             rule: allow
             comment: "SSH access"
           - port: 80
             protocol: tcp
             rule: allow
             comment: "HTTP"
           - port: 443
             protocol: tcp
             rule: allow
             comment: "HTTPS"

Layered Configuration
---------------------

Apply configuration at multiple inventory levels:

.. code-block:: yaml

   # group_vars/all.yml - Base level (all hosts)
   manage_packages_all:
     Ubuntu:
       - name: git
       - name: curl

   # group_vars/webservers.yml - Group level
   manage_packages_group:
     Ubuntu:
       - name: nginx
       - name: postgresql

   # host_vars/web01.yml - Host level
   manage_packages_host:
     Ubuntu:
       - name: redis-server

The packages are merged automatically:
- web01 gets: git, curl, nginx, postgresql, redis-server

Common Patterns
---------------

Check Mode (Dry Run)
~~~~~~~~~~~~~~~~~~~~

Preview changes without applying them:

.. code-block:: bash

   ansible-playbook playbook.yml --check

Limit to Specific Hosts
~~~~~~~~~~~~~~~~~~~~~~~~

Run on a subset of hosts:

.. code-block:: bash

   ansible-playbook playbook.yml --limit webservers

Use Tags
~~~~~~~~

Run specific parts of a role:

.. code-block:: bash

   # Only install packages, skip repositories
   ansible-playbook playbook.yml --tags packages

   # Skip container-incompatible tasks
   ansible-playbook playbook.yml --skip-tags no-container

Complete Example
----------------

Here's a complete playbook configuring a web server:

.. code-block:: yaml

   # site.yml
   - name: Configure web server
     hosts: webservers
     become: true

     roles:
       # System configuration
       - role: wolskies.infrastructure.os_configuration
         vars:
           host_hostname: "{{ inventory_hostname }}"
           domain_name: "example.com"
           domain_timezone: "America/New_York"
           domain_locale: "en_US.UTF-8"

       # Package installation
       - role: wolskies.infrastructure.manage_packages
         vars:
           manage_packages_all:
             Ubuntu:
               - name: nginx
               - name: postgresql
               - name: python3-psycopg2

       # Firewall configuration
       - role: wolskies.infrastructure.manage_security_services
         vars:
           firewall:
             enabled: true
             rules:
               - { port: 22, protocol: tcp, rule: allow, comment: "SSH" }
               - { port: 80, protocol: tcp, rule: allow, comment: "HTTP" }
               - { port: 443, protocol: tcp, rule: allow, comment: "HTTPS" }
           fail2ban:
             enabled: true

Create your inventory:

.. code-block:: ini

   # inventory/hosts.ini
   [webservers]
   web01 ansible_host=192.168.1.10
   web02 ansible_host=192.168.1.11

   [all:vars]
   ansible_user=ubuntu
   ansible_ssh_private_key_file=~/.ssh/id_ed25519

Run the playbook:

.. code-block:: bash

   ansible-playbook -i inventory/hosts.ini site.yml

Next Steps
----------

* :doc:`user-guide/configuration` - Learn about configuration options
* :doc:`roles/index` - Explore all available roles
* :doc:`user-guide/variables` - Understand the variable system
* :doc:`testing/running-tests` - Test your configurations
