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

**REQ-INFRA-002**: Any role using collection variables SHALL respect the defined schema to ensure interoperability.

#### 2.2.1 Collection-Wide Variable Interface

| Variable                              | Type                      | Default         | Description                                                                           |
| ------------------------------------- | ------------------------- | --------------- | ------------------------------------------------------------------------------------- |
| `domain_name`                         | string                    | `""`            | Organization domain name (RFC 1035 format, e.g., "example.com")                       |
| `domain_timezone`                     | string                    | `""`            | System timezone (IANA format, e.g., "America/New_York", "Europe/London")              |
| `domain_locale`                       | string                    | `"en_US.UTF-8"` | System locale (format: language_COUNTRY.encoding, e.g., "en_US.UTF-8", "fr_FR.UTF-8") |
| `domain_language`                     | string                    | `"en_US.UTF-8"` | System language (locale format, e.g., "en_US.UTF-8", "de_DE.UTF-8")                   |
| `host_hostname`                       | string                    | `""`            | System hostname (RFC 1123 format, alphanumeric + hyphens, max 253 chars)              |
| `host_update_hosts`                   | boolean                   | `true`          | Update /etc/hosts with hostname entry                                                 |
| `users`                               | list[object]              | `[]`            | User account definitions (see schema below)                                           |
| `packages`                            | object                    | `{}`            | Package management definitions (see schema below)                                     |
| `host_services.enable`                | list[string]              | `[]`            | Systemd service names to enable (e.g., ["nginx", "postgresql"])                       |
| `host_services.disable`               | list[string]              | `[]`            | Systemd service names to disable (e.g., ["apache2", "sendmail"])                      |
| `host_sysctl.parameters`              | dict[string, string\|int] | `{}`            | Kernel parameter definitions (see schema below)                                       |
| `domain_ntp.enabled`                  | boolean                   | `false`         | Enable NTP time synchronization configuration                                         |
| `domain_ntp.servers`                  | list[string]              | `[]`            | NTP server hostnames/IPs (e.g., ["pool.ntp.org", "time.google.com"])                  |
| `firewall.enabled`                    | boolean                   | `false`         | Enable firewall rule management                                                       |
| `firewall.prevent_ssh_lockout`        | boolean                   | `true`          | Automatically allow SSH during firewall configuration                                 |
| `firewall.package`                    | string                    | `"ufw"`         | Firewall management tool ("ufw", "firewalld", "iptables")                             |
| `firewall.rules`                      | list[object]              | `[]`            | Firewall rule definitions (see schema below)                                          |
| `host_security.hardening_enabled`     | boolean                   | `false`         | Enable devsec.hardening security baseline                                             |
| `host_security.ssh_hardening_enabled` | boolean                   | `false`         | Enable SSH-specific security hardening                                                |

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

**Packages Object Schema:**

| Field                                | Type         | Default | Description                                                               |
| ------------------------------------ | ------------ | ------- | ------------------------------------------------------------------------- |
| `packages.present.all.<OS_Family>`   | list[string] | `[]`    | Package names to install on all systems (e.g., ["git", "curl", "vim"])    |
| `packages.present.group.<OS_Family>` | list[string] | `[]`    | Package names by Ansible inventory group (e.g., ["nginx", "php-fpm"])     |
| `packages.present.host.<OS_Family>`  | list[string] | `[]`    | Host-specific package names (e.g., ["docker-ce", "nodejs"])               |
| `packages.absent.all.<OS_Family>`    | list[string] | `[]`    | Package names to remove from all systems (e.g., ["telnet", "rsh-server"]) |
| `packages.absent.group.<OS_Family>`  | list[string] | `[]`    | Package names to remove by inventory group                                |
| `packages.absent.host.<OS_Family>`   | list[string] | `[]`    | Host-specific package names to remove                                     |

_OS_Family values: Debian, Archlinux, Darwin_

**Firewall Rules Object Schema:**

| Field         | Type            | Required | Default   | Description                                    |
| ------------- | --------------- | -------- | --------- | ---------------------------------------------- |
| `port`        | integer\|string | Yes      | -         | Port number or range (e.g., 22, "8080:8090")   |
| `protocol`    | string          | No       | `"tcp"`   | Protocol ("tcp", "udp", "any")                 |
| `rule`        | string          | No       | `"allow"` | Rule action ("allow", "deny")                  |
| `source`      | string          | No       | `"any"`   | Source IP/CIDR (e.g., "192.168.1.0/24", "any") |
| `destination` | string          | No       | `"any"`   | Destination IP/CIDR                            |
| `comment`     | string          | No       | `""`      | Rule description                               |

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

- A comment explaining why a module cannot be used
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

**REQ-INFRA-009**: Tasks SHALL fail with descriptive error messages when encountering unrecoverable conditions

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

The `os_configuration` role handles fundamental operating system configuration.

#### 3.1.2 Variables

This role uses collection-wide variables from section 2.2.1. No role-specific variables are defined.

#### 3.1.3 Features and Functionality

##### 3.1.3.1 Cross-Platform System Configuration

###### 3.1.3.1.1 Hostname Configuration

**REQ-OS-001**: The system SHALL be capable of setting the system hostname

**Implementation**: Uses `ansible.builtin.hostname` module when `host_hostname` is defined and non-empty.

**REQ-OS-002**: The system SHALL be capable of updating the `/etc/hosts` file with hostname entries

**Implementation**: Uses `ansible.builtin.lineinfile` to update `/etc/hosts` when `host_update_hosts` is true, format: `127.0.0.1 localhost {hostname}.{domain} {hostname}`. Requires both `host_hostname` and `domain_name` to be defined.

###### 3.1.3.1.2 Timezone Configuration

**REQ-OS-003**: The system SHALL be capable of setting the system timezone

**Implementation**: Uses `community.general.timezone` module when `domain_timezone` is defined and non-empty.

##### 3.1.3.2 Linux System Configuration

###### 3.1.3.2.1 Security Hardening

**REQ-OS-004**: The system SHALL be capable of implementing OS security hardening configurations using `devsec.hardening.os_hardening` role

**Implementation**: Uses `ansible.builtin.include_role` to call `devsec.hardening.os_hardening` when security hardening is enabled

**REQ-OS-005**: The system SHALL be capable of applying SSH security hardening on Linux systems

**Implementation**: Uses `devsec.hardening.ssh_hardening` role when `host_security.ssh_hardening_enabled` is true.

###### 3.1.3.2.2 Locale and Language Configuration

**REQ-OS-006**: The system SHALL be capable of setting the system locale on Linux systems

**Implementation**: Uses `community.general.locale_gen` + `ansible.builtin.lineinfile` for `/etc/default/locale` when `domain_locale` is defined.

**REQ-OS-007**: The system SHALL be capable of setting the system language on Linux systems

**Implementation**: Uses `ansible.builtin.lineinfile` for LANGUAGE in `/etc/default/locale` when `domain_language` is defined.

###### 3.1.3.2.3 NTP Time Synchronization

**REQ-OS-008**: The system SHALL be capable of configuring NTP time synchronization on Linux systems

**Implementation**: Uses `ansible.builtin.template` for `/etc/systemd/timesyncd.conf` when `domain_ntp.enabled` is true. Loop variable name: `ntp_server`.

###### 3.1.3.2.4 Journal and Logging Configuration

**REQ-OS-009**: The system SHALL be capable of configuring systemd journal settings on Linux systems

**Implementation**: Uses `ansible.builtin.template` for `/etc/systemd/journald.conf.d/00-ansible-managed.conf` when `journal.configure` is true.

**REQ-OS-010**: The system SHALL be capable of configuring rsyslog for remote logging on Linux systems

**Implementation**: Uses `ansible.builtin.lineinfile` to configure rsyslog remote host when `rsyslog.enabled` is true.

###### 3.1.3.2.5 Service Management

**REQ-OS-011**: The system SHALL be capable of enabling system services on Linux systems

**Implementation**: Uses `ansible.builtin.systemd` for enable/start operations. Loop variable name: `item` (from `host_services.enable`).

**REQ-OS-012**: The system SHALL be capable of disabling system services on Linux systems

**Implementation**: Uses `ansible.builtin.systemd` for disable/stop operations. Loop variable name: `item` (from `host_services.disable`).

**REQ-OS-013**: The system SHALL be capable of masking system services on Linux systems

**Implementation**: Uses `ansible.builtin.systemd` for mask/stop operations. Loop variable name: `item` (from `host_services.mask`).

###### 3.1.3.2.6 Kernel Module Management

**REQ-OS-014**: The system SHALL be capable of loading kernel modules at boot on Linux systems

**Implementation**: Uses `ansible.builtin.lineinfile` for `/etc/modules-load.d/{module}.conf` files. Loop variable name: `item` (from `host_modules.load`).

**REQ-OS-015**: The system SHALL be capable of blacklisting kernel modules on Linux systems

**Implementation**: Uses `ansible.builtin.lineinfile` for `/etc/modprobe.d/blacklist-ansible-managed.conf`. Loop variable name: `item` (from `host_modules.blacklist`).

###### 3.1.3.2.7 Hardware Configuration

**REQ-OS-016**: The system SHALL be capable of deploying custom udev rules on Linux systems

**Implementation**: Uses `ansible.builtin.copy` to deploy rules to `/etc/udev/rules.d/`. Loop variable name: `item` (from `host_udev.rules`).

###### 3.1.3.2.8 Debian/Ubuntu Specific Configuration

**REQ-OS-017**: The system SHALL be capable of configuring APT behavior on Debian/Ubuntu systems

**Implementation**: Uses `ansible.builtin.copy` for `/etc/apt/apt.conf.d/` files (no-recommends, proxy).

**REQ-OS-018**: The system SHALL be capable of configuring APT unattended upgrades on Debian/Ubuntu systems

**Implementation**: Uses `ansible.builtin.template` for `/etc/apt/apt.conf.d/50unattended-upgrades`.

**REQ-OS-019**: The system SHALL be capable of purging snapd on Debian/Ubuntu systems

**Implementation**: Uses `wolskies.infrastructure.manage_snap_packages` role to purge snapd.

**REQ-OS-020**: The system SHALL be capable of installing Nerd Fonts on Debian/Ubuntu systems

**Implementation**: Uses `ansible.builtin.unarchive` to download and install fonts. Loop variable name: `font_item`.

###### 3.1.3.2.9 Arch Linux Specific Configuration

**REQ-OS-021**: The system SHALL be capable of configuring Pacman behavior on Arch Linux systems

**Implementation**: Uses `ansible.builtin.lineinfile` to modify `/etc/pacman.conf` for NoConfirm, multilib repository, and proxy settings.

##### 3.1.3.3 macOS System Configuration

###### 3.1.3.3.1 Locale and Language Configuration

**REQ-OS-022**: The system SHALL be capable of setting the system locale on macOS systems

**Implementation**: Uses `community.general.osx_defaults` with NSGlobalDomain/AppleLocale when `domain_locale` is defined.

**REQ-OS-023**: The system SHALL be capable of setting the system language on macOS systems

**Implementation**: Uses `community.general.osx_defaults` with NSGlobalDomain/AppleLanguages when `domain_language` is defined.

###### 3.1.3.3.2 NTP Time Synchronization

**REQ-OS-024**: The system SHALL be capable of configuring NTP time synchronization on macOS systems

**Implementation**: Uses `ansible.builtin.command` with `systemsetup` utility when `domain_ntp.enabled` is true.

###### 3.1.3.3.3 Software Updates

**REQ-OS-025**: The system SHALL be capable of configuring macOS automatic updates

**Implementation**: Uses `community.general.osx_defaults` for `/Library/Preferences/com.apple.SoftwareUpdate`. Loop variable name: `item`.

###### 3.1.3.3.4 Security Configuration

**REQ-OS-026**: The system SHALL be capable of configuring macOS Gatekeeper security

**Implementation**: Uses `ansible.builtin.command` with `spctl` utility when `macosx.gatekeeper.enabled` is defined.

###### 3.1.3.3.5 System Preferences

**REQ-OS-027**: The system SHALL be capable of configuring macOS system preferences

**Implementation**: Uses `community.general.osx_defaults` with NSGlobalDomain. Loop variable name: `item`.

###### 3.1.3.3.6 Network Configuration

**REQ-OS-028**: The system SHALL be capable of configuring AirDrop over Ethernet

**Implementation**: Uses `community.general.osx_defaults` for `com.apple.NetworkBrowser` when `macosx.airdrop.ethernet_enabled` is defined.

---

### 3.2 manage_security_services

#### 3.2.1 Role Description

The `manage_security_services` role handles firewall configuration and intrusion prevention services.

#### 3.2.2 Variables

This role uses collection-wide variables from section 2.2.1 (firewall._, fail2ban._). No role-specific variables are defined.

#### 3.2.3 Features and Functionality

##### 3.2.3.1 Linux Security Services

###### 3.2.3.1.1 UFW Firewall Management

**REQ-SS-001**: The system SHALL be capable of managing firewalls via UFW on Linux systems

**Implementation**: Uses `ansible.builtin.package` to install UFW package and `community.general.ufw` module for configuration when `firewall.enabled` is true.

**REQ-SS-002**: The system SHALL not inadvertently interrupt SSH access during firewall operations

**Implementation**: Uses `ansible.builtin.set_fact` to detect SSH port from `ansible_env.SSH_CONNECTION` when `firewall.prevent_ssh_lockout` is enabled.

**REQ-SS-003**: The system SHALL be capable of configuring firewall rules on Linux systems

**Implementation**: Uses `community.general.ufw` module to apply firewall rules. Loop variable name: `item` (from `firewall.rules`).

**REQ-SS-004**: The system SHALL be capable of enabling UFW firewall service on Linux systems

**Implementation**: Uses `community.general.ufw` with `state: enabled` when `firewall.enabled` is true.

###### 3.2.3.1.2 Fail2ban Intrusion Prevention

**REQ-SS-005**: The system SHALL be capable of installing fail2ban on Linux systems

**Implementation**: Uses `ansible.builtin.package` to install fail2ban package when `fail2ban.enabled` is true.

**REQ-SS-006**: The system SHALL be capable of configuring fail2ban jails on Linux systems

**Implementation**: Uses `ansible.builtin.template` to deploy `/etc/fail2ban/jail.local` configuration when `fail2ban.enabled` is true.

**REQ-SS-007**: The system SHALL be capable of managing fail2ban service state on Linux systems

**Implementation**: Uses `ansible.builtin.service` to control fail2ban service state based on `fail2ban.enabled` setting.

##### 3.2.3.2 macOS Security Services

###### 3.2.3.2.1 Application Layer Firewall Management

**REQ-SS-008**: The system SHALL be capable of checking firewall state on macOS systems

**Implementation**: Uses `ansible.builtin.command` with `/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate` to query current state.

**REQ-SS-009**: The system SHALL be capable of enabling/disabling Application Layer Firewall on macOS systems

**Implementation**: Uses `ansible.builtin.command` with `/usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate` when `firewall.enabled` is defined.

**REQ-SS-010**: The system SHALL be capable of configuring stealth mode on macOS systems

**Implementation**: Uses `ansible.builtin.command` with `/usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode` when `firewall.stealth_mode` is defined.

**REQ-SS-011**: The system SHALL be capable of configuring block all setting on macOS systems

**Implementation**: Uses `ansible.builtin.command` with `/usr/libexec/ApplicationFirewall/socketfilterfw --setblockall` when `firewall.block_all` is defined.

**REQ-SS-012**: The system SHALL be capable of configuring firewall logging on macOS systems

**Implementation**: Uses `ansible.builtin.command` with `/usr/libexec/ApplicationFirewall/socketfilterfw --setloggingmode` when `firewall.logging` is defined and logging options are available.

### 3.3 manage_packages

#### 3.3.1 Role Description

The `manage_packages` role handles package management across different operating systems and package managers.

#### 3.3.2 Variables

This role uses collection-wide variables from section 2.2.1 (packages._, apt._, pacman._, homebrew._). No role-specific variables are defined.

#### 3.3.3 Features and Functionality

##### 3.3.3.1 Cross-Platform Package Management

###### 3.3.3.1.1 Package Merging and Organization

**REQ-MP-001**: The system SHALL merge packages defined at the global ("all") level with packages defined at the group level and packages defined at the host level

**Implementation**: Uses `ansible.builtin.set_fact` to merge packages from `packages.present.all[ansible_distribution]`, `packages.present.group[ansible_distribution]`, and `packages.present.host[ansible_distribution]` into `merged_packages_install`. Similarly merges `packages.remove.all[ansible_distribution]`, `packages.remove.group[ansible_distribution]`, and `packages.remove.host[ansible_distribution]` into `merged_packages_remove`. Uses `unique | list` filter to eliminate duplicates.

##### 3.3.3.2 Debian/Ubuntu Package Management

###### 3.3.3.2.1 APT Repository Management

**REQ-MP-002**: The system SHALL merge APT repositories defined at the global ("all") level with repositories defined at the group level and repositories defined at the host level

**Implementation**: Uses `ansible.builtin.set_fact` to merge repositories from `apt.repositories.all[ansible_distribution]`, `apt.repositories.group[ansible_distribution]`, and `apt.repositories.host[ansible_distribution]` into `merged_apt_repositories`. Uses `unique | list` filter to eliminate duplicates.

**REQ-MP-003**: The system SHALL be capable of managing APT repositories using deb822 format

**Implementation**: Uses `ansible.builtin.file` to remove legacy `.list` files from `/etc/apt/sources.list.d/` and `.asc` GPG keys from `/etc/apt/trusted.gpg.d/` for any repository name in `merged_apt_repositories` (removes multiple naming variations including `{name}.list`, `{name-with-dashes}.list`, and `download_{name}.list`). Then uses `ansible.builtin.deb822_repository` module for repository management. Loop variable names: `file_item` (cleanup), `item` (repository management).

**Note**: Cleanup is necessary because `deb822_repository` module does not interact with legacy formats, leading to duplicate repository entries if legacy files are not removed.

**REQ-MP-004**: The system SHALL ensure APT repository dependencies are present whenever managing repositories

**Implementation**: Uses `ansible.builtin.apt` to install `apt-transport-https`, `ca-certificates`, `python3-debian`, and `gnupg` packages when repositories are being configured.

###### 3.3.3.2.2 APT Package Management

**REQ-MP-005**: The system SHALL update the APT cache before attempting to install packages

**Implementation**: Uses `ansible.builtin.apt` with `update_cache: true` and configurable cache validity time.

**REQ-MP-006**: The system SHALL be capable of removing packages via APT

**Implementation**: Uses `ansible.builtin.apt` with `state: absent` for packages in `merged_packages_remove`.

**REQ-MP-007**: The system SHALL be capable of installing packages via APT

**Implementation**: Uses `ansible.builtin.apt` with `state: present` for packages in `merged_packages_install`.

**REQ-MP-008**: The system SHALL be capable of performing system upgrades via APT

**Implementation**: Uses `ansible.builtin.apt` with configurable upgrade type when `apt.system_upgrade.enable` is true.

##### 3.3.3.3 Arch Linux Package Management

###### 3.3.3.3.1 Pacman Package Management

**REQ-MP-009**: The system SHALL be capable of updating Pacman package cache

**Implementation**: Uses `community.general.pacman` with `update_cache: true`.

**REQ-MP-010**: The system SHALL be capable of removing packages via Pacman

**Implementation**: Uses `community.general.pacman` with `state: absent` for packages in `merged_packages_remove`.

**REQ-MP-011**: The system SHALL be capable of upgrading all Pacman packages

**Implementation**: Uses `community.general.pacman` with `upgrade: true`.

**REQ-MP-012**: The system SHALL be capable of disabling AUR package installation

**Implementation**: Uses `community.general.pacman` with `state: present` when `pacman.enable_aur` is false, restricting package installation to official repositories only.

###### 3.3.3.3.2 AUR Package Management

**REQ-MP-013**: The system SHALL be capable of managing AUR packages when enabled

**Implementation**: Uses `ansible.builtin.lineinfile` to configure passwordless sudo for pacman operations, then uses `kewlfft.aur.aur` module with paru as the preferred AUR helper when `pacman.enable_aur` is true.

**Note**: AUR package management requires passwordless sudo access to `/usr/bin/pacman` for the ansible user to enable automated package installation. This is limited to the pacman binary only, not full system access.

##### 3.3.3.4 macOS Package Management

###### 3.3.3.4.1 Homebrew Package Management

**REQ-MP-014**: The system SHALL be capable of managing Homebrew packages and casks

**Implementation**: Merges casks from `packages.casks_present.all`, `packages.casks_present.group`, and `packages.casks_present.host` into `merged_homebrew_casks_install`. Merges cask removals from `packages.casks_remove` into `merged_homebrew_casks_remove`. Uses `geerlingguy.mac.homebrew` role with variables: `homebrew_installed_packages`, `homebrew_uninstalled_packages`, `homebrew_cask_apps`, `homebrew_cask_uninstalled_apps`, `homebrew_cask_appdir: /Applications`.

**REQ-MP-015**: The system SHALL be capable of managing Homebrew taps

**Implementation**: Uses `geerlingguy.mac.homebrew` role with `homebrew_taps` from `homebrew.taps` configuration and `homebrew_clear_cache` from `homebrew.cleanup_cache`.

### 3.4 manage_snap_packages

#### 3.4.1 Role Description

The `manage_snap_packages` role manages both snapd and snapd packages on Debian/Ubuntu systems.

#### 3.4.2 Variables

This role uses collection-wide variables from section 2.2.1 (snap.\*). No role-specific variables are defined.

#### 3.4.3 Features and Functionality

##### 3.4.3.1 Snap System Removal

###### 3.4.3.1.1 Complete Snap System Disabling

**REQ-MSP-001**: The system SHALL be capable of completely removing the snap package system from Debian/Ubuntu systems

**Implementation**: Uses `ansible.builtin.command` to list and remove all installed snap packages (except core packages which are removed last), `ansible.builtin.systemd` to stop and disable snapd services, `ansible.builtin.apt` to purge snapd packages, `ansible.builtin.file` to remove snap directories, and `ansible.builtin.lineinfile` to remove snap from PATH. Loop variable names: `snap_line` (package removal), `snapd_service` (service management), `snap_dir` (directory cleanup).

**REQ-MSP-002**: The system SHALL prevent snap packages from being reinstalled after removal

**Implementation**: Uses `ansible.builtin.copy` to create `/etc/apt/preferences.d/no-snap` with Pin-Priority: -10 to prevent snapd and gnome-software-plugin-snap from being installed.

##### 3.4.3.2 Snap Package Management

###### 3.4.3.2.1 Snap Package Installation and Removal

**REQ-MSP-003**: The system SHALL be capable of managing individual snap packages when snap system is enabled

**Implementation**: Ensures snapd is installed via `ansible.builtin.apt`, starts services via `ansible.builtin.systemd`, waits for system readiness via `ansible.builtin.command`, then uses `community.general.snap` for package installation and removal. Loop variable names: `snapd_service` (service management), `snap_package` (package operations).

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

**REQ-MF-004**: The system SHALL be capable of removing flatpak packages

**Implementation**: Uses `community.general.flatpak` with `state: absent`, configurable method from `flatpak.method`, and user from `flatpak.user`. Loop variable name: `flatpak_package` (from `flatpak.packages.remove`).

**REQ-MF-005**: The system SHALL be capable of installing flatpak packages

**Implementation**: Uses `community.general.flatpak` with `state: present`, configurable method from `flatpak.method`, and user from `flatpak.user`. Loop variable name: `flatpak_package` (from `flatpak.packages.install`).

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

---

## 5. Future Requirements

### 5.1 v1.2.0 Target Requirements

#### 5.1.1 User Management Refactor

- Move all user management from `os_configuration` to `configure_user`
- Implement execution order: os_config → packages → users
- Add superuser privilege management with platform detection

#### 5.1.2 Repository Management Enhancement

- Implement external APT repository management with GPG key handling
- Support for Docker CE, NodeJS, PostgreSQL, Kubernetes, HashiCorp repositories
- Proper error handling and recovery for repository failures

#### 5.1.3 Enhanced Testing

- Comprehensive edge case coverage for all roles
- VM testing matrix across all supported platforms
- Automated validation and regression testing

### 5.2 Long-term Requirements

#### 5.2.1 Platform Expansion

- Windows support evaluation
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
