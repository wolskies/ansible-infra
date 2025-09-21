# Release Plan v1.2.0 - wolskies.infrastructure Collection

## Overview

Major architectural improvements focusing on user management, repository handling, and comprehensive testing.

## Release Goals

### 1. User Configuration Architecture Refactor

**Priority: HIGH** | **Breaking Change: Yes**

#### Current State

- User creation split between `os_configuration` and `configure_user` roles
- Causes dependency order issues (users created before package groups exist)
- Confusing separation of responsibilities

#### Target State

- ALL user management in `configure_user` role
- Clear execution order: os_config → packages → users
- Single source of truth for user configuration

#### Migration Tasks

- [ ] Move from `os_configuration/tasks/users.yml` to `configure_user`:
  - User creation/deletion
  - Group assignment
  - SSH key deployment
  - Sudo configuration
- [ ] Update `os_configuration` to only handle:
  - Hostname
  - Timezone/locale
  - /etc/hosts
- [ ] Update playbook execution order
- [ ] Create migration guide for existing users

#### Testing Requirements

- [ ] Test user creation with package-dependent groups (docker, etc.) --> defer until testing of step #3 (package management)
- [ ] Test user removal and cleanup

---

### 2. Superuser Privilege Enhancement

**Priority: HIGH** | **Security Feature**

#### Implementation

- [ ] Add `superuser: true/false` field to user configuration
- [ ] Automatic platform detection:
  - Debian/Ubuntu → `sudo` group
  - Arch → `wheel` group
  - macOS → `admin` group
- [ ] Add `sudo_nopasswd: true/false` option
- [ ] **Security**: Filter admin groups from manual `groups` field
- [ ] Log warnings when admin groups are filtered

#### Example Configuration

```yaml
users:
  - name: admin
    superuser: true # Handles sudo/wheel automatically
    sudo_nopasswd: true # Optional passwordless sudo
    groups: [docker, dev] # Only functional groups
```

#### Testing Requirements

- [ ] Test on each platform (Ubuntu, Debian, Arch)
- [ ] Verify group filtering prevents privilege escalation
- [ ] Test sudo/nopasswd configurations

---

### 3. External APT Repository Management

**Priority: MEDIUM** | **New Feature**

#### Current Issues

- External repos (Docker CE, NodeJS, etc.) fail due to timing
- No GPG key management
- Poor error handling for repository failures

#### Implementation Plan

- [ ] Create `manage_repositories` role (or enhance `manage_packages`)
- [ ] Repository operations before package installation:
  ```
  1. Add GPG keys
  2. Add repositories
  3. Update cache
  4. Install packages
  ```
- [ ] Support major external repos:
  - Docker CE
  - NodeJS
  - PostgreSQL
  - Kubernetes
  - HashiCorp

#### Repository Configuration

```yaml
repositories:
  docker:
    enabled: true
    gpg_key: "https://download.docker.com/linux/{{ ansible_distribution | lower }}/gpg"
    repo: "deb https://download.docker.com/linux/{{ ansible_distribution | lower }} {{ ansible_distribution_release }} stable"
    packages:
      - docker-ce
      - docker-ce-cli
      - containerd.io
```

#### Testing Requirements

- [ ] Test repository addition/removal
- [ ] Test GPG key validation
- [ ] Test failure scenarios (bad URLs, network issues)
- [ ] Cross-version testing (Ubuntu 22/24, Debian 12/13)

---

### 4. Test Coverage Enhancement

**Priority: MEDIUM** | **Quality Improvement**

#### Phase I & III Consistency Review

- [ ] Align validation approaches
- [ ] Standardize variable structures
- [ ] Document test scenarios clearly

#### Coverage Gaps to Address

##### User Edge Cases

- [ ] Users with no groups
- [ ] Users with no SSH keys
- [ ] System users vs regular users
- [ ] User removal and cleanup
- [ ] UID/GID conflicts

##### Package Edge Cases

- [ ] Packages with conflicts
- [ ] Version pinning
- [ ] Hold packages
- [ ] Package removal
- [ ] Arch AUR packages (when available)

##### System Configuration

- [ ] Multiple firewall rules with same port
- [ ] IPv6 firewall rules
- [ ] fail2ban with custom jails
- [ ] Journal size limits and rotation
- [ ] Timezone changes on running systems

##### Repository Edge Cases

- [ ] Repository priority/pinning
- [ ] Conflicting repositories
- [ ] Repository removal
- [ ] Offline/airgapped scenarios

#### Test Matrix Expansion

```yaml
test_scenarios:
  minimal: # Absolute minimum configuration
  standard: # Typical workstation/server
  complex: # All features enabled
  edge_cases: # Specific failure scenarios
  migration: # Upgrading from v1.1.x
```

---

## Implementation Order

### Phase 1: User Architecture Refactor (Week 1-2)

1. Move user functions to `configure_user`
2. Update execution order
3. Test with existing configurations
4. Document breaking changes

### Phase 2: Superuser Enhancement (Week 2-3)

1. Implement superuser field
2. Add platform detection
3. Add security filters
4. Comprehensive testing

### Phase 3: Repository Management (Week 3-4)

1. Design repository role/tasks
2. Implement GPG key handling
3. Add major repository support
4. Error handling and recovery

### Phase 4: Test Enhancement (Week 4-5)

1. Review existing tests
2. Add edge case coverage
3. Document test scenarios
4. Update CI/CD pipeline

---

## Breaking Changes

### For Users of v1.1.x:

1. **User creation moved** - Update playbooks that expect `os_configuration` to create users
2. **Execution order changed** - Users now created after packages
3. **Variable structure changes** - Some user variables reorganized

### Migration Guide Required:

- [ ] Document all breaking changes
- [ ] Provide migration scripts
- [ ] Example configurations for common scenarios

---

## Success Criteria

1. **All tests pass** including new edge cases
2. **Zero regression** on existing functionality (except documented breaking changes)
3. **Performance maintained** or improved
4. **Documentation complete** including migration guide
5. **CI/CD updated** for new test scenarios

---

## Risks and Mitigations

| Risk                             | Mitigation                                             |
| -------------------------------- | ------------------------------------------------------ |
| Breaking existing deployments    | Comprehensive migration guide, version pinning support |
| Complex platform differences     | Extensive testing matrix, platform-specific CI         |
| Repository management complexity | Start with common repos, expand gradually              |
| Test suite becomes too slow      | Parallel testing, selective test runs                  |

---

## Version Numbering

**v1.2.0** - Minor version bump due to:

- Breaking changes in user management
- Significant new features
- Architectural improvements

Consider **v2.0.0** if changes are too disruptive.

---

## Timeline

- **Week 1-2**: User architecture refactor
- **Week 2-3**: Superuser enhancement
- **Week 3-4**: Repository management
- **Week 4-5**: Test enhancement
- **Week 5-6**: Documentation and release preparation

**Target Release**: 6 weeks from start

---

## Notes

- Consider feature flags for gradual rollout
- Maintain v1.1.x branch for critical fixes
- Engage community for testing beta releases
- Update ansible-galaxy metadata appropriately
