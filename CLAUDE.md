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

For repository management on Debian/Ubuntu systems, ALWAYS use ansible.builtin.deb822_repository. The deprecated apt_repository module will fail and must never be used.

### Supported Operating Systems

The role is intended to support Archlinux, MacOSX, Debian 12+, and Ubuntu 22+. That should be clear to the user in the documentation. There doesn't need to be any excessive version checking.

### Testing Principles

When working with molecule tests and CI:

- **Never add test-specific conditionals to production code** - Don't pollute roles with `when: not molecule_test` or similar defensive programming
- **Use tags for container limitations** - Skip tasks that don't work in containers using tags (e.g., `skip-tags: hostname,docker-compose`)
- **Individual role tests are valuable** - Maintain granular molecule scenarios for each role rather than only integration tests
- **Let roles fail semantically** - Roles should fail properly when dependencies are missing rather than masking issues
- **Container vs VM testing** - Some functionality (like hostname changes, docker-compose) requires VM testing with delegated driver
- **VM testing approach** - Use molecule with delegated driver for external VMs. The user manages VM provisioning; molecule connects via SSH to existing infrastructure for realistic system testing

### Testing Strategy Migration Plan

**Principle**: Every role gets a specific test. The complexity of the role determines the test type.

**Target testing structure**:
1. **Simple, standalone roles** → Individual role tests in `test-{role-name}` scenarios
   - Examples: test-os-configuration, test-packages, test-security-services, test-language-toolchains
   - Focus: Role-specific functionality, package installation, configuration validation

2. **Complex roles that orchestrate other roles** → Integration tests in `test-integration`
   - Examples: configure_system (calls multiple roles), complex multi-role workflows
   - Focus: Role interactions, cross-role dependencies, end-to-end scenarios

3. **Integration tests should NOT repeat unit-level testing** already covered by individual role tests

**Migration approach**: Incremental - each time we fix a molecule issue, extract one more individual role test from integration, following this plan until complete.

### Test Flow Hierarchy

**Local Development Pipeline** (catches issues before CI):
1. `validate-locally` with ansible-lint - syntax/best practices validation
2. `molecule role test` (or `molecule converge` during development) - individual role functionality testing
3. `pre-commit checks` - formatting, linting, custom validation hooks
4. **CI Tests** - should be identical to local molecule tests (same containers, scenarios, verification)

**Critical principle**: Individual role tests are the contract. If they pass locally and in CI, the role should work in integration. If integration fails anyway, investigate why the role test didn't catch the integration issue first - this indicates missing test coverage at the role level.
