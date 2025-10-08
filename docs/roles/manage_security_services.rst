manage_security_services
========================

Firewall and intrusion prevention configuration for Linux and macOS.

.. contents::
   :local:
   :depth: 2

Overview
--------

The ``manage_security_services`` role configures security services with platform-specific implementations:

- **Linux**: UFW (Uncomplicated Firewall) rules and fail2ban intrusion prevention
- **macOS**: Application Layer Firewall (ALF) configuration

Features
~~~~~~~~

**Linux (UFW + fail2ban):**

- Port-based firewall rules with comprehensive options
- Automatic SSH anti-lockout protection
- Intrusion detection and prevention via fail2ban
- Support for allow, deny, limit, and reject rules
- Source/destination IP filtering
- Rule comments for documentation

**macOS (Application Layer Firewall):**

- Application-based firewall control
- Stealth mode configuration
- Global blocking options
- Logging control

Platform Support
~~~~~~~~~~~~~~~~

- **Ubuntu** 22.04+, 24.04+
- **Debian** 12+, 13+
- **Arch Linux** (Rolling)
- **macOS** 13+ (Ventura)

Usage
-----

Basic Firewall Configuration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Simple firewall with common service ports:

.. code-block:: yaml

   - hosts: all
     become: true
     roles:
       - wolskies.infrastructure.manage_security_services
     vars:
       firewall:
         enabled: true
         rules:
           - rule: allow
             port: 22
             protocol: tcp
           - rule: allow
             port: 80,443
             protocol: tcp

       fail2ban:
         enabled: true
         maxretry: 3
         bantime: "1h"

Advanced Configuration
~~~~~~~~~~~~~~~~~~~~~~

Comprehensive security configuration with custom rules and jails:

.. code-block:: yaml

   firewall:
     enabled: true
     prevent_ssh_lockout: true
     default_policy:
       incoming: deny
       outgoing: allow
       routed: deny
     rules:
       - rule: allow
         port: 22
         protocol: tcp
         comment: "SSH access"
       - rule: allow
         source: 192.168.1.0/24
         port: 3000
         protocol: tcp
         comment: "Internal development server"
       - rule: allow
         port: 80,443
         protocol: tcp
         comment: "HTTP/HTTPS traffic"
       - rule: deny
         port: 23
         protocol: tcp
         comment: "Block telnet"
       - rule: limit
         port: 22
         protocol: tcp
         comment: "Rate limit SSH connections"

   fail2ban:
     enabled: true
     bantime: "10m"
     findtime: "10m"
     maxretry: 5
     destemail: "admin@example.com"
     sender: "fail2ban@example.com"
     action: "%(action_mwl)s"
     jails:
       - name: sshd
         enabled: true
         maxretry: 3
         logpath: /var/log/auth.log
       - name: nginx-http-auth
         enabled: true
         port: "http,https"
         logpath: /var/log/nginx/error.log
       - name: nginx-noscript
         enabled: true
         port: "http,https"
         logpath: /var/log/nginx/access.log

macOS Firewall Configuration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Application Layer Firewall for macOS:

.. code-block:: yaml

   firewall:
     enabled: true
     stealth_mode: true
     block_all: false
     logging: true
     allow_signed_applications: true

Variables
---------

Firewall Variables
~~~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 25 15 60

   * - Variable
     - Type
     - Description
   * - ``firewall.enabled``
     - boolean
     - Enable firewall service. Default: false
   * - ``firewall.prevent_ssh_lockout``
     - boolean
     - Automatically allow SSH to prevent lockout (Linux). Default: true
   * - ``firewall.default_policy.incoming``
     - string
     - Default policy for incoming traffic: "deny" or "allow" (Linux)
   * - ``firewall.default_policy.outgoing``
     - string
     - Default policy for outgoing traffic: "deny" or "allow" (Linux)
   * - ``firewall.default_policy.routed``
     - string
     - Default policy for routed traffic: "deny" or "allow" (Linux)
   * - ``firewall.rules``
     - list
     - Firewall rules (Linux only, see schema below)
   * - ``firewall.stealth_mode``
     - boolean
     - Don't respond to ping (macOS). Default: false
   * - ``firewall.block_all``
     - boolean
     - Block all incoming connections (macOS). Default: false
   * - ``firewall.logging``
     - boolean
     - Enable firewall logging (macOS). Default: false
   * - ``firewall.allow_signed_applications``
     - boolean
     - Automatically allow signed applications (macOS). Default: true

Firewall Rules Schema (Linux)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Each rule in ``firewall.rules`` is a dictionary:

.. list-table::
   :header-rows: 1
   :widths: 15 15 15 55

   * - Field
     - Type
     - Default
     - Description
   * - ``port``
     - int/string
     - Required
     - Port number or range (e.g., 22, "8080:8090", "80,443")
   * - ``protocol``
     - string
     - "tcp"
     - Protocol: "tcp", "udp", or "any"
   * - ``rule``
     - string
     - "allow"
     - Rule action: "allow", "deny", "limit", or "reject"
   * - ``source``
     - string
     - "any"
     - Source IP or CIDR (e.g., "192.168.1.0/24")
   * - ``destination``
     - string
     - "any"
     - Destination IP or CIDR
   * - ``direction``
     - string
     - "in"
     - Traffic direction: "in", "out", or "both"
   * - ``interface``
     - string
     - none
     - Network interface (e.g., "eth0", "wlan0")
   * - ``comment``
     - string
     - ""
     - Rule description

fail2ban Variables (Linux)
~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 25 15 60

   * - Variable
     - Type
     - Description
   * - ``fail2ban.enabled``
     - boolean
     - Enable fail2ban intrusion prevention. Default: false
   * - ``fail2ban.bantime``
     - string
     - Ban duration (e.g., "10m", "1h", "1d"). Default: "10m"
   * - ``fail2ban.findtime``
     - string
     - Time window for counting failures. Default: "10m"
   * - ``fail2ban.maxretry``
     - integer
     - Number of failures before ban. Default: 5
   * - ``fail2ban.destemail``
     - string
     - Email address for ban notifications
   * - ``fail2ban.sender``
     - string
     - Sender address for notifications
   * - ``fail2ban.action``
     - string
     - Default action for bans. Default: "%(action_)s"
   * - ``fail2ban.jails``
     - list
     - Jail configurations (see schema below)

fail2ban Jails Schema
~~~~~~~~~~~~~~~~~~~~~

Each jail in ``fail2ban.jails`` is a dictionary:

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
     - Jail name (e.g., "sshd", "apache-auth", "nginx-http-auth")
   * - ``enabled``
     - boolean
     - true
     - Whether this jail is active
   * - ``port``
     - string
     - varies
     - Port(s) to monitor (e.g., "ssh", "http,https", "22")
   * - ``filter``
     - string
     - name
     - Filter name (defaults to jail name)
   * - ``logpath``
     - string
     - Required
     - Log file path (e.g., "/var/log/auth.log")
   * - ``maxretry``
     - integer
     - inherit
     - Override global maxretry for this jail
   * - ``bantime``
     - string
     - inherit
     - Override global bantime for this jail
   * - ``findtime``
     - string
     - inherit
     - Override global findtime for this jail

Tags
----

Control which components run using tags:

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - Tag
     - Description
   * - ``firewall``
     - Complete firewall management
   * - ``firewall-rules``
     - Firewall rule application only
   * - ``firewall-services``
     - Firewall service state management only
   * - ``fail2ban``
     - Intrusion prevention service management
   * - ``security``
     - All security services (firewall + fail2ban)
   * - ``no-container``
     - Tasks requiring host capabilities (skip in containers)

Examples
--------

Skip fail2ban Configuration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   ansible-playbook --skip-tags fail2ban playbook.yml

Skip All Security Services
~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   ansible-playbook --skip-tags security playbook.yml

Web Server Security
~~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   - hosts: webservers
     become: true
     roles:
       - wolskies.infrastructure.manage_security_services
     vars:
       firewall:
         enabled: true
         prevent_ssh_lockout: true
         default_policy:
           incoming: deny
           outgoing: allow
         rules:
           - rule: allow
             port: 22
             protocol: tcp
             source: "10.0.0.0/8"
             comment: "SSH from internal network"
           - rule: allow
             port: 80,443
             protocol: tcp
             comment: "HTTP/HTTPS public traffic"

       fail2ban:
         enabled: true
         bantime: "1h"
         findtime: "10m"
         maxretry: 5
         jails:
           - name: sshd
             enabled: true
             maxretry: 3
           - name: nginx-http-auth
             enabled: true
             port: "http,https"
             logpath: /var/log/nginx/error.log
           - name: nginx-limit-req
             enabled: true
             port: "http,https"
             logpath: /var/log/nginx/error.log

Database Server Security
~~~~~~~~~~~~~~~~~~~~~~~~~

Restrict database access to specific networks:

.. code-block:: yaml

   - hosts: databases
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
           - rule: allow
             port: 22
             protocol: tcp
             source: "10.0.0.0/8"
             comment: "SSH from management network"
           - rule: allow
             port: 5432
             protocol: tcp
             source: "10.1.0.0/16"
             comment: "PostgreSQL from application network"
           - rule: deny
             port: 5432
             protocol: tcp
             comment: "Block PostgreSQL from elsewhere"

       fail2ban:
         enabled: true
         jails:
           - name: sshd
             enabled: true
             maxretry: 3
             bantime: "1h"

Development Workstation
~~~~~~~~~~~~~~~~~~~~~~~

More permissive rules for development:

.. code-block:: yaml

   - hosts: workstations
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
           - rule: allow
             port: 22
             protocol: tcp
           - rule: allow
             port: 3000:9999
             protocol: tcp
             comment: "Development server range"
           - rule: allow
             port: 5432,3306,6379,27017
             protocol: tcp
             comment: "Database development ports"

SSH Hardening with Port Knocking
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Use rate limiting to mitigate brute force attacks:

.. code-block:: yaml

   firewall:
     enabled: true
     rules:
       - rule: limit
         port: 22
         protocol: tcp
         comment: "Rate limit SSH (6 connections per 30 seconds)"

   fail2ban:
     enabled: true
     bantime: "24h"
     findtime: "10m"
     maxretry: 3
     jails:
       - name: sshd
         enabled: true
         maxretry: 3
         bantime: "24h"
       - name: sshd-ddos
         enabled: true
         port: "ssh"
         logpath: /var/log/auth.log
         maxretry: 10
         findtime: "2m"

Platform Differences
--------------------

Linux (UFW + fail2ban)
~~~~~~~~~~~~~~~~~~~~~~

**Firewall:**

- Port-based firewall rules with fine-grained control
- Supports IPv4 and IPv6
- SSH anti-lockout protection automatically detects and allows SSH port
- Default policies for incoming, outgoing, and routed traffic
- Rule actions: allow, deny, limit (rate limiting), reject (sends ICMP unreachable)

**fail2ban:**

- Monitors log files for suspicious activity
- Automatically bans IPs after repeated failures
- Extensive jail collection for common services
- Email notifications on bans
- Unban commands and persistent ban database

macOS (Application Layer Firewall)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Firewall:**

- Application-based, not port-based
- Controls which applications can accept incoming connections
- ``firewall.rules`` variable is ignored
- SSH access controlled via System Preferences → Sharing → Remote Login
- Stealth mode prevents responses to ping/probe attempts

**fail2ban:**

- Not supported (macOS has different security model)
- Use macOS-specific security tools instead

Limitations
-----------

**Container Environments:**

Firewall configuration requires host capabilities not available in containers. Use ``--skip-tags no-container`` when testing in containers.

**macOS:**

- No port-based firewall rules (application-based only)
- No fail2ban support
- Limited firewall configuration options

**UFW Limitations:**

- UFW rules are stateful by default
- Complex routing scenarios may require direct iptables/nftables configuration
- Application profiles are not managed by this role

Dependencies
------------

**Required:**

- ``community.general`` - UFW module
- ``ansible.posix`` - Service management

**System Packages (installed automatically):**

- ``ufw`` - Uncomplicated Firewall (Linux)
- ``fail2ban`` - Intrusion prevention (Linux)

Install Ansible dependencies:

.. code-block:: bash

   ansible-galaxy collection install -r requirements.yml

See Also
--------

- :doc:`os_configuration` - OS hardening and SSH security
- :doc:`manage_packages` - Package installation
- :doc:`/reference/variables-reference` - Complete variable reference
- :doc:`/testing/writing-tests` - Testing security services
