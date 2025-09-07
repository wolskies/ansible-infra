# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is an **Ansible Collection** (`wolskinet.infrastructure`) that provides infrastructure automation roles for multi-OS environments (Ubuntu 22+, Debian 12/13, Arch Linux, macOS).

## Prerequisites

### Philosopy/Style

The user is assumed to be a moderately experienced user. That means we can assume the user knows what they are doing and don't need multiple warnings, or erroring out if the configuration isn't supported.

Likewise, as long as our roles are clearly named, and we're using clearly named variables we don't need to add comments that repeat the obvious. Comments should be included where we may do something non-standard (like merging variables to get around ansible's variable hierarchy) or unexpected.

Finally, where there is an existing ansible module (ansible.builtin or community.general) or role by an accepted expert in ansible (like Jeff Geerling), this collection should use those roles to take advantage of the community support and updates, rather than rolling our own.

In the same light, ansible.builtin.command should be considered a last resort where a suitable module can be found -- and ansible.builtin.shell needs my explicit permission to include in a role.

### Supported Operating Systems

The role is intended to support Archlinux, MacOSX, Debian 12+, and Ubuntu 22+. That should be clear to the user in the documentation. There doesn't need to be any excessive version checking.

### macOS Requirements

- **Xcode Command Line Tools**: Required for Ansible to function on macOS
  ```bash
  xcode-select --install
  ```
  These must be installed manually before running any Ansible playbooks on macOS hosts.

## Core Architecture

### Unified Infrastructure Variable Structure

The roles use an identical variable naming convention with the intent of allowing them to work both independently as individual roles, or called as a collection of roles by the `configure_system` role.

Wherever possible, variables are not specified by os, or distribution. In most cases os or distribution differences are taken care of in the tasks themselves either with branching logic or filtering. The sole exception to this is packages because packages names vary widely across distribution and likely need to be distribution specific.

To maintain integrity between roles, the configure_system/defaults/main.yml should be treated as the reference file for the macro variable structure. It needs to be kept up to date, and other roles should mimic the parts they need to function.

### User Management Architecture

User management is split into two distinct roles with clear separation of concerns:

**manage_users** (system-level, sudo required):

- Creates/removes user accounts, groups, SSH keys
- Reads from `infrastructure.domain.users[]`
- Handles system account lifecycle

**configure_user** (per-user, runs as target user):

- Configures user preferences, dotfiles, language packages
- Called per-user with `target_user` variable and `become_user`
- Handles cross-platform settings (Git, nodejs/rust/go packages) and OS-specific preferences (shell, dotfiles, GUI)

### User Configuration Structure

```yaml
infrastructure:
  domain:
    users:
      - name: alice
        # System account fields (manage_users)
        groups: [sudo]
        ssh_pubkey: "ssh-ed25519..."

        # Cross-platform preferences (configure_user)
        git: { user_name: "Alice", user_email: "..." }
        nodejs: { packages: [typescript, eslint] }
        rust: { packages: [ripgrep, bat] }
```

### Language Package Integration

Language ecosystem packages are configured per-user with automatic dependency installation:

- `nodejs.packages` → auto-installs `nodejs` if `npm` not found
- `rust.packages` → auto-installs `rustup` if `cargo` not found
- `go.packages` → auto-installs `golang` if `go` not found

The `manage_language_packages` role was eliminated - this functionality is now integrated into `configure_user`.

### Role Organization

- **configure_system**: Orchestration role that calls other roles based on inventory
- **os_configuration**: Domain/host/distribution OS settings (timezone, hostname, services)
- **manage_users**: System-level account management (sudo)
- **configure_user**: Per-user preferences and language packages (per-user execution)
- **manage_packages**: Distribution-specific package installation
- **manage_security_services**: Firewall and fail2ban configuration
- **manage_snap_packages/manage_flatpak**: Alternative package systems

### Discovery

The discovery role is intended to be a helper or convenience role for the user - it is not intended to drive architecture or variable naming. Rather it can populate a host_vars/{{ hostname }}.yaml file with discovered values that is in the format that the remaining roles use.

### Non-Opinionated with regard to groups and naming

The collection is intended to be generic and not force users into a specific naming convention for groups. Users can organize inventory however they want - the `{{ ansible_distribution }}` fact drives OS-specific behavior.

## Recent Major Changes

### Infrastructure Hierarchy Implementation (2025-01-06)

Completed major architectural refactoring to implement unified variable structure:

1. **Domain Abstraction**: Moved shared settings (timezone, locale, NTP, users) to `infrastructure.domain` level to eliminate duplication across distributions.

2. **User Management Overhaul**:

   - Split user management into system-level (`manage_users`) and user-level (`configure_user`) roles
   - Moved users to `infrastructure.domain.users[]` with cross-platform and OS-specific preferences
   - Eliminated `manage_language_packages` role - functionality integrated into per-user configuration
   - Deleted redundant `configure_users` role

3. **Language Package Architecture**:

   - Language packages (nodejs, rust, go) are now user-scoped preferences
   - Automatic dependency installation when users request packages
   - Cross-platform consistency - same packages work on Ubuntu/Darwin

4. **Updated All Core Roles**:

   - `os_configuration`: Uses domain/host/distribution separation
   - `manage_users`: Creates system accounts from domain user list
   - `configure_user`: Configures per-user preferences (git, language packages, dotfiles, GUI)
   - `manage_packages`, `manage_security_services`, `manage_snap_packages`, `manage_flatpak`: Use unified structure

5. **Documentation Overhaul**: Completely rewrote all core role READMEs and collection README to reflect new architecture with advanced user focus.

6. **Molecule Test Updates**: Updated all molecule tests to use new infrastructure variable structure.

### Key Architectural Decisions Made

- **Domain-level users**: Users defined once in domain, consistent across all hosts
- **Cross-platform language packages**: Git, nodejs, rust, go settings work identically across OS
- **OS-specific preferences**: Shell paths, dotfiles repos, GUI settings vary by OS
- **Automatic dependency installation**: System installs language tools when user requests packages
- **Clean role separation**: System (sudo) vs user (per-user) execution contexts
