# os_configuration Role Gap Analysis

**Document Version:** 1.0
**Date:** September 22, 2025
**Purpose:** Compare current implementation against validation plan requirements

---

## Current Molecule Test Status

### What's Currently Tested (3 of 28 requirements)
✅ **REQ-OS-003**: Timezone configuration - verified with `timedatectl`
✅ **REQ-OS-008**: NTP configuration (partial) - file existence only
✅ **REQ-OS-006**: Locale (basic check) - `localectl status` but no assertion

### What's Explicitly Skipped
❌ **Tags skipped in molecule.yml**: `locale,hardening,hostname`
- REQ-OS-001: Hostname configuration (skipped - container limitation)
- REQ-OS-004: OS hardening (skipped)
- REQ-OS-005: SSH hardening (skipped)
- REQ-OS-006: Locale configuration (skipped)

### Critical Issues with Current Tests

1. **Limited Validation**: Only 3 requirements have any testing
2. **Weak Assertions**: Locale check has no assertions (displays but doesn't verify)
3. **Missing Negative Tests**: No validation of conditional logic
4. **Platform Coverage**: Ubuntu + Arch but no macOS scenarios
5. **Container Limitations**: Several requirements skipped due to container constraints

---

## Requirement Coverage Analysis

### Cross-Platform Requirements (REQ-OS-001 to REQ-OS-003)

| Requirement | Current Status | Gap Analysis |
|-------------|----------------|--------------|
| REQ-OS-001: Hostname | ❌ Skipped (hostname tag) | Need VM testing scenario |
| REQ-OS-002: /etc/hosts | ❌ Not tested | Need file content verification |
| REQ-OS-003: Timezone | ✅ Basic test | Need negative tests |

### Linux Security Requirements (REQ-OS-004 to REQ-OS-005)

| Requirement | Current Status | Gap Analysis |
|-------------|----------------|--------------|
| REQ-OS-004: OS Hardening | ❌ Skipped (hardening tag) | Need role execution verification |
| REQ-OS-005: SSH Hardening | ❌ Skipped (hardening tag) | Need SSH config verification |

### Linux Locale/Language (REQ-OS-006 to REQ-OS-007)

| Requirement | Current Status | Gap Analysis |
|-------------|----------------|--------------|
| REQ-OS-006: Locale | ⚠️ Check only, no assertions | Need proper validation + negative tests |
| REQ-OS-007: Language | ❌ Not tested | Need implementation + tests |

### Linux NTP (REQ-OS-008)

| Requirement | Current Status | Gap Analysis |
|-------------|----------------|--------------|
| REQ-OS-008: NTP | ⚠️ File existence only | Need file content verification + service status |

### Linux Advanced (REQ-OS-009 to REQ-OS-021)

| Requirement | Current Status | Gap Analysis |
|-------------|----------------|--------------|
| REQ-OS-009: Journal config | ❌ Not tested | Need implementation + tests |
| REQ-OS-010: Rsyslog | ❌ Not tested | Need implementation + tests |
| REQ-OS-011: Enable services | ❌ Not tested | Need implementation + tests |
| REQ-OS-012: Disable services | ❌ Not tested | Need implementation + tests |
| REQ-OS-013: Mask services | ❌ Not tested | Need implementation + tests |
| REQ-OS-014: Load modules | ❌ Not tested | Need implementation + tests |
| REQ-OS-015: Blacklist modules | ❌ Not tested | Need implementation + tests |
| REQ-OS-016: Udev rules | ❌ Not tested | Need implementation + tests |
| REQ-OS-017: APT config | ❌ Not tested | Need implementation + tests |
| REQ-OS-018: APT upgrades | ❌ Not tested | Need implementation + tests |
| REQ-OS-019: Purge snapd | ❌ Not tested | Need implementation + tests |
| REQ-OS-020: Nerd Fonts | ❌ Not tested | Need implementation + tests |
| REQ-OS-021: Pacman config | ❌ Not tested | Need implementation + tests |

### macOS Requirements (REQ-OS-022 to REQ-OS-028)

| Requirement | Current Status | Gap Analysis |
|-------------|----------------|--------------|
| REQ-OS-022: macOS Locale | ❌ No macOS testing | Need macOS platform + tests |
| REQ-OS-023: macOS Language | ❌ No macOS testing | Need macOS platform + tests |
| REQ-OS-024: macOS NTP | ❌ No macOS testing | Need macOS platform + tests |
| REQ-OS-025: macOS Updates | ❌ No macOS testing | Need macOS platform + tests |
| REQ-OS-026: macOS Gatekeeper | ❌ No macOS testing | Need macOS platform + tests |
| REQ-OS-027: macOS Preferences | ❌ No macOS testing | Need macOS platform + tests |
| REQ-OS-028: AirDrop Ethernet | ❌ No macOS testing | Need macOS platform + tests |

---

## Implementation Gaps in Production Code

**Note**: This analysis is based on reviewing molecule tests only, not production code yet.

### Likely Missing Implementation
Based on skipped tests and SRD requirements, these features likely need implementation:
- Journal configuration (REQ-OS-009)
- Rsyslog configuration (REQ-OS-010)
- Service management (REQ-OS-011 to REQ-OS-013)
- Kernel module management (REQ-OS-014 to REQ-OS-015)
- Udev rules (REQ-OS-016)
- APT configuration (REQ-OS-017 to REQ-OS-018)
- Snapd purging (REQ-OS-019)
- Nerd Fonts installation (REQ-OS-020)
- Pacman configuration (REQ-OS-021)

### Container vs VM Testing Strategy

**Container-Testable** (can validate with current Docker setup):
- File creation/modification
- Configuration templating
- Package installation
- Basic service enable (not start)

**VM-Required** (need dedicated VM testing):
- Hostname changes
- Service start/stop/restart
- Firewall configuration
- systemd configuration that requires running systemd
- Kernel module loading/blacklisting

---

## Proposed Implementation Plan

### Phase 1: Fix Current Tests (Week 1)
**Priority**: Get existing tests working properly

1. **REQ-OS-003**: Fix timezone negative test cases
2. **REQ-OS-006**: Add proper locale assertions
3. **REQ-OS-008**: Add NTP file content verification
4. **REQ-OS-002**: Add /etc/hosts testing (container-safe)

### Phase 2: Add Container-Safe Requirements (Week 2)
**Priority**: Implement requirements that work in containers

5. **REQ-OS-007**: Language configuration
6. **REQ-OS-017**: APT configuration
7. **REQ-OS-018**: APT unattended upgrades
8. **REQ-OS-021**: Pacman configuration
9. **REQ-OS-020**: Nerd Fonts installation

### Phase 3: VM-Required Requirements (Week 3)
**Priority**: Implement requirements needing VMs

10. **REQ-OS-001**: Hostname (VM testing)
11. **REQ-OS-004**: OS hardening (enable tests)
12. **REQ-OS-005**: SSH hardening (enable tests)
13. **REQ-OS-011 to REQ-OS-013**: Service management
14. **REQ-OS-014 to REQ-OS-015**: Kernel modules

### Phase 4: Advanced Features (Week 4)
**Priority**: Complex integrations

15. **REQ-OS-009**: Journal configuration
16. **REQ-OS-010**: Rsyslog configuration
17. **REQ-OS-016**: Udev rules
18. **REQ-OS-019**: Snapd purging (role integration)

### Phase 5: macOS Support (Future)
**Priority**: Platform expansion

19. **REQ-OS-022 to REQ-OS-028**: All macOS requirements

---

## Success Criteria

### Phase 1 Complete
- All currently-tested requirements have comprehensive validation
- Both positive and negative test cases implemented
- Container test suite passes 100%

### Phase 2 Complete
- 75% of container-testable requirements implemented and tested
- Cross-platform (Ubuntu + Arch) validation working

### Phase 3 Complete
- VM testing infrastructure operational
- All VM-required Linux requirements implemented
- Integration with existing hardening roles working

### Phase 4 Complete
- 100% of Linux requirements implemented and tested
- Advanced integrations working properly

### Phase 5 Complete
- macOS platform support added
- All 28 requirements implemented across all platforms

---

## Risk Assessment

### High Risk
- **VM testing setup**: Complex infrastructure requirement
- **Service management**: Container limitations may require creative solutions
- **macOS testing**: Platform access and tooling challenges

### Medium Risk
- **Role integrations**: Dependencies on other collection roles
- **Cross-platform differences**: Ubuntu vs Arch vs macOS variations

### Low Risk
- **File/template operations**: Well-understood Ansible patterns
- **Container testing**: Existing working infrastructure

---

This gap analysis shows we need significant work to meet all 28 requirements, but we have a clear path forward with manageable phases.
