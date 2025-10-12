# VM Test Infrastructure

VM-based testing infrastructure for comprehensive end-to-end validation of the wolskies.infrastructure collection.

## Overview

This directory contains VM test configurations and infrastructure code for testing the collection on real operating systems using libvirt/KVM virtual machines.

## Test Scenarios

### server-config.yml
Production-like server configuration testing:
- Minimal package set
- Security hardening (firewall, fail2ban)
- System services configuration
- Package management validation

### workstation-config.yml
Desktop/workstation configuration testing:
- GUI applications
- Development tools (nodejs, rust, go)
- Terminal configuration
- User environment setup

## Critical Testing Guidelines

### Distribution-Specific Package Selection

**IMPORTANT:** Test configurations MUST use different packages per distribution to catch bugs where code incorrectly uses `ansible_os_family` instead of `ansible_distribution`.

#### Why This Matters

During v1.0.2 final testing, we discovered a critical bug where `manage_packages` used `ansible_os_family` (returns "Debian" for both Ubuntu and Debian) instead of `ansible_distribution` (returns "Ubuntu" or "Debian"). This bug went undetected because test configs used identical packages for Ubuntu and Debian.

**The Bug:**
```yaml
# WRONG - Uses "Debian" for both Ubuntu and Debian
loop: "{{ _final_packages[ansible_os_family] | default([]) }}"

# CORRECT - Uses "Ubuntu" or "Debian"
loop: "{{ _final_packages[ansible_distribution] | default([]) }}"
```

If test configs use identical packages, the bug is invisible because both distributions get the same list regardless of which variable is used.

#### Testing Requirements

1. **Use different packages per distribution**
   ```yaml
   manage_packages_all:
     Ubuntu:
       - { name: tree }      # Ubuntu-specific
       - { name: jq }        # Ubuntu-specific
     Debian:
       - { name: rsync }     # Debian-specific
       - { name: dnsutils }  # Debian-specific
   ```

2. **Choose equivalent but different packages**
   - postgresql (Ubuntu) vs mariadb-server (Debian)
   - redis-server (Ubuntu) vs memcached (Debian)
   - emacs-nox (Ubuntu) vs firefox (Arch)

3. **Document why packages differ**
   ```yaml
   Ubuntu:
     - { name: postgresql }      # Ubuntu uses PostgreSQL for testing
   Debian:
     - { name: mariadb-server }  # Debian uses MariaDB (catches distro bugs)
   ```

4. **Apply to ALL package-related variables**
   - `manage_packages_all`
   - `manage_packages_group`
   - `manage_packages_host`
   - Any language-specific package lists (nodejs, rust, etc.)

#### Checklist for New Test Configurations

- [ ] Do Ubuntu and Debian have different packages in `manage_packages_all`?
- [ ] Do Ubuntu and Debian have different packages in `manage_packages_group`?
- [ ] Are package differences documented with comments explaining why?
- [ ] Do version-specific configs account for distro differences (e.g., firefox snap on Ubuntu 24.04)?
- [ ] Will the test fail if code uses `ansible_os_family` instead of `ansible_distribution`?

#### Examples

**Good - Catches bugs:**
```yaml
manage_packages_all:
  Ubuntu: [curl, wget, tree, jq]
  Debian: [curl, wget, rsync, dnsutils]
```
If code uses `ansible_os_family`, Ubuntu will try to install Debian's packages (rsync, dnsutils) and fail.

**Bad - Misses bugs:**
```yaml
manage_packages_all:
  Ubuntu: [curl, wget, tree, rsync]
  Debian: [curl, wget, tree, rsync]  # Identical - bug invisible
```
If code uses `ansible_os_family`, both get the same list so bug is hidden.

## Version-Specific Considerations

Different OS versions may require different packages:

```yaml
# Ubuntu 24.04: firefox is snap-only, use emacs-nox for apt testing
# Ubuntu 22.04: firefox available via apt
# Debian 12+: firefox available via apt
```

Document these considerations in test config comments.

## Running VM Tests

(Instructions for running VM tests will be added when Terraform infrastructure is implemented)

## Benefits of This Approach

- **Earlier bug detection**: Code using wrong variable fails immediately in tests
- **Real-world validation**: Tests reflect actual multi-distro deployments
- **Version coverage**: Catches distro-version-specific issues
- **Regression prevention**: Once fixed, stays fixed through continuous testing
