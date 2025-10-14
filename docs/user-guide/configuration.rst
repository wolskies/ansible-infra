Configuration
=============

Guide to configuring the ``wolskies.infrastructure`` collection.

.. contents::
   :local::
   :depth: 2

Overview
--------

The collection uses a layered configuration approach that allows you to define base configuration for all hosts, group-specific configuration, and host-specific overrides. This provides flexibility while maintaining consistency across your infrastructure.

**Configuration Layers:**

1. **All** (``group_vars/all.yml``) - Base configuration for all hosts
2. **Group** (``group_vars/<group>.yml``) - Configuration for inventory groups
3. **Host** (``host_vars/<host>.yml``) - Host-specific configuration

Variables are merged in order: all → group → host, with later values taking precedence.

Layered Configuration
---------------------

Basic Structure
~~~~~~~~~~~~~~~

Organize your Ansible inventory and variables:

.. code-block:: text

   infrastructure/
   ├── inventory/
   │   ├── production/
   │   │   ├── hosts
   │   │   ├── group_vars/
   │   │   │   ├── all.yml
   │   │   │   ├── webservers.yml
   │   │   │   └── databases.yml
   │   │   └── host_vars/
   │   │       ├── web01.yml
   │   │       └── db01.yml
   │   └── development/
   │       ├── hosts
   │       └── group_vars/
   │           └── all.yml
   └── playbooks/
       └── site.yml

All Hosts Configuration
~~~~~~~~~~~~~~~~~~~~~~~

Define base configuration in ``group_vars/all.yml``:

.. code-block:: yaml

   # group_vars/all.yml
   # Applied to all hosts

   # Phase 1: Operating System
   timezone: UTC

   firewall:
     enabled: true
     default_policy: deny
     allow_ssh: true

   # Phase 2: Software
   manage_packages_all:
     Ubuntu:
       - git
       - curl
       - vim
       - htop
       - tmux

     Debian:
       - git
       - curl
       - vim
       - htop
       - tmux

     Archlinux:
       - git
       - curl
       - vim
       - htop
       - tmux

     Darwin:
       - git
       - curl
       - vim
       - htop
       - tmux

Group Configuration
~~~~~~~~~~~~~~~~~~~

Add group-specific packages in ``group_vars/<group>.yml``:

.. code-block:: yaml

   # group_vars/webservers.yml
   # Applied to all hosts in the webservers group

   manage_packages_group:
     Ubuntu:
       - nginx
       - postgresql-client
       - certbot

     Debian:
       - nginx
       - postgresql-client
       - certbot

   firewall:
     rules:
       - port: 80
         protocol: tcp
         rule: allow
       - port: 443
         protocol: tcp
         rule: allow

.. code-block:: yaml

   # group_vars/databases.yml
   # Applied to all hosts in the databases group

   manage_packages_group:
     Ubuntu:
       - postgresql-14
       - redis-server

   firewall:
     rules:
       - port: 5432
         protocol: tcp
         rule: allow
         from: 10.0.1.0/24  # Web server subnet

Host Configuration
~~~~~~~~~~~~~~~~~~

Override or extend configuration in ``host_vars/<host>.yml``:

.. code-block:: yaml

   # host_vars/web01.yml
   # Applied only to web01

   hostname: web01.example.com

   manage_packages_host:
     Ubuntu:
       - memcached
       - varnish

The final package list for web01 will be:
- All hosts packages (git, curl, vim, htop, tmux)
- Webservers group packages (nginx, postgresql-client, certbot)
- Host-specific packages (memcached, varnish)

Variable Merging
----------------

How Variables Merge
~~~~~~~~~~~~~~~~~~~

The collection uses Ansible's variable precedence with hierarchical merging:

**Package Variables:**

- ``manage_packages_all`` - Base packages for all hosts
- ``manage_packages_group`` - Group-specific packages
- ``manage_packages_host`` - Host-specific packages

All three are merged together, not replaced.

**Example:**

.. code-block:: yaml

   # group_vars/all.yml
   manage_packages_all:
     Ubuntu: [git, vim]

   # group_vars/webservers.yml
   manage_packages_group:
     Ubuntu: [nginx, certbot]

   # host_vars/web01.yml
   manage_packages_host:
     Ubuntu: [memcached]

   # Result for web01:
   # Final package list: [git, vim, nginx, certbot, memcached]

**Other Variables:**

Non-package variables use standard Ansible precedence (host_vars override group_vars override all).

.. code-block:: yaml

   # group_vars/all.yml
   timezone: UTC

   # host_vars/special-host.yml
   timezone: America/New_York  # Overrides UTC for this host

OS Family Keys
~~~~~~~~~~~~~~

Always use the correct OS family key for your platform:

.. list-table::
   :header-rows: 1
   :widths: 30 70

   * - OS Family Key
     - Platform
   * - ``Ubuntu``
     - Ubuntu (all versions)
   * - ``Debian``
     - Debian (all versions)
   * - ``Archlinux``
     - Arch Linux
   * - ``Darwin``
     - macOS

**Important:** Use ``Archlinux`` (not ``ArchLinux`` or ``arch``) and ``Darwin`` (not ``macOS`` or ``MacOS``).

**Cross-Platform Example:**

.. code-block:: yaml

   manage_packages_all:
     Ubuntu: [git, curl, build-essential]
     Debian: [git, curl, build-essential]
     Archlinux: [git, curl, base-devel]
     Darwin: [git, curl]

Platform-Specific Configuration
--------------------------------

Conditional Configuration
~~~~~~~~~~~~~~~~~~~~~~~~~

Configure based on the target platform:

.. code-block:: yaml

   # Different firewall rules for Linux vs macOS
   firewall:
     enabled: true
     # Linux-specific configuration
     default_policy: "{{ 'deny' if ansible_os_family != 'Darwin' else omit }}"
     allow_ssh: "{{ true if ansible_os_family != 'Darwin' else omit }}"

     # macOS-specific configuration
     Darwin:
       allow_built_in: true
       log_mode: detail

Platform-Specific Roles
~~~~~~~~~~~~~~~~~~~~~~~

Some roles have platform-specific features:

.. code-block:: yaml

   users:
     - name: developer
       # Works on all platforms
       git:
         user_name: "Developer Name"
         user_email: "dev@company.com"

       # macOS-specific preferences
       Darwin:
         dock:
           tile_size: 48
           autohide: true
         finder:
           show_extensions: true
           show_hidden: true

Variable Organization
---------------------

Recommended Structure
~~~~~~~~~~~~~~~~~~~~~

Organize variables by concern:

.. code-block:: yaml

   # group_vars/all.yml

   # ========================================
   # Phase 1: Operating System Configuration
   # ========================================

   timezone: UTC

   firewall:
     enabled: true
     default_policy: deny
     allow_ssh: true

   fail2ban:
     enabled: true
     services:
       - sshd

   # ========================================
   # Phase 2: Software Package Management
   # ========================================

   manage_packages_all:
     Ubuntu: [git, curl, vim, htop, tmux]
     Darwin: [git, curl, vim, htop, tmux]

   apt_repositories_all:
     Ubuntu:
       - name: docker
         uris: "https://download.docker.com/linux/ubuntu"
         suites: "{{ ansible_distribution_release }}"
         components: "stable"
         signed_by: "https://download.docker.com/linux/ubuntu/gpg"

   # ========================================
   # Phase 3: User Configuration
   # ========================================

   users:
     - name: deploy
       git:
         user_name: "Deploy Bot"
         user_email: "deploy@example.com"

Variable Naming
~~~~~~~~~~~~~~~

The collection uses clear, descriptive variable names:

**Package Management:**

- ``manage_packages_all`` - Base packages
- ``manage_packages_group`` - Group packages
- ``manage_packages_host`` - Host packages

**Repository Management:**

- ``apt_repositories_all`` - Base APT repositories
- ``apt_repositories_group`` - Group repositories
- ``apt_repositories_host`` - Host repositories

**Feature Configuration:**

- ``firewall`` - Firewall configuration
- ``fail2ban`` - Intrusion prevention configuration
- ``users`` - User configuration list

Best Practices
--------------

1. Start with All Configuration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Define sensible defaults in ``group_vars/all.yml``:

.. code-block:: yaml

   # group_vars/all.yml
   manage_packages_all:
     Ubuntu: [git, curl, vim, htop, tmux]

   firewall:
     enabled: true
     default_policy: deny
     allow_ssh: true

2. Use Groups for Role-Based Config
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Organize hosts into groups and configure by role:

.. code-block:: yaml

   # group_vars/webservers.yml
   manage_packages_group:
     Ubuntu: [nginx, certbot]

   firewall:
     rules:
       - port: 80
         protocol: tcp
         rule: allow
       - port: 443
         protocol: tcp
         rule: allow

3. Reserve Host Vars for Exceptions
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Use ``host_vars`` only for host-specific overrides:

.. code-block:: yaml

   # host_vars/special-web.yml
   hostname: special-web.example.com

   manage_packages_host:
     Ubuntu: [varnish]  # Only this host needs varnish

4. Keep Secrets Separate
~~~~~~~~~~~~~~~~~~~~~~~~~

Use Ansible Vault for sensitive data:

.. code-block:: bash

   ansible-vault create group_vars/all/vault.yml

.. code-block:: yaml

   # group_vars/all/vault.yml (encrypted)
   vault_postgres_password: secret123

   # group_vars/all.yml (plaintext)
   postgres_password: "{{ vault_postgres_password }}"

5. Document Your Configuration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Add comments to explain configuration decisions:

.. code-block:: yaml

   # group_vars/webservers.yml

   # Web servers need nginx and certbot for Let's Encrypt SSL
   manage_packages_group:
     Ubuntu: [nginx, certbot]

   # Open HTTP and HTTPS for web traffic
   firewall:
     rules:
       - port: 80
         protocol: tcp
         rule: allow
       - port: 443
         protocol: tcp
         rule: allow

Multi-Environment Patterns
---------------------------

Separate Inventories
~~~~~~~~~~~~~~~~~~~~

Maintain separate inventories for each environment:

.. code-block:: text

   infrastructure/
   ├── inventory/
   │   ├── production/
   │   │   ├── hosts
   │   │   └── group_vars/
   │   │       └── all.yml
   │   ├── staging/
   │   │   ├── hosts
   │   │   └── group_vars/
   │   │       └── all.yml
   │   └── development/
   │       ├── hosts
   │       └── group_vars/
   │           └── all.yml
   └── playbooks/
       └── site.yml

Run against specific inventory:

.. code-block:: bash

   ansible-playbook -i inventory/production site.yml
   ansible-playbook -i inventory/staging site.yml

Environment-Specific Config
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Configure environment-specific settings:

.. code-block:: yaml

   # inventory/production/group_vars/all.yml
   environment: production

   firewall:
     enabled: true
     default_policy: deny

   fail2ban:
     enabled: true

.. code-block:: yaml

   # inventory/development/group_vars/all.yml
   environment: development

   firewall:
     enabled: false  # More permissive for development

   fail2ban:
     enabled: false

Common Patterns
---------------

Development Workstation
~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   # group_vars/workstations.yml
   manage_packages_group:
     Ubuntu: [build-essential, python3-dev, nodejs]
     Darwin: [python3, nodejs]

   users:
     - name: developer
       git:
         user_name: "{{ lookup('env', 'USER') }}"
         user_email: "{{ lookup('env', 'USER') }}@example.com"
         editor: "nvim"

       nodejs:
         packages: [typescript, eslint, prettier, "@vue/cli"]

       rust:
         packages: [ripgrep, bat, fd-find, cargo-watch]

       neovim:
         deploy_config: true

Web Server
~~~~~~~~~~

.. code-block:: yaml

   # group_vars/webservers.yml
   manage_packages_group:
     Ubuntu: [nginx, certbot, fail2ban]

   firewall:
     enabled: true
     rules:
       - port: 80
         protocol: tcp
         rule: allow
       - port: 443
         protocol: tcp
         rule: allow

   fail2ban:
     enabled: true
     services: [sshd, nginx-http-auth]

Database Server
~~~~~~~~~~~~~~~

.. code-block:: yaml

   # group_vars/databases.yml
   manage_packages_group:
     Ubuntu: [postgresql-14, redis-server]

   firewall:
     enabled: true
     rules:
       - port: 5432
         protocol: tcp
         rule: allow
         from: 10.0.1.0/24  # Application server subnet
       - port: 6379
         protocol: tcp
         rule: allow
         from: 10.0.1.0/24

See Also
--------

- :doc:`variables` - Variable system details
- :doc:`platform-support` - Platform-specific information
- :doc:`../reference/variables-reference` - Complete variable reference
- :doc:`../roles/index` - Role documentation
