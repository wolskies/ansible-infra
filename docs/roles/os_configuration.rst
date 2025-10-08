os_configuration
================

Core operating system configuration for Ubuntu, Debian, Arch Linux, and macOS.

.. contents::
   :local:
   :depth: 2

Overview
--------

The ``os_configuration`` role manages fundamental operating system settings that form the foundation of system configuration. It handles hostname, timezone, locale, time synchronization, systemd services, kernel modules, security hardening, and platform-specific settings.

**This is typically the first role** to run in system configuration workflows, as it establishes the base system state that other roles depend on.

Features
~~~~~~~~

- **Hostname Management** - Set system hostname and update /etc/hosts
- **Time Configuration** - Timezone and NTP synchronization
- **Locale Settings** - System locale and language configuration (Linux)
- **Service Management** - Enable, disable, or mask systemd services (Linux)
- **Security Hardening** - OS and SSH hardening via devsec.hardening collection (Linux)
- **Kernel Configuration** - Load modules, set parameters, configure udev rules (Linux)
- **Journal Settings** - Configure systemd journal retention and size (Linux)
- **Package Manager Config** - APT/Pacman proxy and settings (Linux)
- **System Preferences** - Basic system settings (macOS)

Platform Support
~~~~~~~~~~~~~~~~

- **Ubuntu** 22.04+, 24.04+
- **Debian** 12+, 13+
- **Arch Linux** (Rolling)
- **macOS** 13+ (Ventura) - limited features

Usage
-----

Basic Configuration
~~~~~~~~~~~~~~~~~~~

Minimal configuration for hostname and timezone:

.. code-block:: yaml

   - hosts: all
     become: true
     roles:
       - wolskies.infrastructure.os_configuration
     vars:
       domain_timezone: "America/New_York"
       host_hostname: "{{ inventory_hostname }}"
       host_update_hosts: true

Advanced Configuration
~~~~~~~~~~~~~~~~~~~~~~

Complete configuration with all features:

.. code-block:: yaml

   # group_vars/all.yml - Domain-wide settings
   domain_timezone: "America/New_York"
   domain_locale: "en_US.UTF-8"
   domain_timesync:
     enabled: true
     ntp_servers:
       - 0.pool.ntp.org
       - 1.pool.ntp.org

   # host_vars/server01.yml - Host-specific settings
   host_hostname: "server01"
   host_update_hosts: true

   host_services:
     enable:
       - nginx
       - postgresql
     disable:
       - apache2
       - sendmail
     mask:
       - snapd

   host_modules:
     load:
       - br_netfilter
       - ip_vs
     blacklist:
       - pcspkr
       - nouveau

   host_sysctl:
     net.ipv4.ip_forward: 1
     net.ipv6.conf.all.forwarding: 1
     vm.swappiness: 10

   journal:
     configure: true
     max_size: "500M"
     max_retention: "30d"
     compress: true
     forward_to_syslog: false

Security Hardening
~~~~~~~~~~~~~~~~~~

Enable OS and SSH hardening using the devsec.hardening collection:

.. code-block:: yaml

   hardening:
     os_hardening_enabled: true
     ssh_hardening_enabled: true

     # devsec.hardening.os_hardening variables
     os_auth_pw_max_age: 90
     os_ctrlaltdel_disabled: true
     os_security_users_allow: []
     os_auth_timeout: 60
     os_security_kernel_enable_core_dump: false

     # devsec.hardening.ssh_hardening variables
     ssh_server_ports: ["22"]
     ssh_listen_to: ["0.0.0.0"]
     sftp_enabled: true
     ssh_client_alive_interval: 300
     ssh_max_auth_retries: 3
     ssh_permit_root_login: "no"
     ssh_password_authentication: false

All variables from `devsec.hardening.os_hardening <https://github.com/dev-sec/ansible-collection-hardening/tree/master/roles/os_hardening>`_ and `devsec.hardening.ssh_hardening <https://github.com/dev-sec/ansible-collection-hardening/tree/master/roles/ssh_hardening>`_ can be set directly under the ``hardening:`` key.

Variables
---------

Core Configuration
~~~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 25 15 60

   * - Variable
     - Type
     - Description
   * - ``domain_timezone``
     - string
     - System timezone in IANA format (e.g., "America/New_York", "Europe/London", "UTC")
   * - ``domain_locale``
     - string
     - System locale (e.g., "en_US.UTF-8"). Linux only. Default: "en_US.UTF-8"
   * - ``host_hostname``
     - string
     - System hostname. Typically set to ``{{ inventory_hostname }}``
   * - ``host_update_hosts``
     - boolean
     - Update /etc/hosts with hostname mapping. Default: false

Time Synchronization
~~~~~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 25 15 60

   * - Variable
     - Type
     - Description
   * - ``domain_timesync.enabled``
     - boolean
     - Enable NTP configuration. Default: false
   * - ``domain_timesync.ntp_servers``
     - list
     - List of NTP server addresses
   * - ``domain_timesync.fallback_servers``
     - list
     - Fallback NTP servers
   * - ``domain_timesync.timezone``
     - string
     - Alternative way to set timezone (use ``domain_timezone`` instead)

Service Management (Linux)
~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 25 15 60

   * - Variable
     - Type
     - Description
   * - ``host_services.enable``
     - list
     - Service names to enable and start
   * - ``host_services.disable``
     - list
     - Service names to disable and stop
   * - ``host_services.mask``
     - list
     - Service names to mask (prevent from starting)

Kernel Configuration (Linux)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 25 15 60

   * - Variable
     - Type
     - Description
   * - ``host_modules.load``
     - list
     - Kernel modules to load at boot
   * - ``host_modules.blacklist``
     - list
     - Kernel modules to blacklist
   * - ``host_sysctl``
     - dict
     - Sysctl parameters as key-value pairs
   * - ``host_udev_rules``
     - list
     - Custom udev rules (see examples below)

Security Hardening (Linux)
~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 25 15 60

   * - Variable
     - Type
     - Description
   * - ``hardening.os_hardening_enabled``
     - boolean
     - Enable OS hardening via devsec.hardening.os_hardening. Default: false
   * - ``hardening.ssh_hardening_enabled``
     - boolean
     - Enable SSH hardening via devsec.hardening.ssh_hardening. Default: false
   * - ``hardening.*``
     - various
     - All devsec.hardening variables can be set here

Journal Configuration (Linux)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 25 15 60

   * - Variable
     - Type
     - Description
   * - ``journal.configure``
     - boolean
     - Enable journal configuration. Default: false
   * - ``journal.max_size``
     - string
     - Maximum journal size (e.g., "500M", "1G")
   * - ``journal.max_retention``
     - string
     - Maximum retention time (e.g., "30d", "1week")
   * - ``journal.compress``
     - boolean
     - Enable journal compression. Default: true
   * - ``journal.forward_to_syslog``
     - boolean
     - Forward to syslog. Default: false

Package Manager Configuration (Linux)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 25 15 60

   * - Variable
     - Type
     - Description
   * - ``apt.proxy``
     - string
     - APT proxy URL (Ubuntu/Debian)
   * - ``apt.config``
     - dict
     - Additional APT configuration directives
   * - ``pacman.proxy``
     - string
     - Pacman proxy URL (Arch Linux)

Tags
----

Skip specific configuration areas using tags:

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - Tag
     - Configuration Area
   * - ``hostname``
     - Hostname and /etc/hosts management
   * - ``timezone``
     - Timezone configuration
   * - ``locale``
     - Locale/language settings
   * - ``ntp``
     - NTP time synchronization
   * - ``services``
     - Systemd service management
   * - ``modules``
     - Kernel module configuration
   * - ``sysctl``
     - Kernel parameter tuning
   * - ``security``
     - Security hardening (OS and SSH)
   * - ``journal``
     - Journal configuration
   * - ``apt``
     - APT configuration (Ubuntu/Debian)
   * - ``pacman``
     - Pacman configuration (Arch Linux)
   * - ``no-container``
     - Tasks requiring host capabilities (skip in containers)

Examples
--------

Skip Container-Incompatible Tasks
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

When running in Docker containers, skip tasks that require host capabilities:

.. code-block:: bash

   ansible-playbook --skip-tags no-container playbook.yml

Skip Security Hardening
~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   ansible-playbook --skip-tags security playbook.yml

Configure Only Timezone
~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   ansible-playbook --tags timezone playbook.yml

Web Server Configuration
~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   - hosts: webservers
     become: true
     roles:
       - wolskies.infrastructure.os_configuration
     vars:
       domain_timezone: "UTC"
       host_hostname: "{{ inventory_hostname }}"

       host_services:
         enable: [nginx, fail2ban]
         disable: [apache2]
         mask: [snapd]

       host_sysctl:
         net.ipv4.ip_forward: 0
         net.core.somaxconn: 1024
         net.ipv4.tcp_max_syn_backlog: 2048

       hardening:
         os_hardening_enabled: true
         ssh_hardening_enabled: true
         ssh_server_ports: ["2222"]
         ssh_permit_root_login: "no"

Database Server with Custom Kernel Tuning
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   - hosts: databases
     become: true
     roles:
       - wolskies.infrastructure.os_configuration
     vars:
       domain_timezone: "UTC"
       host_hostname: "{{ inventory_hostname }}"

       host_services:
         enable: [postgresql]

       host_sysctl:
         # Shared memory for PostgreSQL
         kernel.shmmax: 17179869184
         kernel.shmall: 4194304
         # Network tuning
         net.core.rmem_max: 134217728
         net.core.wmem_max: 134217728
         net.ipv4.tcp_rmem: "4096 87380 67108864"
         net.ipv4.tcp_wmem: "4096 65536 67108864"
         # Swap tuning
         vm.swappiness: 1
         vm.dirty_ratio: 15
         vm.dirty_background_ratio: 5

       journal:
         configure: true
         max_size: "1G"
         max_retention: "60d"

Router/Firewall Configuration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   - hosts: routers
     become: true
     roles:
       - wolskies.infrastructure.os_configuration
     vars:
       domain_timezone: "UTC"
       host_hostname: "{{ inventory_hostname }}"

       host_modules:
         load:
           - br_netfilter
           - ip_vs
           - ip_vs_rr
           - ip_vs_wrr
           - nf_conntrack

       host_sysctl:
         # IP forwarding
         net.ipv4.ip_forward: 1
         net.ipv6.conf.all.forwarding: 1
         # Disable ICMP redirects
         net.ipv4.conf.all.send_redirects: 0
         net.ipv4.conf.default.send_redirects: 0
         # Increase connection tracking
         net.netfilter.nf_conntrack_max: 262144

Custom Udev Rules
~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   host_udev_rules:
     - name: "99-usb-serial"
       content: |
         SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", SYMLINK+="ttyUSB-FTDI"
     - name: "99-network-interfaces"
       content: |
         SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="aa:bb:cc:dd:ee:ff", NAME="eth-external"

Dependencies
------------

**Required:**

- ``community.general`` - Ansible collection for various OS tasks

**Optional (for security hardening):**

- ``devsec.hardening.os_hardening`` - OS hardening role
- ``devsec.hardening.ssh_hardening`` - SSH hardening role

Install dependencies:

.. code-block:: bash

   ansible-galaxy collection install -r requirements.yml

Limitations
-----------

**Container Environments:**

Some tasks require host capabilities not available in containers:

- Hostname configuration
- Kernel module loading
- Sysctl parameters
- Journal configuration
- Service management (depending on container)

Use ``--skip-tags no-container`` when running in containers.

**macOS Support:**

macOS support is limited to basic features:

- Hostname configuration
- Timezone configuration
- System preferences

Locale, services, kernel modules, and security hardening are Linux-only.

See Also
--------

- :doc:`manage_packages` - Package installation and repository management
- :doc:`manage_security_services` - Firewall and fail2ban configuration
- :doc:`/reference/variables-reference` - Complete variable reference
- :doc:`/testing/writing-tests` - Testing os_configuration
