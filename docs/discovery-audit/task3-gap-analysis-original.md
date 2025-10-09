# Task 3: Gap Analysis - Collection Variables vs Discovery Capabilities

**Issue**: #24 (Part of #11 - Discovery Coverage Audit)
**Date**: 2025-10-09
**Sources**:
- Task 1: `docs/discovery-audit/task1-collection-variables.md`
- Task 2: `docs/discovery-audit/task2-discovery-capabilities.md`

## Summary

This document performs gap analysis between what the collection can configure (Task 1) and what the discovery role can detect (Task 2). It identifies coverage gaps and unnecessary discovery to prioritize improvements.

---

## Gap Analysis Methodology

**Coverage Gaps**: Collection variables that exist but discovery cannot detect
- **Impact**: Users cannot use discovery to capture existing system configurations
- **Priority**: Based on feasibility (from Task 2) and user value

**Unnecessary Discovery**: Discovery detects state that collection cannot configure
- **Impact**: Wasted effort scanning for unusable data
- **Priority**: Low - informational only, minimal cost

**User Preference Flags**: Variables that control collection behavior, not system state
- **Impact**: Cannot be discovered (by definition)
- **Priority**: N/A - documentation clarity only

---

## 1. Domain-Level Configuration Gaps

### 1.1 Domain Identity

| Collection Variable | Discovery Status | Gap Type | Priority |
|---------------------|------------------|----------|----------|
| `domain_name` | ✅ Detected | No gap | - |
| `domain_timezone` | ✅ Detected | No gap | - |
| `domain_locale` | ✅ Detected | No gap | - |
| `domain_language` | ✅ Detected | No gap | - |

**Coverage**: 100% (4/4 variables)

### 1.2 Time Synchronization

| Collection Variable | Discovery Status | Gap Type | Priority |
|---------------------|------------------|----------|----------|
| `domain_timesync.enabled` | ✅ Detected | No gap | - |
| `domain_timesync.servers` | ❌ Not detected | **Coverage gap** | Medium |

**Coverage**: 50% (1/2 variables)

**Gap Details**:
- **Variable**: `domain_timesync.servers`
- **Detection method**: Parse `/etc/systemd/timesyncd.conf` NTP= lines (Linux) / systemsetup -getnetworktimeserver (macOS)
- **Feasibility**: Easy (file parsing)
- **Value**: Medium - users may customize NTP servers for corporate/regional time sources
- **Action**: Add to discovery implementation backlog

---

## 2. Host-Level Configuration Gaps

### 2.1 Host Identity

| Collection Variable | Discovery Status | Gap Type | Priority |
|---------------------|------------------|----------|----------|
| `host_hostname` | ✅ Detected | No gap | - |
| `host_update_hosts` | 🔵 User preference | Not discoverable | N/A |

**Coverage**: 100% of discoverable state (1/1)

### 2.2 System Services

| Collection Variable | Discovery Status | Gap Type | Priority |
|---------------------|------------------|----------|----------|
| `host_services.enable` | ✅ Detected | No gap | - |
| `host_services.disable` | ✅ Detected | No gap | - |
| `host_services.mask` | ⚠️ Collected but not output | **Discovery anomaly** | Medium |

**Coverage**: 67% output (2/3 variables), 100% detected (3/3)

**Gap Details**:
- **Variable**: `host_services.mask`
- **Issue**: Data collected (`discovery_services_masked`) but not included in template output
- **Feasibility**: Trivial - already collected
- **Value**: Medium - users may intentionally mask services to prevent activation
- **Action**: Add to template output immediately (easy win)

### 2.3 Kernel Modules

| Collection Variable | Discovery Status | Gap Type | Priority |
|---------------------|------------------|----------|----------|
| `host_modules.load` | ❌ Not detected | **Coverage gap** | High |
| `host_modules.blacklist` | ❌ Not detected | **Coverage gap** | High |

**Coverage**: 0% (0/2 variables)

**Gap Details**:
1. **Variable**: `host_modules.load`
   - **Detection method**: Read `/etc/modules-load.d/*.conf` files
   - **Feasibility**: Easy (file enumeration)
   - **Value**: High - critical user customization for hardware, networking, containers
   - **Action**: Implement immediately (easy win)

2. **Variable**: `host_modules.blacklist`
   - **Detection method**: Read `/etc/modprobe.d/*-blacklist.conf` files
   - **Feasibility**: Easy (file enumeration with pattern matching)
   - **Value**: High - important for disabling problematic drivers
   - **Action**: Implement immediately (easy win)

**Note**: Currently loaded modules (`lsmod`) are scanned but not output - this is informational only, not configuration state.

### 2.4 udev Rules

| Collection Variable | Discovery Status | Gap Type | Priority |
|---------------------|------------------|----------|----------|
| `host_udev_rules` | ✅ Detected | No gap | - |

**Coverage**: 100% (1/1 variables)

---

## 3. System Logging Gaps

### 3.1 systemd Journal

| Collection Variable | Discovery Status | Gap Type | Priority |
|---------------------|------------------|----------|----------|
| `journal.configure` | 🔵 User preference | Not discoverable | N/A |
| `journal.max_size` | ❌ Not detected | **Coverage gap** | Medium |
| `journal.max_retention` | ❌ Not detected | **Coverage gap** | Medium |
| `journal.forward_to_syslog` | ❌ Not detected | **Coverage gap** | Low |
| `journal.compress` | ❌ Not detected | **Coverage gap** | Low |

**Coverage**: 0% of discoverable state (0/4 configuration variables)

**Gap Details**:
- **Variables**: All journal configuration parameters
- **Detection method**: Parse `/etc/systemd/journald.conf` or `/etc/systemd/journald.conf.d/*.conf`
- **Feasibility**: Easy (INI file parsing)
- **Value**: Medium - sysadmins customize for disk space management
- **Action**: Add to discovery implementation backlog

### 3.2 rsyslog

| Collection Variable | Discovery Status | Gap Type | Priority |
|---------------------|------------------|----------|----------|
| `rsyslog.enabled` | 🔵 User preference | Not discoverable | N/A |
| `rsyslog.remote_host` | ❌ Not detected | **Coverage gap** | Medium |
| `rsyslog.remote_port` | ❌ Not detected | **Coverage gap** | Medium |
| `rsyslog.protocol` | ❌ Not detected | **Coverage gap** | Medium |

**Coverage**: 0% of discoverable state (0/3 configuration variables)

**Gap Details**:
- **Variables**: All rsyslog remote logging configuration
- **Detection method**: Parse `/etc/rsyslog.conf` and `/etc/rsyslog.d/*.conf` for `@@remote` patterns
- **Feasibility**: Moderate (requires parsing rsyslog syntax)
- **Value**: Medium - important for centralized logging environments
- **Action**: Add to discovery implementation backlog (moderate effort)

---

## 4. Security Hardening Gaps

| Collection Variable | Discovery Status | Gap Type | Priority |
|---------------------|------------------|----------|----------|
| `hardening.os_hardening_enabled` | 🔵 User preference | Not discoverable | N/A |
| `hardening.ssh_hardening_enabled` | 🔵 User preference | Not discoverable | N/A |

**Coverage**: N/A (user preference flags)

**Note**: These variables control whether to apply devsec.hardening roles, not system state.

---

## 5. Package Management Gaps

### 5.1 APT Configuration

| Collection Variable | Discovery Status | Gap Type | Priority |
|---------------------|------------------|----------|----------|
| `apt.proxy` | ❌ Not detected | **Coverage gap** | High |
| `apt.no_recommends` | ❌ Not detected | **Coverage gap** | Medium |
| `apt.unattended_upgrades.enabled` | ❌ Not detected | **Coverage gap** | High |
| `apt.system_upgrade.enable` | 🔵 User preference | Not discoverable | N/A |
| `apt.system_upgrade.type` | 🔵 User preference | Not discoverable | N/A |

**Coverage**: 0% of discoverable state (0/3 configuration variables)

**Gap Details**:
1. **Variable**: `apt.proxy`
   - **Detection method**: Parse `/etc/apt/apt.conf.d/*` for `Acquire::http::Proxy`
   - **Feasibility**: Easy (file parsing)
   - **Value**: High - corporate environments require proxy configuration
   - **Action**: Implement immediately (easy win)

2. **Variable**: `apt.no_recommends`
   - **Detection method**: Parse `/etc/apt/apt.conf.d/*` for `APT::Install-Recommends`
   - **Feasibility**: Easy (file parsing)
   - **Value**: Medium - common user preference to reduce package bloat
   - **Action**: Add to discovery implementation backlog

3. **Variable**: `apt.unattended_upgrades.enabled`
   - **Detection method**: Check `/etc/apt/apt.conf.d/20auto-upgrades` existence and parse
   - **Feasibility**: Easy (file check + parsing)
   - **Value**: High - critical security posture indicator
   - **Action**: Implement immediately (easy win)

### 5.2 APT Repositories

| Collection Variable | Discovery Status | Gap Type | Priority |
|---------------------|------------------|----------|----------|
| `apt_repositories_all` | ✅ Detected (host-level) | No gap | - |
| `apt_repositories_group` | ✅ Detected (host-level) | No gap | - |
| `apt_repositories_host` | ✅ Detected | No gap | - |

**Coverage**: 100% (3/3 variables)

**Note**: Discovery outputs host-level repositories; all/group are organizational abstractions.

### 5.3 Pacman Configuration

| Collection Variable | Discovery Status | Gap Type | Priority |
|---------------------|------------------|----------|----------|
| `pacman.proxy` | ❌ Not detected | **Coverage gap** | Medium |
| `pacman.no_confirm` | 🔵 User preference | Not discoverable | N/A |
| `pacman.multilib.enabled` | ❌ Not detected | **Coverage gap** | High |
| `pacman.enable_aur` | 🔵 User preference | Not discoverable | N/A |

**Coverage**: 0% of discoverable state (0/2 configuration variables)

**Gap Details**:
1. **Variable**: `pacman.proxy`
   - **Detection method**: Parse `/etc/pacman.conf` for `XferCommand` with proxy
   - **Feasibility**: Easy (file parsing)
   - **Value**: Medium - corporate environments
   - **Action**: Add to discovery implementation backlog

2. **Variable**: `pacman.multilib.enabled`
   - **Detection method**: Check if `[multilib]` section uncommented in `/etc/pacman.conf`
   - **Feasibility**: Easy (file parsing)
   - **Value**: High - extremely common user customization for 32-bit support
   - **Action**: Implement immediately (easy win)

### 5.4 Homebrew Configuration

| Collection Variable | Discovery Status | Gap Type | Priority |
|---------------------|------------------|----------|----------|
| `homebrew.cleanup_cache` | 🔵 User preference | Not discoverable | N/A |
| `homebrew.taps` | ✅ Detected | No gap | - |

**Coverage**: 100% of discoverable state (1/1)

### 5.5 System Packages

| Collection Variable | Discovery Status | Gap Type | Priority |
|---------------------|------------------|----------|----------|
| `manage_packages_all` | ✅ Detected (host-level) | No gap | - |
| `manage_packages_group` | ✅ Detected (host-level) | No gap | - |
| `manage_packages_host` | ✅ Detected | No gap | - |
| `manage_casks` | ✅ Detected | No gap | - |

**Coverage**: 100% (4/4 variables)

**Note**: Discovery outputs host-level packages; all/group are organizational abstractions.

### 5.6 Snap Packages

| Collection Variable | Discovery Status | Gap Type | Priority |
|---------------------|------------------|----------|----------|
| `snap.remove_completely` | 🔵 User preference | Not discoverable | N/A |
| `snap.packages.install` | ✅ Detected | No gap | - |
| `snap.packages.remove` | ✅ Detected (inverse) | No gap | - |

**Coverage**: 100% of discoverable state (2/2)

### 5.7 Flatpak Packages

| Collection Variable | Discovery Status | Gap Type | Priority |
|---------------------|------------------|----------|----------|
| `flatpak.enabled` | 🔵 User preference | Not discoverable | N/A |
| `flatpak.remotes` | ⚠️ Collected but not output | **Discovery anomaly** | Medium |
| `flatpak.packages.install` | ✅ Detected | No gap | - |
| `flatpak.packages.remove` | ✅ Detected (inverse) | No gap | - |

**Coverage**: 67% output (2/3 discoverable), 100% detected (3/3)

**Gap Details**:
- **Variable**: `flatpak.remotes`
- **Issue**: Data collected (`discovery_flatpak_remotes`) but not included in template output
- **Feasibility**: Trivial - already collected
- **Value**: Medium - users add custom remotes (flathub-beta, elementary, etc.)
- **Action**: Add to template output immediately (easy win)

---

## 6. User Configuration Gaps

### 6.1 Basic User Properties

| Collection Variable | Discovery Status | Gap Type | Priority |
|---------------------|------------------|----------|----------|
| `users[].name` | ✅ Detected | No gap | - |
| `users[].shell` | ✅ Detected | No gap | - |
| `users[].dotfiles.*` | ✅ Detected | No gap | - |

**Coverage**: 100% (3/3 variables)

### 6.2 Git Configuration

| Collection Variable | Discovery Status | Gap Type | Priority |
|---------------------|------------------|----------|----------|
| `users[].git.user_name` | ❌ Not detected | **Coverage gap** | High |
| `users[].git.user_email` | ❌ Not detected | **Coverage gap** | High |
| `users[].git.editor` | ❌ Not detected | **Coverage gap** | Medium |

**Coverage**: 0% (0/3 variables)

**Gap Details**:
- **Variables**: All git per-user configuration
- **Detection method**: Run `git config --get user.name/user.email/core.editor` as user
- **Feasibility**: Easy (command execution per user)
- **Value**: High - essential developer environment state
- **Action**: Implement immediately (easy win)

### 6.3 Language Packages

| Collection Variable | Discovery Status | Gap Type | Priority |
|---------------------|------------------|----------|----------|
| `users[].nodejs.packages` | ❌ Not detected | **Coverage gap** | High |
| `users[].rust.packages` | ❌ Not detected | **Coverage gap** | High |
| `users[].go.packages` | ❌ Not detected | **Coverage gap** | Medium |

**Coverage**: 0% (0/3 variables)

**Gap Details**:
1. **Variable**: `users[].nodejs.packages`
   - **Detection method**: Run `npm list -g --depth=0` as user
   - **Feasibility**: Easy (command execution per user)
   - **Value**: High - critical developer environment state
   - **Action**: Implement immediately (easy win)

2. **Variable**: `users[].rust.packages`
   - **Detection method**: Parse `~/.cargo/bin/` for installed binaries
   - **Feasibility**: Moderate (directory enumeration + binary identification)
   - **Value**: High - important for Rust developers
   - **Action**: Add to discovery implementation backlog

3. **Variable**: `users[].go.packages`
   - **Detection method**: Check `~/go/bin/` for installed binaries
   - **Feasibility**: Moderate (directory enumeration)
   - **Value**: Medium - useful for Go developers
   - **Action**: Add to discovery implementation backlog

### 6.4 Development Tools

| Collection Variable | Discovery Status | Gap Type | Priority |
|---------------------|------------------|----------|----------|
| `users[].neovim.enabled` | ❌ Not detected | **Coverage gap** | Medium |
| `users[].terminal_entries` | ❌ Not detected | **Coverage gap** | Low |

**Coverage**: 0% (0/2 variables)

**Gap Details**:
1. **Variable**: `users[].neovim.enabled`
   - **Detection method**: Check if `nvim` command exists for user
   - **Feasibility**: Easy (command check)
   - **Value**: Medium - editor preference
   - **Action**: Add to discovery implementation backlog

2. **Variable**: `users[].terminal_entries`
   - **Detection method**: Too variable - would require checking for alacritty, kitty, wezterm configs
   - **Feasibility**: Hard - too many emulators with varying config formats
   - **Value**: Low - highly variable
   - **Action**: Do not implement (impractical)

### 6.5 macOS Per-User Preferences

| Collection Variable | Discovery Status | Gap Type | Priority |
|---------------------|------------------|----------|----------|
| `users[].Darwin.dock.*` | ❌ Not detected | **Coverage gap** | Medium |
| `users[].Darwin.finder.*` | ❌ Not detected | **Coverage gap** | Medium |
| `users[].Darwin.screenshots.*` | ❌ Not detected | **Coverage gap** | Low |
| `users[].Darwin.iterm2.*` | ❌ Not detected | **Coverage gap** | Low |

**Coverage**: 0% (0/4 variable groups)

**Gap Details**:
- **Variables**: All macOS per-user preferences
- **Detection method**: Query defaults per-user (e.g., `defaults read com.apple.dock` as user)
- **Feasibility**: Easy (command execution per user)
- **Value**: Medium - common user customizations on macOS
- **Action**: Add to discovery implementation backlog (macOS-specific)

---

## 7. Security Services Gaps

### 7.1 Firewall (ufw)

| Collection Variable | Discovery Status | Gap Type | Priority |
|---------------------|------------------|----------|----------|
| `firewall.enabled` | ✅ Detected | No gap | - |
| `firewall.prevent_ssh_lockout` | 🔵 User preference | Not discoverable | N/A |
| `firewall.stealth_mode` | 🔵 User preference | Not discoverable | N/A |
| `firewall.block_all` | 🔵 User preference | Not discoverable | N/A |
| `firewall.logging` | ❌ Not detected | **Coverage gap** | Low |
| `firewall.rules` | ✅ Detected | No gap | - |

**Coverage**: 67% of discoverable state (2/3 configuration variables)

**Gap Details**:
- **Variable**: `firewall.logging`
- **Detection method**: Run `ufw status verbose` and parse logging line
- **Feasibility**: Easy (command execution)
- **Value**: Low - rarely customized from defaults
- **Action**: Low priority (minimal value)

### 7.2 Fail2ban

| Collection Variable | Discovery Status | Gap Type | Priority |
|---------------------|------------------|----------|----------|
| `fail2ban.enabled` | ❌ Not detected | **Coverage gap** | High |
| `fail2ban.bantime` | ❌ Not detected | **Coverage gap** | Medium |
| `fail2ban.findtime` | ❌ Not detected | **Coverage gap** | Medium |
| `fail2ban.maxretry` | ❌ Not detected | **Coverage gap** | Medium |
| `fail2ban.jails` | ❌ Not detected | **Coverage gap** | High |

**Coverage**: 0% (0/5 variables)

**Gap Details**:
- **Variables**: All fail2ban configuration
- **Detection method**:
  - Enabled: Check if `fail2ban` service is active
  - Configuration: Parse `/etc/fail2ban/jail.local` and `/etc/fail2ban/jail.d/*.conf`
- **Feasibility**: Moderate (service check is easy, config parsing requires understanding fail2ban syntax)
- **Value**: High - critical security service for server hardening
- **Action**: Implement immediately (high security value)
- **Note**: Template placeholder exists but no implementation

---

## 8. macOS-Specific Configuration Gaps

### 8.1 System Updates

| Collection Variable | Discovery Status | Gap Type | Priority |
|---------------------|------------------|----------|----------|
| `macosx.updates.auto_check` | ❌ Not detected | **Coverage gap** | Medium |
| `macosx.updates.auto_download` | ❌ Not detected | **Coverage gap** | Medium |

**Coverage**: 0% (0/2 variables)

**Gap Details**:
- **Variables**: macOS automatic update settings
- **Detection method**: Query system preferences (e.g., `defaults read /Library/Preferences/com.apple.SoftwareUpdate`)
- **Feasibility**: Easy (defaults query)
- **Value**: Medium - security preference
- **Action**: Add to discovery implementation backlog (macOS-specific)

### 8.2 Security

| Collection Variable | Discovery Status | Gap Type | Priority |
|---------------------|------------------|----------|----------|
| `macosx.gatekeeper.enabled` | ✅ Detected | No gap | - |

**Coverage**: 100% (1/1 variables)

### 8.3 System Preferences

| Collection Variable | Discovery Status | Gap Type | Priority |
|---------------------|------------------|----------|----------|
| `macosx.system_preferences.natural_scroll` | ✅ Detected | No gap | - |
| `macosx.system_preferences.measurement_units` | ✅ Detected | No gap | - |
| `macosx.system_preferences.use_metric` | ✅ Detected | No gap | - |
| `macosx.system_preferences.show_all_extensions` | ✅ Detected | No gap | - |

**Coverage**: 100% (4/4 variables)

### 8.4 Network

| Collection Variable | Discovery Status | Gap Type | Priority |
|---------------------|------------------|----------|----------|
| `macosx.airdrop.ethernet_enabled` | ✅ Detected | No gap | - |

**Coverage**: 100% (1/1 variables)

---

## Overall Coverage Summary

### By Category

| Category | Total Variables | Discoverable | Detected | Coverage % |
|----------|----------------|--------------|----------|-----------|
| Domain-Level Identity | 4 | 4 | 4 | 100% |
| Domain-Level Timesync | 2 | 2 | 1 | 50% |
| Host Identity | 2 | 1 | 1 | 100% |
| System Services | 3 | 3 | 2 | 67% |
| Kernel Modules | 2 | 2 | 0 | 0% |
| udev Rules | 1 | 1 | 1 | 100% |
| Journal Config | 5 | 4 | 0 | 0% |
| rsyslog Config | 4 | 3 | 0 | 0% |
| APT Config | 5 | 3 | 0 | 0% |
| APT Repositories | 3 | 3 | 3 | 100% |
| Pacman Config | 4 | 2 | 0 | 0% |
| Homebrew Config | 2 | 1 | 1 | 100% |
| System Packages | 4 | 4 | 4 | 100% |
| Snap Packages | 3 | 2 | 2 | 100% |
| Flatpak Packages | 4 | 3 | 2 | 67% |
| User Basic | 3 | 3 | 3 | 100% |
| User Git | 3 | 3 | 0 | 0% |
| User Languages | 3 | 3 | 0 | 0% |
| User Dev Tools | 2 | 1 | 0 | 0% |
| User macOS Prefs | 4 | 4 | 0 | 0% |
| Firewall | 6 | 3 | 2 | 67% |
| Fail2ban | 5 | 5 | 0 | 0% |
| macOS Updates | 2 | 2 | 0 | 0% |
| macOS Security | 1 | 1 | 1 | 100% |
| macOS System Prefs | 4 | 4 | 4 | 100% |
| macOS Network | 1 | 1 | 1 | 100% |

### Overall Statistics

- **Total collection variables**: ~100
- **User preference flags**: 15 (not discoverable by design)
- **Discoverable configuration**: 85 variables
- **Currently detected**: 35 variables
- **Overall coverage**: **41%**

**Gap breakdown**:
- **Coverage gaps**: 48 variables (56% of discoverable)
- **Discovery anomalies**: 2 variables (collected but not output)
- **No gap**: 35 variables (41% of discoverable)

---

## Priority Rankings

### Critical Gaps (Implement Immediately - Easy Wins)

These are high-value gaps with easy/trivial implementation:

1. **Kernel modules** (`host_modules.load`, `host_modules.blacklist`)
   - Feasibility: Easy (file enumeration)
   - Value: High (hardware/networking customization)

2. **Masked services** (`host_services.mask`)
   - Feasibility: Trivial (already collected)
   - Value: Medium (intentional service disablement)

3. **Flatpak remotes** (`flatpak.remotes`)
   - Feasibility: Trivial (already collected)
   - Value: Medium (custom package sources)

4. **APT proxy** (`apt.proxy`)
   - Feasibility: Easy (file parsing)
   - Value: High (corporate environments)

5. **APT unattended upgrades** (`apt.unattended_upgrades.enabled`)
   - Feasibility: Easy (file check)
   - Value: High (security posture)

6. **Pacman multilib** (`pacman.multilib.enabled`)
   - Feasibility: Easy (file parsing)
   - Value: High (extremely common customization)

7. **Git user config** (`users[].git.*`)
   - Feasibility: Easy (command per user)
   - Value: High (developer identity)

8. **NPM global packages** (`users[].nodejs.packages`)
   - Feasibility: Easy (command per user)
   - Value: High (developer environment)

9. **Fail2ban detection** (`fail2ban.enabled`, `fail2ban.jails`)
   - Feasibility: Easy for service, Moderate for config
   - Value: High (security service)

### High-Value Gaps (Implement Next)

Valuable but require moderate effort:

10. **NTP servers** (`domain_timesync.servers`)
11. **Journal configuration** (`journal.*`)
12. **rsyslog remote logging** (`rsyslog.*`)
13. **APT no_recommends** (`apt.no_recommends`)
14. **Pacman proxy** (`pacman.proxy`)
15. **Rust cargo packages** (`users[].rust.packages`)
16. **Go packages** (`users[].go.packages`)
17. **Fail2ban config details** (`fail2ban.bantime`, etc.)
18. **macOS auto-update settings** (`macosx.updates.*`)
19. **macOS per-user preferences** (`users[].Darwin.*`)

### Low-Priority Gaps

Minimal value or impractical to implement:

20. **UFW logging** (`firewall.logging`) - Rarely customized
21. **Neovim detection** (`users[].neovim.enabled`) - Low value
22. **Journal forward_to_syslog** (`journal.forward_to_syslog`) - Uncommon
23. **Journal compress** (`journal.compress`) - Usually default

### Do Not Implement

Technically impractical or too variable:

24. **Terminal emulator configs** (`users[].terminal_entries`) - Too many formats

---

## Unnecessary Discovery

Variables that discovery detects but collection cannot configure:

**None identified** - All discovered state maps to collection variables.

**Note**: `discovery_modules_loaded` (currently loaded modules from `lsmod`) is informational only and not output to template. This is appropriate as it represents runtime state, not persistent configuration.

---

## Recommendations

### Immediate Actions (Easy Wins - Week 1)

1. **Add already-collected variables to template**:
   - `host_services.mask`
   - `flatpak.remotes`

2. **Implement trivial file-based detection**:
   - Kernel modules load/blacklist (`/etc/modules-load.d/`, `/etc/modprobe.d/`)
   - APT proxy (`/etc/apt/apt.conf.d/`)
   - APT unattended upgrades (`/etc/apt/apt.conf.d/20auto-upgrades`)
   - Pacman multilib (`/etc/pacman.conf`)

3. **Implement per-user command-based detection**:
   - Git configuration (`git config --get`)
   - NPM global packages (`npm list -g`)

4. **Implement fail2ban basic detection**:
   - Service enabled check (`systemctl is-active`)

### Short-Term Actions (Month 1)

5. **Implement moderate file parsing**:
   - NTP servers (`/etc/systemd/timesyncd.conf`)
   - Journal configuration (`/etc/systemd/journald.conf`)
   - APT no_recommends (`/etc/apt/apt.conf.d/`)
   - Pacman proxy (`/etc/pacman.conf`)

6. **Implement advanced fail2ban detection**:
   - Parse jail configurations

7. **Implement per-user binary detection**:
   - Rust cargo packages (`~/.cargo/bin/`)
   - Go packages (`~/go/bin/`)

### Medium-Term Actions (Month 2-3)

8. **Implement rsyslog detection**:
   - Parse rsyslog configs for remote logging

9. **Implement macOS-specific detection**:
   - Auto-update settings
   - Per-user preferences (dock, finder, screenshots)

### Long-Term Considerations

10. **Neovim detection** - Low priority, implement if requested
11. **Additional per-user tooling** - As requirements emerge

---

## Success Metrics

**Target coverage**: 80% of discoverable variables

**Current**: 41% (35/85)
**After Easy Wins**: ~60% (51/85)
**After Short-Term**: ~75% (64/85)
**After Medium-Term**: ~85% (72/85)

**Estimated effort**:
- Easy wins: ~2-3 days
- Short-term: ~1 week
- Medium-term: ~2 weeks
- **Total**: ~4 weeks to reach 85% coverage

---

## Next Steps

1. **Create implementation issues** for each priority tier
2. **Update discovery role** with easy wins
3. **Test coverage improvements** with molecule scenarios
4. **Document new detection capabilities** in discovery role README
5. **Update collection documentation** to reflect improved discovery coverage
