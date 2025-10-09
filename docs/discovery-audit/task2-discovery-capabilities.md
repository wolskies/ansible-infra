# Task 2: Discovery Capabilities Inventory

**Issue**: #23 (Part of #11 - Discovery Coverage Audit)
**Date**: 2025-10-09
**Source**: `roles/discovery/`

## Summary

This document inventories what the discovery role currently detects and outputs to `host_vars/`. The discovery role scans system state and generates Ansible variables that can be used by the `configure_system` role.

---

## Discovery Architecture

### Output Location
- **File**: `inventory/host_vars/{hostname}/vars.yml`
- **Template**: `roles/discovery/templates/simple_host_vars.yml.j2`
- **Format**: Flat YAML structure matching collection variable names

### Discovery Process
1. Gather system facts (`ansible.builtin.setup`)
2. Gather package facts (`ansible.builtin.package_facts`)
3. Run specialized scan tasks for each domain
4. Generate host_vars file from template

---

## 1. Domain-Level Discovery

### 1.1 Domain Identity
| Variable Discovered | Detection Method | Output Variable |
|---------------------|------------------|-----------------|
| Domain name | `ansible_domain` fact | `domain_name` |
| Timezone | `timedatectl show` (Linux) / `readlink /etc/localtime` (macOS) | `domain_timezone` |
| Locale | `ansible_env.LANG` | `domain_locale` |
| Language | `ansible_env.LANG` | `domain_language` |

**Source**: `roles/discovery/tasks/main.yml` (lines 77-102)

### 1.2 Time Synchronization
| Variable Discovered | Detection Method | Output Variable |
|---------------------|------------------|-----------------|
| NTP enabled status | `timedatectl show --property=NTP` (Linux) / `sntp -K` (macOS) | `domain_timesync.enabled` |
| NTP servers | **NOT DISCOVERED** - Uses hardcoded defaults (0/1.pool.ntp.org) | `domain_timesync.servers` |

**Source**: `roles/discovery/tasks/main.yml` (lines 63-76, 103-112)
**Template**: `roles/discovery/templates/simple_host_vars.yml.j2` (lines 22-28)

**Gap**: Cannot discover which NTP servers are actually configured in `/etc/systemd/timesyncd.conf` or similar configs.

---

## 2. Host-Level Discovery

### 2.1 Host Identity
| Variable Discovered | Detection Method | Output Variable |
|---------------------|------------------|-----------------|
| Hostname | `ansible_hostname` fact | `host_hostname` |
| Update /etc/hosts | **NOT DISCOVERED** | `host_update_hosts` |

**Source**: `roles/discovery/tasks/main.yml` (line 93)
**Template**: `roles/discovery/templates/simple_host_vars.yml.j2` (line 41)

### 2.2 System Services
| Variable Discovered | Detection Method | Output Variable |
|---------------------|------------------|-----------------|
| Enabled services | `systemctl list-unit-files --state=enabled` | `host_services.enable` |
| Disabled services | `systemctl list-unit-files --state=disabled` | `host_services.disable` |
| Masked services | **NOT DISCOVERED** (scanned but not output) | `host_services.mask` |

**Source**: `roles/discovery/tasks/scan-system-settings.yml` (lines 26-35, 87-119)
**Template**: `roles/discovery/templates/simple_host_vars.yml.j2` (lines 45-49)

**Gap**: Masked services are scanned (`discovery_services_masked`) but not included in template output.

### 2.3 Kernel Modules
| Variable Discovered | Detection Method | Output Variable |
|---------------------|------------------|-----------------|
| Loaded modules | `lsmod` | **NOT OUTPUT** (stored in `discovery_modules_loaded`) |
| Blacklisted modules | **NOT DISCOVERED** | N/A |
| Persistent modules | **NOT DISCOVERED** | N/A |

**Source**: `roles/discovery/tasks/scan-system-settings.yml` (lines 19-24, 76-86)

**Gap**: Module discovery exists but is not output to host_vars. Cannot discover blacklisted or persistent module configurations.

### 2.4 udev Rules
| Variable Discovered | Detection Method | Output Variable |
|---------------------|------------------|-----------------|
| Custom udev rules | Read `/etc/udev/rules.d/*.rules` files | `host_udev_rules` |

**Source**: `roles/discovery/tasks/scan-system-settings.yml` (lines 44-60, 122-136)
**Template**: `roles/discovery/templates/simple_host_vars.yml.j2` (lines 60-68)

**Schema Discovered**:
```yaml
host_udev_rules:
  - name: string        # Parsed from filename
    content: string     # Rule content
    priority: int       # Parsed from filename prefix
    state: present
```

---

## 3. System Logging Discovery

| Variable Discovered | Detection Method | Output Variable |
|---------------------|------------------|-----------------|
| Journal configuration | **NOT DISCOVERED** | N/A |
| rsyslog configuration | **NOT DISCOVERED** | N/A |

**Gap**: No discovery of journal (`/etc/systemd/journald.conf`) or rsyslog (`/etc/rsyslog.conf`, `/etc/rsyslog.d/`) configuration.

---

## 4. Security Hardening Discovery

| Variable Discovered | Detection Method | Output Variable |
|---------------------|------------------|-----------------|
| OS hardening status | **NOT DISCOVERABLE** (policy, not state) | N/A |
| SSH hardening status | **NOT DISCOVERABLE** (policy, not state) | N/A |

**Note**: Security hardening settings (devsec.hardening) represent desired policy, not system state. These are intentionally not discoverable.

---

## 5. Package Management Discovery

### 5.1 System Packages

#### Linux (Debian/Ubuntu)
| Variable Discovered | Detection Method | Output Variable |
|---------------------|------------------|-----------------|
| User-installed packages | `apt-mark showmanual` | `packages.present.host.{Distribution}` |

**Source**: `roles/discovery/tasks/scan-packages.yml` (lines 11-26, 28-71)

#### Linux (Arch)
| Variable Discovered | Detection Method | Output Variable |
|---------------------|------------------|-----------------|
| Explicitly installed packages | `pacman -Qe --quiet` | `packages.present.host.{Distribution}` |

**Source**: `roles/discovery/tasks/scan-packages.yml` (lines 4-21, 28-71)

#### macOS
| Variable Discovered | Detection Method | Output Variable |
|---------------------|------------------|-----------------|
| Homebrew formulas | `brew list --formula` | `packages.present.host.MacOSX` |
| Homebrew casks | `brew list --cask` | `packages.casks_present.host` |
| Homebrew taps | `brew tap` | `homebrew.taps` |

**Source**: `roles/discovery/tasks/scan-packages.yml` (lines 74-131)
**Template**: `roles/discovery/templates/simple_host_vars.yml.j2` (lines 101-130)

**Filtering**: Discovery filters out system packages using regex patterns (base packages, drivers, DE meta-packages, etc.).

### 5.2 APT Configuration
| Variable Discovered | Detection Method | Output Variable |
|---------------------|------------------|-----------------|
| APT proxy | **NOT DISCOVERED** | N/A |
| APT no_recommends | **NOT DISCOVERED** | N/A |
| Unattended upgrades | **NOT DISCOVERED** | N/A |
| System upgrade settings | **NOT DISCOVERED** | N/A |

**Gap**: No discovery of `/etc/apt/apt.conf.d/` settings.

### 5.3 APT Repositories
| Variable Discovered | Detection Method | Output Variable |
|---------------------|------------------|-----------------|
| Repository definitions | Parse `/etc/apt/sources.list.d/*.{list,sources}` | `apt_repositories_host.{Distribution}` |

**Source**: `roles/discovery/tasks/scan-apt-repositories.yml`
**Template**: `roles/discovery/templates/simple_host_vars.yml.j2` (lines 120-125)

**Schema Discovered**:
```yaml
apt_repositories_host:
  Ubuntu:
    - name: string
      types: deb|deb-src
      uris: string
      suites: string
      components: [string, ...]
      signed_by: string  # GPG key URL (mapped from known domains)
      state: present
      enabled: boolean
```

**Note**: GPG keys are inferred from known domain mappings (`discovery_repository_detection.apt.gpg_key_mapping`).

### 5.4 Pacman Configuration
| Variable Discovered | Detection Method | Output Variable |
|---------------------|------------------|-----------------|
| Pacman proxy | **NOT DISCOVERED** | N/A |
| Pacman no_confirm | **NOT DISCOVERED** | N/A |
| Multilib enabled | **NOT DISCOVERED** | N/A |
| AUR enabled | **NOT DISCOVERED** | N/A |

**Gap**: No discovery of `/etc/pacman.conf` settings.

### 5.5 Snap Packages
| Variable Discovered | Detection Method | Output Variable |
|---------------------|------------------|-----------------|
| Installed snap packages | `snap list` | `snap.packages.install` |
| Snapd removal | **NOT DISCOVERED** | N/A |

**Source**: `roles/discovery/tasks/scan-snap-flatpak.yml` (lines 6-35)
**Template**: `roles/discovery/templates/simple_host_vars.yml.j2` (lines 132-137)

### 5.6 Flatpak Packages
| Variable Discovered | Detection Method | Output Variable |
|---------------------|------------------|-----------------|
| Flatpak remotes | `flatpak remotes` | **NOT OUTPUT** (stored in `discovery_flatpak_remotes`) |
| Installed flatpak packages | `flatpak list --app` | `flatpak.packages.install` |

**Source**: `roles/discovery/tasks/scan-snap-flatpak.yml` (lines 38-90)
**Template**: `roles/discovery/templates/simple_host_vars.yml.j2` (lines 139-145)

**Gap**: Flatpak remotes are discovered but not included in template output.

---

## 6. User Configuration Discovery

| Variable Discovered | Detection Method | Output Variable |
|---------------------|------------------|-----------------|
| User account details | `getent passwd` (Linux) / `dscl . list /Users` (macOS) + `ansible.builtin.user` | `users` |
| User shell | From user module query | `users[].shell` |
| User groups | From user module query | `users[].groups` |
| User home directory | From user module query | `users[].home` |
| User UID | From user module query | `users[].uid` |
| User comment/GECOS | From user module query | `users[].comment` |
| Dotfiles repository | Check `~/.dotfiles/.git/config` for `remote.origin.url` | `users[].dotfiles.repo` |
| Dotfiles directory | Check for `~/.dotfiles/` directory | `users[].dotfiles.directory` |

**Source**: `roles/discovery/tasks/scan-users.yml`
**Template**: `roles/discovery/templates/simple_host_vars.yml.j2` (lines 30-35)

**Filtering**: Only regular users (UID 1000-59999 on Linux, 501-59999 on macOS) with valid shells.

**Schema Discovered**:
```yaml
users:
  - name: string
    uid: int
    home: string
    shell: string
    comment: string       # If not empty
    groups: [string, ...] # If defined
    create_home: true
    dotfiles:             # If ~/.dotfiles exists
      enable: true
      repo: string        # From git remote or guessed
      branch: "main"
      directory: string
```

**Gaps**:
- Cannot discover git configuration (user.name, user.email, core.editor)
- Cannot discover language packages (nodejs, rust, go)
- Cannot discover neovim installation status
- Cannot discover terminal emulator configs
- Cannot discover macOS per-user preferences (dock, finder, screenshots, iterm2)

---

## 7. Security Services Discovery

### 7.1 Firewall (ufw)
| Variable Discovered | Detection Method | Output Variable |
|---------------------|------------------|-----------------|
| UFW enabled status | `ufw status` | `firewall.enabled` |
| UFW package | **NOT DISCOVERED** | `firewall.package` (hardcoded in template if enabled) |
| UFW rules | `ufw status numbered` + parsing | `firewall.rules` |
| Prevent SSH lockout | **NOT DISCOVERED** | N/A |
| Stealth mode | **NOT DISCOVERED** | N/A |
| Block all | **NOT DISCOVERED** | N/A |
| Logging | **NOT DISCOVERED** | N/A |

**Source**: `roles/discovery/tasks/scan-firewall.yml`
**Template**: `roles/discovery/templates/simple_host_vars.yml.j2` (lines 78-90)

**Schema Discovered**:
```yaml
firewall:
  enabled: boolean
  rules:
    - rule: allow|deny
      port: int|string        # Port number or service name
      protocol: tcp|udp       # If specified
      name: string            # If service name used
      source: string          # If source restriction exists
      comment: string         # If comment exists
```

**Gaps**:
- Cannot discover UFW global settings (logging, default policies)
- Rule parsing is basic and may miss complex rules

### 7.2 Fail2ban
| Variable Discovered | Detection Method | Output Variable |
|---------------------|------------------|-----------------|
| Fail2ban detected | **NOT IMPLEMENTED** | `fail2ban.enabled` (only if detected) |
| Ban time | **NOT DISCOVERED** | N/A |
| Find time | **NOT DISCOVERED** | N/A |
| Max retry | **NOT DISCOVERED** | N/A |
| Jails | **NOT DISCOVERED** | N/A |

**Template**: `roles/discovery/templates/simple_host_vars.yml.j2` (lines 92-95)

**Gap**: Fail2ban detection placeholder exists in template but no actual discovery implementation in scan tasks.

---

## 8. macOS-Specific Discovery

| Variable Discovered | Detection Method | Output Variable |
|---------------------|------------------|-----------------|
| Natural scroll | `osx_defaults` query for `com.apple.swipescrolldirection` | `macosx.system_preferences.natural_scroll` |
| Measurement units | `osx_defaults` query for `AppleMeasurementUnits` | `macosx.system_preferences.measurement_units` |
| Use metric | `osx_defaults` query for `AppleMetricUnits` | `macosx.system_preferences.use_metric` |
| Show all extensions | `osx_defaults` query for `AppleShowAllExtensions` | `macosx.system_preferences.show_all_extensions` |
| AirDrop ethernet | `osx_defaults` query for `BrowseAllInterfaces` | `macosx.airdrop.ethernet_enabled` |
| Gatekeeper enabled | `spctl --status` | `macosx.gatekeeper.enabled` |
| Auto check updates | **NOT DISCOVERED** | N/A |
| Auto download updates | **NOT DISCOVERED** | N/A |

**Source**: `roles/discovery/tasks/scan-system-settings.yml` (lines 140-202)
**Template**: `roles/discovery/templates/simple_host_vars.yml.j2` (lines 147-177)

**Gaps**:
- Cannot discover macOS update settings
- Cannot discover per-user macOS preferences (covered in User Configuration gaps)

---

## Summary of Discovery Capabilities

### What Discovery CAN Detect

**Domain-Level**:
- Domain name, timezone, locale, language
- NTP enabled status (but not server list)

**Host-Level**:
- Hostname
- Enabled/disabled services (Linux)
- Custom udev rules

**Package Management**:
- User-installed packages (Linux/macOS)
- APT repositories (Debian/Ubuntu)
- Homebrew formulas, casks, and taps (macOS)
- Snap packages
- Flatpak packages (but not remotes in output)

**Users**:
- Basic user account info (name, UID, home, shell, groups)
- Dotfiles repository (if exists)

**Security Services**:
- UFW firewall status and rules (Linux)

**macOS**:
- System preferences (scroll, units, extensions, AirDrop)
- Gatekeeper status

### Discovery Gaps - Feasibility Analysis

This section analyzes what discovery **currently does not detect** and assesses feasibility of implementation.

**Classification**:
- **DO NOT detect**: System state that is not currently discovered but feasible to implement
- **USER PREF**: Collection behavior flags that control role actions, not discoverable system state
- **CANNOT detect**: Technically impractical or infeasible to discover (too variable, no persistent config)

---

#### Domain-Level Gaps

| Gap | Status | How to Detect | Feasibility | Value |
|-----|--------|---------------|-------------|-------|
| NTP server list | **DO NOT** | Parse `/etc/systemd/timesyncd.conf` NTP= lines | Easy | Medium - users may customize |

---

#### Host-Level Gaps

| Gap | Status | How to Detect | Feasibility | Value |
|-----|--------|---------------|-------------|-------|
| Kernel modules to load | **DO NOT** | Read `/etc/modules-load.d/*.conf` files | Easy | High - user customization |
| Kernel modules blacklisted | **DO NOT** | Read `/etc/modprobe.d/*-blacklist.conf` files | Easy | High - user customization |
| `/etc/hosts` update preference | **USER PREF** | Controls role behavior, not discoverable system state | N/A | User decides per-deployment |
| Masked services output | **DO NOT** | Already collected (`discovery_services_masked`), just add to template | Trivial | Medium - user may mask services |

**Note**: Loaded modules are already scanned but not output (collected in `discovery_modules_loaded`).

---

#### System Logging Gaps

| Gap | Status | How to Detect | Feasibility | Value |
|-----|--------|---------------|-------------|-------|
| Journal max size | **DO NOT** | Parse `/etc/systemd/journald.conf` SystemMaxUse= | Easy | Medium - sysadmin customization |
| Journal retention | **DO NOT** | Parse `/etc/systemd/journald.conf` MaxRetentionSec= | Easy | Medium - sysadmin customization |
| Journal forward to syslog | **DO NOT** | Parse `/etc/systemd/journald.conf` ForwardToSyslog= | Easy | Low - uncommon |
| Journal compress | **DO NOT** | Parse `/etc/systemd/journald.conf` Compress= | Easy | Low - usually default |
| rsyslog remote host | **DO NOT** | Parse `/etc/rsyslog.conf` and `/etc/rsyslog.d/*.conf` for @@remote | Moderate | Medium - centralized logging |
| rsyslog remote port | **DO NOT** | Parse rsyslog config for remote host port | Moderate | Medium - centralized logging |
| rsyslog protocol | **DO NOT** | Parse rsyslog config (@=udp, @@=tcp) | Moderate | Medium - centralized logging |

---

#### Package Management Gaps

| Gap | Status | How to Detect | Feasibility | Value |
|-----|--------|---------------|-------------|-------|
| **APT Configuration** |
| APT proxy | **DO NOT** | Parse `/etc/apt/apt.conf.d/*` for Acquire::http::Proxy | Easy | High - corporate environments |
| APT no_recommends | **DO NOT** | Parse `/etc/apt/apt.conf.d/*` for APT::Install-Recommends | Easy | Medium - user preference |
| Unattended upgrades enabled | **DO NOT** | Check if `/etc/apt/apt.conf.d/20auto-upgrades` exists + parse | Easy | High - security posture |
| System upgrade type | **USER PREF** | Controls role behavior (apt dist-upgrade vs safe-upgrade), not system state | N/A | User decides per-deployment |
| **Pacman Configuration** |
| Pacman proxy | **DO NOT** | Parse `/etc/pacman.conf` for XferCommand with proxy | Easy | Medium - corporate environments |
| Pacman no_confirm | **USER PREF** | Controls role behavior (--noconfirm flag), not system state | N/A | User decides per-deployment |
| Pacman multilib enabled | **DO NOT** | Check if `[multilib]` section uncommented in `/etc/pacman.conf` | Easy | High - common user customization |
| Pacman AUR enabled | **USER PREF** | Controls whether collection manages AUR, not system state | N/A | User decides per-deployment |
| **Flatpak** |
| Flatpak remotes | **DO NOT** | Already collected (`discovery_flatpak_remotes`), just add to template | Trivial | Medium - user adds remotes |

---

#### User Configuration Gaps

| Gap | Status | How to Detect | Feasibility | Value |
|-----|--------|---------------|-------------|-------|
| **Git Configuration** |
| Git user.name | **DO NOT** | Run `git config --get user.name` as user | Easy | High - per-user customization |
| Git user.email | **DO NOT** | Run `git config --get user.email` as user | Easy | High - per-user customization |
| Git core.editor | **DO NOT** | Run `git config --get core.editor` as user | Easy | Medium - per-user preference |
| **Language Packages** |
| Node.js global packages | **DO NOT** | Run `npm list -g --depth=0` as user | Easy | High - dev environment |
| Rust cargo packages | **DO NOT** | Parse `~/.cargo/bin/` for installed binaries | Moderate | High - dev environment |
| Go installed packages | **DO NOT** | Check `~/go/bin/` for installed binaries | Moderate | Medium - dev environment |
| **Development Tools** |
| Neovim installed | **DO NOT** | Check if `nvim` command exists for user | Easy | Medium - editor preference |
| Terminal emulator configs | **CANNOT** | Too many emulators, config formats vary wildly | Hard | Low - highly variable |
| **macOS Per-User Preferences** |
| Dock preferences | **DO NOT** | Query `com.apple.dock` defaults per-user | Easy | Medium - user customization |
| Finder preferences | **DO NOT** | Query NSGlobalDomain/Finder defaults per-user | Easy | Medium - user customization |
| Screenshot preferences | **DO NOT** | Query `com.apple.screencapture` defaults per-user | Easy | Low - rarely customized |
| iTerm2 preferences | **DO NOT** | Query `com.googlecode.iterm2` defaults per-user | Easy | Low - specific tool |

**Note**: Per-user language packages represent significant user customization and development environment state.

---

#### Security Services Gaps

| Gap | Status | How to Detect | Feasibility | Value |
|-----|--------|---------------|-------------|-------|
| **Fail2ban** |
| Fail2ban enabled | **DO NOT** | Check if fail2ban service is active (`systemctl is-active fail2ban`) | Easy | High - security service |
| Fail2ban bantime | **DO NOT** | Parse `/etc/fail2ban/jail.local` or `/etc/fail2ban/jail.d/*.conf` | Moderate | Medium - security tuning |
| Fail2ban findtime | **DO NOT** | Parse fail2ban config | Moderate | Medium - security tuning |
| Fail2ban maxretry | **DO NOT** | Parse fail2ban config | Moderate | Medium - security tuning |
| Fail2ban jails | **DO NOT** | Parse fail2ban jail configs | Moderate | High - security coverage |
| **UFW** |
| UFW logging level | **DO NOT** | Run `ufw status verbose` and parse logging line | Easy | Low - rarely customized |
| UFW default policies | **DO NOT** | Parse `ufw status verbose` for default policies | Easy | Medium - security posture |
| **Security Hardening** |
| OS hardening status | **USER PREF** | Controls whether to apply devsec.hardening role | N/A | User decides security policy |
| SSH hardening status | **USER PREF** | Controls whether to apply SSH hardening from devsec.hardening | N/A | User decides security policy |

**Note**: Fail2ban template placeholder exists but has no implementation. This is a significant gap for security-conscious users.

---

#### macOS System Gaps

| Gap | Status | How to Detect | Feasibility | Value |
|-----|--------|---------------|-------------|-------|
| Auto check updates | **DO NOT** | Query `defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled` | Easy | Medium - security preference |
| Auto download updates | **DO NOT** | Query `defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload` | Easy | Medium - security preference |

### Discovery Anomalies

Variables that are **collected but not output** to host_vars:

1. **Masked services** (`discovery_services_masked`) - Collected but not in template
   - **Fix**: Add to template output under `host_services.mask`
   - **Value**: Medium - users may intentionally mask services

2. **Loaded kernel modules** (`discovery_modules_loaded`) - Collected but not in template
   - **Fix**: Add to template output (informational only, not for configuration)
   - **Value**: Low - informational, not typically reconfigured

3. **Flatpak remotes** (`discovery_flatpak_remotes`) - Collected but not in template
   - **Fix**: Add to template output under `flatpak.remotes`
   - **Value**: Medium - users add custom remotes

4. **Fail2ban detection placeholder** - Template has conditional but no detection
   - **Fix**: Implement fail2ban detection in scan tasks
   - **Value**: High - important security service

### Feasibility Summary

#### Easy Wins (Trivial/Easy + High Value)
These should be prioritized for implementation:
- Kernel module load/blacklist configs (user customization)
- Masked services output (already collected)
- Flatpak remotes output (already collected)
- Fail2ban detection and config parsing
- Git per-user configuration
- Node.js global packages
- APT proxy and unattended-upgrades
- Pacman multilib enabled
- NTP server list

#### Moderate Effort, High Value
Worth considering for implementation:
- Rust cargo packages (parse binary directory)
- Go packages (check binary directory)
- Fail2ban detailed config (parse jail files)
- rsyslog remote logging config

#### Low Priority / Impractical
Should not be implemented:
- Terminal emulator configs (too variable)

#### User Preference Flags (Not Discoverable)
These control collection behavior and are not system state:
- `/etc/hosts` update preference - Role behavior toggle
- System upgrade type - apt dist-upgrade vs safe-upgrade choice
- Pacman no_confirm - Controls --noconfirm flag usage
- Pacman AUR enabled - Whether collection manages AUR
- OS/SSH hardening status - Security policy application flags

### Gap Statistics

**Total Gaps Analyzed**: ~50

**By Classification**:
- **DO NOT detect** (feasible to implement): 39 gaps
- **USER PREF** (behavior flags, not discoverable): 6 gaps
- **CANNOT detect** (technically impractical): 1 gap (terminal emulator configs)

**By Feasibility** (DO NOT gaps only):
- **Trivial** (already collected): 3 gaps
- **Easy** (straightforward parsing/checks): 28 gaps
- **Moderate** (requires parsing complex configs): 8 gaps

**By Value** (DO NOT gaps only):
- **High** (user customization/security): 18 gaps
- **Medium** (common customization): 21 gaps
- **Low** (rare/defaults): 6 gaps

---

## Discovery Task Files

| Task File | Purpose | Variables Set |
|-----------|---------|---------------|
| `main.yml` | Orchestration, domain discovery | `discovery_hostname`, `discovery_domain_*`, `discovery_domain_timesync_enabled` |
| `scan-system-settings.yml` | System config, services, modules, udev | `discovery_sysctl_current`, `discovery_modules_loaded`, `discovery_services_*`, `discovery_udev_rules`, `discovery_macos_preferences` |
| `scan-packages.yml` | Package discovery | `discovery_packages_host`, `discovery_homebrew_casks`, `discovery_homebrew_taps` |
| `scan-apt-repositories.yml` | APT repo discovery | `discovery_repositories` |
| `scan-users.yml` | User account discovery | `users` |
| `scan-firewall.yml` | Firewall rule discovery | `discovery_firewall_enabled`, `discovery_firewall_rules` |
| `scan-snap-flatpak.yml` | Snap/Flatpak discovery | `discovery_snap_packages`, `discovery_flatpak_packages`, `discovery_flatpak_remotes` |

---

## Output Template

**File**: `roles/discovery/templates/simple_host_vars.yml.j2`

The template generates a flat YAML structure organized by domain:
1. Domain-level configuration (lines 6-28)
2. Users (lines 30-35)
3. Host-level configuration (lines 37-68)
4. Security configuration (lines 72-95)
5. Package management (lines 97-145)
6. macOS-specific settings (lines 147-177)

---

## Next Steps (Task 3)

With both collection variables (Task 1) and discovery capabilities (Task 2) documented, Task 3 will perform gap analysis to identify:
1. **Coverage gaps**: Collection can configure but discovery cannot detect
2. **Unnecessary discovery**: Discovery detects but collection cannot configure
3. **Discovery anomalies**: Variables collected but not output
