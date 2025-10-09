# Issues to Create from Discovery Audit

**Source**: Task 4 Prioritization (`docs/discovery-audit/task4-prioritization.md`)
**Date**: 2025-10-09

---

## v1.3.0 Discovery Implementation Issues

### 1. Discovery: Add masked services to template output

**Type**: Discovery gap (trivial)
**Effort**: 30 minutes
**Priority**: Medium
**Labels**: `enhancement`, `role::discovery`, `v1.3.0`

**Description**:
Masked services are already collected by discovery (`discovery_services_masked`) but not output to template.

**Implementation**:
- Add `host_services.mask` to template at lines 45-49
- Update template to include masked services list
- No new scan tasks needed

**Testing**:
- Verify masked services appear in generated host_vars
- Test with systems that have masked services

**Acceptance Criteria**:
- [ ] Template outputs `host_services.mask` when services are masked
- [ ] Empty list when no services masked
- [ ] Format matches `host_services.enable` and `host_services.disable`

**Status**: To be combined with issue #15

---

### 2. Discovery: APT configuration detection (proxy and unattended-upgrades)

**Type**: Discovery gap (easy)
**Effort**: 1 day
**Priority**: High
**Labels**: `enhancement`, `role::discovery`, `v1.3.0`, `os::debian`

**Description**:
Detect APT proxy configuration and unattended-upgrades status for Debian/Ubuntu systems.

**Alignment**: #20, #19 (Debian-specific testing expansion)

**Implementation**:
1. Add scan task to parse `/etc/apt/apt.conf.d/*` for `Acquire::http::Proxy`
2. Add scan task to check `/etc/apt/apt.conf.d/20auto-upgrades` and parse `APT::Periodic::Update-Package-Lists` and `APT::Periodic::Unattended-Upgrade`
3. Add `apt.proxy` and `apt.unattended_upgrades.enabled` to template output

**Testing**:
- Test with APT proxy configured
- Test with unattended-upgrades enabled/disabled
- Test with no apt configuration (defaults)

**Acceptance Criteria**:
- [ ] Detects APT proxy from apt.conf.d files
- [ ] Detects unattended-upgrades status
- [ ] Outputs `apt.proxy` and `apt.unattended_upgrades.enabled` to host_vars
- [ ] Handles missing configuration gracefully

**Status**: ✅ Created as issue #27

---

### 3. Discovery: Pacman multilib detection

**Type**: Discovery gap (easy)
**Effort**: 2 hours
**Priority**: High
**Labels**: `enhancement`, `role::discovery`, `v1.3.0`, `os::archlinux`

**Description**:
Detect whether Pacman multilib repository is enabled on Arch Linux systems.

**Alignment**: #19, #20 (Distribution-specific testing)

**Implementation**:
1. Add scan task to parse `/etc/pacman.conf`
2. Check if `[multilib]` section is uncommented
3. Add `pacman.multilib.enabled` to template output

**Testing**:
- Test with multilib enabled
- Test with multilib disabled (commented)
- Test with missing pacman.conf (edge case)

**Acceptance Criteria**:
- [ ] Detects multilib enabled status
- [ ] Outputs `pacman.multilib.enabled` to host_vars
- [ ] Handles missing/malformed pacman.conf gracefully

**Status**: ✅ Created as issue #28

---

### 4. Remove unimplemented rsyslog variables from defaults

**Type**: Cleanup (bug fix)
**Effort**: 30 minutes
**Priority**: High
**Labels**: `bug`, `v1.3.0`

**Description**:
Remove rsyslog remote logging variables from `defaults/main.yml` since the feature is not implemented. This prevents user confusion and false expectations.

**Background**:
- Variables defined: `rsyslog.enabled`, `rsyslog.remote_host`, `rsyslog.remote_port`, `rsyslog.protocol`
- No implementation exists for remote logging configuration
- Only service enable/disable is tested (via `host_services.enable`)
- Issue #12 documents this discrepancy

**Implementation**:
1. Remove lines 63-67 from `defaults/main.yml` (rsyslog block)
2. Remove rsyslog from `inventory/group_vars/all.yml.example` (line 38)
3. Keep test verification for rsyslog service enable (verify.yml) - this uses `host_services.enable`, not the removed vars
4. Update issue #12 description to reflect removal and retag for future implementation

**Files to modify**:
- `defaults/main.yml` (remove lines 63-67)
- `inventory/group_vars/all.yml.example` (remove line 38 block)
- Issue #12 (update description, change to `enhancement`, retag)

**Acceptance Criteria**:
- [ ] rsyslog variables removed from defaults
- [ ] rsyslog removed from example group_vars
- [ ] Service enable/disable tests still work (uses host_services.enable)
- [ ] Issue #12 updated to track future implementation

**Status**: To be created and implemented in v1.3.0

---

## v1.4.0 New Functionality Issues

### 5. Implement multiple flatpak remotes support

**Type**: New functionality (configuration + discovery)
**Effort**: 2 days
**Priority**: Medium
**Labels**: `enhancement`, `role::manage_flatpak`, `role::discovery`, `v1.4.0`

**Description**:
Collection defines `flatpak.remotes` in defaults but manage_flatpak role only supports hardcoded Flathub toggle. Implement support for multiple flatpak remotes and corresponding discovery.

**Background**:
- Current: Role only supports `flatpak.flathub` boolean toggle
- Desired: Support `flatpak.remotes` list with multiple remotes (flathub, flathub-beta, elementary, etc.)
- Discovery already scans for remotes but doesn't output (waiting for configuration support)

**Configuration Work** (1.5 days):
1. Update `manage_flatpak` role to support `flatpak.remotes` list
2. Replace hardcoded Flathub task with loop over remotes
3. Handle remote addition and removal
4. Maintain backward compatibility or document breaking change

**Discovery Work** (0.5 days):
1. Add `flatpak.remotes` to template output (trivial - data already collected in `discovery_flatpak_remotes`)

**Testing**:
- Test with multiple remotes (flathub + flathub-beta)
- Test with single remote
- Test with no remotes
- Verify discovery detects all configured remotes

**Acceptance Criteria**:
- [ ] manage_flatpak supports `flatpak.remotes` list
- [ ] Can add/remove multiple remotes
- [ ] Discovery outputs detected remotes to host_vars
- [ ] Documentation updated with examples
- [ ] Molecule tests cover multiple remotes

**Alignment**: Completes flatpak work started in #21, #16

**Status**: ✅ Created as issue #26

---

### 6. Discovery: Kernel modules detection

**Type**: Discovery gap (easy)
**Effort**: 1 day
**Priority**: High
**Labels**: `enhancement`, `role::discovery`, `v1.4.0`

**Description**:
Detect persistent kernel module configuration (modules to load and blacklist).

**Implementation**:
1. Read `/etc/modules-load.d/*.conf` for modules to load
2. Read `/etc/modprobe.d/*-blacklist.conf` for blacklisted modules
3. Add `host_modules.load` and `host_modules.blacklist` to template output

**Value**: High - critical for hardware/networking/container configurations

**Status**: ✅ Created as issue #29

---

### 7. Discovery: User git configuration detection

**Type**: Discovery gap (easy)
**Effort**: 1 day
**Priority**: High
**Labels**: `enhancement`, `role::discovery`, `v1.4.0`
**Blocked by**: #31 (User-level architecture decision)

**Description**:
Detect per-user git configuration (name, email, editor).

**Implementation**:
1. For each user, run `git config --get user.name/user.email/core.editor`
2. Add to `users[].git.*` in template output

**Value**: High - essential developer environment configuration

**Status**: ✅ Created as issue #30

---

### 8. Architecture Decision: User-level discovery and configuration scope

**Type**: Architecture / Meta-issue
**Effort**: Discussion + documentation
**Priority**: High (blocks user-level issues)
**Labels**: `architecture`, `discussion`, `v1.4.0`

**Description**:
Meta-issue to decide user-level discovery architecture and whether collection should support user creation/SSH keys.

**Questions to resolve**:
1. Should collection support user creation? (Currently out of scope)
2. If yes: SSH key management? Sudoers configuration?
3. User scanning scope: all users / selective / ansible_user only / none?
4. Security implications of become_user for tool detection
5. Performance impact of per-user scanning

**Blocks**: #30 (git config), NPM packages, Rust packages, Go packages, Neovim detection

**Decision for v1.3.0**: Keep current user scanning (basic account info only)

**Status**: ✅ Created as issue #31

---

### 9. Discovery: Fail2ban basic detection

**Type**: Discovery gap (easy)
**Effort**: 2 hours
**Priority**: High
**Labels**: `enhancement`, `role::discovery`, `v1.4.0`

**Description**:
Detect whether fail2ban service is enabled. Template placeholder exists but has no implementation.

**Implementation**:
1. Check `systemctl is-active fail2ban`
2. Update template placeholder (lines 92-95)
3. Output `fail2ban.enabled` to host_vars

**Value**: High security value - knowing if fail2ban is active

**Status**: ✅ Created as issue #32

---

### 10. Discovery: NTP servers detection

**Type**: Discovery gap (easy)
**Effort**: 1 day
**Priority**: Medium
**Labels**: `enhancement`, `role::discovery`, `v1.4.0`

**Description**:
Detect actual NTP servers instead of hardcoded fallback. Currently template hardcodes `["0.pool.ntp.org", "1.pool.ntp.org"]`.

**Implementation**:
- Linux: Parse `/etc/systemd/timesyncd.conf` for `NTP=` lines
- macOS: Run `systemsetup -getnetworktimeserver`
- Replace hardcoded servers with actual detection

**Value**: Medium - corporate environments customize for regional/corporate time sources

**Status**: ✅ Created as issue #33

---

### 11. Discovery: Pacman proxy detection

**Type**: Discovery gap (easy)
**Effort**: 2 hours
**Priority**: Medium
**Labels**: `enhancement`, `role::discovery`, `v1.4.0`, `os::archlinux`

**Description**:
Detect Pacman proxy configuration. Complements #28 (multilib) for complete Pacman discovery.

**Implementation**:
1. Parse `/etc/pacman.conf` for `XferCommand` with proxy
2. Add `pacman.proxy` to template output

**Value**: Medium - corporate/enterprise Arch Linux deployments

**Status**: ✅ Created as issue #34

---

### 12. Discovery: Fail2ban configuration parsing

**Type**: Discovery gap (moderate)
**Effort**: 3 days
**Priority**: Medium (after #32 basic detection)
**Labels**: `enhancement`, `role::discovery`, `v1.4.0`
**Depends on**: #32

**Description**:
Parse fail2ban configuration for bantime, findtime, maxretry, and enabled jails. Extends #32 with full configuration discovery.

**Implementation**:
1. Parse `/etc/fail2ban/jail.local` and `/etc/fail2ban/jail.d/*.conf`
2. Handle fail2ban INI-like format with inheritance
3. Extract global settings and jails
4. Add to template output

**Value**: High security value - complete fail2ban configuration documentation

**Status**: ✅ Created as issue #35

---

### 13. Discovery: Journal configuration detection

**Type**: Discovery gap (easy)
**Effort**: 1 day (included in #17)
**Priority**: Medium
**Labels**: `enhancement`, `role::discovery`, `v1.4.0`

**Description**:
Detect systemd journal configuration (max_size, max_retention, forward_to_syslog, compress).

**Implementation**:
1. Parse `/etc/systemd/journald.conf` and `/etc/systemd/journald.conf.d/*.conf`
2. Extract SystemMaxUse, MaxRetentionSec, ForwardToSyslog, Compress
3. Add to template output

**Alignment**: #17 (journal configuration VM testing) - discovery needed for validation

**Value**: Medium - sysadmin disk management customization

**Status**: ✅ Added as note to issue #17

---

## Future Issues (Deferred/Blocked)

### 14. Implement rsyslog remote logging support

**Type**: New functionality (configuration + discovery)
**Effort**: 1 week
**Priority**: Medium (future release)
**Labels**: `enhancement`, `role::os_configuration`, `role::discovery`

**Description**:
Implement rsyslog remote logging configuration that was removed from v1.3.0 defaults.

**Background**:
- Variables previously defined: `rsyslog.enabled`, `rsyslog.remote_host`, `rsyslog.remote_port`, `rsyslog.protocol`
- Removed in v1.3.0 because not implemented (issue #12)
- This issue tracks future implementation

**Configuration Work**:
1. Create rsyslog configuration templates
2. Implement remote logging setup in os_configuration role
3. Add to defaults/main.yml (re-introduce variables)
4. Write molecule tests

**Discovery Work**:
1. Parse `/etc/rsyslog.conf` and `/etc/rsyslog.d/*.conf`
2. Detect `@@remote` (TCP) and `@remote` (UDP) patterns
3. Extract hostname, port, protocol
4. Add to template output

**Acceptance Criteria**:
- [ ] rsyslog remote logging configuration implemented
- [ ] Variables re-added to defaults
- [ ] Discovery detects rsyslog configuration
- [ ] Molecule tests verify configuration
- [ ] Documentation updated

**Blocks**: Discovery issue (Task 4 Item #18)
**Related**: Issue #12 (documents removal from v1.3.0)

**Status**: To be created after #12 is updated

---

## Summary

**Created for v1.3.0**:
- ✅ #27: APT configuration detection (1 day)
- ✅ #28: Pacman multilib detection (2 hours)
- ⏳ Rsyslog removal from defaults (30 min) - to be created
- ⏳ #15: Add masked services to discovery - to be updated

**Created for v1.4.0**:
- ✅ #26: Implement flatpak remotes support (2 days)
- ✅ #29: Kernel modules discovery (1 day)
- ✅ #30: Git config discovery (1 day)
- ✅ #31: User-level architecture meta-issue
- ✅ #32: Fail2ban basic detection (2 hours)
- ✅ #33: NTP servers detection (1 day)
- ✅ #34: Pacman proxy detection (2 hours)
- ✅ #35: Fail2ban config parsing (3 days)
- ✅ #17: Journal discovery added as note

**Future**:
- ⏳ rsyslog implementation (blocked - removed from v1.3.0)

**Total v1.3.0 Discovery Work**: ~1.5 days
**Total v1.4.0 Work**: ~10 days (configuration + discovery)
