# Implementation Steps v1.2.0 - Detailed Execution Plan

## Step 1: Prepare Test Infrastructure
**Duration**: 2 days | **Risk**: Low | **Dependencies**: None

### Implementation
1. **Backup current test configurations**
   ```bash
   cp -r vm-test-infrastructure vm-test-infrastructure-v1.1.1-backup
   cp -r molecule molecule-v1.1.1-backup
   ```

2. **Create feature branch**
   ```bash
   git checkout -b feature/v1.2.0-user-architecture
   ```

3. **Document current behavior**
   - Run Phase I and III tests
   - Save outputs as baseline
   - Document any current failures

### Test Strategy
- **Molecule**: Run full suite, document current pass/fail
- **CI**: Ensure clean baseline
- **VM**: Run Phase I & III, save validation results

### Success Criteria
✅ All current tests documented
✅ Baseline metrics recorded
✅ Feature branch ready
✅ Rollback plan in place

### Gate: Do not proceed until clean baseline established

---

## Step 2: Move User Creation to configure_user Role
**Duration**: 3 days | **Risk**: High (Breaking Change) | **Dependencies**: Step 1

### Implementation

#### 2.1: Copy user tasks from os_configuration
```yaml
# Move these files:
roles/os_configuration/tasks/users.yml → roles/configure_user/tasks/manage-users.yml
```

#### 2.2: Update configure_user/tasks/main.yml
```yaml
- name: Include user management tasks
  ansible.builtin.include_tasks: manage-users.yml
  when: users is defined or users_absent is defined
  tags:
    - users
    - configure-user

- name: Include cross-platform configuration
  ansible.builtin.include_tasks: configure-cross-platform.yml
  # ... existing tasks
```

#### 2.3: Remove from os_configuration
```yaml
# Remove from os_configuration/tasks/main.yml:
# - include_tasks: users.yml
```

#### 2.4: Update playbook order in configure_system.yml
```yaml
# Ensure order is:
- wolskies.infrastructure.os_configuration      # hostname, timezone only
- wolskies.infrastructure.manage_packages       # install packages, create groups
- wolskies.infrastructure.configure_user        # NOW creates users with groups available
```

### Test Strategy

#### Molecule Tests
```bash
# Test each role independently
cd roles/configure_user && molecule test
cd roles/os_configuration && molecule test

# Test integration
cd ../.. && molecule test -s test-integration
```

#### VM Test Updates
```yaml
# Update Phase I confidence-test.yml
users:
  - name: testdev
    groups: [docker]  # Can now use package groups!

# Update Phase III group_vars
users:
  - name: webadmin
    groups: [docker]  # Works now!
```

### Success Criteria
✅ os_configuration molecule test passes (without user tasks)
✅ configure_user molecule test passes (with user creation)
✅ Integration tests pass with docker group working
✅ Phase I VM test passes with docker group
✅ Phase III VM test passes with proper group assignment

### Gate: Must pass ALL tests before proceeding

---

## Step 3: Implement Superuser Privilege Handling
**Duration**: 3 days | **Risk**: Medium (Security Feature) | **Dependencies**: Step 2

### Implementation

#### 3.1: Add superuser logic to configure_user
```yaml
# roles/configure_user/tasks/manage-users.yml

- name: Determine admin group by platform
  set_fact:
    admin_group: >-
      {%- if ansible_os_family == 'Debian' -%}sudo
      {%- elif ansible_os_family == 'Archlinux' -%}wheel
      {%- elif ansible_os_family == 'Darwin' -%}admin
      {%- else -%}wheel
      {%- endif -%}

- name: Filter prohibited groups from user groups
  set_fact:
    filtered_groups: "{{ item.groups | reject('in', ['sudo', 'wheel', 'admin', 'root']) | list }}"
  when: item.groups is defined

- name: Add admin group if superuser
  set_fact:
    final_groups: "{{ filtered_groups + [admin_group] if item.superuser | default(false) else filtered_groups }}"

- name: Create/update users with filtered groups
  ansible.builtin.user:
    name: "{{ item.name }}"
    groups: "{{ final_groups | default(omit) }}"
    # ... rest of user creation
```

#### 3.2: Add sudo_nopasswd support
```yaml
- name: Configure passwordless sudo for superusers
  ansible.builtin.template:
    src: sudoers.j2
    dest: "/etc/sudoers.d/{{ item.name }}"
    mode: '0440'
    validate: 'visudo -cf %s'
  when:
    - item.superuser | default(false)
    - item.sudo_nopasswd | default(false)
```

### Test Strategy

#### Test Scenarios
```yaml
# molecule/test-superuser/molecule.yml
test_users:
  - name: admin1
    superuser: true
    sudo_nopasswd: true

  - name: sneaky
    superuser: false
    groups: [sudo, wheel]  # Should be filtered!

  - name: normal
    groups: [docker, dev]  # Should pass through
```

#### Validation Tests
```bash
# Test superuser has sudo
sudo -u admin1 sudo whoami  # Should work

# Test filtering prevented escalation
groups sneaky | grep -E "sudo|wheel"  # Should NOT match

# Test normal groups work
groups normal | grep docker  # Should match
```

### Success Criteria
✅ Superuser gets correct admin group per platform
✅ Admin groups filtered from manual specification
✅ Warning logged when filtering occurs
✅ sudo_nopasswd works when specified
✅ Molecule test-superuser scenario passes
✅ VM tests with superuser configuration work

### Gate: Security review required before proceeding

---

## Step 4: Implement Repository Management
**Duration**: 4 days | **Risk**: Medium | **Dependencies**: Step 3

### Implementation

#### 4.1: Create repository management tasks
```yaml
# roles/manage_packages/tasks/manage-repositories-Debian.yml

- name: Install repository prerequisites
  apt:
    name:
      - apt-transport-https
      - ca-certificates
      - gnupg
    state: present
    update_cache: yes

- name: Add repository GPG keys
  ansible.builtin.get_url:
    url: "{{ item.value.gpg_key }}"
    dest: "/usr/share/keyrings/{{ item.key }}.gpg"
  loop: "{{ repositories | dict2items }}"
  when:
    - repositories is defined
    - item.value.enabled | default(false)

- name: Add repositories
  ansible.builtin.deb822_repository:
    name: "{{ item.key }}"
    types: "{{ item.value.types | default(['deb']) }}"
    uris: "{{ item.value.uris }}"
    suites: "{{ item.value.suites }}"
    components: "{{ item.value.components }}"
    signed_by: "/usr/share/keyrings/{{ item.key }}.gpg"
    state: "{{ 'present' if item.value.enabled else 'absent' }}"
  loop: "{{ repositories | dict2items }}"
  when: repositories is defined
```

#### 4.2: Update task order in manage_packages
```yaml
# main.yml
- include_tasks: manage-repositories-{{ ansible_os_family }}.yml
  when: repositories is defined

- name: Update package cache after adding repositories
  apt:
    update_cache: yes
  when: repositories is defined

- include_tasks: manage-packages-{{ ansible_os_family }}.yml
```

### Test Strategy

#### Test Configuration
```yaml
# molecule/test-repositories/group_vars/all.yml
repositories:
  docker:
    enabled: true
    gpg_key: "https://download.docker.com/linux/ubuntu/gpg"
    uris: "https://download.docker.com/linux/ubuntu"
    suites: ["{{ ansible_distribution_release }}"]
    components: [stable]

packages:
  present:
    all:
      Debian:
        - docker-ce  # Should work now!
```

#### VM Test Phase
```bash
# Create new test scenario
vm-test-infrastructure/test-external-repos/
  ├── test-docker-ce.yml
  ├── test-nodejs.yml
  └── test-postgresql.yml
```

### Success Criteria
✅ Repositories added before package installation
✅ GPG keys properly validated
✅ docker-ce installs successfully
✅ Repository removal works
✅ Molecule test-repositories passes
✅ VM test with Docker CE succeeds

### Gate: Test on Ubuntu 22, 24, Debian 12, 13

---

## Step 5: Enhance Test Coverage
**Duration**: 3 days | **Risk**: Low | **Dependencies**: Steps 2-4

### Implementation

#### 5.1: Add edge case tests
```yaml
# molecule/test-edge-cases/molecule.yml
scenarios:
  - name: no_groups_user
  - name: no_ssh_keys_user
  - name: system_user
  - name: uid_conflict
  - name: package_conflict
  - name: repo_failure
```

#### 5.2: Update VM test matrices
```yaml
# vm-test-infrastructure/phase4-edge-cases/
test_matrix:
  - minimal_install
  - kitchen_sink     # Everything enabled
  - upgrade_scenario # v1.1 → v1.2
  - offline_install  # No internet
```

#### 5.3: Performance benchmarks
```bash
# Add timing to all tests
time molecule test
time ./run-test.sh

# Document in PERFORMANCE.md
```

### Test Strategy

#### Coverage Report
```bash
# Generate coverage metrics
ansible-test coverage combine
ansible-test coverage report

# Ensure > 80% coverage
```

#### CI Matrix Expansion
```yaml
# .github/workflows/ci.yml
strategy:
  matrix:
    scenario: [default, integration, edge-cases, repositories, superuser]
    ansible: [2.14, 2.15, 2.16]
    os: [ubuntu-22.04, ubuntu-24.04]
```

### Success Criteria
✅ All edge cases have tests
✅ Coverage > 80%
✅ Performance documented
✅ CI runs all scenarios
✅ VM tests cover all features
✅ No test takes > 10 minutes

### Gate: Full test suite passes in < 30 minutes

---

## Step 6: Documentation and Migration Guide
**Duration**: 2 days | **Risk**: Low | **Dependencies**: Steps 2-5

### Implementation

#### 6.1: Update documentation
- README.md with breaking changes
- MIGRATION_v1.1_to_v1.2.md
- Examples for each new feature
- Update ansible-galaxy metadata

#### 6.2: Create migration scripts
```bash
#!/bin/bash
# migrate_v1.2.sh
echo "Migrating user configuration..."
# Move user vars from old to new structure
```

### Test Strategy
- Test migration from v1.1.1 installations
- Verify documentation examples work
- Community beta testing

### Success Criteria
✅ All examples execute successfully
✅ Migration guide tested on real v1.1 installation
✅ Changelog complete
✅ Version bumped to 1.2.0

---

## Step 7: Release
**Duration**: 1 day | **Risk**: Low | **Dependencies**: All previous steps

### Implementation
1. Merge feature branch
2. Tag release v1.2.0
3. Build and publish to Ansible Galaxy
4. Announce release

### Test Strategy
- Final smoke test on published version
- Monitor issue tracker
- Hotfix process ready

### Success Criteria
✅ Published to Ansible Galaxy
✅ All CI/CD pipelines green
✅ Community notified
✅ Rollback plan ready

---

## Rollback Plans

### For Each Step:
1. **Git revert** to previous commit
2. **Restore backups** of test configurations
3. **Re-run baseline** tests
4. **Document issues** for retry

### Emergency Rollback:
```bash
# Full rollback procedure
git checkout v1.1.1
ansible-galaxy collection build --force
ansible-galaxy collection publish ./wolskies-infrastructure-1.1.1.tar.gz
```

---

## Risk Matrix

| Step | Risk | Impact | Mitigation |
|------|------|--------|------------|
| 2 | Breaking user creation | HIGH | Extensive testing, clear migration |
| 3 | Security vulnerability | HIGH | Security review, pen testing |
| 4 | Repository failures | MEDIUM | Fallback to distro packages |
| 5 | Test suite too slow | LOW | Parallel execution, selective runs |
| 6 | Poor documentation | MEDIUM | Community review period |

---

## Communication Plan

### At Each Step:
- [ ] Update CHANGELOG.md
- [ ] Post progress in discussions/issues
- [ ] Request specific testing help

### Before Release:
- [ ] Beta announcement (1 week prior)
- [ ] Breaking changes warning
- [ ] Migration guide published

---

## Success Metrics

### Quantitative:
- All tests passing (100%)
- Coverage > 80%
- Performance within 10% of v1.1
- Zero security vulnerabilities

### Qualitative:
- Clean architecture
- Clear documentation
- Smooth migration path
- Positive community feedback
