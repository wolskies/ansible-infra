# Software Requirements Document (SRD)

## wolskies.infrastructure Ansible Collection

**Document Version:** 1.0
**Collection Version:** 1.2.0 (Target)
**Last Updated:** September 21, 2025
**Status:** Draft

---

## Table of Contents

1. [Collection Overview](#1-collection-overview)
2. [Collection-Wide Requirements](#2-collection-wide-requirements)
3. [Role Requirements](#3-role-requirements)
   - [3.1 os_configuration](#31-os_configuration)
   - [3.2 manage_security_services](#32-manage_security_services)
   - [3.3 manage_packages](#33-manage_packages)
   - [3.4 manage_snap_packages](#34-manage_snap_packages)
   - [3.5 manage_flatpak](#35-manage_flatpak)
   - [3.6 configure_user](#36-configure_user)
   - [3.7 nodejs](#37-nodejs)
   - [3.8 rust](#38-rust)
   - [3.9 go](#39-go)
   - [3.10 neovim](#310-neovim)
   - [3.11 terminal_config](#311-terminal_config)
4. [Known Issues and Limitations](#4-known-issues-and-limitations)
5. [Future Requirements](#5-future-requirements)

---

## 1. Collection Overview

### 1.1 Purpose

The `wolskies.infrastructure` collection provides infrastructure management automation for cross-platform development and production environments. The collection focuses on configuration management, security hardening, and development environment setup.

### 1.2 Target Users

- **Primary**: Moderately experienced system administrators and DevOps engineers
- **Secondary**: Development teams requiring consistent environment setup
- **Design Philosophy**: No excessive warnings or defensive programming; users are expected to understand basic system administration concepts

### 1.3 Scope

- **In Scope**: OS configuration, package management, user management, security services, development environment setup
- **Out of Scope**: Application deployment, database administration, network infrastructure management

---

## 2. Collection-Wide Requirements

### 2.1 Supported Platforms

#### 2.1.1 Operating Systems

**REQ-INFRA-001**: The collection SHALL support the following operating systems:

| Platform   | Versions       | OS Family | Architecture |
| ---------- | -------------- | --------- | ------------ |
| Ubuntu     | 22.04+, 24.04+ | Debian    | amd64        |
| Debian     | 12+, 13+       | Debian    | amd64        |
| Arch Linux | Rolling        | Archlinux | amd64        |
| macOS      | 13+ (Ventura)  | Darwin    | amd64, arm64 |

#### 2.1.2 Software Environment

**Standards - Tested Software Versions**
The collection is developed and tested with:

- Ansible 2.17 (current stable)
- Python 3.11+ on control and managed nodes
- OpenSSH 8.4+ for remote management

**Standards - Expected Compatibility**
While not explicitly tested, the collection should work with:

- Ansible 2.15+ (uses no features newer than 2.15)
- Python 3.9+ (uses no features newer than 3.9)
- OpenSSH 8.0+ (uses standard SSH features)

### 2.2 Variable Standards

**Standards - Variable Precedence**
Standard Ansible 2.15+ variable precedence rules apply to all collection variables.

**Standards - Naming Conventions**

- **`domain_` prefix**: Variables typically applied at organizational/domain scope (e.g., `domain_timezone`)
- **`host_` prefix**: Variables that typically vary per host (e.g., `host_hostname`)
- **Role-specific variables**: No prefix, scoped to role context (e.g., `users`, `packages`)
- **Boolean variables**: Use `true`/`false`, never `yes`/`no` or `1`/`0`

**Standards - Configuration Management Behavior**

Collection variables follow standard Ansible configuration patterns:

- **Variable defined/non-empty**: Feature is configured/enabled, configuration files are created/updated
- **Variable undefined/empty**: Feature is left in current state (not modified)
- **Explicit removal**: Use role-specific removal mechanisms when cleanup is needed
- **Additive behavior**: Most features add to existing configuration rather than replacing it

This follows established Ansible conventions and prevents accidental removal of existing configurations.

**Standards - Variable Structure and Layering**

This collection uses standard Ansible variable precedence (host_vars > group_vars > role defaults) for configuration. Where layered configuration is needed (such as package management), roles implement explicit merging using the `combine` filter to ensure predictable, portable behavior.

For complex merging scenarios, roles use the `combine` filter with appropriate list merge strategies:

```yaml
# Example: Combining package lists from multiple inventory levels
- name: Combine packages from all inventory levels
  ansible.builtin.set_fact:
    _final_packages: >-
      {{
        (manage_packages_all | default({})) |
        combine(manage_packages_group | default({}), list_merge='append') |
        combine(manage_packages_host | default({}), list_merge='append')
      }}
```

This approach provides explicit control over merging behavior while maintaining compatibility with all Ansible versions and configurations.

**REQ-INFRA-002**: Any role using collection variables SHALL respect the defined schema to ensure interoperability.

**Standards - Role-Based Firewall Rule Contribution**

Roles within this collection MAY contribute firewall rules using the collection-wide `firewall.rules` variable through role defaults or vars. This enables service-specific roles (nginx, database, etc.) to declare their required firewall access.

**Interface Requirements:**

- Roles SHALL define firewall rules in `defaults/main.yml` or `vars/main.yml` using the `firewall.rules` array
- Rules SHALL follow the Firewall Rules Object Schema (see schema below)
- The `manage_security_services` role SHALL be executed last in playbooks to apply the complete firewall configuration
- Rules from all roles are combined using standard Ansible variable precedence before being applied to the firewall

**Example role contribution:**

```yaml
# roles/nginx/defaults/main.yml
firewall:
  rules:
    - rule: allow
      port: 80
      protocol: tcp
      comment: "HTTP"
    - rule: allow
      port: 443
      protocol: tcp
      comment: "HTTPS"
```

**Execution pattern in playbooks:**

```yaml
- name: Configure web servers
  hosts: webservers
  roles:
    - nginx # Contributes HTTP/HTTPS rules
    - ssl_certificates # May contribute additional rules
    - manage_security_services # MUST be last - applies complete ruleset
```

#### 2.2.1 Collection-Wide Variable Interface

| Variable                                        | Type                      | Default         | Description                                                                                              |
| ----------------------------------------------- | ------------------------- | --------------- | -------------------------------------------------------------------------------------------------------- |
| `domain_name`                                   | string                    | `""`            | Organization domain name (RFC 1035 format, e.g., "example.com")                                          |
| `domain_timezone`                               | string                    | `""`            | System timezone (IANA format, e.g., "America/New_York", "Europe/London")                                 |
| `domain_locale`                                 | string                    | `"en_US.UTF-8"` | System locale (format: language_COUNTRY.encoding, e.g., "en_US.UTF-8", "fr_FR.UTF-8")                    |
| `domain_language`                               | string                    | `"en_US.UTF-8"` | System language (locale format, e.g., "en_US.UTF-8", "de_DE.UTF-8")                                      |
| `host_hostname`                                 | string                    | `""`            | System hostname (RFC 1123 format, alphanumeric + hyphens, max 253 chars)                                 |
| `host_update_hosts`                             | boolean                   | `true`          | Update /etc/hosts with hostname entry                                                                    |
| `users`                                         | list[object]              | `[]`            | User account definitions (see schema below)                                                              |
| `packages`                                      | object                    | `{}`            | Package management definitions (see schema below)                                                        |
| `host_services.enable`                          | list[string]              | `[]`            | Systemd service names to enable (e.g., ["nginx", "postgresql"])                                          |
| `host_services.disable`                         | list[string]              | `[]`            | Systemd service names to disable (e.g., ["apache2", "sendmail"])                                         |
| `host_services.mask`                            | list[string]              | `[]`            | Systemd service names to mask (e.g., ["snapd", "telnet"])                                                |
| `host_modules.load`                             | list[string]              | `[]`            | Kernel modules to load persistently (e.g., ["br_netfilter", "overlay"])                                  |
| `host_modules.blacklist`                        | list[string]              | `[]`            | Kernel modules to blacklist (e.g., ["pcspkr", "snd_pcsp"])                                               |
| `host_udev.rules`                               | list[object]              | `[]`            | Custom udev rules definitions (see schema below)                                                         |
| `host_sysctl.parameters`                        | dict[string, string\|int] | `{}`            | Kernel parameter definitions (see schema below)                                                          |
| `domain_ntp.enabled`                            | boolean                   | `false`         | Enable NTP time synchronization configuration                                                            |
| `domain_ntp.servers`                            | list[string]              | `[]`            | NTP server hostnames/IPs (e.g., ["pool.ntp.org", "time.google.com"])                                     |
| `firewall.enabled`                              | boolean                   | `false`         | Enable firewall rule management                                                                          |
| `firewall.prevent_ssh_lockout`                  | boolean                   | `true`          | Automatically allow SSH during firewall configuration                                                    |
| `firewall.rules`                                | list[object]              | `[]`            | Firewall rule definitions (see schema below)                                                             |
| `host_security.hardening_enabled`               | boolean                   | `false`         | Enable devsec.hardening security baseline                                                                |
| `host_security.ssh_hardening_enabled`           | boolean                   | `false`         | Enable SSH-specific security hardening                                                                   |
| `apt.proxy`                                     | string                    | `""`            | APT proxy URL (format: http[s]://[user:pass@]host:port, e.g., "http://user:pass@proxy.company.com:8080") |
| `apt.no_recommends`                             | boolean                   | `false`         | Disable APT automatic installation of recommended and suggested packages                                 |
| `apt.unattended_upgrades.enabled`               | boolean                   | `false`         | Enable APT unattended security upgrades on Debian/Ubuntu systems                                         |
| `snap.remove_completely`                        | boolean                   | `false`         | Completely remove snapd system from Debian/Ubuntu systems (manage_snap_packages role)                    |
| `snap_packages`                                 | list[object]              | `[]`            | Snap package definitions (see schema below)                                                              |
| `flatpak.enabled`                               | boolean                   | `false`         | Enable flatpak runtime installation and repository management                                             |
| `flatpak.flathub`                               | boolean                   | `false`         | Enable Flathub repository as package source                                                              |
| `flatpak.method`                                | string                    | `"system"`      | Installation scope ("system" or "user") for flatpak packages                                             |
| `flatpak.user`                                  | string                    | `""`            | Target username for user-scope flatpak operations (ignored for system scope)                            |
| `flatpak.plugins.gnome`                         | boolean                   | `false`         | Install GNOME Software flatpak plugin for desktop integration                                            |
| `flatpak.plugins.plasma`                        | boolean                   | `false`         | Install Plasma Discover flatpak plugin for desktop integration                                           |
| `flatpak_packages`                              | list[object]              | `[]`            | Flatpak package definitions (see schema below)                                                           |
| `pacman.proxy`                                  | string                    | `""`            | Pacman proxy URL (format: http[s]://[user:pass@]host:port, e.g., "http://proxy.example.com:3128")        |
| `pacman.no_confirm`                             | boolean                   | `false`         | Enable Pacman NoConfirm option (skip confirmation prompts on Arch Linux systems)                         |
| `pacman.multilib.enabled`                       | boolean                   | `false`         | Enable Pacman multilib repository for 32-bit packages on Arch Linux systems                              |
| `macosx.updates.auto_check`                     | boolean                   | `true`          | Enable automatic checking for macOS software updates                                                     |
| `macosx.updates.auto_download`                  | boolean                   | `true`          | Enable automatic downloading of macOS software updates                                                   |
| `macosx.gatekeeper.enabled`                     | boolean                   | `true`          | Enable macOS Gatekeeper security feature (prevents unsigned application execution)                       |
| `macosx.system_preferences.natural_scroll`      | boolean                   | `true`          | Enable natural scroll direction (reverse scrolling) on macOS                                             |
| `macosx.system_preferences.measurement_units`   | string                    | `"Inches"`      | System measurement units ("Inches", "Centimeters")                                                       |
| `macosx.system_preferences.use_metric`          | boolean                   | `false`         | Use metric system for measurements and temperatures                                                      |
| `macosx.system_preferences.show_all_extensions` | boolean                   | `false`         | Show all file extensions in Finder                                                                       |
| `macosx.airdrop.ethernet_enabled`               | boolean                   | `false`         | Enable AirDrop over Ethernet interfaces (BrowseAllInterfaces setting)                                    |
| `fail2ban.enabled`                              | boolean                   | `false`         | Enable fail2ban intrusion prevention service on Linux systems                                            |
| `fail2ban.bantime`                              | string                    | `"10m"`         | Duration for which IP is banned (e.g., "10m", "1h", "1d")                                                |
| `fail2ban.findtime`                             | string                    | `"10m"`         | Time window for counting failures (e.g., "10m", "1h")                                                    |
| `fail2ban.maxretry`                             | integer                   | `5`             | Number of failures before IP is banned                                                                   |
| `fail2ban.jails`                                | list[object]              | `[]`            | Fail2ban jail configurations (see schema below)                                                          |
| `firewall.stealth_mode`                         | boolean                   | `false`         | Enable stealth mode on macOS Application Layer Firewall (don't respond to pings)                         |
| `firewall.block_all`                            | boolean                   | `false`         | Block all incoming connections on macOS (except essential services)                                      |
| `firewall.logging`                              | boolean                   | `false`         | Enable firewall logging on macOS Application Layer Firewall                                              |
| `apt.repositories.<OS_Family>`                  | list[object]              | `[]`            | APT repository definitions using deb822 format (see schema below)                                        |
| `apt.system_upgrade.enable`                     | boolean                   | `false`         | Enable APT system upgrades (security, dist-upgrade, etc.)                                                |
| `apt.system_upgrade.type`                       | string                    | `"safe"`        | APT upgrade type ("safe", "dist", "full", "yes")                                                         |
| `manage_casks.Darwin`                           | list[dict]                | `[]`            | macOS Homebrew cask specifications with name and optional state                                          |
| `manage_casks.Darwin[].name`                    | string                    | -               | Cask name (e.g., "google-chrome", "visual-studio-code")                                                  |
| `manage_casks.Darwin[].state`                   | string                    | `"present"`     | Cask state ("present" or "absent")                                                                       |
| `homebrew.taps`                                 | list[string]              | `[]`            | Homebrew tap repositories (e.g., ["homebrew/cask-fonts", "user/repo"])                                   |
| `homebrew.cleanup_cache`                        | boolean                   | `true`          | Clean Homebrew download cache after operations                                                           |
| `pacman.enable_aur`                             | boolean                   | `false`         | Enable AUR (Arch User Repository) package support with paru helper                                       |

**Users Object Schema:**

| Field              | Type         | Required | Default        | Description                                                                    |
| ------------------ | ------------ | -------- | -------------- | ------------------------------------------------------------------------------ |
| `name`             | string       | Yes      | -              | Username (alphanumeric + underscore/hyphen, max 32 chars)                      |
| `uid`              | integer      | No       | auto           | User ID (1000-65533 for regular users, <1000 for system)                       |
| `gid`              | integer      | No       | auto           | Primary group ID (matches uid by default)                                      |
| `groups`           | list[string] | No       | `[]`           | Secondary group names (e.g., ["docker", "sudo", "developers"])                 |
| `shell`            | string       | No       | system default | Login shell path (e.g., "/bin/bash", "/bin/zsh", "/bin/false")                 |
| `home`             | string       | No       | `/home/{name}` | Home directory absolute path (e.g., "/home/username", "/var/lib/service")      |
| `comment`          | string       | No       | `""`           | GECOS field description (e.g., "John Doe,,")                                   |
| `password`         | string       | No       | none           | Password (plaintext or SHA-512 hash starting with $6$)                         |
| `ssh_keys`         | list[string] | No       | `[]`           | SSH public key strings (full key content, one per list item)                   |
| `sudo.nopasswd`    | boolean      | No       | `false`        | Allow passwordless sudo access within sudo configuration object                |
| `state`            | enum         | No       | `"present"`    | User state ("present" or "absent")                                             |
| `create_home`      | boolean      | No       | `true`         | Create home directory if it doesn't exist                                      |
| `system`           | boolean      | No       | `false`        | System account (uid <1000, no home by default)                                 |
| `git.user_name`    | string       | No       | none           | Git global user.name setting (full name, e.g., "John Doe")                     |
| `git.user_email`   | string       | No       | none           | Git global user.email setting (email address, e.g., "john@example.com")        |
| `git.editor`       | string       | No       | none           | Git global core.editor setting (editor command, e.g., "vim", "code --wait")    |
| `nodejs.packages`  | list[string] | No       | `[]`           | npm package names to install globally (e.g., ["typescript", "@angular/cli"])   |
| `rust.packages`    | list[string] | No       | `[]`           | Cargo package names to install (e.g., ["ripgrep", "fd-find"])                  |
| `go.packages`      | list[string] | No       | `[]`           | Go package URLs to install (e.g., ["github.com/user/package@latest"])          |
| `neovim.enabled`   | boolean      | No       | `false`        | Install and configure Neovim for this user                                     |
| `terminal_entries` | list[object] | No       | `[]`           | Terminal emulator configuration entries (see schema below)                     |
| `dotfiles.enable`  | boolean      | No       | `true`         | Enable dotfiles configuration                                                  |
| `dotfiles.repo`    | string       | No       | none           | Git repository URL for dotfiles (e.g., "https://github.com/user/dotfiles.git") |
| `dotfiles.dest`    | string       | No       | `~/.dotfiles`  | Destination directory path for dotfiles (absolute or ~/ relative)              |

**Package Management Schema:**

| Field                                 | Type       | Default   | Description                                         |
| ------------------------------------- | ---------- | --------- | --------------------------------------------------- |
| `manage_packages.<OS_Family>`         | list[dict] | `[]`      | Package specifications with name and optional state |
| `manage_packages.<OS_Family>[].name`  | string     | -         | Package name (e.g., "git", "curl", "vim")           |
| `manage_packages.<OS_Family>[].state` | string     | "present" | Package state ("present" or "absent")               |

_OS_Family values: Debian, Archlinux, Darwin_

**Example**:

```yaml
manage_packages:
  Debian:
    - name: git
      state: present # optional, defaults to present
    - name: curl
    - name: telnet
      state: absent
```

**Note**: Where package layering is needed, roles implement explicit combining of package lists from different inventory levels using the `combine` filter with `list_merge='append'` to achieve additive behavior across inventory scopes.

**Snap Package Schema:**

| Field            | Type   | Default   | Description                                                              |
| ---------------- | ------ | --------- | ------------------------------------------------------------------------ |
| `snap_packages`  | list[dict] | `[]`  | Snap package specifications with name and optional state/options         |
| `snap_packages[].name` | string | -     | Snap package name (e.g., "code", "firefox", "discord")                  |
| `snap_packages[].state` | string | "present" | Package state ("present", "absent", "enabled", "disabled")            |
| `snap_packages[].classic` | boolean | `false` | Install with classic confinement (--classic)                          |
| `snap_packages[].channel` | string | none  | Install from specific channel (e.g., "latest/edge", "stable")           |

**Example**:

```yaml
snap_packages:
  - name: code
    state: present
    classic: true
  - name: firefox
    # state defaults to present
  - name: old-app
    state: absent
  - name: discord
    channel: latest/edge
```

**APT Repository Object Schema:**

| Field        | Type   | Required | Default | Description                                                       |
| ------------ | ------ | -------- | ------- | ----------------------------------------------------------------- |
| `name`       | string | Yes      | -       | Repository name (used for file naming and cleanup)                |
| `uris`       | string | Yes      | -       | Repository URL (e.g., "https://download.docker.com/linux/ubuntu") |
| `suites`     | string | Yes      | -       | Distribution suite (e.g., "jammy", "focal")                       |
| `components` | string | Yes      | -       | Repository components (e.g., "stable main")                       |
| `signed_by`  | string | No       | -       | GPG key file path (e.g., "/etc/apt/keyrings/docker.gpg")          |

**Firewall Rules Object Schema:**

| Field         | Type            | Required | Default   | Description                                    |
| ------------- | --------------- | -------- | --------- | ---------------------------------------------- |
| `port`        | integer\|string | Yes      | -         | Port number or range (e.g., 22, "8080:8090")   |
| `protocol`    | string          | No       | `"tcp"`   | Protocol ("tcp", "udp", "any")                 |
| `rule`        | string          | No       | `"allow"` | Rule action ("allow", "deny")                  |
| `source`      | string          | No       | `"any"`   | Source IP/CIDR (e.g., "192.168.1.0/24", "any") |
| `destination` | string          | No       | `"any"`   | Destination IP/CIDR                            |
| `comment`     | string          | No       | `""`      | Rule description                               |

**Fail2ban Jails Object Schema:**

| Field      | Type    | Required | Default      | Description                                                |
| ---------- | ------- | -------- | ------------ | ---------------------------------------------------------- |
| `name`     | string  | Yes      | -            | Jail name (e.g., "sshd", "apache-auth", "nginx-http-auth") |
| `enabled`  | boolean | No       | `true`       | Whether this jail is active                                |
| `port`     | string  | No       | varies       | Port(s) to monitor (e.g., "ssh", "http,https", "22")       |
| `filter`   | string  | No       | auto         | Filter name to use (defaults to jail name)                 |
| `logpath`  | string  | Yes      | -            | Log file path to monitor (e.g., "/var/log/auth.log")       |
| `maxretry` | integer | No       | inherit      | Override global maxretry for this jail                     |
| `bantime`  | string  | No       | inherit      | Override global bantime for this jail (e.g., "1h", "1d")   |
| `findtime` | string  | No       | inherit      | Override global findtime for this jail                     |
| `action`   | string  | No       | `"iptables"` | Ban action (e.g., "iptables", "iptables-multiport", "ufw") |

**Udev Rules Object Schema:**

| Field      | Type    | Required | Default     | Description                                                |
| ---------- | ------- | -------- | ----------- | ---------------------------------------------------------- |
| `name`     | string  | Yes      | -           | Rule identifier (alphanumeric + hyphens, used in filename) |
| `content`  | string  | Yes      | -           | Udev rule content (e.g., 'SUBSYSTEM=="usb", MODE="0666"')  |
| `priority` | integer | No       | `99`        | Rule priority (10-99, lower executes first)                |
| `state`    | string  | No       | `"present"` | Rule state ("present" to deploy, "absent" to remove)       |

**Sysctl Parameters Schema:**

| Field              | Type        | Default | Description                                         |
| ------------------ | ----------- | ------- | --------------------------------------------------- |
| `<parameter_name>` | string\|int | varies  | Kernel parameter (key: sysctl name, value: setting) |

_Common sysctl parameters:_

- `vm.swappiness`: int (0-100, controls swap usage)
- `net.ipv4.ip_forward`: string ("0" or "1", enables IP forwarding)
- `fs.file-max`: int (maximum number of file handles)
- `kernel.pid_max`: int (maximum process ID value)
- `net.core.rmem_max`: int (maximum receive buffer size)

**Terminal Entries Object Schema:**

| Field       | Type   | Required | Default   | Description                                                                |
| ----------- | ------ | -------- | --------- | -------------------------------------------------------------------------- |
| `name`      | string | Yes      | -         | Terminal configuration name/identifier (alphanumeric + spaces)             |
| `command`   | string | No       | none      | Shell command to execute (e.g., "npm start", "ssh server.example.com")     |
| `directory` | string | No       | `~`       | Working directory path (absolute or ~/ relative, e.g., "~/projects/myapp") |
| `profile`   | string | No       | "default" | Terminal profile name to use                                               |

**Snap Packages Object Schema:**

| Field     | Type   | Required | Default     | Description                                                             |
| --------- | ------ | -------- | ----------- | ----------------------------------------------------------------------- |
| `name`    | string | Yes      | -           | Snap package name (e.g., "hello-world", "code", "discord")             |
| `state`   | string | No       | `"present"` | Package state ("present" to install, "absent" to remove)               |
| `classic` | boolean| No       | `false`     | Install with classic confinement (bypasses snap security restrictions) |
| `channel` | string | No       | `"stable"`  | Package channel (e.g., "stable", "latest/edge", "latest/beta")         |

**Flatpak Packages Object Schema:**

| Field   | Type   | Required | Default     | Description                                                       |
| ------- | ------ | -------- | ----------- | ----------------------------------------------------------------- |
| `name`  | string | Yes      | -           | Flatpak package name (e.g., "org.mozilla.firefox", "com.spotify.Client") |
| `state` | string | No       | `"present"` | Package state ("present" to install, "absent" to remove)         |

### 2.3 Coding Standards

#### 2.3.1 Ansible Galaxy Standards

**REQ-INFRA-003**: All roles SHALL conform to Ansible Galaxy development standards as defined in the [Ansible Galaxy Developer Guide](https://docs.ansible.com/ansible/latest/galaxy/dev_guide.html), including properly formatted `meta/main.yml` files with role dependencies, supported platforms, and complete metadata. Any deviations from Galaxy standards SHALL be explicitly documented with justification in the role's README or documentation.

#### 2.3.2 Module Usage

**Standards - Module Selection Hierarchy**
The collection should prioritize module usage in this order:

1. Standard Ansible modules (ansible.builtin, community.general, etc.)
2. Widely accepted third-party roles (e.g., geerlingguy.\*, devsec.hardening)
3. `ansible.builtin.command` module (only when no module exists for the task)
4. `ansible.builtin.shell` module (requires explicit justification)

**REQ-INFRA-004**: Use of `ansible.builtin.shell` SHALL be avoided except when shell-specific features (pipes, redirects, environment expansion) are absolutely required and cannot be achieved through other means.

**REQ-INFRA-005**: When `ansible.builtin.command` or `ansible.builtin.shell` are used, the task SHALL include:

- A comment explaining why the command was chosen over an existing module, if a module is available.
- If the command involves complex logic or multiple step commands, it needs to have a descriptive comment explaining what the intended function is.
- Proper error handling with `failed_when` or `ignore_errors`
- Idempotency checks with `changed_when` or `creates`/`removes`

#### 2.3.2 Loop Variable Management

**REQ-INFRA-006**: Tasks using loops SHALL use unique variable names to prevent variable collisions

**Implementation**:

- Simple loops: Use descriptive variable names instead of default `item` (e.g., `loop_var: user_item`, `loop_var: package_item`)
- Nested loops: Use `loop_control.loop_var` with unique names (e.g., `outer_user`, `inner_key`)
- Include/import with loops: Use `loop_control.loop_var` to avoid collision with included task loops
- Variable names should be descriptive of the data being processed (e.g., `current_user`, `pkg_item`, `rule_def`)

#### 2.3.3 Module Deprecation

**Standards - Deprecated Modules**
Use current modules and address deprecation warnings when possible.

### 2.4 Configuration Management Requirements

#### 2.4.1 Idempotency and Error Handling

**REQ-INFRA-007**: The collection SHALL maintain Ansible's inherent idempotency (verified by running playbooks twice with no changes reported on second run)

**REQ-INFRA-008**: Input validation SHALL be performed ONLY when required for:

- Safety (e.g., preventing data loss or system damage)
- Clarity (e.g., providing meaningful error messages for invalid configurations)

**REQ-INFRA-009**: Tasks SHALL fail with descriptive error messages when encountering unrecoverable conditions and a determination is made that ansible's builtin error handling is not sufficient.

#### 2.4.2 Security Requirements

**REQ-INFRA-010**: Tasks SHALL use least privilege principle - run without `become: true` by default, only elevating privileges via `become: true` with sudo method when operations require root access

**REQ-INFRA-011**: The collection SHALL ensure ACL package is available on non-macOS systems to support `become_user` privilege escalation

**Implementation**: Uses `ansible.builtin.package` with `name: acl` and `state: present` when `ansible_os_family != 'Darwin'` and user privilege operations are required (e.g., `become_user` scenarios).

**REQ-INFRA-012**: Sensitive information (passwords, keys) MUST NOT be logged

**REQ-INFRA-013**: File permissions MUST be explicitly set for security-critical files

---

## 3. Role Requirements

### 3.1 os_configuration

#### 3.1.1 Role Description

The `os_configuration` role handles fundamental operating system configuration. In general, these are simple, safe configuration changes to make to a system. Features or functions requiring more complex or finer-grained configuration will be separated into their own role.

#### 3.1.2 Variables

This role uses collection-wide variables from section 2.2.1. No role-specific variables are defined.

#### 3.1.3 Tag Strategy

The `os_configuration` role implements a rationalized tag strategy supporting two primary use cases:

##### 3.1.3.1 Container Limitations

**Tag**: `no-container`

Tasks that require capabilities unavailable in containers (hostname changes, systemd services, kernel modules, etc.) are tagged with `no-container`. Use `skip-tags: no-container` when running in containerized environments.

**Example**: `ansible-playbook playbook.yml --skip-tags no-container`

##### 3.1.4.2 Feature Opt-Out via Tags

**Concept**: The role provides comprehensive system configuration management. However, operational reality requires the ability to preserve existing system configurations.

**Solution**: Use `skip-tags` to completely bypass management of specific configuration areas, leaving existing system state untouched.

**Available Feature Tags**:

- `hostname` - System hostname and /etc/hosts management
- `timezone` - System timezone configuration
- `locale` - System locale/language settings
- `ntp` - Network time synchronization
- `apt` - APT proxy, no-recommends, and unattended-upgrades (Debian/Ubuntu)
- `pacman` - Pacman proxy, no-confirm, and multilib repository (Arch Linux)
- `services` - Systemd service enable/disable/mask operations
- `modules` - Kernel module loading and blacklisting
- `journal` - Systemd journal configuration
- `udev` - Custom udev rules deployment
- `security` - Security hardening via devsec roles
- `updates` - Automatic software update configuration (macOS)
- `preferences` - System preference configuration (macOS)
- `network` - Network-related configurations (macOS AirDrop, etc.)

**Usage Examples**:

- `skip-tags: apt` - Don't manage APT configuration, preserve existing proxy/settings
- `skip-tags: services,modules` - Leave systemd services and kernel modules alone
- `skip-tags: security` - Skip security hardening on legacy/special-purpose systems
- `skip-tags: hostname,timezone` - Preserve existing hostname and timezone settings

**Benefits**:

- **Operational Safety**: Prevents accidental removal of critical existing configurations
- **Gradual Adoption**: Allows incremental deployment of configuration management
- **Special Cases**: Accommodates systems with non-standard configurations that shouldn't be managed
- **Predictable Configuration**: When tags aren't skipped, provides consistent configuration management behavior

This approach resolves the tension between comprehensive configuration management and operational requirements to preserve existing system configurations.

#### 3.1.4 Features and Functionality

##### 3.1.4.1 Cross-Platform System Configuration

###### 3.1.4.1.1 Hostname Configuration

**REQ-OS-001**: The system SHALL be capable of setting the system hostname

**Implementation**: Uses `ansible.builtin.hostname` module when `host_hostname` is defined and non-empty.

**REQ-OS-002**: The system SHALL be capable of updating the `/etc/hosts` file with hostname entries

**Implementation**: Uses `ansible.builtin.lineinfile` to update `/etc/hosts` when `host_update_hosts` is true, format: `127.0.0.1 localhost {hostname}.{domain} {hostname}`. Requires both `host_hostname` and `domain_name` to be defined.

###### 3.1.4.1.2 Timezone Configuration

**REQ-OS-003**: The system SHALL be capable of setting the system timezone

**Implementation**: Uses `community.general.timezone` module when `domain_timezone` is defined and non-empty.

##### 3.1.4.2 Linux System Configuration

###### 3.1.4.2.1 Security Hardening

**REQ-OS-004**: The system SHALL be capable of applying OS security hardening on Linux systems

**Implementation**: Uses `devsec.hardening.os_hardening` role with variables from `host_security.*` and `host_sysctl.parameters` when `host_security.hardening_enabled` is true.

**REQ-OS-005**: The system SHALL be capable of applying SSH security hardening on Linux systems

**Implementation**: Uses `devsec.hardening.ssh_hardening` role when `host_security.ssh_hardening_enabled` is true.

###### 3.1.4.2.2 Locale and Language Configuration

**REQ-OS-006**: The system SHALL be capable of setting the system locale on Linux systems

**Implementation**: Uses `community.general.locale_gen` + the localectl command when `domain_locale` is defined.

**REQ-OS-007**: DELETED - Merged into REQ-OS-006 (locale and language are part of same locale configuration)

###### 3.1.4.2.3 NTP Time Synchronization

**REQ-OS-008**: The system SHALL be capable of configuring basic time synchronization on Linux systems

**Implementation**: Uses systemd-timesyncd for client-side time synchronization via SNTP. Steps: 1) `ansible.builtin.package` ensures systemd-timesyncd is installed, 2) `ansible.builtin.systemd` ensures service is enabled, 3) `ansible.builtin.template` configures `/etc/systemd/timesyncd.conf` when `domain_ntp.enabled` is true. Loop variable name: `ntp_server`.

**Note**: This implements basic SNTP client functionality only. Full NTP server/client capabilities require a dedicated NTP role (future work).

###### 3.1.4.2.4 Journal and Logging Configuration

**REQ-OS-009**: The system SHALL be capable of configuring systemd journal settings on Linux systems

**Implementation**: Uses `ansible.builtin.template` for `/etc/systemd/journald.conf.d/00-ansible-managed.conf` when `journal.configure` is true.

**REQ-OS-010**: DELETED - Remote logging capabilities moved to dedicated logging role (future work)

###### 3.1.4.2.5 Service Management

**REQ-OS-011**: The system SHALL be capable of controlling systemd units (services, timers, and so on) on Linux systems

**Implementation**: Uses `ansible.builtin.systemd_service` to manage systemd units with three operations:

- Enable/start: When `host_services.enable` is defined (enabled: true, state: started)
- Disable/stop: When `host_services.disable` is defined (enabled: false, state: stopped)
- Mask/stop: When `host_services.mask` is defined (masked: true, state: stopped)
  Loop variable name: `service_item` (from respective `host_services.*` arrays).

**REQ-OS-012**: DELETED - Consolidated into REQ-OS-011 (systemd unit control)

**REQ-OS-013**: DELETED - Consolidated into REQ-OS-011 (systemd unit control)

###### 3.1.4.2.6 Kernel Module Management

**REQ-OS-014**: The system SHALL be capable of managing kernel modules on Linux systems

**Implementation**: Uses `community.general.modprobe` to manage kernel modules with operations:

- Load modules: When `host_modules.load` is defined (state: present, persistent: present)
- Blacklist modules: When `host_modules.blacklist` is defined (state: absent, persistent: absent)
  Loop variable name: `module_item` (from respective `host_modules.*` arrays).

**REQ-OS-015**: DELETED - Consolidated into REQ-OS-014 (kernel module management)

###### 3.1.4.2.7 Hardware Configuration

**REQ-OS-016**: The system SHALL be capable of deploying custom udev rules on Linux systems

**Implementation**:

- Uses `ansible.builtin.file` to ensure `/etc/udev/rules.d/` directory exists with mode 0755
- Uses `ansible.builtin.copy` to deploy rules to `/etc/udev/rules.d/{priority}-{name}.rules` when `item.state` is 'present' (default)
- Uses `ansible.builtin.file` with `state: absent` to remove rules when `item.state` is 'absent'
- Triggers handler to reload udev via `udevadm control --reload-rules && udevadm trigger`
- Loop variable name: `udev_rule` (from `host_udev.rules`)
- Rule format: `name` (rule identifier), `content` (rule text), `priority` (default 99), `state` (present/absent)

###### 3.1.4.2.8 Debian/Ubuntu Specific Configuration

**REQ-OS-017**: The system SHALL be capable of configuring APT proxy on Debian/Ubuntu systems

**Implementation**:

- Uses `ansible.builtin.copy` to create `/etc/apt/apt.conf.d/99-proxy` when `apt.proxy` is defined
- Uses `ansible.builtin.file` with `state: absent` to remove proxy config when `apt.proxy` is undefined/empty
- Content template sets both `Acquire::http::Proxy` and `Acquire::https::Proxy` to same URL
- Expected `apt.proxy` format: `http[s]://[user:pass@]host:port`

**REQ-OS-017a**: The system SHALL be capable of disabling APT recommends on Debian/Ubuntu systems

**Implementation**:

- Uses `ansible.builtin.copy` to create `/etc/apt/apt.conf.d/99-no-recommends` when `apt.no_recommends` is true
- Uses `ansible.builtin.file` with `state: absent` to remove config when `apt.no_recommends` is false/undefined
- Content disables both `APT::Install-Recommends` and `APT::Install-Suggests`

**REQ-OS-018**: The system SHALL be capable of configuring APT unattended upgrades on Debian/Ubuntu systems

**Implementation**:

- Uses `ansible.builtin.apt` to ensure `unattended-upgrades` package is installed when `apt.unattended_upgrades.enabled` is true
- Uses `ansible.builtin.copy` to create `/etc/apt/apt.conf.d/50unattended-upgrades` when `apt.unattended_upgrades.enabled` is true
- Uses `ansible.builtin.file` with `state: absent` to remove config when `apt.unattended_upgrades.enabled` is false/undefined
- Package removal is left to package management roles (manage_packages)
- Content enables security updates only with basic error recovery (minimal, safe configuration)
- **Interface Contract**: File priority `50` reserved for os_configuration role's basic unattended-upgrades toggle
- **Future Role Integration**: Dedicated unattended-upgrades role should:
  - Use priority `20` or lower (e.g., `20-unattended-upgrades`) to override this basic configuration
  - Or remove this `50` file entirely and manage complete configuration independently

###### 3.1.4.2.9 Arch Linux Specific Configuration

**REQ-OS-021**: The system SHALL be capable of configuring Pacman proxy on Arch Linux systems

**Implementation**:

- Uses `ansible.builtin.lineinfile` to add/modify `Server = $repo/$arch` under `[options]` section when `pacman.proxy` is defined
- Uses `ansible.builtin.lineinfile` to remove proxy configuration when `pacman.proxy` is undefined/empty
- Expected `pacman.proxy` format: `http[s]://[user:pass@]host:port`

**REQ-OS-021a**: The system SHALL be capable of configuring Pacman NoConfirm on Arch Linux systems

**Implementation**:

- Uses `ansible.builtin.lineinfile` to add/modify `NoConfirm` under `[options]` section when `pacman.no_confirm` is true
- Uses `ansible.builtin.lineinfile` to remove/comment NoConfirm setting when `pacman.no_confirm` is false/undefined

**REQ-OS-021b**: The system SHALL be capable of configuring Pacman multilib repository on Arch Linux systems

**Implementation**:

- Uses `ansible.builtin.lineinfile` to uncomment `[multilib]` section and `Include = /etc/pacman.d/mirrorlist` when `pacman.multilib.enabled` is true
- Uses `ansible.builtin.lineinfile` to comment out multilib section when `pacman.multilib.enabled` is false/undefined

##### 3.1.4.3 macOS System Configuration

###### 3.1.4.3.1 Locale and Language Configuration

**REQ-OS-022**: The system SHALL be capable of setting the system locale on macOS systems

**Implementation**: Uses `community.general.osx_defaults` with NSGlobalDomain/AppleLocale when `domain_locale` is defined.

**REQ-OS-023**: The system SHALL be capable of setting the system language on macOS systems

**Implementation**: Uses `community.general.osx_defaults` with NSGlobalDomain/AppleLanguages when `domain_language` is defined.

###### 3.1.4.3.2 NTP Time Synchronization

**REQ-OS-024**: The system SHALL be capable of configuring NTP time synchronization on macOS systems

**Implementation**: Uses `ansible.builtin.command` with `systemsetup` utility for NTP configuration. Enables network time synchronization with `systemsetup -setusingnetworktime on` and configures the first server from `domain_ntp.servers` when `domain_ntp.enabled` is true. Disables network time synchronization with `systemsetup -setusingnetworktime off` when `domain_ntp.enabled` is false.

###### 3.1.4.3.3 Software Updates

**REQ-OS-025**: The system SHALL be capable of configuring macOS automatic updates

**Implementation**: Uses `community.general.osx_defaults` for `/Library/Preferences/com.apple.SoftwareUpdate` domain to configure `AutomaticCheckEnabled` (controlled by `macosx.updates.auto_check`) and `AutomaticDownload` (controlled by `macosx.updates.auto_download`) settings.

###### 3.1.4.3.4 Security Configuration

**REQ-OS-026**: The system SHALL be capable of configuring macOS Gatekeeper security

**Implementation**: Uses `ansible.builtin.command` with `spctl --master-enable` when `macosx.gatekeeper.enabled` is true, or `spctl --master-disable` when `macosx.gatekeeper.enabled` is false.

###### 3.1.4.3.5 System Preferences

**REQ-OS-027**: The system SHALL be capable of configuring macOS system preferences

**Implementation**: Uses `community.general.osx_defaults` with NSGlobalDomain to configure: scroll direction (`com.apple.swipescrolldirection` controlled by `macosx.system_preferences.natural_scroll`), measurement units (`AppleMeasurementUnits` and `AppleMetricUnits` controlled by `macosx.system_preferences.measurement_units` and `macosx.system_preferences.use_metric`), and file extension visibility (`AppleShowAllExtensions` controlled by `macosx.system_preferences.show_all_extensions`).

###### 3.1.4.3.6 Network Configuration

**REQ-OS-028**: The system SHALL be capable of configuring AirDrop over Ethernet

**Implementation**: Uses `community.general.osx_defaults` for `com.apple.NetworkBrowser` domain to configure `BrowseAllInterfaces` setting (controlled by `macosx.airdrop.ethernet_enabled`), enabling AirDrop functionality over wired Ethernet connections.

---

### 3.2 manage_security_services

#### 3.2.1 Role Description

The `manage_security_services` role handles firewall configuration and intrusion prevention services.

#### 3.2.2 Variables

This role uses collection-wide variables from section 2.2.1 (firewall._, fail2ban._). No role-specific variables are defined.

#### 3.2.3 Tag Strategy

The `manage_security_services` role implements a tag strategy following the pattern established in `os_configuration`:

##### 3.2.3.1 Container Limitations

**Tag**: `no-container`

Tasks requiring elevated privileges or kernel features unavailable in containers are tagged with `no-container`. Use `skip-tags: no-container` when running in containerized environments.

##### 3.2.3.2 Feature Opt-Out

**Available Feature Tags**:

- `firewall` - Complete firewall management (UFW on Linux, Application Layer Firewall on macOS)
- `firewall-rules` - Firewall rule application only
- `firewall-services` - Firewall service state management only
- `fail2ban` - Intrusion prevention service management
- `security` - All security services (firewall + fail2ban)

**Usage Examples**:

- `skip-tags: firewall` - Don't manage firewall configuration
- `skip-tags: fail2ban` - Skip intrusion prevention setup
- `skip-tags: security` - Skip all security service configuration

#### 3.2.4 Features and Functionality

##### 3.2.4.1 Linux Security Services

###### 3.2.4.1.1 UFW Firewall Management

**REQ-SS-001**: The system SHALL be capable of installing and configuring UFW firewall package on Linux systems

**Implementation**: Uses `ansible.builtin.package` to install UFW package when `firewall.enabled` is true.

**REQ-SS-002**: The system SHALL automatically detect and protect SSH access during firewall operations

**Implementation**: Uses `ansible.builtin.set_fact` to detect current SSH port from `ansible_env.SSH_CONNECTION` when `firewall.prevent_ssh_lockout` is true (default). Falls back to `ansible_port` or port 22 if SSH_CONNECTION unavailable.

**REQ-SS-004**: The system SHALL be capable of enabling or disabling UFW firewall service based on configuration

**Implementation**: Uses `community.general.ufw` with `state: enabled` when `firewall.enabled` is true. When `firewall.enabled` is false or undefined, firewall remains in current state (doesn't force disable to avoid lockouts).

###### 3.2.4.1.2 Fail2ban Intrusion Prevention

**REQ-SS-005**: The system SHALL be capable of installing fail2ban on Linux systems

**Implementation**: Uses `ansible.builtin.package` to install fail2ban package when `fail2ban` is defined and `fail2ban.enabled` is true.

**REQ-SS-006**: The system SHALL be capable of configuring fail2ban jails on Linux systems

**Implementation**: Uses `ansible.builtin.template` to deploy `/etc/fail2ban/jail.local` configuration file with mode 0644. Template processes `fail2ban.bantime`, `fail2ban.findtime`, `fail2ban.maxretry` and `fail2ban.jails` array. Notifies handler to restart fail2ban when configuration changes.

**REQ-SS-007**: The system SHALL be capable of managing fail2ban service state on Linux systems

**Implementation**: Uses `ansible.builtin.service` to manage fail2ban service. Service is started and enabled when `fail2ban.enabled` is true, stopped and disabled when false.

##### 3.2.4.2 macOS Security Services

###### 3.2.4.2.1 Application Layer Firewall Management

**REQ-SS-008**: The system SHALL be capable of checking firewall state on macOS systems

**Implementation**: Uses `ansible.builtin.command` with `/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate` to query current firewall state. Sets `changed_when: false` for idempotency.

**REQ-SS-009**: The system SHALL be capable of enabling/disabling Application Layer Firewall on macOS systems

**Implementation**: Uses `ansible.builtin.command` with `/usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on/off` based on `firewall.enabled` value. Checks previous state to determine if change occurred for proper idempotency reporting.

**REQ-SS-010**: The system SHALL be capable of configuring stealth mode on macOS systems

**Implementation**: Uses `ansible.builtin.command` with `/usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on/off` based on `firewall.stealth_mode` value (default false).

**REQ-SS-011**: The system SHALL be capable of configuring block all setting on macOS systems

**Implementation**: Uses `ansible.builtin.command` with `/usr/libexec/ApplicationFirewall/socketfilterfw --setblockall on/off` based on `firewall.block_all` value (default false).

**REQ-SS-012**: The system SHALL be capable of configuring firewall logging on macOS systems

**Implementation**: First checks if logging options are available (version-dependent) using `socketfilterfw -h`. If available, uses `--setloggingmode on/off` based on `firewall.logging` value. When logging enabled, also sets `--setloggingopt detail` for comprehensive logging.

### 3.3 manage_packages

#### 3.3.1 Role Description

The `manage_packages` role handles package management across different operating systems and package managers.

#### 3.3.2 Variables

This role uses collection-wide variables from section 2.2.1 (packages._, apt._, pacman._, homebrew._). No role-specific variables are defined.

**Note**: Where layered configuration is needed, roles implement explicit merging of package and repository definitions across inventory levels using the `combine` filter, providing predictable and portable behavior.

#### 3.3.3 Tag Strategy

The `manage_packages` role implements a tag strategy following the pattern established in `os_configuration` and `manage_security_services`:

##### 3.3.3.1 Container Limitations

**Tag**: `no-container`

Tasks that require capabilities unavailable in containers (AUR building as non-root user) are tagged with `no-container`. Use `skip-tags: no-container` when running in containerized environments.

**Example**: `ansible-playbook playbook.yml --skip-tags no-container`

##### 3.3.3.2 Feature Opt-Out via Tags

**Available Feature Tags**:

- `packages` - Package installation and removal operations
- `repositories` - Repository management (APT repositories, Homebrew taps, etc.)
- `upgrades` - System package upgrades (APT, Pacman)
- `aur` - AUR (Arch User Repository) package management with paru

**Usage Examples**:

- `skip-tags: repositories` - Don't manage repositories, preserve existing sources
- `skip-tags: upgrades` - Skip system package upgrades
- `skip-tags: aur` - Use only official repositories, skip AUR operations
- `skip-tags: packages` - Skip package installation/removal, manage only repositories

#### 3.3.4 Features and Functionality

##### 3.3.4.1 Cross-Platform Package Management

###### 3.3.4.1.1 Package Merging and Organization

**REQ-MP-001** (DELETED): ~~The system SHALL merge packages defined at the global ("all") level with packages defined at the group level and packages defined at the host level~~

**Rationale**: Package installation and removal operations are both package management functionality and are consolidated into a single requirement for clarity.

##### 3.3.4.2 Debian/Ubuntu Package Management

###### 3.3.4.2.1 APT Repository Management

**REQ-MP-002** (DELETED): ~~The system SHALL merge APT repositories defined at the global ("all") level with repositories defined at the group level and repositories defined at the host level~~

**Rationale**: Repository installation and management operations are consolidated into a single requirement for clarity.

**REQ-MP-003**: The system SHALL be capable of managing APT repositories using deb822 format

**Implementation**:

1. **Repository dependencies**: Uses `ansible.builtin.apt` to install `apt-transport-https`, `ca-certificates`, `python3-debian`, and `gnupg` packages when repositories are being configured
2. **Legacy cleanup**: Uses `ansible.builtin.file` to remove legacy `.list` files from `/etc/apt/sources.list.d/` and `.asc` GPG keys from `/etc/apt/trusted.gpg.d/` for any repository name in `apt.repositories[ansible_distribution]` (removes multiple naming variations including `{name}.list`, `{name-with-dashes}.list`, and `download_{name}.list`)
3. **deb822 repository management**: Uses `ansible.builtin.deb822_repository` module for repository management with proper deb822 format

**Note**: Legacy cleanup is necessary because `deb822_repository` module does not interact with legacy formats, leading to duplicate repository entries if legacy files are not removed. Dependencies must be installed before repository operations to ensure proper functionality.

**REQ-MP-004** (MERGED INTO REQ-MP-003): ~~The system SHALL ensure APT repository dependencies are present whenever managing repositories~~

**Rationale**: This requirement is an implementation detail of REQ-MP-003 repository management, not a separate functional requirement.

###### 3.3.4.2.2 APT Package Management

**REQ-MP-005** (DELETED): ~~The system SHALL update the APT cache before attempting to install packages~~

**Rationale**: This is an implementation detail, not a functional requirement. Cache updating is handled automatically by the apt module when needed.

**REQ-MP-006**: The system SHALL be capable of managing packages via APT

**Implementation**: Uses `ansible.builtin.apt` with each package's specified `state` (defaults to `present`) for packages in `manage_packages[ansible_os_family]`. Cache is updated automatically via `update_cache: true` with configurable `cache_valid_time`.

**REQ-MP-007** (MERGED INTO REQ-MP-006): ~~The system SHALL be capable of installing packages via APT~~

**Rationale**: Package installation and removal are both package management operations and should be a single requirement. Merged into REQ-MP-006.
MP
**REQ-MP-008**: The system SHALL be capable of performing system upgrades via APT

**Implementation**: Uses `ansible.builtin.apt` with configurable upgrade type when `apt.system_upgrade.enable` is true.

##### 3.3.4.3 Arch Linux Package Management

###### 3.3.4.3.1 Pacman Package Management

**REQ-MP-009** (DELETED): ~~The system SHALL be capable of updating Pacman package cache~~

**Rationale**: This is an implementation detail, not a functional requirement. Cache updating is handled automatically by the pacman module when needed.

**REQ-MP-009a**: The system SHALL be capable of managing packages via Pacman

**Implementation**: When `pacman.enable_aur` is false, uses `community.general.pacman` with each package's specified `state` (defaults to `present`) for packages in `manage_packages[ansible_os_family]`. Cache is updated automatically via `update_cache: true`.

**REQ-MP-010** (MERGED INTO REQ-MP-009a): ~~The system SHALL be capable of removing packages via Pacman~~

**Rationale**: Package installation and removal are both package management operations and should be a single requirement. Merged into REQ-MP-009a.

**REQ-MP-011**: The system SHALL be capable of upgrading all Pacman packages

**Implementation**: Uses `community.general.pacman` with `upgrade: true`.

**REQ-MP-012**: The system SHALL be capable of disabling AUR package installation

**Implementation**: When `pacman.enable_aur` is false, uses `community.general.pacman` for official repository packages only. When `pacman.enable_aur` is true, uses AUR helper for all package management (see REQ-MP-013).

###### 3.3.4.3.2 AUR Package Management

**REQ-MP-013**: The system SHALL be capable of managing AUR packages when enabled

**Implementation**: When `pacman.enable_aur` is true: 1) Configures passwordless sudo for pacman operations using `ansible.builtin.lineinfile`, 2) Bootstraps paru AUR helper using `kewlfft.aur.aur` with `use: auto`, 3) Manages ALL packages (both official repository and AUR) using `kewlfft.aur.aur` with `use: paru`.

**Note**: AUR package management requires passwordless sudo access to `/usr/bin/pacman` for the ansible_user (who acts as the AUR builder) to enable automated package installation and dependency resolution. The ansible_user's home directory is used for AUR package building. This is limited to the pacman binary only, not full system access.

##### 3.3.4.4 macOS Package Management

###### 3.3.4.4.1 Homebrew Package Management

**REQ-MP-014**: The system SHALL be capable of managing Homebrew packages and casks

**Implementation**: Uses `geerlingguy.mac.homebrew` role with variables mapped from `manage_packages[ansible_os_family]` and `manage_casks[ansible_os_family]` lists. Package state is determined per item with defaults to `present`. Sets `homebrew_cask_appdir: /Applications`.

**REQ-MP-015**: The system SHALL be capable of managing Homebrew taps

**Implementation**: Uses `geerlingguy.mac.homebrew` role with `homebrew_taps` from `homebrew.taps` configuration and `homebrew_clear_cache` from `homebrew.cleanup_cache`.

### 3.4 manage_snap_packages

#### 3.4.1 Role Description

The `manage_snap_packages` role manages both snapd system and snap packages on Debian/Ubuntu systems.

#### 3.4.2 Variables

This role uses collection-wide variables from section 2.2.1 (snap.* and snap_packages). No role-specific variables are defined.

#### 3.4.3 Tag Strategy

The `manage_snap_packages` role implements a tag strategy following the pattern established in other collection roles:

##### 3.4.3.1 Container Limitations

**Tag**: `no-container`

Tasks that require capabilities unavailable in containers are tagged with `no-container`. However, this role currently has no such limitations as snap operations can be tested in containers.

##### 3.4.3.2 Feature Opt-Out via Tags

**Available Feature Tags**:

- `snap-packages` - All snap package management operations (install, remove, system removal)

**Usage Examples**:

- `skip-tags: snap-packages` - Skip all snap package management operations

**Note**: This role uses a single comprehensive tag as snap operations are typically all-or-nothing (either managing snaps or completely removing the snap system).

#### 3.4.4 Features and Functionality

##### 3.4.4.1 Snap System Removal

###### 3.4.4.1.1 Complete Snap System Disabling

**REQ-MSP-001**: The system SHALL be capable of completely removing the snap package system from Debian/Ubuntu systems

**Implementation**: When `snap.remove_completely` is true, uses `ansible.builtin.command` to list and remove all installed snap packages (except core packages which are removed last), `ansible.builtin.systemd` to stop and disable snapd services, `ansible.builtin.apt` to purge snapd packages, `ansible.builtin.file` to remove snap directories, and `ansible.builtin.lineinfile` to remove snap from PATH. Loop variable names: `snap_line` (package removal), `snapd_service` (service management), `snap_dir` (directory cleanup).

**REQ-MSP-002**: The system SHALL prevent snap packages from being reinstalled after removal

**Implementation**: When `snap.remove_completely` is true, uses `ansible.builtin.copy` to create `/etc/apt/preferences.d/no-snap` with Pin-Priority: -10 to prevent snapd and gnome-software-plugin-snap from being installed.

##### 3.4.4.2 Snap Package Management

###### 3.4.4.2.1 Snap Package Installation and Removal

**REQ-MSP-003**: The system SHALL be capable of managing individual snap packages when snap system is enabled

**Implementation**: When `snap.remove_completely` is false and `snap_packages` contains one or more packages, ensures snapd is installed via `ansible.builtin.apt`, starts services via `ansible.builtin.systemd`, waits for system readiness via `ansible.builtin.command`, then uses `community.general.snap` for package management with support for state (present/absent), classic confinement, and channel specification. Loop variable names: `snapd_service` (service management), `snap_package` (package operations from `snap_packages` list).

### 3.5 manage_flatpak

#### 3.5.1 Role Description

The `manage_flatpak` role handles flatpak package management and desktop integration plugins on Debian and Arch Linux systems.

#### 3.5.2 Variables

This role uses collection-wide variables from section 2.2.1 (flatpak.\*). No role-specific variables are defined.

#### 3.5.3 Features and Functionality

##### 3.5.3.1 Flatpak Infrastructure Management

###### 3.5.3.1.1 Flatpak Installation

**REQ-MF-001**: The system SHALL install flatpak runtime on Debian and Arch Linux systems when enabled

**Implementation**: Uses `ansible.builtin.apt` for Debian/Ubuntu and `community.general.pacman` for Arch Linux to install flatpak package when `flatpak.enabled` is true.

###### 3.5.3.1.2 Desktop Integration Plugins

**REQ-MF-002**: The system SHALL install desktop environment flatpak plugins when configured

**Implementation**: Uses platform-specific package managers to install GNOME Software plugin (`gnome-software-plugin-flatpak` on Debian, `gnome-software-flatpak` on Arch) when `flatpak.plugins.gnome` is true, and Plasma Discover plugin (`plasma-discover-backend-flatpak` on Debian, `discover` on Arch) when `flatpak.plugins.plasma` is true.

###### 3.5.3.1.3 Repository Management

**REQ-MF-003**: The system SHALL enable Flathub repository when configured

**Implementation**: Uses `community.general.flatpak_remote` to add flathub repository with configurable method from `flatpak.method` and user from `flatpak.user` when `flatpak.flathub` is true.

##### 3.5.3.2 Flatpak Package Management

###### 3.5.3.2.1 Package Operations

**REQ-MF-004**: The system SHALL be capable of managing individual flatpak packages when flatpak system is enabled

**Implementation**: When `flatpak.enabled` is true and `flatpak_packages` contains one or more packages, uses `community.general.flatpak` for package management with configurable method from `flatpak.method` and user from `flatpak.user`. Supports state-based management (present/absent). Loop variable name: `flatpak_package` (from `flatpak_packages` list).

#### 3.5.4 Tag Strategy

##### 3.5.4.1 Container Limitations

**Tag: `no-container`**

Currently no tasks in this role require the `no-container` tag. All flatpak operations are compatible with container environments using the testing approach.

##### 3.5.4.2 Features Opt Out

**Tag: `flatpak-system`**

Tasks installing flatpak runtime and repositories. Skip to avoid installing flatpak entirely while still managing packages if already present.

**Tag: `flatpak-plugins`**

Tasks installing desktop environment plugins (GNOME Software, Plasma Discover). Skip to install flatpak without desktop integration.

**Tag: `flatpak-packages`**

Tasks managing individual flatpak packages. Skip to configure flatpak system without installing specific packages.

### 3.6 configure_user

#### 3.6.1 Role Description

The `configure_user` role is a standalone role that configures a single user and their preferences. It handles comprehensive user management including account creation, SSH key management, sudo access, user preferences, and development environment configuration. This role consolidates ALL user management functionality and operates on a single user configuration passed via the `target_user` variable.

#### 3.6.2 Variables

This role configures a single user via the `target_user` variable. This is a standalone role that requires the `target_user` variable structure to be identical to individual user objects from the collection-wide `users[]` variable (section 2.2.1) for integration compatibility.

**target_user Object Schema:**

| Field                 | Type         | Required | Default        | Description                                                                    |
| --------------------- | ------------ | -------- | -------------- | ------------------------------------------------------------------------------ |
| `name`                | string       | Yes      | -              | Username (alphanumeric + underscore/hyphen, max 32 chars)                      |
| `uid`                 | integer      | No       | auto           | User ID (1000-65533 for regular users, <1000 for system)                       |
| `gid`                 | integer      | No       | auto           | Primary group ID (matches uid by default)                                      |
| `groups`              | list[string] | No       | `[]`           | Secondary group names (e.g., ["docker", "sudo", "developers"])                 |
| `shell`               | string       | No       | system default | Login shell path (e.g., "/bin/bash", "/bin/zsh", "/bin/false")                 |
| `home`                | string       | No       | `/home/{name}` | Home directory absolute path (e.g., "/home/username", "/var/lib/service")      |
| `comment`             | string       | No       | `""`           | GECOS field description (e.g., "John Doe,,")                                   |
| `password`            | string       | No       | none           | Password (plaintext or SHA-512 hash starting with $6$)                         |
| `ssh_keys`            | list[string] | No       | `[]`           | SSH public key strings (full key content, one per list item)                   |
| `sudo.nopasswd`       | boolean      | No       | `false`        | Allow passwordless sudo access within sudo configuration object                |
| `state`               | enum         | No       | `"present"`    | User state ("present" or "absent")                                             |
| `create_home`         | boolean      | No       | `true`         | Create home directory if it doesn't exist                                      |
| `system`              | boolean      | No       | `false`        | System account (uid <1000, no home by default)                                 |
| `git.user_name`       | string       | No       | none           | Git global user.name setting (full name, e.g., "John Doe")                     |
| `git.user_email`      | string       | No       | none           | Git global user.email setting (email address, e.g., "john@example.com")        |
| `git.editor`          | string       | No       | none           | Git global core.editor setting (editor command, e.g., "vim", "code --wait")    |
| `nodejs.packages`     | list[string] | No       | `[]`           | npm package names to install globally (e.g., ["typescript", "@angular/cli"])   |
| `rust.packages`       | list[string] | No       | `[]`           | Cargo package names to install (e.g., ["ripgrep", "fd-find"])                  |
| `go.packages`         | list[string] | No       | `[]`           | Go package URLs to install (e.g., ["github.com/user/package@latest"])          |
| `neovim.enabled`      | boolean      | No       | `false`        | Install and configure Neovim for this user                                     |
| `terminal_entries`    | list[object] | No       | `[]`           | Terminal emulator configuration entries (see schema below)                     |
| `dotfiles.enable`     | boolean      | No       | `true`         | Enable dotfiles configuration                                                  |
| `dotfiles.repo`       | string       | No       | none           | Git repository URL for dotfiles (e.g., "https://github.com/user/dotfiles.git") |
| `superuser`           | boolean      | No       | `false`        | Automatically assign platform-appropriate admin groups (sudo/wheel/admin)      |
| `sudo`                | object       | No       | `{}`           | Custom sudo configuration (commands, nopasswd, runas)                          |
| `macos.dock.*`        | object       | No       | `{}`           | macOS Dock preferences (tilesize, autohide, minimize_to_app, show_recents)     |
| `macos.finder.*`      | object       | No       | `{}`           | macOS Finder preferences (show_extensions, show_hidden, show_pathbar, etc.)    |
| `macos.screenshots.*` | object       | No       | `{}`           | macOS screenshot preferences (location, format)                                |
| `macos.iterm2.*`      | object       | No       | `{}`           | macOS iTerm2 preferences (prompt_on_quit)                                      |

#### 3.6.3 Features and Functionality

##### 3.6.3.1 User Account Management

###### 3.6.3.1.1 User Creation and Configuration

**REQ-CU-001**: The system SHALL be capable of creating and configuring user accounts

**Implementation**: Uses `ansible.builtin.user` module with variable mappings: `target_user.name` → `name`, `target_user.comment` → `comment`, `target_user.shell` → `shell`, `target_user.groups` → `groups`, `target_user.password` → `password`, `target_user.home` → `home`, `target_user.system` → `system`, `target_user.uid` → `uid`, `target_user.group` → `group`, `target_user.generate_ssh_key` → `generate_ssh_key`, `target_user.expires` → `expires`.

**REQ-CU-002**: The system SHALL be capable of removing user accounts

**Implementation**: Uses `ansible.builtin.user` module with `name: target_user.name` and `state: absent` when `target_user.state` is set to `absent`.

###### 3.6.3.1.2 Privilege Management

**REQ-CU-003**: The system SHALL manage platform-appropriate admin group assignments with security filtering

**Implementation**: Uses `ansible.builtin.set_fact` to detect platform and filter platform admin groups (`sudo`, `wheel`, `admin`) from `target_user.groups` with warning logging, ensuring superuser privileges are only granted through the explicit `target_user.superuser` field and not through manual group assignment.

**REQ-CU-004**: The system SHALL grant sudo access through platform admin group membership

**Implementation**: Uses `ansible.builtin.user` module to add user to platform-appropriate admin groups (`sudo` for Debian/Ubuntu, `wheel` for Arch, `admin` for macOS) when `target_user.superuser` is true. This grants sudo access through existing system sudoers rules that allow these groups to use sudo with password authentication.

**REQ-CU-005**: The system SHALL support custom sudo configuration with optional passwordless access

**Implementation**: Uses `ansible.builtin.template` with `src: sudoers.j2`, `dest: /etc/sudoers.d/{{ target_user.name }}`, `owner: root`, `group: root`, `mode: '0440'`, and `validate: /usr/sbin/visudo -cf %s` to create individual sudoers files from `target_user.sudo` configuration object. Template renders sudo rules based on `target_user.sudo.commands`, `target_user.sudo.nopasswd`, and `target_user.sudo.runas` settings when `target_user.sudo` is defined.

**Note**: When `target_user.sudo.nopasswd: true`, this grants passwordless sudo access. Use with caution as this provides unrestricted root access without password verification.

##### 3.6.3.2 SSH Key Management

###### 3.6.3.2.1 SSH Authorized Keys

**REQ-CU-006**: The system SHALL be capable of managing SSH authorized keys for users

**Implementation**: Uses `ansible.posix.authorized_key` module with variable mappings: `user: target_user.name`, `key: ssh_key.key`, `comment: ssh_key.comment`, `key_options: ssh_key.options`, `exclusive: ssh_key.exclusive`, and `state: ssh_key.state | default('present')`. Uses `with_subelements` to iterate through `target_user.ssh_keys` list. Loop variable name: `ssh_key`.

##### 3.6.3.3 User Preference Configuration

###### 3.6.3.3.1 Node.js Development Environment

**REQ-CU-007**: The system SHALL configure Node.js development environment for users

**Implementation**: Passes the following variables to the nodejs role (see section 3.7): `node_user: target_user.name` and `node_packages: target_user.nodejs.packages` when `target_user.nodejs.packages` is defined and non-empty.

###### 3.6.3.3.2 Rust Development Environment

**REQ-CU-008**: The system SHALL configure Rust development environment for users

**Implementation**: Passes the following variables to the rust role (see section 3.8): `rust_user: target_user.name` and `rust_packages: target_user.rust.packages` when `target_user.rust.packages` is defined and non-empty.

###### 3.6.3.3.3 Go Development Environment

**REQ-CU-009**: The system SHALL configure Go development environment for users

**Implementation**: Passes the following variables to the go role (see section 3.9): `go_user: target_user.name` and `go_packages: target_user.go.packages` when `target_user.go.packages` is defined and non-empty.

###### 3.6.3.3.4 Neovim Configuration

**REQ-CU-010**: The system SHALL configure Neovim for users

**Implementation**: Passes the following variables to the neovim role (see section 3.10): `neovim_user: target_user.name` when `target_user.neovim.enabled` is true.

###### 3.6.3.3.5 Terminal Configuration

**REQ-CU-011**: The system SHALL configure terminal emulators for users

**Implementation**: Passes the following variables to the terminal_config role (see section 3.11): `terminal_user: target_user.name` and `terminal_entries: target_user.terminal_entries` when `target_user.terminal_entries` is defined and non-empty.

###### 3.6.3.3.6 Git Configuration

**REQ-CU-012**: The system SHALL be capable of configuring Git settings for users

**Implementation**: Uses `community.general.git_config` to set `user.name` from `target_user.git.user_name`, `user.email` from `target_user.git.user_email`, and `core.editor` from `target_user.git.editor` with global scope when `target_user.git` is defined.

##### 3.6.3.4 Linux Shell Configuration

**REQ-CU-013**: The system SHALL be capable of setting user shell preferences on Linux systems

**Implementation**: Uses `ansible.builtin.user` module with `name: target_user.name` and `shell: target_user.shell` when `target_user.shell` is defined.

##### 3.6.3.5 macOS User Configuration

###### 3.6.3.5.1 System Integration

**REQ-CU-014**: The system SHALL configure Homebrew PATH for macOS users

**Implementation**: Uses `ansible.builtin.stat` to check `/opt/homebrew/bin/brew` existence and `ansible.builtin.lineinfile` to add Homebrew PATH to `~{{ target_user.name }}/.zprofile` when Homebrew is detected.

###### 3.6.3.5.2 macOS Application Preferences

**REQ-CU-015**: The system SHALL configure Dock preferences for macOS users

**Implementation**: Uses `community.general.osx_defaults` with variable mappings: `domain: com.apple.dock`, `user: target_user.name`, and the following key-value pairs: `target_user.macos.dock.tilesize` → `key: tilesize`, `target_user.macos.dock.autohide` → `key: autohide`, `target_user.macos.dock.minimize_to_app` → `key: minimize-to-application`, `target_user.macos.dock.show_recents` → `key: show-recents`. Loop variable name: `dock_setting`.

**REQ-CU-016**: The system SHALL configure Finder preferences for macOS users

**Implementation**: Uses `community.general.osx_defaults` with variable mappings: `domain: com.apple.finder`, `user: target_user.name`, and the following key-value pairs: `target_user.macos.finder.show_extensions` → `key: AppleShowAllExtensions`, `target_user.macos.finder.show_hidden` → `key: AppleShowAllFiles`, `target_user.macos.finder.show_pathbar` → `key: ShowPathbar`, `target_user.macos.finder.show_statusbar` → `key: ShowStatusBar`, `target_user.macos.finder.show_drives` → `key: ShowHardDrivesOnDesktop`. Loop variable name: `finder_setting`.

**REQ-CU-017**: The system SHALL configure screenshot preferences for macOS users

**Implementation**: Uses `ansible.builtin.file` with `path: target_user.macos.screenshots.location`, `state: directory`, and `owner: target_user.name`, then uses `community.general.osx_defaults` with variable mappings: `domain: com.apple.screencapture`, `user: target_user.name`, and the following key-value pairs: `target_user.macos.screenshots.location` → `key: location`, `target_user.macos.screenshots.format` → `key: type`. Loop variable name: `screenshot_setting`.

**REQ-CU-018**: The system SHALL configure iTerm2 preferences for macOS users

**Implementation**: Uses `community.general.osx_defaults` with `domain: com.googlecode.iterm2`, `key: PromptOnQuit`, and `value: target_user.macos.iterm2.prompt_on_quit` for user `target_user.name`.

### 3.7 nodejs

#### 3.7.1 Role Description

The `nodejs` role handles Node.js installation and npm package management for individual users. This role installs Node.js via Node Version Manager (nvm) and manages global npm packages for a specified user.

#### 3.7.2 Variables

This role uses role-specific variables passed from calling roles (e.g., configure_user):

| Variable        | Type         | Required | Default | Description                                                                |
| --------------- | ------------ | -------- | ------- | -------------------------------------------------------------------------- |
| `node_user`     | string       | Yes      | -       | Target username for Node.js installation                                   |
| `node_packages` | list[string] | No       | `[]`    | Global npm package names to install (e.g., ["typescript", "@angular/cli"]) |

#### 3.7.3 Features and Functionality

##### 3.7.3.1 Node.js Installation

**REQ-NODE-001**: The system SHALL install Node.js via Node Version Manager (nvm) for the specified user

**Implementation**: Uses `ansible.builtin.get_url` to download nvm install script, `ansible.builtin.shell` to install nvm with `become_user: node_user`, and `ansible.builtin.shell` to install latest Node.js LTS version via nvm.

##### 3.7.3.2 npm Package Management

**REQ-NODE-002**: The system SHALL install global npm packages for the specified user

**Implementation**: Uses `ansible.builtin.shell` with `npm install -g {{ item }}` for each package in `node_packages` with `become_user: node_user`. Loop variable name: `item`.

### 3.8 rust

#### 3.8.1 Role Description

The `rust` role handles Rust toolchain installation and cargo package management for individual users. This role installs Rust via rustup and manages cargo packages for a specified user.

#### 3.8.2 Variables

This role uses role-specific variables passed from calling roles (e.g., configure_user):

| Variable        | Type         | Required | Default | Description                                                   |
| --------------- | ------------ | -------- | ------- | ------------------------------------------------------------- |
| `rust_user`     | string       | Yes      | -       | Target username for Rust installation                         |
| `rust_packages` | list[string] | No       | `[]`    | Cargo package names to install (e.g., ["ripgrep", "fd-find"]) |

#### 3.8.3 Features and Functionality

##### 3.8.3.1 Rust Toolchain Installation

**REQ-RUST-001**: The system SHALL install Rust toolchain via rustup for the specified user

**Implementation**: Uses `ansible.builtin.get_url` to download rustup-init script, `ansible.builtin.shell` to install rustup with default settings and `become_user: rust_user`.

##### 3.8.3.2 Cargo Package Management

**REQ-RUST-002**: The system SHALL install cargo packages for the specified user

**Implementation**: Uses `ansible.builtin.shell` with `cargo install {{ item }}` for each package in `rust_packages` with `become_user: rust_user`. Loop variable name: `item`.

### 3.9 go

#### 3.9.1 Role Description

The `go` role handles Go programming language installation and package management for individual users. This role installs Go and manages go packages for a specified user.

#### 3.9.2 Variables

This role uses role-specific variables passed from calling roles (e.g., configure_user):

| Variable      | Type         | Required | Default | Description                                                           |
| ------------- | ------------ | -------- | ------- | --------------------------------------------------------------------- |
| `go_user`     | string       | Yes      | -       | Target username for Go installation                                   |
| `go_packages` | list[string] | No       | `[]`    | Go package URLs to install (e.g., ["github.com/user/package@latest"]) |

#### 3.9.3 Features and Functionality

##### 3.9.3.1 Go Language Installation

**REQ-GO-001**: The system SHALL install Go programming language for the specified user

**Implementation**: Uses `ansible.builtin.get_url` to download Go binary tarball, `ansible.builtin.unarchive` to extract to user's home directory with `owner: go_user`, and `ansible.builtin.lineinfile` to add Go PATH to user's shell profile.

##### 3.9.3.2 Go Package Management

**REQ-GO-002**: The system SHALL install go packages for the specified user

**Implementation**: Uses `ansible.builtin.shell` with `go install {{ item }}` for each package in `go_packages` with `become_user: go_user`. Loop variable name: `item`.

### 3.10 neovim

#### 3.10.1 Role Description

The `neovim` role handles Neovim installation and basic configuration for individual users. This role installs Neovim and sets up basic user configuration.

#### 3.10.2 Variables

This role uses role-specific variables passed from calling roles (e.g., configure_user):

| Variable      | Type   | Required | Default | Description                             |
| ------------- | ------ | -------- | ------- | --------------------------------------- |
| `neovim_user` | string | Yes      | -       | Target username for Neovim installation |

#### 3.10.3 Features and Functionality

##### 3.10.3.1 Neovim Installation

**REQ-NEOVIM-001**: The system SHALL install Neovim for the specified user

**Implementation**: Uses platform-specific package managers: `ansible.builtin.apt` for Debian/Ubuntu, `community.general.pacman` for Arch Linux, and `community.general.homebrew` for macOS.

##### 3.10.3.2 Neovim Configuration

**REQ-NEOVIM-002**: The system SHALL create basic Neovim configuration for the specified user

**Implementation**: Uses `ansible.builtin.file` to create `~{{ neovim_user }}/.config/nvim` directory with `owner: neovim_user` and `ansible.builtin.copy` to deploy basic `init.vim` configuration file.

### 3.11 terminal_config

#### 3.11.1 Role Description

The `terminal_config` role handles terminal emulator configuration for individual users. This role manages terminal emulator settings and preferences based on provided configuration entries.

#### 3.11.2 Variables

This role uses role-specific variables passed from calling roles (e.g., configure_user):

| Variable           | Type         | Required | Default | Description                                       |
| ------------------ | ------------ | -------- | ------- | ------------------------------------------------- |
| `terminal_user`    | string       | Yes      | -       | Target username for terminal configuration        |
| `terminal_entries` | list[object] | Yes      | -       | Terminal configuration entries (see schema below) |

**terminal_entries Object Schema:**

| Field   | Type   | Required | Default | Description                                                |
| ------- | ------ | -------- | ------- | ---------------------------------------------------------- |
| `type`  | string | Yes      | -       | Terminal emulator type ("gnome-terminal", "konsole", etc.) |
| `key`   | string | Yes      | -       | Configuration key name                                     |
| `value` | string | Yes      | -       | Configuration value                                        |

#### 3.11.3 Features and Functionality

##### 3.11.3.1 GNOME Terminal Configuration

**REQ-TERMINAL-001**: The system SHALL configure GNOME Terminal settings for the specified user

**Implementation**: Uses `ansible.builtin.shell` with `gsettings set org.gnome.Terminal.Legacy.Settings:{{ item.key }} {{ item.value }}` for entries where `item.type == 'gnome-terminal'` with `become_user: terminal_user`. Loop variable name: `item`.

##### 3.11.3.2 KDE Konsole Configuration

**REQ-TERMINAL-002**: The system SHALL configure KDE Konsole settings for the specified user

**Implementation**: Uses `ansible.builtin.ini_file` to modify `~{{ terminal_user }}/.config/konsolerc` with `section: {{ item.section }}`, `option: {{ item.key }}`, `value: {{ item.value }}`, and `owner: terminal_user` for entries where `item.type == 'konsole'`. Loop variable name: `item`.

---

## 4. Known Issues and Limitations

### 4.1 Current Known Issues

#### 4.1.1 User Management Dependencies

- **Issue**: Users with package-dependent groups (e.g., `docker`) fail when groups don't exist yet
- **Impact**: User creation fails in `os_configuration` when packages haven't been installed
- **Workaround**: Remove package-dependent groups from user definitions
- **Resolution**: Moving user management to `configure_user` role (v1.2.0)

#### 4.1.2 External Repository Management

- **Issue**: External repositories (Docker CE, NodeJS) fail due to timing and GPG key management
- **Impact**: Package installation failures for non-distribution packages
- **Workaround**: Use distribution packages instead of external repositories
- **Resolution**: Implement proper repository management in v1.2.0

#### 4.1.3 Validation Logic

- **Issue**: User validation reads discovery output instead of configuration input
- **Impact**: Validation reports wrong users as missing/present
- **Workaround**: Manual verification of user creation
- **Resolution**: Refactor validation to preserve input configuration variables

### 4.2 Platform-Specific Limitations

#### 4.2.1 Container Testing

- Hostname changes not supported in containers (use `skip-tags: hostname`)
- Systemd service management limited in containers
- Firewall configuration not testable in containers

#### 4.2.2 macOS Limitations

- Requires elevated privileges for system configuration
- Some Linux-specific modules not available
- Package management differs significantly from Linux

#### 4.2.3 Arch Linux Considerations

- Firewall/iptables kernel modules may be missing in cloud images
- AUR package support requires special handling
- Rolling release model requires flexible version handling
- **Testing Status**: REQ-OS-021/021a/021b tests written but awaiting Arch Linux container implementation
- **Required Containers**: arch-full-positive, arch-partial-enabled, arch-negative-empty, arch-edge-cases for complete Pacman testing

---

## 5. Future Requirements

### 5.2 Long-term Requirements

#### 5.2.1 Platform Expansion

- Move services enable/disable to package management
- Nerd Fonts functionality moved to configure_user role or dedicated role (removed from os_configuration due to role boundary violation - fonts are user preferences, not system configuration, and implementation was platform-specific stopgap)
- Configuration of NTP server

- Configuration of Remote logging (rsyslog)
- Additional Linux distributions (RHEL, CentOS Stream, Fedora)
- Container platform support (Docker, Podman configuration)

#### 5.2.2 Advanced Features

- Configuration templating and environments
- Secrets management integration
- Infrastructure as Code integration (Terraform, CloudFormation)

---

## Document Control

**Approval:** [To be completed]
**Review Schedule:** Quarterly or with major releases
**Distribution:** Development team, DevOps team, Documentation team

---

_This document serves as the single source of truth for wolskies.infrastructure collection requirements. All implementation decisions should reference and align with these specifications._
