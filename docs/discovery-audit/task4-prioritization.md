# Task 4: Gap Prioritization - Two-Lens Analysis

**Issue**: #25 (Part of #11 - Discovery Coverage Audit)
**Date**: 2025-10-09
**Source**: Task 3 gap analysis (`docs/discovery-audit/task3-gap-analysis.md`)

## Summary

This document prioritizes the 40 TRUE coverage gaps identified in Task 3 using two lenses:
1. **Technical Implementation**: Easy/Moderate/Hard
2. **Release Alignment**: Next (v1.3.0) / Later (v1.4.0+) / Defer

---

## Prioritization Methodology

### Lens 1: Technical Implementation Difficulty

Based on Task 2 feasibility analysis:

- **Easy**: Simple file parsing, straightforward command execution, data already collected
- **Moderate**: Complex config parsing, binary detection, per-user command execution
- **Hard**: Multi-format parsing, highly variable configurations

### Lens 2: Release Alignment

Based on v1.3.0 issue queue:

**v1.3.0 Tagged Issues**:
- #21: Remove user-level flatpak support
- #20: Add Debian-specific molecule test scenarios
- #19: VM test configurations should differentiate between distributions
- #16: Flatpak never enabled in integration tests
- #4: Add docker services deployment

**Alignment Criteria**:
- **Next Release (v1.3.0)**: Aligns with existing v1.3.0 work + Easy/Moderate difficulty + High value
- **Later Release (v1.4.0+)**: High value but no v1.3.0 alignment OR requires separate implementation effort
- **Defer**: Low value + Hard difficulty OR edge cases

---

## Next Release (v1.3.0) - Recommended

### 1. Flatpak Remotes - DEFERRED TO v1.4.0

**Gap**: `flatpak.remotes` - Two-part gap

**Discovery Side**:
- **Technical**: Trivial (already scanned by `discovery_flatpak_remotes`)
- **Implementation**: Add to template output

**Configuration Side**:
- **Status**: NEW FUNCTIONALITY - Collection defines `flatpak.remotes` in defaults but role doesn't implement it
- **Current**: Role only supports Flathub toggle (`flatpak.flathub`), not arbitrary remotes
- **Implementation**: Would require updating manage_flatpak role to support multiple remotes

**Alignment**: #21 (flatpak cleanup), #16 (flatpak testing)

**Analysis**:
Issues #21 and #16 focus on **existing functionality**:
- #21: Remove untested user-level support (cleanup)
- #16: Enable flatpak in VM tests (validation)

Adding `flatpak.remotes` support is NEW functionality and scope creep for v1.3.0.

**Recommendation for v1.3.0**:
1. Complete #21 (remove user-level, simplify to system-only)
2. Complete #16 (enable Flathub-only in VM tests)
3. Document current limitation (Flathub-only)
4. **Defer discovery** until configuration support exists

**Recommendation for v1.4.0**:
1. **Create new issue**: "Implement multiple flatpak remotes support"
2. Implement `flatpak.remotes` in manage_flatpak role
3. Add discovery template output for `flatpak.remotes`
4. Test with multiple remotes (flathub + flathub-beta or elementary)

**Justification**: Discovery should not detect what collection cannot configure. Stay aligned with collection capabilities. Complete existing flatpak work before adding new features.

---

### 2. Masked Services Output (TRIVIAL - 30 min)

**Gap**: `host_services.mask` - Data collected but not in template

**Technical**: Trivial (already scanned by `discovery_services_masked`)
**Value**: Medium
**Alignment**: #15 (service masking not tested) - not v1.3.0 but related

**Implementation**:
- Add to template: `roles/discovery/templates/simple_host_vars.yml.j2` lines 45-49
- No new scan tasks needed

**Justification**: Already collected, trivial to output, completes service management discovery.

---

### 3. APT Configuration Discovery (EASY - 1 day)

**Gaps**:
- `apt.proxy`
- `apt.unattended_upgrades.enabled`

**Technical**: Easy (file parsing)
**Value**: High (corporate environments, security posture)
**Alignment**: #20, #19 (Debian-specific testing being added)

**Implementation**:
1. Parse `/etc/apt/apt.conf.d/*` for `Acquire::http::Proxy`
2. Check `/etc/apt/apt.conf.d/20auto-upgrades` existence + parse
3. Add to template output

**Justification**: Strong alignment with Debian/Ubuntu testing expansion in v1.3.0. High value for corporate deployments and security.

**Note**: Excluded `apt.no_recommends` - lower priority, save for v1.4.0.

---

### 4. Pacman Multilib Discovery (EASY - 2 hours)

**Gap**: `pacman.multilib.enabled`

**Technical**: Easy (file parsing)
**Value**: High (extremely common Arch customization for 32-bit support)
**Alignment**: Distribution-specific testing (#19, #20 focus on distro differentiation)

**Implementation**:
- Parse `/etc/pacman.conf` for uncommented `[multilib]` section
- Add to template output

**Justification**: Arch Linux is a supported distribution, multilib is nearly universal for desktop Arch users. Aligns with distribution-specific testing emphasis.

---

## Later Release (v1.4.0+) - High Value, Separate Scope

### 5. Kernel Modules Discovery (EASY - 1 day)

**Gaps**:
- `host_modules.load`
- `host_modules.blacklist`

**Technical**: Easy (file enumeration)
**Value**: High (critical for hardware/networking/containers)
**Alignment**: None (no v1.3.0 kernel/hardware work)

**Implementation**:
- Read `/etc/modules-load.d/*.conf` files
- Read `/etc/modprobe.d/*-blacklist.conf` files
- Add to template output

**Justification**: High value but no natural fit with v1.3.0 scope. Should be prioritized for v1.4.0 as it's easy and valuable.

---

### 6. User Git Configuration Discovery (EASY - 1 day)

**Gaps**:
- `users[].git.user_name`
- `users[].git.user_email`
- `users[].git.editor`

**Technical**: Easy (command execution per user)
**Value**: High (essential developer environment state)
**Alignment**: None (no v1.3.0 user configuration work)

**Implementation**:
- For each discovered user, run: `git config --get user.name/user.email/core.editor`
- Handle missing git or unset config gracefully
- Add to users[] output in template

**Justification**: High value for developer environments but no v1.3.0 alignment. Save for v1.4.0 user configuration enhancement release.

---

### 7. User NPM Packages Discovery (EASY - 1 day)

**Gap**: `users[].nodejs.packages`

**Technical**: Easy (command execution per user)
**Value**: High (critical developer environment state)
**Alignment**: None (no v1.3.0 nodejs/user work)

**Implementation**:
- For each discovered user, run: `npm list -g --depth=0`
- Parse output for package names
- Add to users[] output in template

**Justification**: High value for Node.js developers but no v1.3.0 alignment. Pair with git config in v1.4.0 "developer environment discovery" theme.

---

### 8. Fail2ban Basic Detection (EASY - 2 hours)

**Gap**: `fail2ban.enabled`

**Technical**: Easy (service check)
**Value**: High (security service detection)
**Alignment**: None (no v1.3.0 security services work)

**Implementation**:
- Check: `systemctl is-active fail2ban`
- Update template placeholder (lines 92-95) with actual detection
- Add to template output

**Justification**: High security value, easy implementation, but no v1.3.0 alignment. Template placeholder already exists. Save for v1.4.0 security-focused release.

**Note**: Full fail2ban config parsing (bantime, jails, etc.) deferred to later due to moderate complexity.

---

### 9. NTP Servers Discovery (EASY - 1 day)

**Gap**: `domain_timesync.servers`

**Technical**: Easy (file parsing)
**Value**: Medium (corporate/regional time sources)
**Alignment**: None (no v1.3.0 time sync work)

**Implementation**:
- Linux: Parse `/etc/systemd/timesyncd.conf` for `NTP=` lines
- macOS: Run `systemsetup -getnetworktimeserver`
- Replace hardcoded `["0.pool.ntp.org", "1.pool.ntp.org"]` in template with actual detection
- Add to template output

**Justification**: Medium value, easy implementation, but no v1.3.0 alignment. Save for v1.4.0.

---

### 10. Journal Configuration Discovery (EASY - 1 day)

**Gaps**:
- `journal.max_size`
- `journal.max_retention`
- `journal.forward_to_syslog`
- `journal.compress`

**Technical**: Easy (INI file parsing)
**Value**: Medium (sysadmin disk management customization)
**Alignment**: #17 (journal configuration missing from VM tests) - but not v1.3.0

**Implementation**:
- Parse `/etc/systemd/journald.conf` and `/etc/systemd/journald.conf.d/*.conf`
- Extract SystemMaxUse, MaxRetentionSec, ForwardToSyslog, Compress
- Add to template output

**Justification**: Issue #17 identifies this as a gap but it's not tagged v1.3.0. Medium value. Save for v1.4.0 logging-focused work.

---

### 11. APT No-Recommends - RECLASSIFIED AS USER PREFERENCE

**Gap**: `apt.no_recommends`

**Original Classification**: Coverage gap
**Revised Classification**: **USER PREFERENCE** - Controls collection behavior

**Rationale**:
- This is a preference about HOW to install packages, not WHAT is installed
- Similar to `pacman.no_confirm` - controls package manager behavior
- User decides whether they want recommended packages or not
- Not discoverable system state, but deployment preference

**Action**: Move to "Won't Fix" section as user preference flag

---

### 12. Pacman Proxy Discovery (EASY - 2 hours)

**Gap**: `pacman.proxy`

**Technical**: Easy (file parsing)
**Value**: Medium (corporate environments)
**Alignment**: Partial (#19, #20 distro work)

**Implementation**:
- Parse `/etc/pacman.conf` for `XferCommand` with proxy URL
- Add to template output

**Justification**: Lower priority than multilib. Save for v1.4.0 Pacman completion.

---

### 13. User Rust Packages Discovery (MODERATE - 2 days)

**Gap**: `users[].rust.packages`

**Technical**: Moderate (binary detection, name inference)
**Value**: High (Rust developer environments)
**Alignment**: None (no v1.3.0 rust work)

**Implementation**:
- Parse `~/.cargo/bin/` for binaries per user
- Infer package names from binary names (imperfect)
- Add to users[] output in template

**Justification**: High value for Rust developers, moderate complexity. Pair with Go packages in v1.4.0 "language tooling discovery" theme.

---

### 14. User Go Packages Discovery (MODERATE - 2 days)

**Gap**: `users[].go.packages`

**Technical**: Moderate (binary detection)
**Value**: Medium (Go developer environments)
**Alignment**: None (no v1.3.0 go work)

**Implementation**:
- Check `~/go/bin/` for binaries per user
- List installed tools
- Add to users[] output in template

**Justification**: Medium value, moderate complexity. Pair with Rust in v1.4.0.

---

### 15. User Neovim Detection (EASY - 2 hours)

**Gap**: `users[].neovim.enabled`

**Technical**: Easy (command check)
**Value**: Medium (editor preference)
**Alignment**: None (no v1.3.0 editor work)

**Implementation**:
- Check if `nvim` command exists for each user
- Add to users[] output in template

**Justification**: Medium value, easy implementation. Save for v1.4.0 user tooling discovery.

---

### 16. macOS Auto-Update Settings Discovery (EASY - 1 day)

**Gaps**:
- `macosx.updates.auto_check`
- `macosx.updates.auto_download`

**Technical**: Easy (defaults query)
**Value**: Medium (macOS security preference)
**Alignment**: None (no v1.3.0 macOS work)

**Implementation**:
- Query: `defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled`
- Query: `defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload`
- Add to macosx section in template

**Justification**: Medium value for macOS users. Save for v1.4.0 macOS-focused enhancements.

---

### 17. Fail2ban Configuration Discovery (MODERATE - 3 days)

**Gaps**:
- `fail2ban.bantime`
- `fail2ban.findtime`
- `fail2ban.maxretry`
- `fail2ban.jails`

**Technical**: Moderate (fail2ban config parsing)
**Value**: High (security configuration)
**Alignment**: None (no v1.3.0 fail2ban work)

**Implementation**:
- Parse `/etc/fail2ban/jail.local` and `/etc/fail2ban/jail.d/*.conf`
- Handle fail2ban INI-like format with inheritance
- Extract global settings and per-jail configurations
- Add to template output

**Justification**: High security value but moderate complexity. Requires understanding fail2ban config inheritance. Save for v1.4.0 security-focused release after basic detection (#8 above).

---

### 18. rsyslog Configuration Discovery (MODERATE - 3 days)

**Gaps**:
- `rsyslog.remote_host`
- `rsyslog.remote_port`
- `rsyslog.protocol`

**Technical**: Moderate (rsyslog syntax parsing)
**Value**: Medium (centralized logging environments)
**Alignment**: #12 (rsyslog remote logging) - BUT this is a bug saying rsyslog ISN'T implemented

**Implementation**:
- Parse `/etc/rsyslog.conf` and `/etc/rsyslog.d/*.conf`
- Detect `@@remote` (TCP) and `@remote` (UDP) patterns
- Extract hostname and port
- Add to template output

**Justification**: Issue #12 indicates rsyslog remote logging is "defined in defaults but not implemented" - this means the **configuration role** doesn't support it yet. Discovery cannot detect what the collection cannot configure. **Defer until rsyslog implementation is complete in collection.**

---

## Defer - Low Value or Impractical

### 19. UFW Logging Discovery (EASY - 1 hour)

**Gap**: `firewall.logging`

**Technical**: Easy (command parsing)
**Value**: Low (rarely customized)
**Alignment**: None

**Implementation**:
- Parse `ufw status verbose` for logging line
- Add to firewall section in template

**Justification**: Low value - most users leave at defaults. Defer indefinitely.

---

### 20. User Terminal Entries Discovery (HARD - impractical)

**Gap**: `users[].terminal_entries`

**Technical**: Hard (too many formats)
**Value**: Low (highly variable)
**Alignment**: None

**Implementation**: Would require checking for alacritty, kitty, wezterm, iterm2, gnome-terminal, konsole, etc. with different config formats

**Justification**: Too many terminal emulators with wildly different config formats. Low value for high complexity. **Do not implement.**

---

## Won't Fix - Intentionally One-Way

### User Preference Flags (15 variables)

These control collection behavior and are not discoverable by design:

**Domain-Level**:
- N/A (all domain variables are discoverable state)

**Host-Level**:
- `host_update_hosts` - Controls whether collection updates /etc/hosts

**System Logging**:
- `journal.configure` - Controls whether collection configures journal
- `rsyslog.enabled` - Controls whether collection configures rsyslog

**Security Hardening**:
- `hardening.os_hardening_enabled` - Controls whether to apply devsec.hardening
- `hardening.ssh_hardening_enabled` - Controls SSH hardening application

**Package Management**:
- `apt.no_recommends` - Controls whether to install recommended packages (behavior preference)
- `apt.system_upgrade.enable` - Controls whether collection runs apt upgrades
- `apt.system_upgrade.type` - Controls apt upgrade type (safe/full)
- `pacman.no_confirm` - Controls --noconfirm flag usage
- `pacman.enable_aur` - Controls whether collection manages AUR
- `homebrew.cleanup_cache` - Controls Homebrew cache cleanup
- `snap.remove_completely` - Controls complete snapd removal
- `flatpak.enabled` - Controls Flatpak management

**Security Services**:
- `firewall.enabled` - Controls whether collection manages firewall
- `firewall.prevent_ssh_lockout` - Controls automatic SSH rule
- `firewall.stealth_mode` - Controls stealth mode application
- `firewall.block_all` - Controls default-deny policy

**Justification**: These are collection behavior toggles, not system state. Users set these based on deployment intent, not discovered configuration.

---

## Summary Statistics

### Coverage Gap Distribution

**Total TRUE coverage gaps**: 40

**By Implementation Difficulty**:
- **Trivial** (already collected): 2 gaps (5%)
- **Easy** (file parsing, command execution): 17 gaps (43%)
- **Moderate** (complex parsing, binary detection): 5 gaps (12%)
- **Hard/Impractical**: 1 gap (2%)
- **Won't Fix** (user preferences): 15 flags (38%)

**By Release Prioritization**:
- **Next Release (v1.3.0)**: 4 gaps (10%)
- **Later Release (v1.4.0+)**: 14 gaps (35%)
- **Defer**: 2 gaps (5%)
- **Won't Fix**: 15 flags (38%)
- **Blocked** (rsyslog): 3 gaps (8%) - waiting for collection implementation

### v1.3.0 Recommendation Summary

**Total gaps for v1.3.0**: 3 gaps
**Total implementation time**: ~1.5 days

1. **Masked services** (30 min) - Trivial, already collected
2. **APT configuration** (1 day) - Easy, aligns with Debian testing
3. **Pacman multilib** (2 hours) - Easy, aligns with distro testing

**Coverage improvement**: 47% → 51% (35/75 → 38/75)

**Alignment with v1.3.0 issues**:
- #20, #19: Distribution-specific testing (Debian, Arch)
- #21, #16: Flatpak work (completes existing functionality, defers new features)

**Deferred to v1.4.0**: Flatpak remotes (needs configuration implementation first)

**Risk**: Low - all easy implementations, high alignment with existing work

---

## v1.4.0+ Roadmap

### Theme 0: Flatpak Remotes Support (NEW - 2 days)

**Prerequisite**: Create new issue "Implement multiple flatpak remotes support"

**Configuration Work** (1.5 days):
- Update manage_flatpak role to support `flatpak.remotes` list
- Replace hardcoded Flathub toggle with remotes list
- Add support for multiple remotes (flathub, flathub-beta, elementary, etc.)

**Discovery Work** (0.5 days):
- Add `flatpak.remotes` to template output (trivial - data already collected)

**Testing**:
- Update molecule scenarios with multiple remotes
- Validate discovery detects all configured remotes

**Gap**: 1 gap
**Coverage improvement**: 51% → 52% (38/75 → 39/75)

### Theme 1: Developer Environment Discovery (4 days)

**Gaps**: 6 gaps
- User git configuration
- User NPM packages
- User Rust packages
- User Go packages
- User Neovim detection

**Coverage improvement**: 52% → 60% (39/75 → 45/75)

### Theme 2: Security Configuration Discovery (5 days)

**Gaps**: 6 gaps
- Fail2ban basic detection
- Fail2ban configuration parsing
- Journal configuration
- UFW logging (low priority)

**Coverage improvement**: 60% → 68% (45/75 → 51/75)

### Theme 3: System Configuration Completion (4 days)

**Gaps**: 7 gaps
- Kernel modules (load/blacklist)
- NTP servers
- APT no-recommends
- Pacman proxy
- macOS auto-updates

**Coverage improvement**: 68% → 77% (51/75 → 58/75)

### Theme 4: Advanced Logging (3 days)

**Gaps**: 3 gaps (blocked)
- rsyslog configuration (waiting for collection implementation per #12)

**Coverage improvement**: 77% → 81% (58/75 → 61/75)

**Note**: Blocked until rsyslog remote logging is implemented in collection.

---

## Blocked Work

### rsyslog Remote Logging Discovery

**Issue**: #12 states "rsyslog remote logging defined in defaults but not implemented"

**Interpretation**: The collection **configuration roles** do not implement rsyslog remote logging functionality yet. Discovery cannot detect what the collection cannot configure.

**Recommendation**:
1. First implement rsyslog remote logging in `os_configuration` role
2. Then add discovery support in v1.4.0 or later
3. Close #12 when implementation is complete
4. Add rsyslog discovery in subsequent release

**Timeline**: Dependent on rsyslog implementation work - not yet scheduled

---

## Implementation Sequence

### v1.3.0 (2 days)

**Week 1**:
1. Day 1 AM: Flatpak remotes + Masked services (trivial template additions)
2. Day 1 PM - Day 2: APT configuration + Pacman multilib

**Testing**: Leverage existing #20, #19, #16 test scenario work

**Release Notes**: "Improved discovery coverage for Debian/Ubuntu APT configuration and Arch Linux multilib detection. Completed flatpak and systemd service discovery."

### v1.4.0 (16 days)

**Month 1 - Developer Environment** (1 week):
- Git configuration
- NPM packages
- Neovim detection
- Rust packages
- Go packages

**Month 2 - Security Configuration** (1 week):
- Fail2ban detection + configuration
- Journal configuration
- Kernel modules

**Month 3 - System Completion** (4 days):
- NTP servers
- APT no-recommends
- Pacman proxy
- macOS auto-updates

**Release Notes**: "Major discovery enhancements: developer environment detection (git, npm, rust, go), security configuration discovery (fail2ban, journal), and system configuration completion (kernel modules, NTP servers)."

### v1.5.0+ (3 days)

**rsyslog Discovery** (after #12 implementation):
- Remote host, port, protocol detection

**Release Notes**: "Added rsyslog remote logging discovery support."

---

## Success Metrics

**v1.3.0 Target**: 51% coverage (38/75 discoverable variables)
**v1.4.0 Target**: 77% coverage (58/75 discoverable variables)
**v1.5.0+ Target**: 81%+ coverage (61+/75 discoverable variables)

**Final Coverage**: 81%+ (61+/75)
- 14 gaps remain: 13 deferred/won't-fix, 1 impractical

**v1.3.0 ROI**: 3 gaps in 1.5 days (4% coverage improvement)
**v1.4.0 ROI**: 20 gaps in 18 days (26% coverage improvement, includes flatpak remotes configuration work)

---

## Recommendations

1. **Approve v1.3.0 gaps** (3 gaps, 1.5 days) - Low risk, high alignment
2. **Defer flatpak remotes to v1.4.0** - Requires configuration implementation first
3. **Create new issue for v1.4.0**: "Implement multiple flatpak remotes support"
4. **Plan v1.4.0 themed releases** - Group related discovery work for coherent releases
5. **Block rsyslog discovery** until #12 implementation complete
6. **Close terminal_entries gap** - Mark as "won't implement" due to impracticality
7. **Document user preference flags** - Update discovery docs to clarify intentionally one-way variables

---

## Next Steps

1. Create implementation issues for v1.3.0 gaps (3 issues)
2. Update v1.3.0 milestone to include discovery gaps
3. Create v1.4.0 issue: "Implement multiple flatpak remotes support"
4. Begin v1.3.0 implementation (masked services first - trivial)
5. Document won't-fix decisions in discovery role README
6. Plan v1.4.0 themes based on community feedback
