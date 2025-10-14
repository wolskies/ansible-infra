Quick Start Guide
=================

Get up and running with the ``wolskies.infrastructure`` collection in minutes.

Installation
------------

Install the collection from Git and its dependencies:

.. code-block:: bash

   # Install the collection
   ansible-galaxy collection install \
     git+https://gitlab.wolskinet.com/ansible/collections/infrastructure.git

   # Install required dependencies
   ansible-galaxy collection install -r requirements.yml

5-Minute Workstation Setup
---------------------------

Configure a developer workstation using the ``system_setup`` role (orchestrates the System → Software → Users pattern: configure_operating_system, configure_software, and configure_users).

Create a playbook:

.. code-block:: yaml

   # workstation.yml
   - name: Configure developer workstation
     hosts: workstations
     become: true
     roles:
       - wolskies.infrastructure.system_setup
     vars:
       # System configuration
       domain_timezone: "America/New_York"
       host_hostname: "{{ inventory_hostname }}"

       # Install development tools
       manage_packages_all:
         Ubuntu: [git, curl, vim, build-essential, python3-pip]
         Archlinux: [git, curl, vim, base-devel, python-pip]
         Darwin: [git, curl, vim]

       # Configure developer user
       users:
         - name: developer
           git:
             user_name: "Developer Name"
             user_email: "dev@example.com"
             editor: "vim"
           nodejs:
             packages: [typescript, eslint, prettier]
           rust:
             packages: [ripgrep, bat, fd-find]
           neovim:
             deploy_config: true

Create an inventory:

.. code-block:: ini

   # inventory/hosts.ini
   [workstations]
   laptop ansible_host=localhost ansible_connection=local

   [all:vars]
   ansible_user=your_username

Run the playbook:

.. code-block:: bash

   ansible-playbook -i inventory/hosts.ini workstation.yml

**What This Does:**

1. Sets hostname and timezone
2. Installs system packages (git, build tools, etc.)
3. Configures Git for the developer user
4. Installs Node.js and npm packages
5. Installs Rust and cargo packages
6. Deploys Neovim with LSP configuration

5-Minute Server Setup
----------------------

Configure a secure web server with firewall and fail2ban.

Create a playbook:

.. code-block:: yaml

   # webserver.yml
   - name: Configure web server
     hosts: webservers
     become: true
     roles:
       - wolskies.infrastructure.system_setup
     vars:
       # System configuration
       domain_timezone: "UTC"
       host_hostname: "{{ inventory_hostname }}"

       # Install server packages
       manage_packages_all:
         Ubuntu: [nginx, postgresql, certbot, python3-psycopg2]
         Debian: [nginx, postgresql, certbot, python3-psycopg2]

       # Configure firewall
       firewall:
         enabled: true
         default_policy:
           incoming: deny
           outgoing: allow
         rules:
           - port: 22
             protocol: tcp
             comment: "SSH access"
           - port: 80
             protocol: tcp
             comment: "HTTP"
           - port: 443
             protocol: tcp
             comment: "HTTPS"

       # Enable intrusion prevention
       fail2ban:
         enabled: true
         bantime: "1h"
         maxretry: 3
         jails:
           - name: sshd
             enabled: true
             maxretry: 3

Create an inventory:

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

   ansible-playbook -i inventory/hosts.ini webserver.yml

**What This Does:**

1. Sets hostname and timezone
2. Installs web server packages (nginx, PostgreSQL, certbot)
3. Enables and configures UFW firewall with SSH/HTTP/HTTPS rules
4. Enables fail2ban with SSH protection
5. Secures the server with default-deny incoming policy

Individual Role Usage
---------------------

You can also use individual roles for specific tasks following the System → Software → Users pattern:

Operating System Configuration Only (Phase 1)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   - hosts: all
     become: true
     roles:
       - wolskies.infrastructure.configure_operating_system
     vars:
       host_hostname: "myserver"
       domain_timezone: "America/New_York"
       domain_locale: "en_US.UTF-8"
       host_update_hosts: true
       firewall:
         enabled: true
         rules:
           - port: 22
             protocol: tcp

Software Package Management Only (Phase 2)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   - hosts: all
     become: true
     roles:
       - wolskies.infrastructure.configure_software
     vars:
       manage_packages_all:
         Ubuntu: [git, curl, vim]
         Archlinux: [git, curl, vim]
       snap:
         remove_completely: true
       flatpak:
         enabled: true
         flathub: true

User Environment Configuration Only (Phase 3)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   - hosts: workstations
     become: true
     roles:
       - wolskies.infrastructure.configure_users
     vars:
       users:
         - name: developer
           git:
             user_name: "Developer Name"
             user_email: "dev@example.com"
           nodejs:
             packages: [typescript, eslint]
           rust:
             packages: [ripgrep, bat]
           dotfiles:
             enable: true
             repository: "https://github.com/user/dotfiles"



Next Steps
----------

* :doc:`roles/system_setup` - Complete system_setup role documentation
* :doc:`roles/configure_operating_system` - Operating system configuration (Phase 1)
* :doc:`roles/configure_software` - Software package management (Phase 2)
* :doc:`roles/configure_users` - User preferences and environments (Phase 3)
* :doc:`user-guide/configuration` - Configuration strategies and patterns
* :doc:`reference/variables-reference` - Complete variable reference
* :doc:`roles/index` - Browse all available roles
* :doc:`testing/running-tests` - Testing guide
