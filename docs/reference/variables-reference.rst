Variables Reference
===================

Complete variable interface documentation for the ``wolskies.infrastructure`` collection.

All variables are defined in ``defaults/main.yml`` and can be overridden at the inventory level (all/group/host).

.. contents:: Table of Contents
   :local:
   :depth: 2

Domain-Level Configuration
---------------------------

Variables that apply to entire domains or sets of hosts.

Domain Identity
~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 20 10 15 55

   * - Variable
     - Type
     - Default
     - Purpose
   * - ``domain_name``
     - string
     - ``""``
     - Organization domain name (RFC 1035 format, e.g., "example.com")
   * - ``domain_timezone``
     - string
     - ``""``
     - System timezone (IANA format, e.g., "America/New_York", "Europe/London")
   * - ``domain_locale``
     - string
     - ``"en_US.UTF-8"``
     - System locale (format: language_COUNTRY.encoding)
   * - ``domain_language``
     - string
     - ``"en_US.UTF-8"``
     - System language setting

Time Synchronization
~~~~~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 20 10 15 55

   * - Variable
     - Type
     - Default
     - Purpose
   * - ``domain_timesync.enabled``
     - boolean
     - ``true``
     - Enable systemd-timesyncd
   * - ``domain_timesync.servers``
     - list
     - ``[]``
     - NTP servers to use

**Schema:**

.. code-block:: yaml

   domain_timesync:
     enabled: true
     servers: []

Host-Level Configuration
-------------------------

Variables that apply to individual hosts.

Host Identity
~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 20 10 15 55

   * - Variable
     - Type
     - Default
     - Purpose
   * - ``host_hostname``
     - string
     - ``""``
     - System hostname (RFC 1123 format, alphanumeric + hyphens, max 253 chars)
   * - ``host_update_hosts``
     - boolean
     - ``true``
     - Update /etc/hosts with hostname entry

System Services
~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 20 10 15 55

   * - Variable
     - Type
     - Default
     - Purpose
   * - ``host_services.enable``
     - list
     - ``[]``
     - Services to enable via systemd
   * - ``host_services.disable``
     - list
     - ``[]``
     - Services to disable via systemd
   * - ``host_services.mask``
     - list
     - ``[]``
     - Services to mask via systemd

**Schema:**

.. code-block:: yaml

   host_services:
     enable: []
     disable: []
     mask: []

Kernel Modules
~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 20 10 15 55

   * - Variable
     - Type
     - Default
     - Purpose
   * - ``host_modules.load``
     - list
     - ``[]``
     - Kernel modules to load persistently
   * - ``host_modules.blacklist``
     - list
     - ``[]``
     - Kernel modules to blacklist

**Schema:**

.. code-block:: yaml

   host_modules:
     load: []
     blacklist: []

udev Rules
~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 20 15 65

   * - Variable
     - Type
     - Purpose
   * - ``host_udev_rules``
     - list of dicts
     - Custom udev rules definitions

**Schema:**

.. code-block:: yaml

   host_udev_rules:
     - name: string           # Rule name
       content: string        # Rule content
       priority: int          # Rule priority (e.g., 99)
       state: present|absent  # Rule state

**Example:**

.. code-block:: yaml

   host_udev_rules:
     - name: pico-usb
       content: 'SUBSYSTEM=="usb", ATTRS{idVendor}=="2e8a", ATTRS{idProduct}=="000c", MODE="0666"'
       priority: 99
       state: present

System Logging
--------------

systemd Journal
~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 20 10 15 55

   * - Variable
     - Type
     - Default
     - Purpose
   * - ``journal.configure``
     - boolean
     - ``false``
     - Enable journal configuration management
   * - ``journal.max_size``
     - string
     - ``"500M"``
     - Maximum journal size
   * - ``journal.max_retention``
     - string
     - ``"30d"``
     - Maximum retention period
   * - ``journal.forward_to_syslog``
     - boolean
     - ``false``
     - Forward logs to syslog
   * - ``journal.compress``
     - boolean
     - ``true``
     - Compress journal files

**Schema:**

.. code-block:: yaml

   journal:
     configure: false
     max_size: "500M"
     max_retention: "30d"
     forward_to_syslog: false
     compress: true

rsyslog
~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 20 10 15 55

   * - Variable
     - Type
     - Default
     - Purpose
   * - ``rsyslog.enabled``
     - boolean
     - ``false``
     - Enable rsyslog remote logging
   * - ``rsyslog.remote_host``
     - string
     - ``""``
     - Remote syslog server
   * - ``rsyslog.remote_port``
     - int
     - ``514``
     - Remote syslog port
   * - ``rsyslog.protocol``
     - string
     - ``"udp"``
     - Protocol (udp/tcp)

**Schema:**

.. code-block:: yaml

   rsyslog:
     enabled: false
     remote_host: ""
     remote_port: 514
     protocol: "udp"

Security Hardening
------------------

.. note::
   The ``hardening.*`` variables are pass-through configuration for external roles
   (``devsec.hardening.os_hardening`` and ``devsec.hardening.ssh_hardening``). These
   represent desired security posture rather than discoverable system state.

.. list-table::
   :header-rows: 1
   :widths: 25 10 15 50

   * - Variable
     - Type
     - Default
     - Purpose
   * - ``hardening.os_hardening_enabled``
     - boolean
     - ``false``
     - Enable devsec.hardening.os_hardening role
   * - ``hardening.ssh_hardening_enabled``
     - boolean
     - ``false``
     - Enable devsec.hardening.ssh_hardening role

Package Management
------------------

APT (Debian/Ubuntu)
~~~~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 25 10 15 50

   * - Variable
     - Type
     - Default
     - Purpose
   * - ``apt.proxy``
     - string
     - ``""``
     - APT proxy server URL
   * - ``apt.no_recommends``
     - boolean
     - ``false``
     - Don't install recommended packages
   * - ``apt.unattended_upgrades.enabled``
     - boolean
     - ``false``
     - Enable unattended-upgrades
   * - ``apt.system_upgrade.enable``
     - boolean
     - ``false``
     - Enable system upgrades
   * - ``apt.system_upgrade.type``
     - string
     - ``"safe"``
     - Upgrade type (safe/full)

**Schema:**

.. code-block:: yaml

   apt:
     proxy: ""
     no_recommends: false
     unattended_upgrades:
       enabled: false
     system_upgrade:
       enable: false
       type: "safe"

APT Repositories
~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 30 15 55

   * - Variable
     - Type
     - Purpose
   * - ``apt_repositories_all``
     - dict
     - Repositories for all hosts
   * - ``apt_repositories_group``
     - dict
     - Repositories for group hosts
   * - ``apt_repositories_host``
     - dict
     - Repositories for specific hosts

**Schema:**

.. code-block:: yaml

   apt_repositories_host:
     Ubuntu:
       - name: string              # Repository name
         types: [deb]              # Repository types
         uris: string              # Repository URI
         suites: string            # Distribution suite
         components: string        # Repository components
         signed_by: string         # GPG key URL

**Example:**

.. code-block:: yaml

   apt_repositories_host:
     Ubuntu:
       - name: docker
         types: [deb]
         uris: "https://download.docker.com/linux/ubuntu"
         suites: "{{ ansible_distribution_release }}"
         components: "stable"
         signed_by: "https://download.docker.com/linux/ubuntu/gpg"

Pacman (Arch Linux)
~~~~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 25 10 15 50

   * - Variable
     - Type
     - Default
     - Purpose
   * - ``pacman.proxy``
     - string
     - ``""``
     - Pacman proxy server
   * - ``pacman.no_confirm``
     - boolean
     - ``false``
     - Skip confirmation prompts
   * - ``pacman.multilib.enabled``
     - boolean
     - ``false``
     - Enable multilib repository
   * - ``pacman.enable_aur``
     - boolean
     - ``true``
     - Enable AUR support

**Schema:**

.. code-block:: yaml

   pacman:
     proxy: ""
     no_confirm: false
     multilib:
       enabled: false
     enable_aur: true

Homebrew (macOS)
~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 25 10 15 50

   * - Variable
     - Type
     - Default
     - Purpose
   * - ``homebrew.cleanup_cache``
     - boolean
     - ``true``
     - Clean up Homebrew cache
   * - ``homebrew.taps``
     - list
     - ``[]``
     - Homebrew taps to enable

**Schema:**

.. code-block:: yaml

   homebrew:
     cleanup_cache: true
     taps: []

Hierarchical Package Management
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 30 15 55

   * - Variable
     - Type
     - Purpose
   * - ``manage_packages_all``
     - dict
     - Packages for all hosts (by OS)
   * - ``manage_packages_group``
     - dict
     - Packages for group hosts (by OS)
   * - ``manage_packages_host``
     - dict
     - Packages for specific hosts (by OS)
   * - ``manage_casks``
     - dict
     - macOS Homebrew casks (by OS)

**Schema:**

.. code-block:: yaml

   manage_packages_all:
     Ubuntu:
       - name: string
         state: present|absent  # Optional, default: present
     Debian:
       - name: string
     Archlinux:
       - name: string
     MacOSX:
       - name: string

**Example:**

.. code-block:: yaml

   manage_packages_all:
     Ubuntu:
       - name: git
       - name: curl
       - name: vim
     Archlinux:
       - name: git
       - name: curl

   manage_packages_host:
     Ubuntu:
       - name: redis-server
       - name: telnet
         state: absent

Snap Packages
~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 30 10 15 45

   * - Variable
     - Type
     - Default
     - Purpose
   * - ``snap.remove_completely``
     - boolean
     - ``false``
     - Remove snapd completely
   * - ``snap.packages.install``
     - list
     - ``[]``
     - Snap packages to install
   * - ``snap.packages.remove``
     - list
     - ``[]``
     - Snap packages to remove

**Schema:**

.. code-block:: yaml

   snap:
     remove_completely: false
     packages:
       install: []
       remove: []

Flatpak Packages
~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 30 10 15 45

   * - Variable
     - Type
     - Default
     - Purpose
   * - ``flatpak.enabled``
     - boolean
     - ``false``
     - Enable Flatpak management
   * - ``flatpak.remotes``
     - list
     - ``[]``
     - Flatpak remotes to add
   * - ``flatpak.packages.install``
     - list
     - ``[]``
     - Flatpak packages to install
   * - ``flatpak.packages.remove``
     - list
     - ``[]``
     - Flatpak packages to remove

**Schema:**

.. code-block:: yaml

   flatpak:
     enabled: false
     remotes: []
     packages:
       install: []
       remove: []

User Configuration
------------------

.. list-table::
   :header-rows: 1
   :widths: 20 20 60

   * - Variable
     - Type
     - Purpose
   * - ``users``
     - list of dicts
     - User configurations including development tools, dotfiles, and platform preferences

**Schema:**

.. code-block:: yaml

   users:
     - name: string                    # Required: Existing username
       shell: string                   # Optional: User shell (Linux only)
       git:                            # Optional: Git configuration
         user_name: string
         user_email: string
         editor: string
       nodejs:                         # Optional: Node.js packages
         packages: [string, ...]
       rust:                           # Optional: Rust packages
         packages: [string, ...]
       go:                             # Optional: Go packages
         packages: [string, ...]
       neovim:                         # Optional: Neovim installation
         enabled: boolean
       terminal_entries: [string, ...] # Optional: Terminal emulator configs (alacritty, kitty, wezterm)
       dotfiles:                       # Optional: Dotfiles repository
         enable: boolean
         repository: string
         dest: string
         branch: string
         disable_clone: boolean
       Darwin:                         # Optional: macOS-specific preferences
         dock:
           tile_size: int
           autohide: boolean
           minimize_to_application: boolean
           show_recents: boolean
         finder:
           show_extensions: boolean
           show_hidden: boolean
           show_pathbar: boolean
           show_statusbar: boolean
           show_external_drives: boolean
           show_removable_media: boolean
           show_posix_path: boolean
         screenshots:
           directory: string
           format: string
         iterm2:
           prompt_on_quit: boolean

**Example:**

.. code-block:: yaml

   users:
     - name: developer
       shell: /bin/bash
       git:
         user_name: "John Doe"
         user_email: "john@example.com"
         editor: "nvim"
       nodejs:
         packages: [eslint, prettier, typescript]
       rust:
         packages: [cargo-watch, ripgrep]
       go:
         packages: [github.com/golangci/golangci-lint/cmd/golangci-lint]
       neovim:
         enabled: true
       terminal_entries: [alacritty, kitty]
       dotfiles:
         enable: true
         repository: "https://github.com/user/dotfiles.git"
         dest: ".dotfiles"
         branch: "main"
       Darwin:
         dock:
           tile_size: 48
           autohide: true
           show_recents: false
         finder:
           show_extensions: true
           show_hidden: true
           show_pathbar: true
         screenshots:
           directory: "Screenshots"
           format: "png"

Security Services
-----------------

Firewall (ufw)
~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 30 10 15 45

   * - Variable
     - Type
     - Default
     - Purpose
   * - ``firewall.enabled``
     - boolean
     - ``false``
     - Enable firewall (ufw)
   * - ``firewall.prevent_ssh_lockout``
     - boolean
     - ``true``
     - Automatically allow SSH
   * - ``firewall.stealth_mode``
     - boolean
     - ``false``
     - Enable stealth mode (macOS)
   * - ``firewall.block_all``
     - boolean
     - ``false``
     - Block all incoming by default
   * - ``firewall.logging``
     - boolean
     - ``false``
     - Enable firewall logging
   * - ``firewall.rules``
     - list of dicts
     - ``[]``
     - Firewall rules

**Schema:**

.. code-block:: yaml

   firewall:
     enabled: false
     prevent_ssh_lockout: true
     stealth_mode: false
     block_all: false
     logging: false
     rules:
       - rule: allow|deny
         port: int
         protocol: tcp|udp
         source: string  # Optional: CIDR or IP

**Example:**

.. code-block:: yaml

   firewall:
     enabled: true
     rules:
       - rule: allow
         port: 80
         protocol: tcp
       - rule: allow
         source: 192.168.1.0/24
         port: 3000
         protocol: tcp

Fail2ban
~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 25 10 15 50

   * - Variable
     - Type
     - Default
     - Purpose
   * - ``fail2ban.enabled``
     - boolean
     - ``false``
     - Enable fail2ban
   * - ``fail2ban.bantime``
     - string
     - ``"1h"``
     - Ban duration
   * - ``fail2ban.findtime``
     - string
     - ``"10m"``
     - Time window for max retries
   * - ``fail2ban.maxretry``
     - int
     - ``5``
     - Max retries before ban
   * - ``fail2ban.jails``
     - list of dicts
     - See below
     - Fail2ban jail configurations

**Schema:**

.. code-block:: yaml

   fail2ban:
     enabled: false
     bantime: "1h"
     findtime: "10m"
     maxretry: 5
     jails:
       - name: string
         enabled: boolean
         maxretry: int
         bantime: string
         findtime: string
         logpath: string

**Default Jail:**

.. code-block:: yaml

   fail2ban:
     jails:
       - name: sshd
         enabled: true
         maxretry: 5
         bantime: "1h"
         findtime: "10m"
         logpath: /var/log/auth.log

macOS-Specific Configuration
-----------------------------

System Updates
~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 30 10 15 45

   * - Variable
     - Type
     - Default
     - Purpose
   * - ``macosx.updates.auto_check``
     - boolean
     - ``true``
     - Automatically check for updates
   * - ``macosx.updates.auto_download``
     - boolean
     - ``true``
     - Automatically download updates

Security
~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 30 10 15 45

   * - Variable
     - Type
     - Default
     - Purpose
   * - ``macosx.gatekeeper.enabled``
     - boolean
     - ``true``
     - Enable Gatekeeper

System Preferences
~~~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 30 10 15 45

   * - Variable
     - Type
     - Default
     - Purpose
   * - ``macosx.system_preferences.natural_scroll``
     - boolean
     - ``true``
     - Enable natural scrolling
   * - ``macosx.system_preferences.measurement_units``
     - string
     - ``"Inches"``
     - Measurement units
   * - ``macosx.system_preferences.use_metric``
     - boolean
     - ``false``
     - Use metric system
   * - ``macosx.system_preferences.show_all_extensions``
     - boolean
     - ``false``
     - Show all file extensions

Network
~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 30 10 15 45

   * - Variable
     - Type
     - Default
     - Purpose
   * - ``macosx.airdrop.ethernet_enabled``
     - boolean
     - ``false``
     - Enable AirDrop over Ethernet

**Complete Schema:**

.. code-block:: yaml

   macosx:
     updates:
       auto_check: true
       auto_download: true
     gatekeeper:
       enabled: true
     system_preferences:
       natural_scroll: true
       measurement_units: "Inches"
       use_metric: false
       show_all_extensions: false
     airdrop:
       ethernet_enabled: false

Variable Summary
----------------

.. list-table:: Variables by Category
   :header-rows: 1
   :widths: 40 60

   * - Category
     - Description
   * - **Domain-Level (4 variables)**
     - Domain identity (name, timezone, locale, language), Time synchronization
   * - **Host-Level (4 variable groups)**
     - Host identity (hostname, hosts file), System services (enable/disable/mask), Kernel modules (load/blacklist), udev rules
   * - **System Logging (2 variable groups)**
     - systemd journal configuration, rsyslog remote logging
   * - **Security Hardening (2 variables)**
     - OS/SSH hardening enable flags (devsec.hardening pass-through)
   * - **Package Management (9 variable groups)**
     - APT, Pacman, Homebrew configuration and repositories; Hierarchical packages; Snap/Flatpak
   * - **User Configuration (1 variable)**
     - Per-user settings (shell, git, languages, dotfiles, terminal, macOS preferences)
   * - **Security Services (2 variable groups)**
     - Firewall (ufw) with rules, Fail2ban with jails
   * - **macOS-Specific (4 variable groups)**
     - System updates, Gatekeeper, System preferences, AirDrop

**Totals:**

- **Top-level variables:** 29
- **Nested configuration groups:** ~35
- **Total configurable parameters:** ~100+

Key Notes
---------

1. **Hierarchical Variables**: Package management uses a three-tier hierarchy (all/group/host) for flexibility
2. **OS-Specific**: Some variables only apply to specific operating systems (apt → Debian/Ubuntu, pacman → Arch, homebrew/Darwin → macOS)
3. **Integration Variables**: ``hardening.*`` variables pass through to external roles (devsec.hardening collection). Only the enable flags are documented here; pass-through configuration options are outside discovery scope.
4. **Complex Schemas**: Several variables accept complex nested structures (users with Darwin sub-config, firewall rules, repositories, udev rules)
5. **Empty Defaults**: Most optional features default to disabled/empty to avoid unintended configuration changes
6. **User Darwin Configuration**: The ``users`` variable includes extensive macOS-specific configuration options for dock, finder, screenshots, and iterm2 preferences
