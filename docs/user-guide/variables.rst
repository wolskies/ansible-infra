Variables
=========

Understanding the collection's variable system.

.. contents::
   :local::
   :depth: 2

Overview
--------

The ``wolskies.infrastructure`` collection uses a structured variable system designed for flexibility and maintainability. Variables follow clear naming conventions and support hierarchical configuration across multiple layers.

**Key Concepts:**

- **Hierarchical Merging** - Variables merge across all/group/host layers
- **OS Family Keys** - Platform-specific configuration with consistent keys
- **Layered Configuration** - Define base, group, and host-specific settings
- **Clear Naming** - Descriptive variable names indicate purpose and scope

Variable Naming Conventions
----------------------------

Hierarchical Package Variables
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Package management variables use a suffix pattern to indicate scope:

.. list-table::
   :header-rows: 1
   :widths: 40 60

   * - Variable Name
     - Scope
   * - ``manage_packages_all``
     - Base packages for all hosts (``group_vars/all.yml``)
   * - ``manage_packages_group``
     - Group-specific packages (``group_vars/<group>.yml``)
   * - ``manage_packages_host``
     - Host-specific packages (``host_vars/<host>.yml``)

**Example:**

.. code-block:: yaml

   # group_vars/all.yml
   manage_packages_all:
     Ubuntu: [git, curl, vim]

   # group_vars/webservers.yml
   manage_packages_group:
     Ubuntu: [nginx, certbot]

   # host_vars/web01.yml
   manage_packages_host:
     Ubuntu: [memcached]

   # Final result for web01: [git, curl, vim, nginx, certbot, memcached]

Repository Variables
~~~~~~~~~~~~~~~~~~~~

Repository management follows the same pattern:

.. list-table::
   :header-rows: 1
   :widths: 40 60

   * - Variable Name
     - Scope
   * - ``apt_repositories_all``
     - Base repositories for all hosts
   * - ``apt_repositories_group``
     - Group-specific repositories
   * - ``apt_repositories_host``
     - Host-specific repositories

**Example:**

.. code-block:: yaml

   # group_vars/all.yml
   apt_repositories_all:
     Ubuntu:
       - name: docker
         uris: "https://download.docker.com/linux/ubuntu"
         suites: "{{ ansible_distribution_release }}"
         components: "stable"
         signed_by: "https://download.docker.com/linux/ubuntu/gpg"

Feature Configuration
~~~~~~~~~~~~~~~~~~~~~

Non-hierarchical configuration uses descriptive names:

- ``firewall`` - Firewall configuration
- ``fail2ban`` - Intrusion prevention
- ``users`` - User configuration list
- ``hostname`` - System hostname
- ``timezone`` - System timezone

OS Family Keys
--------------

Platform Identification
~~~~~~~~~~~~~~~~~~~~~~~

The collection uses OS family keys to target specific platforms:

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
     - Arch Linux (note the capitalization)
   * - ``Darwin``
     - macOS (all versions)

**Important Notes:**

- Use ``Archlinux`` (capital A, lowercase linux) - not ``ArchLinux`` or ``arch``
- Use ``Darwin`` - not ``macOS``, ``MacOS``, or ``macos``
- Keys are case-sensitive

Cross-Platform Configuration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Define configuration for multiple platforms:

.. code-block:: yaml

   manage_packages_all:
     Ubuntu:
       - git
       - curl
       - build-essential

     Debian:
       - git
       - curl
       - build-essential

     Archlinux:
       - git
       - curl
       - base-devel

     Darwin:
       - git
       - curl

The role automatically selects the correct platform configuration based on ``ansible_os_family``.

Platform-Specific Packages
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Different platforms may require different package names:

.. code-block:: yaml

   manage_packages_all:
     # Ubuntu/Debian use 'python3-pip'
     Ubuntu: [python3, python3-pip, python3-venv]
     Debian: [python3, python3-pip, python3-venv]

     # Arch uses 'python-pip'
     Archlinux: [python, python-pip]

     # macOS Homebrew uses 'python@3'
     Darwin: [python@3]

Variable Hierarchies
--------------------

How Hierarchies Work
~~~~~~~~~~~~~~~~~~~~

The collection implements hierarchical variable merging for package and repository management:

**Merge Order:**

1. ``*_all`` variables (base layer)
2. ``*_group`` variables (group layer)
3. ``*_host`` variables (host layer)

All three layers are merged together, creating a combined list.

**Non-hierarchical Variables:**

Other variables (``firewall``, ``hostname``, etc.) use standard Ansible variable precedence where host_vars override group_vars override all.

Merge Example
~~~~~~~~~~~~~

Complete example showing how variables merge:

.. code-block:: yaml

   # group_vars/all.yml
   manage_packages_all:
     Ubuntu:
       - git      # ← Layer 1
       - curl
       - vim

   # group_vars/webservers.yml
   manage_packages_group:
     Ubuntu:
       - nginx    # ← Layer 2
       - certbot

   # host_vars/web01.yml
   manage_packages_host:
     Ubuntu:
       - memcached  # ← Layer 3

   # Final package list for web01:
   # [git, curl, vim, nginx, certbot, memcached]

Override Example
~~~~~~~~~~~~~~~~

Non-hierarchical variables use replacement, not merging:

.. code-block:: yaml

   # group_vars/all.yml
   timezone: UTC

   hostname: "{{ inventory_hostname }}"

   # host_vars/special-host.yml
   timezone: America/New_York  # ← Replaces UTC
   hostname: special.example.com  # ← Replaces inventory_hostname

Common Variables
----------------

Phase 1: Operating System
~~~~~~~~~~~~~~~~~~~~~~~~~~

**System Configuration:**

.. code-block:: yaml

   # Hostname
   hostname: web-server-01

   # Timezone
   timezone: America/New_York

   # Locale (Linux only)
   locale:
     lang: en_US.UTF-8
     language: en_US:en
     lc_all: en_US.UTF-8

**Firewall (UFW on Linux):**

.. code-block:: yaml

   firewall:
     enabled: true
     default_policy: deny
     allow_ssh: true
     rules:
       - port: 80
         protocol: tcp
         rule: allow
       - port: 443
         protocol: tcp
         rule: allow

**Firewall (ALF on macOS):**

.. code-block:: yaml

   firewall:
     enabled: true
     Darwin:
       allow_built_in: true
       allow_signed: true
       stealth_mode: false
       log_mode: detail

**Fail2ban (Linux only):**

.. code-block:: yaml

   fail2ban:
     enabled: true
     services:
       - sshd
       - nginx-http-auth

**APT Configuration (Ubuntu/Debian):**

.. code-block:: yaml

   apt:
     proxy: "http://apt-proxy.example.com:3142"
     unattended_upgrades:
       enabled: true
       auto_reboot: false
       auto_reboot_time: "03:00"

**Pacman Configuration (Arch Linux):**

.. code-block:: yaml

   pacman:
     enable_aur: true
     multilib:
       enabled: true

Phase 2: Software
~~~~~~~~~~~~~~~~~~

**Package Management:**

.. code-block:: yaml

   manage_packages_all:
     Ubuntu: [git, curl, vim, htop, tmux]
     Darwin: [git, curl, vim, htop, tmux]

   manage_packages_group:
     Ubuntu: [nginx, postgresql-14, certbot]

   manage_packages_host:
     Ubuntu: [memcached, varnish]

**APT Repositories:**

.. code-block:: yaml

   apt_repositories_all:
     Ubuntu:
       - name: docker
         uris: "https://download.docker.com/linux/ubuntu"
         suites: "{{ ansible_distribution_release }}"
         components: "stable"
         signed_by: "https://download.docker.com/linux/ubuntu/gpg"

**Homebrew (macOS):**

.. code-block:: yaml

   homebrew:
     taps:
       - homebrew/cask-fonts
       - homebrew/cask-versions
     cleanup_cache: true

   manage_casks:
     Darwin:
       - name: visual-studio-code
         state: present
       - name: docker
         state: present

**Snap Packages:**

.. code-block:: yaml

   snap_packages:
     - name: code
       state: present
       classic: true
     - name: discord
       state: present

   # Or remove Snap entirely
   snap:
     remove_completely: true

**Flatpak:**

.. code-block:: yaml

   flatpak:
     enabled: true
     flathub: true
     plugins:
       gnome: true
       plasma: false

   flatpak_packages:
     - name: org.mozilla.firefox
       state: present
     - name: com.spotify.Client
       state: present

Phase 3: Users
~~~~~~~~~~~~~~

**User Configuration:**

.. code-block:: yaml

   users:
     - name: developer
       git:
         user_name: "Developer Name"
         user_email: "developer@company.com"
         editor: "nvim"

       nodejs:
         packages:
           - typescript
           - eslint
           - "@vue/cli"

       rust:
         packages:
           - ripgrep
           - bat
           - fd-find

       go:
         packages:
           - github.com/jesseduffield/lazygit@latest
           - github.com/charmbracelet/glow@latest

       neovim:
         deploy_config: true

       terminal_config:
         install_terminfo:
           - alacritty
           - kitty

       dotfiles:
         enable: true
         repository: "https://github.com/developer/dotfiles"
         dest: ".dotfiles"
         stow_packages:
           - bash
           - vim
           - tmux

       Darwin:
         dock:
           tile_size: 48
           autohide: true
         finder:
           show_extensions: true
           show_hidden: true

Variable Precedence
-------------------

Ansible Variable Precedence
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The collection follows Ansible's standard variable precedence rules. From lowest to highest priority:

1. role defaults (``defaults/main.yml``)
2. inventory file or script group vars
3. inventory ``group_vars/all``
4. playbook ``group_vars/all``
5. inventory ``group_vars/*``
6. playbook ``group_vars/*``
7. inventory file or script host vars
8. inventory ``host_vars/*``
9. playbook ``host_vars/*``
10. host facts / cached set_facts
11. play vars
12. play vars_prompt
13. play vars_files
14. role vars (``vars/main.yml``)
15. block vars (only for tasks in block)
16. task vars (only for the task)
17. include_vars
18. set_facts / registered vars
19. role (and include_role) params
20. include params
21. extra vars (``-e`` on command line) - **always win**

**Practical Impact:**

- ``group_vars/all.yml`` provides base configuration
- ``group_vars/<group>.yml`` adds group-specific configuration
- ``host_vars/<host>.yml`` overrides for specific hosts
- ``-e`` command-line variables override everything

Hierarchical vs Standard Precedence
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Hierarchical Variables (merged):**

- ``manage_packages_all`` / ``_group`` / ``_host``
- ``apt_repositories_all`` / ``_group`` / ``_host``

These variables are merged together, combining all layers.

**Standard Precedence (replaced):**

- ``firewall``
- ``fail2ban``
- ``hostname``
- ``timezone``
- ``users``

These variables use standard Ansible precedence (later values replace earlier values).

Best Practices
--------------

1. Use OS Family Keys Consistently
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Always define configuration for all target platforms:

.. code-block:: yaml

   manage_packages_all:
     Ubuntu: [git, curl, vim]
     Debian: [git, curl, vim]
     Archlinux: [git, curl, vim]
     Darwin: [git, curl, vim]

2. Leverage Hierarchical Variables
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Use the three-layer system for flexible configuration:

.. code-block:: yaml

   # Base packages for all hosts
   manage_packages_all:
     Ubuntu: [git, curl, vim]

   # Additional packages for group
   manage_packages_group:
     Ubuntu: [nginx, certbot]

   # Host-specific additions
   manage_packages_host:
     Ubuntu: [varnish]

3. Document Complex Configuration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Add comments to explain non-obvious choices:

.. code-block:: yaml

   # Web servers need certbot for Let's Encrypt SSL certificates
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

4. Use YAML Anchors for Repetition
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Reduce repetition with YAML anchors:

.. code-block:: yaml

   base_packages: &base_packages
     - git
     - curl
     - vim
     - htop
     - tmux

   manage_packages_all:
     Ubuntu: *base_packages
     Debian: *base_packages
     Archlinux: *base_packages
     Darwin: *base_packages

5. Separate Secrets
~~~~~~~~~~~~~~~~~~~

Use Ansible Vault for sensitive data:

.. code-block:: yaml

   # group_vars/all/vault.yml (encrypted)
   vault_database_password: secret123

   # group_vars/all.yml (plaintext)
   database_password: "{{ vault_database_password }}"

Variable Reference
------------------

For complete variable documentation including all options and defaults, see:

- :doc:`../reference/variables-reference` - Complete variable reference
- :doc:`../roles/index` - Individual role documentation
- :doc:`configuration` - Configuration strategies

Examples
--------

Minimal Configuration
~~~~~~~~~~~~~~~~~~~~~

Minimal viable configuration:

.. code-block:: yaml

   # group_vars/all.yml
   manage_packages_all:
     Ubuntu: [git, vim]

   timezone: UTC

Development Workstation
~~~~~~~~~~~~~~~~~~~~~~~

Complete workstation setup:

.. code-block:: yaml

   # group_vars/workstations.yml
   manage_packages_group:
     Ubuntu: [build-essential, python3-dev, nodejs]
     Darwin: [python3, nodejs]

   users:
     - name: developer
       git:
         user_name: "{{ lookup('env', 'USER') }}"
         user_email: "{{ lookup('env', 'USER') }}@company.com"
         editor: "nvim"

       nodejs:
         packages: [typescript, eslint, prettier]

       rust:
         packages: [ripgrep, bat, fd-find]

       neovim:
         deploy_config: true

Production Server
~~~~~~~~~~~~~~~~~

Hardened production server:

.. code-block:: yaml

   # group_vars/production.yml
   timezone: UTC

   firewall:
     enabled: true
     default_policy: deny
     allow_ssh: true
     rules:
       - port: 80
         protocol: tcp
         rule: allow
       - port: 443
         protocol: tcp
         rule: allow

   fail2ban:
     enabled: true
     services:
       - sshd
       - nginx-http-auth

   manage_packages_group:
     Ubuntu:
       - nginx
       - postgresql-14
       - certbot
       - fail2ban

See Also
--------

- :doc:`configuration` - Configuration strategies
- :doc:`platform-support` - Platform-specific information
- :doc:`../reference/variables-reference` - Complete variable reference
- :doc:`../roles/index` - Role documentation
