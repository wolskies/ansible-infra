# Task 3: Gap Analysis - Coverage Gaps vs New Functionality

**Issue**: #24 (Part of #11 - Discovery Coverage Audit)
**Date**: 2025-10-09
**Sources**:
- Task 1: `docs/discovery-audit/task1-collection-variables.md`
- Task 2: `docs/discovery-audit/task2-discovery-capabilities.md`
- Collection defaults: `defaults/main.yml`
- Discovery template: `roles/discovery/templates/simple_host_vars.yml.j2`

## Summary

This document separates **coverage gaps** (collection supports but discovery doesn't detect) from **new functionality** (collection doesn't support yet). Only coverage gaps represent true deficiencies in the discovery role.

---

## Methodology

**Coverage Gap**: Collection variable exists in `defaults/main.yml` AND used by roles, but discovery doesn't detect it
- **Impact**: Discovery incomplete - cannot capture existing configurations
- **Priority**: Fix these to achieve complete discovery coverage

**New Functionality**: Suggested capability that collection doesn't currently support
- **Impact**: Would require NEW collection roles/features
- **Priority**: Feature requests for future releases

**Discovery Anomaly**: Discovery collects data but doesn't output it
- **Impact**: Wasted scanning effort
- **Priority**: Trivial fix - add to template

**User Preference**: Variable controls collection behavior, not system state
- **Impact**: Not discoverable by design
- **Priority**: N/A - documentation only

---

## TRUE Coverage Gaps

These are collection-supported variables that discovery SHOULD detect but doesn't:

### 1. Domain-Level Gaps

| Variable | Collection Support | Discovery Support | Gap Type |
|----------|-------------------|-------------------|----------|
| `domain_timesync.servers` | ✅ defaults:9 | ❌ Hardcoded fallback | **Coverage gap** |

**Details**:
- **Variable**: `domain_timesync.servers` (list)
- **Default**: `[]` (empty list)
- **Current discovery**: Hardcodes `["0.pool.ntp.org", "1.pool.ntp.org"]` in template
- **Detection method**: Parse `/etc/systemd/timesyncd.conf` NTP= (Linux) / systemsetup -getnetworktimeserver (macOS)
- **Feasibility**: Easy
- **Value**: Medium - users customize for corporate/regional time sources
- **Action**: Replace hardcoded servers with actual detection

---

### 2. Host-Level Gaps

#### 2.1 System Services

| Variable | Collection Support | Discovery Support | Gap Type |
|----------|-------------------|-------------------|----------|
| `host_services.mask` | ✅ defaults:16 | ⚠️ Collected not output | **Discovery anomaly** |

**Details**:
- **Variable**: `host_services.mask` (list)
- **Current discovery**: Data collected (`discovery_services_masked`) but not in template (line 45-49)
- **Feasibility**: Trivial - already scanned
- **Value**: Medium - users intentionally mask services
- **Action**: Add to template immediately

#### 2.2 Kernel Modules

| Variable | Collection Support | Discovery Support | Gap Type |
|----------|-------------------|-------------------|----------|
| `host_modules.load` | ✅ defaults:19 | ❌ Not detected | **Coverage gap** |
| `host_modules.blacklist` | ✅ defaults:19 | ❌ Not detected | **Coverage gap** |

**Details**:
- **Variables**: `host_modules.load`, `host_modules.blacklist` (lists)
- **Detection method**:
  - Load: Read `/etc/modules-load.d/*.conf`
  - Blacklist: Read `/etc/modprobe.d/*-blacklist.conf`
- **Feasibility**: Easy (file enumeration)
- **Value**: High - critical for hardware/networking/containers
- **Action**: Implement immediately

**Note**: Currently loaded modules (`lsmod` → `discovery_modules_loaded`) are scanned but not output - this is correct as it's runtime state, not persistent configuration.

---

### 3. System Logging Gaps

#### 3.1 Journal Configuration

| Variable | Collection Support | Discovery Support | Gap Type |
|----------|-------------------|-------------------|----------|
| `journal.max_size` | ✅ defaults:59 | ❌ Not detected | **Coverage gap** |
| `journal.max_retention` | ✅ defaults:60 | ❌ Not detected | **Coverage gap** |
| `journal.forward_to_syslog` | ✅ defaults:61 | ❌ Not detected | **Coverage gap** |
| `journal.compress` | ✅ defaults:62 | ❌ Not detected | **Coverage gap** |

**Details**:
- **Variables**: All journal configuration parameters
- **Detection method**: Parse `/etc/systemd/journald.conf` or `/etc/systemd/journald.conf.d/*.conf`
- **Feasibility**: Easy (INI parsing)
- **Value**: Medium - sysadmins customize for disk management
- **Action**: Add to discovery backlog

**Note**: `journal.configure` is a user preference flag (not discoverable).

#### 3.2 rsyslog Configuration

| Variable | Collection Support | Discovery Support | Gap Type |
|----------|-------------------|-------------------|----------|
| `rsyslog.remote_host` | ✅ defaults:65 | ❌ Not detected | **Coverage gap** |
| `rsyslog.remote_port` | ✅ defaults:66 | ❌ Not detected | **Coverage gap** |
| `rsyslog.protocol` | ✅ defaults:67 | ❌ Not detected | **Coverage gap** |

**Details**:
- **Variables**: All rsyslog remote logging config
- **Detection method**: Parse `/etc/rsyslog.conf` and `/etc/rsyslog.d/*.conf` for `@@remote` patterns
- **Feasibility**: Moderate (rsyslog syntax parsing)
- **Value**: Medium - centralized logging environments
- **Action**: Add to discovery backlog

**Note**: `rsyslog.enabled` is a user preference flag (not discoverable).

---

### 4. Package Management Gaps

#### 4.1 APT Configuration

| Variable | Collection Support | Discovery Support | Gap Type |
|----------|-------------------|-------------------|----------|
| `apt.proxy` | ✅ defaults:69 | ❌ Not detected | **Coverage gap** |
| `apt.no_recommends` | ✅ defaults:70 | ❌ Not detected | **Coverage gap** |
| `apt.unattended_upgrades.enabled` | ✅ defaults:72 | ❌ Not detected | **Coverage gap** |

**Details**:
1. **Variable**: `apt.proxy`
   - **Detection method**: Parse `/etc/apt/apt.conf.d/*` for `Acquire::http::Proxy`
   - **Feasibility**: Easy
   - **Value**: High - corporate environments
   - **Action**: Implement immediately

2. **Variable**: `apt.no_recommends`
   - **Detection method**: Parse `/etc/apt/apt.conf.d/*` for `APT::Install-Recommends`
   - **Feasibility**: Easy
   - **Value**: Medium - reduce package bloat
   - **Action**: Add to discovery backlog

3. **Variable**: `apt.unattended_upgrades.enabled`
   - **Detection method**: Check `/etc/apt/apt.conf.d/20auto-upgrades`
   - **Feasibility**: Easy
   - **Value**: High - security posture
   - **Action**: Implement immediately

**Note**: `apt.system_upgrade.*` are user preference flags (not discoverable).

#### 4.2 Pacman Configuration

| Variable | Collection Support | Discovery Support | Gap Type |
|----------|-------------------|-------------------|----------|
| `pacman.proxy` | ✅ defaults:101 | ❌ Not detected | **Coverage gap** |
| `pacman.multilib.enabled` | ✅ defaults:103 | ❌ Not detected | **Coverage gap** |

**Details**:
1. **Variable**: `pacman.proxy`
   - **Detection method**: Parse `/etc/pacman.conf` for `XferCommand` with proxy
   - **Feasibility**: Easy
   - **Value**: Medium - corporate environments
   - **Action**: Add to discovery backlog

2. **Variable**: `pacman.multilib.enabled`
   - **Detection method**: Check if `[multilib]` uncommented in `/etc/pacman.conf`
   - **Feasibility**: Easy
   - **Value**: High - extremely common for 32-bit support
   - **Action**: Implement immediately

**Note**: `pacman.no_confirm` and `pacman.enable_aur` are user preference flags (not discoverable).

#### 4.3 Flatpak Configuration

| Variable | Collection Support | Discovery Support | Gap Type |
|----------|-------------------|-------------------|----------|
| `flatpak.remotes` | ✅ defaults:170 | ⚠️ Collected not output | **Discovery anomaly** |

**Details**:
- **Variable**: `flatpak.remotes` (list)
- **Current discovery**: Data collected (`discovery_flatpak_remotes`) but not in template (line 139-145)
- **Feasibility**: Trivial - already scanned
- **Value**: Medium - users add flathub-beta, elementary, etc.
- **Action**: Add to template immediately

**Note**: `flatpak.enabled` is a user preference flag (not discoverable).

---

### 5. User Configuration Gaps

#### 5.1 Git Configuration

| Variable | Collection Support | Discovery Support | Gap Type |
|----------|-------------------|-------------------|----------|
| `users[].git.user_name` | ✅ defaults:179 | ❌ Not detected | **Coverage gap** |
| `users[].git.user_email` | ✅ defaults:180 | ❌ Not detected | **Coverage gap** |
| `users[].git.editor` | ✅ defaults:181 | ❌ Not detected | **Coverage gap** |

**Details**:
- **Variables**: All git per-user configuration
- **Detection method**: Run `git config --get user.name/user.email/core.editor` as user
- **Feasibility**: Easy
- **Value**: High - essential developer environment
- **Action**: Implement immediately

#### 5.2 Language Packages

| Variable | Collection Support | Discovery Support | Gap Type |
|----------|-------------------|-------------------|----------|
| `users[].nodejs.packages` | ✅ defaults:183 | ❌ Not detected | **Coverage gap** |
| `users[].rust.packages` | ✅ defaults:185 | ❌ Not detected | **Coverage gap** |
| `users[].go.packages` | ✅ defaults:187 | ❌ Not detected | **Coverage gap** |

**Details**:
1. **Variable**: `users[].nodejs.packages`
   - **Detection method**: Run `npm list -g --depth=0` as user
   - **Feasibility**: Easy
   - **Value**: High - critical developer environment
   - **Action**: Implement immediately

2. **Variable**: `users[].rust.packages`
   - **Detection method**: Parse `~/.cargo/bin/` for binaries
   - **Feasibility**: Moderate
   - **Value**: High - Rust developers
   - **Action**: Add to discovery backlog

3. **Variable**: `users[].go.packages`
   - **Detection method**: Check `~/go/bin/` for binaries
   - **Feasibility**: Moderate
   - **Value**: Medium - Go developers
   - **Action**: Add to discovery backlog

#### 5.3 Development Tools

| Variable | Collection Support | Discovery Support | Gap Type |
|----------|-------------------|-------------------|----------|
| `users[].neovim.enabled` | ✅ defaults:189 | ❌ Not detected | **Coverage gap** |
| `users[].terminal_entries` | ✅ defaults:191 | ❌ Not detected | **Coverage gap** |

**Details**:
1. **Variable**: `users[].neovim.enabled`
   - **Detection method**: Check if `nvim` command exists for user
   - **Feasibility**: Easy
   - **Value**: Medium - editor preference
   - **Action**: Add to discovery backlog

2. **Variable**: `users[].terminal_entries`
   - **Detection method**: Check for alacritty/kitty/wezterm configs
   - **Feasibility**: Hard - too many formats
   - **Value**: Low - highly variable
   - **Action**: Low priority / do not implement

---

### 6. Security Services Gaps

#### 6.1 Firewall

| Variable | Collection Support | Discovery Support | Gap Type |
|----------|-------------------|-------------------|----------|
| `firewall.logging` | ✅ defaults:202 | ❌ Not detected | **Coverage gap** |

**Details**:
- **Variable**: `firewall.logging`
- **Detection method**: Parse `ufw status verbose` for logging line
- **Feasibility**: Easy
- **Value**: Low - rarely customized
- **Action**: Low priority

**Note**: `firewall.prevent_ssh_lockout`, `firewall.stealth_mode`, `firewall.block_all` are user preference flags (not discoverable).

#### 6.2 Fail2ban

| Variable | Collection Support | Discovery Support | Gap Type |
|----------|-------------------|-------------------|----------|
| `fail2ban.enabled` | ✅ defaults:218 | ❌ Not detected | **Coverage gap** |
| `fail2ban.bantime` | ✅ defaults:219 | ❌ Not detected | **Coverage gap** |
| `fail2ban.findtime` | ✅ defaults:220 | ❌ Not detected | **Coverage gap** |
| `fail2ban.maxretry` | ✅ defaults:221 | ❌ Not detected | **Coverage gap** |
| `fail2ban.jails` | ✅ defaults:222 | ❌ Not detected | **Coverage gap** |

**Details**:
- **Variables**: All fail2ban configuration
- **Detection method**:
  - Enabled: Check `systemctl is-active fail2ban`
  - Config: Parse `/etc/fail2ban/jail.local` and `/etc/fail2ban/jail.d/*.conf`
- **Feasibility**: Easy for service, Moderate for config parsing
- **Value**: High - critical security service
- **Action**: Implement immediately
- **Note**: Template placeholder exists (line 92-95) but no implementation

---

### 7. macOS-Specific Gaps

| Variable | Collection Support | Discovery Support | Gap Type |
|----------|-------------------|-------------------|----------|
| `macosx.updates.auto_check` | ✅ defaults:108 | ❌ Not detected | **Coverage gap** |
| `macosx.updates.auto_download` | ✅ defaults:109 | ❌ Not detected | **Coverage gap** |

**Details**:
- **Variables**: macOS auto-update settings
- **Detection method**: Query `defaults read /Library/Preferences/com.apple.SoftwareUpdate`
- **Feasibility**: Easy
- **Value**: Medium - security preference
- **Action**: Add to discovery backlog (macOS-specific)

---

## New Functionality (NOT Coverage Gaps)

These would require NEW collection support - not discovery deficiencies:

### macOS Per-User Preferences

**Variables**: `users[].Darwin.*` (dock, finder, screenshots, iterm2)

**Status**: Collection does NOT support these
- Not in `defaults/main.yml`
- Not in `configure_users` role
- Not mentioned in SRD

**Classification**: **New functionality** - would require:
1. New variables in collection defaults
2. New tasks in `configure_users` role for macOS
3. New SRD requirements

**Action**: Feature request for future release (NOT a discovery gap)

---

## Summary: TRUE Coverage Gaps Only

### By Priority

#### Critical (Implement Immediately - Easy Wins)

1. **Kernel modules** - `host_modules.load`, `host_modules.blacklist`
2. **Masked services** - `host_services.mask` (already collected!)
3. **Flatpak remotes** - `flatpak.remotes` (already collected!)
4. **APT proxy** - `apt.proxy`
5. **APT unattended upgrades** - `apt.unattended_upgrades.enabled`
6. **Pacman multilib** - `pacman.multilib.enabled`
7. **Git config** - `users[].git.*`
8. **NPM packages** - `users[].nodejs.packages`
9. **Fail2ban enabled** - `fail2ban.enabled`

#### High-Value (Add to Backlog)

10. **NTP servers** - `domain_timesync.servers`
11. **Journal config** - `journal.*`
12. **rsyslog config** - `rsyslog.*`
13. **APT no_recommends** - `apt.no_recommends`
14. **Pacman proxy** - `pacman.proxy`
15. **Rust packages** - `users[].rust.packages`
16. **Go packages** - `users[].go.packages`
17. **Fail2ban config** - `fail2ban.bantime`, `fail2ban.findtime`, `fail2ban.maxretry`, `fail2ban.jails`
18. **macOS updates** - `macosx.updates.*`
19. **Neovim** - `users[].neovim.enabled`

#### Low Priority

20. **UFW logging** - `firewall.logging`
21. **Terminal entries** - `users[].terminal_entries`

### Coverage Statistics

**Total collection variables**: ~90 (excluding devsec.hardening pass-through)
**User preference flags**: 15 (not discoverable by design)
**Discoverable variables**: 75
**Currently detected**: 35
**TRUE coverage gaps**: 40

**Current coverage**: 47% (35/75)
**After easy wins (9 items)**: 59% (44/75)
**After high-value (19 items)**: 81% (61/75)
**After all gaps (40 items)**: 100% (75/75)

---

## Recommendations

### Immediate Actions (Week 1)

1. **Template fixes** (30 minutes):
   - Add `host_services.mask` to template
   - Add `flatpak.remotes` to template

2. **Easy file-based detection** (2 days):
   - Kernel modules (`/etc/modules-load.d/`, `/etc/modprobe.d/`)
   - APT proxy (`/etc/apt/apt.conf.d/`)
   - APT unattended upgrades (`/etc/apt/apt.conf.d/20auto-upgrades`)
   - Pacman multilib (`/etc/pacman.conf`)

3. **Per-user detection** (2 days):
   - Git config (`git config --get`)
   - NPM packages (`npm list -g`)

4. **Fail2ban basic** (1 day):
   - Service enabled check

### Short-Term (Month 1)

5. **Configuration parsing** (1 week):
   - NTP servers
   - Journal config
   - APT no_recommends
   - Pacman proxy

6. **Advanced fail2ban** (2 days):
   - Jail configuration parsing

7. **User binary detection** (3 days):
   - Rust cargo packages
   - Go packages

### Medium-Term (Month 2)

8. **rsyslog detection** (3 days)
9. **macOS updates** (1 day)
10. **Neovim detection** (1 day)

---

## Next Steps

1. Update issue #24 with corrected analysis
2. Create implementation issues for each priority tier
3. Begin with template fixes (immediate, trivial)
4. Implement easy wins in priority order
