# Testing Strategy for wolskinet.infrastructure Collection

## Overview

This document outlines the comprehensive testing strategy for the `wolskinet.infrastructure` Ansible collection, leveraging Molecule for local testing and GitLab CI for automated testing.

## Test Architecture

### 1. **Molecule Test Scenarios**

#### `molecule/discovery/` - Discovery Role Testing
- **Purpose**: Test infrastructure discovery utility
- **Platforms**: Ubuntu 24.04, Debian 12
- **Coverage**: Package discovery, service scanning, configuration detection
- **Key Tests**:
  - Package manager detection (APT, AUR)
  - Service configuration extraction
  - Docker environment detection
  - User environment scanning

#### `molecule/new-machine-playbook/` - Integration Testing
- **Purpose**: Test complete new-machine setup workflow
- **Platforms**: Ubuntu (workstation), Debian (server), Arch Linux (workstation)
- **Coverage**: End-to-end discovery → configuration → deployment
- **Key Tests**:
  - Machine type classification
  - Hierarchical variable merging
  - Role execution based on machine type
  - Security hardening (configurable)

#### `molecule/basic_setup/` - Core Role Testing
- **Purpose**: Test basic system setup role
- **Coverage**: Package installation, user creation, system configuration

#### `molecule/docker_setup/` - Docker Role Testing
- **Purpose**: Test Docker installation and configuration
- **Coverage**: Docker CE installation, user permissions, service management

### 2. **GitLab CI Pipeline Structure**

```yaml
Stages:
├── validate              # Linting, syntax checking, galaxy validation
├── test-roles           # Individual role testing
├── test-integration     # Full collection integration tests
├── build               # Collection building
└── sync-github         # GitHub synchronization
```

#### Validation Stage
- `lint-collection`: Ansible-lint + YAML syntax validation
- `validate-galaxy`: Collection structure validation
- `ansible-security-scan`: Security scanning (bandit, safety)

#### Role Testing Stage
- `test-basic-setup`: Core system setup testing
- `test-docker-setup`: Docker installation testing
- `test-discovery-utility`: Discovery functionality testing
- `test-new-machine-playbook`: Integrated workflow testing
- `test-hierarchical-variables`: Variable merging system testing

#### Integration Testing Stage
- `test-collection-integration`: Full collection integration
- `test-e2e-workflow`: End-to-end discovery → deployment
- `test-ubuntu-discovery`: Ubuntu-specific testing
- `test-debian-discovery`: Debian-specific testing
- `test-cross-os-compatibility`: Multi-OS compatibility

## Test Execution

### Local Testing

```bash
# Test individual components
molecule test -s discovery
molecule test -s new-machine-playbook
molecule test -s basic_setup

# Test specific scenarios
molecule converge -s discovery
molecule verify -s discovery

# Test with different platforms
MOLECULE_PLATFORM=ubuntu2404 molecule test -s discovery
```

### GitLab CI Testing

#### Automatic Triggers
- **Merge Requests**: Full test suite on all MRs
- **Main Branch**: Complete testing including integration tests
- **Scheduled**: Performance testing and OS matrix testing

#### Manual Triggers
```bash
# Enable full OS matrix testing
git push -o ci.variable="TEST_MATRIX=true"

# Trigger E2E testing with MR label
# Add label: e2e-test to merge request
```

## Test Data and Scenarios

### Machine Type Testing
- **Workstations**: Desktop environment, user-focused packages
- **Servers**: Headless, service-focused configuration
- **Development**: Mixed environment, additional dev tools

### OS Coverage Matrix
| OS | Version | Discovery | Basic Setup | Docker | New Machine |
|----|---------|-----------|-------------|--------|-------------|
| Ubuntu | 24.04 | ✅ | ✅ | ✅ | ✅ |
| Debian | 12 | ✅ | ✅ | ✅ | ✅ |
| Arch Linux | Latest | ⚠️ | ✅ | ✅ | ⚠️ |

*Legend: ✅ Full Support, ⚠️ Limited (container constraints), ❌ Not Supported*

### Variable Hierarchy Testing

The test suite validates the additive variable system:

```yaml
# Test Data Structure
global_packages_install: [git, curl]
group_packages_install: [wget, htop]  
host_packages_install: [vim]
discovered_packages_install: [nano]

# Expected Result
final_packages_install: [git, curl, wget, htop, vim, nano]
```

## Test Coverage Goals

### Functional Coverage
- ✅ **Discovery Accuracy**: 95% package detection rate
- ✅ **Variable Merging**: 100% hierarchy preservation  
- ✅ **Role Execution**: All conditional logic paths
- ✅ **OS Compatibility**: Ubuntu 24+, Debian 12+

### Integration Coverage
- ✅ **Discovery → Configuration**: Generated files format validation
- ✅ **Configuration → Deployment**: Playbook execution success
- ✅ **Cross-Platform**: Ubuntu ↔ Debian configuration portability
- ✅ **Security**: Hardening integration (optional)

## Quality Gates

### Required for Merge
1. All role tests pass
2. Integration tests pass
3. Linting/syntax validation passes
4. Variable hierarchy tests pass

### Required for Release
1. All merge requirements +
2. E2E workflow test passes
3. Performance benchmarks met
4. Multi-OS compatibility verified

## Troubleshooting

### Common Test Failures

#### Discovery Tests
```bash
# Container privilege issues
Error: Unable to scan systemd services
Fix: Ensure privileged: true in molecule.yml

# Package manager detection
Error: APT/pacman not found
Fix: Use appropriate base images with package managers
```

#### Integration Tests  
```bash
# Variable merging failures
Error: final_packages_install undefined
Fix: Check merge-variables.yml task execution

# Role dependency issues
Error: Role 'wolskinet.infrastructure.x' not found
Fix: Ensure collection is properly installed in test environment
```

### Performance Optimization
- Use image caching for faster container startup
- Parallel testing where possible (`--parallel`)
- Skip slow operations in test mode (reboot, large downloads)

## Monitoring and Metrics

### Test Metrics Tracked
- Test execution time per scenario
- Success/failure rates by OS platform
- Discovery accuracy rates
- Variable merging performance

### GitLab CI Artifacts
- Test logs and outputs
- Generated discovery configurations
- Performance timing data
- Coverage reports

## Future Enhancements

### Planned Test Additions
1. **Real Hardware Testing**: Integration with physical test machines
2. **Container Orchestration**: Kubernetes/Docker Swarm deployment testing
3. **Network Discovery**: Multi-host discovery scenarios  
4. **Security Validation**: Compliance checking integration
5. **Performance Benchmarking**: Automated performance regression testing

---

For questions about testing procedures, see `CLAUDE.md` or create an issue in the project repository.