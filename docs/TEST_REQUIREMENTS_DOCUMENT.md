# Test Requirements Document (TRD)
## wolskies.infrastructure Ansible Collection

**Document Version:** 1.0
**Collection Version:** 1.2.0 (Target)
**Last Updated:** September 22, 2025
**Status:** Draft

---

## Table of Contents

1. [Test Strategy Overview](#1-test-strategy-overview)
2. [Test Requirements](#2-test-requirements)
3. [Test Coverage Matrix](#3-test-coverage-matrix)
4. [Test Environment Requirements](#4-test-environment-requirements)
5. [Test Execution](#5-test-execution)

---

## Document Purpose

This document defines the comprehensive test strategy, requirements, and coverage for the wolskies.infrastructure collection v1.2.0. It establishes the testing methodology to validate all requirements specified in the Software Requirements Document (SRD) v1.0.

---

## 1. Test Strategy Overview

### 1.1 Test Philosophy

**Core Principles:**
- **Individual role tests are authoritative** - Each role must have comprehensive tests that validate its specific functionality
- **No test-specific production code** - Never add `when: not molecule_test` conditionals or similar test accommodations to production code
- **Semantic failures over masking** - Let roles fail properly rather than masking issues with test workarounds
- **Progressive testing approach** - Each test phase should catch issues before the next phase

**Testing Contract:**
> Individual role tests are the definitive validation of functionality. If role tests pass but integration fails, this indicates missing role test coverage, not integration code issues.

### 1.2 Test Hierarchy

**Phase I: Development Testing (Required before any commit)**
1. `ansible-lint` - Syntax and standards validation
2. `molecule converge` - Role functionality testing during development
3. `molecule test` - **MUST PASS** - Full test suite including verification
4. `pre-commit` - Formatting, linting, custom hooks

**Phase II: CI Testing (Automated)**
- Individual role tests (parallel execution)
- Integration testing
- Discovery validation
- Minimal scenario testing

**Phase III: VM Testing (Comprehensive validation)**
- Full platform matrix testing
- Real-world scenario validation
- Edge case testing
- Performance validation

### 1.3 Test Types by Role Complexity

**Simple Roles** → Individual role tests (`roles/{role-name}/molecule/default/`)
- Focus: Role-specific functionality, packages, configuration
- Examples: nodejs, rust, go, os_configuration, manage_packages

**Orchestrating Roles** → Integration tests (`molecule/test-integration/`)
- Focus: Role interactions, cross-dependencies, end-to-end workflows
- Examples: configure_system (calls multiple roles)

**Cross-cutting Concerns** → Specialized test suites
- Discovery validation
- Security hardening verification
- Platform compatibility

---

## 2. Test Requirements

### 2.1 Development Test Requirements

#### 2.1.1 Pre-commit Testing

**TEST-REQ-001**: All code changes SHALL pass local molecule testing before commit

**Implementation**:
- `molecule test` must pass for all modified roles
- Pre-commit hooks must pass without errors
- No test failures allowed in CI if local tests pass

**Validation Criteria**:
- Zero molecule test failures
- All pre-commit hooks pass
- No syntax or linting errors

#### 2.1.2 Role-Specific Testing

**TEST-REQ-002**: Each role SHALL have comprehensive molecule tests validating all SRD requirements

**Implementation**:
- Test coverage for every REQ-{ROLE}-### requirement from SRD
- Platform-specific testing where applicable
- Variable validation and edge case testing

**Validation Criteria**:
- All SRD requirements have corresponding test cases
- Platform matrix coverage as defined in role scope
- Variable boundary testing included

### 2.2 CI/CD Test Requirements

#### 2.2.1 Parallel Role Testing

**TEST-REQ-003**: CI SHALL execute individual role tests in parallel for efficiency

**Implementation**:
- 5 parallel role test jobs: nodejs, rust, go, neovim, terminal_config
- Additional jobs: test-integration, test-discovery, test-minimal
- Each job runs independently with isolated test environments

**Validation Criteria**:
- All parallel jobs complete successfully
- No resource conflicts between parallel tests
- Total CI time under 15 minutes

#### 2.2.2 Integration Testing

**TEST-REQ-004**: CI SHALL validate role interactions and dependencies

**Implementation**:
- `molecule/test-integration/` test suite
- Cross-role dependency validation
- End-to-end workflow testing

**Validation Criteria**:
- All role integration scenarios pass
- Dependency resolution works correctly
- Variable passing between roles validated

### 2.3 VM Test Requirements

#### 2.3.1 Platform Matrix Testing

**TEST-REQ-005**: VM testing SHALL validate all supported platforms from SRD REQ-INFRA-001

**Implementation**:
- Ubuntu 22.04 LTS testing
- Ubuntu 24.04 LTS testing
- Arch Linux testing
- macOS testing (future)

**Validation Criteria**:
- All platforms execute successfully
- Platform-specific requirements validated
- Cross-platform compatibility confirmed

#### 2.3.2 Real-world Scenario Testing

**TEST-REQ-006**: VM testing SHALL validate realistic deployment scenarios

**Implementation**:
- Fresh cloud image deployment
- Multi-user configuration scenarios
- Complex package and service management
- Security hardening validation

**Validation Criteria**:
- Cloud images configure successfully
- All test users created and configured
- Security policies properly applied
- Services operational post-configuration

---

## 3. Test Coverage Matrix

### 3.1 Role Test Coverage Requirements

| Role | Test Type | SRD Requirements | Platform Coverage | Status |
|------|-----------|------------------|-------------------|--------|
| os_configuration | Individual | REQ-OS-001 to REQ-OS-028 (28 req) | Ubuntu, Arch, macOS | ✅ Complete |
| manage_security_services | Individual | REQ-SS-001 to REQ-SS-012 (12 req) | Ubuntu, Arch, macOS | ✅ Complete |
| manage_packages | Individual | REQ-MP-001 to REQ-MP-015 (15 req) | Ubuntu, Arch, macOS | ✅ Complete |
| manage_snap_packages | Individual | REQ-MSP-001 to REQ-MSP-003 (3 req) | Ubuntu only | ✅ Complete |
| manage_flatpak | Individual | REQ-MF-001 to REQ-MF-005 (5 req) | Ubuntu, Arch | ✅ Complete |
| configure_user | Individual | REQ-CU-001 to REQ-CU-018 (18 req) | Ubuntu, Arch, macOS | 🔄 In Progress |
| nodejs | Individual | REQ-NODE-001 to REQ-NODE-002 (2 req) | Ubuntu, Arch, macOS | ✅ Complete |
| rust | Individual | REQ-RUST-001 to REQ-RUST-002 (2 req) | Ubuntu, Arch, macOS | ✅ Complete |
| go | Individual | REQ-GO-001 to REQ-GO-002 (2 req) | Ubuntu, Arch, macOS | ✅ Complete |
| neovim | Individual | REQ-NEOVIM-001 to REQ-NEOVIM-002 (2 req) | Ubuntu, Arch, macOS | ✅ Complete |
| terminal_config | Individual | REQ-TERMINAL-001 to REQ-TERMINAL-002 (2 req) | Ubuntu, Arch | ✅ Complete |

**Total SRD Requirements to Test: 89**

### 3.2 Integration Test Coverage

| Integration Scenario | Requirements Covered | Platform | Status |
|---------------------|---------------------|----------|--------|
| System Configuration Workflow | os_configuration + manage_packages + manage_security_services | Ubuntu, Arch | ✅ Complete |
| User Environment Setup | configure_user + dev environments (nodejs/rust/go/neovim) | Ubuntu, Arch, macOS | 🔄 Planned |
| Package Management Combinations | manage_packages + manage_snap_packages + manage_flatpak | Ubuntu, Arch | ✅ Complete |
| Discovery Validation | All roles + discovery role validation | Ubuntu, Arch | ✅ Complete |

### 3.3 Container Test Limitations

**Container Skip Tags (for roles with container limitations):**
- `skip-tags: hostname` - Hostname changes not supported
- `skip-tags: docker-compose` - Docker compose functionality
- `skip-tags: terminal-config` - Terminal emulator configuration
- `skip-tags: systemd` - Systemd service management

---

## 4. Test Environment Requirements

### 4.1 Development Environment

**TEST-REQ-007**: Local development environment SHALL support full test execution

**Requirements**:
- Ansible 2.17+ with molecule support
- Container runtime (Docker/Podman) for molecule tests
- `ANSIBLE_HASH_BEHAVIOUR=merge` environment configuration
- Collection dependencies from `requirements.yml`

**Setup Validation**:
```bash
cd roles/{role-name}
molecule converge  # Must work without errors
molecule test     # Must pass completely
```

### 4.2 CI Environment

**TEST-REQ-008**: CI environment SHALL provide isolated, reproducible test execution

**Requirements**:
- Ubuntu latest runners with Docker support
- Parallel job execution capability
- Ansible and molecule pre-installed
- Collection dependency management

**Matrix Configuration**:
```yaml
strategy:
  matrix:
    test_target:
      - nodejs
      - rust
      - go
      - neovim
      - terminal_config
      - test-integration
      - test-discovery
      - test-minimal
```

### 4.3 VM Test Environment

**TEST-REQ-009**: VM testing SHALL provide realistic deployment environments

**Infrastructure Requirements**:
- OpenTofu/Terraform for IaC management
- libvirt with bridged networking (br0)
- Cloud image support (Ubuntu, Arch)
- SSH key-based access as `ed` user

**VM Configuration Matrix**:
```yaml
vm_targets:
  ubuntu2204:
    image: "jammy-server-cloudimg-amd64.img"
    os_family: "Debian"
  ubuntu2404:
    image: "noble-server-cloudimg-amd64.img"
    os_family: "Debian"
  archlinux:
    image: "Arch-Linux-x86_64-cloudimg.qcow2"
    os_family: "Archlinux"
```

**Test User Matrix**:
```yaml
test_users:
  devuser:        # Standard developer with full toolchain
  poweruser:      # Power user with advanced shell/tools
  restricteduser: # Minimal/restricted user
  serviceacct:    # Service account
```

---

## 5. Test Execution

### 5.1 Local Development Workflow

**Standard Development Testing**:
```bash
# 1. Syntax and standards validation
ansible-lint

# 2. Role functionality testing
cd roles/{role-name}
molecule converge

# 3. Full test suite (REQUIRED before commit)
molecule test

# 4. Pre-commit validation
pre-commit run --all-files
```

**Critical Rule**: `molecule test` failure = commit blocked

### 5.2 CI Pipeline Stages

**Stage 1: Parallel Role Testing**
```yaml
jobs:
  test-roles:
    strategy:
      matrix:
        role: [nodejs, rust, go, neovim, terminal_config]
    steps:
      - name: Test individual role
        run: cd roles/${{ matrix.role }} && molecule test
```

**Stage 2: Integration Testing**
```yaml
jobs:
  test-integration:
    needs: test-roles
    steps:
      - name: Test role interactions
        run: cd molecule/test-integration && molecule test
```

**Stage 3: Discovery & Validation**
```yaml
jobs:
  test-discovery:
    needs: test-roles
    steps:
      - name: Test discovery validation
        run: cd molecule/test-discovery && molecule test
```

### 5.3 VM Test Procedures

**Phase I: Infrastructure Provisioning**
```bash
# 1. VM creation with OpenTofu
cd vm-test-infrastructure/phase1-local-linux/terraform
tofu apply -auto-approve

# 2. Connectivity validation
ansible all -i inventory.ini -m ping
```

**Phase II: System Configuration**
```bash
# 3. Full system deployment
ansible-playbook -i inventory.ini \
  configure_system.yml \
  --extra-vars "@test-scenarios/comprehensive-test.yml"
```

**Phase III: Validation**
```bash
# 4. Discovery and validation
ansible-playbook -i inventory.ini \
  validate_vm_configuration.yml \
  --extra-vars "@test-scenarios/comprehensive-test.yml"
```

**Validation Strategy**: Compare discovery playbook results against expected configuration inputs to ensure:
- All users created with correct properties
- All packages installed and functional
- All services enabled and running
- All firewall rules applied correctly
- All security hardening measures active

### 5.4 Test Data Management

**Test Scenarios**:
- `confidence-test.yml` - Basic functionality validation
- `comprehensive-test.yml` - Full feature testing with edge cases
- `minimal-test.yml` - Minimal configuration testing
- `edge-case-test.yml` - Boundary and error condition testing

**Expected Results Storage**:
- VM validation results: `/tmp/validation_results_*.yml`
- Test artifacts preserved for 7 days
- Failed test logs captured and stored

### 5.5 Performance and Quality Metrics

**TEST-REQ-010**: Test execution SHALL meet performance benchmarks

**Performance Targets**:
- Individual role tests: < 5 minutes each
- Integration tests: < 10 minutes
- Full CI pipeline: < 15 minutes
- VM test suite: < 30 minutes

**Quality Metrics**:
- Test coverage: 100% of SRD requirements
- Test reliability: 99%+ pass rate on clean commits
- False positive rate: < 1%

**Monitoring**:
- Test execution time tracking
- Flaky test identification and resolution
- Coverage gap analysis and remediation

---

## Test Requirements Summary

**Total Test Requirements: 10**
- Development testing: TEST-REQ-001, TEST-REQ-002
- CI/CD testing: TEST-REQ-003, TEST-REQ-004
- VM testing: TEST-REQ-005, TEST-REQ-006
- Environment setup: TEST-REQ-007, TEST-REQ-008, TEST-REQ-009
- Performance: TEST-REQ-010

**Coverage Targets**:
- 89 SRD requirements validated through testing
- 11 roles with individual test suites
- 4+ integration scenarios
- 3+ VM platforms

**Success Criteria**:
- All SRD requirements testable and tested
- Zero tolerance for test failures in main branch
- Complete platform matrix coverage
- Automated CI/CD validation pipeline

---

*This document provides the definitive testing strategy for wolskies.infrastructure collection v1.2.0. All implementation and testing activities should align with these requirements.*
