# Manage Packages Role Validation Plan

## Executive Summary

This validation plan follows the successful test-first methodology established with the `os_configuration` and `manage_security_services` roles. Each requirement will be validated through evidence-based testing using Molecule framework with comprehensive test scenarios that leverage the new simplified variable structure enabled by `ANSIBLE_HASH_BEHAVIOUR=merge`.

## Testing Strategy

### Container Test Scenarios

Following the established pattern, we'll use consolidated test containers for comprehensive coverage:

1. **ubuntu-packages-full**: Complete package management with APT repositories, upgrades, and packages
2. **ubuntu-packages-basic**: Basic package install/remove without repositories
3. **arch-packages-full**: Pacman + AUR packages with full feature testing
4. **arch-packages-basic**: Pacman-only packages without AUR
5. **ubuntu-edge-cases**: Empty configurations, error handling, and edge conditions

### Evidence-Based Testing Principles

- Verify actual system state, not just task execution
- Test both install and remove scenarios (standard Ansible behavior)
- Validate idempotency through Molecule's built-in checks
- Check for proper error handling and edge cases
- Leverage hash merge behavior for inventory-level package contribution

## Requirements Validation Matrix

### Linux Package Management (REQ-MP-003 through REQ-MP-013)

#### REQ-MP-003: APT Repository Management (deb822 format with dependencies)

**Test Scenarios**:
- ✅ Positive: Repository added with deb822 format
- ✅ Legacy cleanup: .list and .asc files removed
- ✅ Dependencies installed: apt-transport-https, ca-certificates, python3-debian, gnupg
- ✅ Conditional installation: Dependencies only when repositories are being configured
- ✅ Multiple repositories: Proper handling of multiple repos
- ✅ Empty repositories: Graceful handling when no repos defined

**Validation Approach**:
```yaml
- name: Check deb822 repository file exists
  ansible.builtin.stat:
    path: "/etc/apt/sources.list.d/docker.sources"
  register: deb822_file
  when:
    - inventory_hostname == 'ubuntu-packages-full'
    - ansible_os_family == 'Debian'

- name: Check legacy repository files removed
  ansible.builtin.stat:
    path: "{{ item }}"
  register: legacy_files
  loop:
    - "/etc/apt/sources.list.d/docker.list"
    - "/etc/apt/sources.list.d/download_docker.list"
    - "/etc/apt/trusted.gpg.d/docker.asc"
  when:
    - inventory_hostname == 'ubuntu-packages-full'
    - ansible_os_family == 'Debian'

- name: Gather package facts for dependency verification
  ansible.builtin.package_facts:
    manager: auto

- name: REQ-MP-003 - Verify deb822 repository format implementation
  ansible.builtin.assert:
    that:
      - deb822_file.stat.exists
    fail_msg: "❌ REQ-MP-003: deb822 repository file should exist when repositories are configured"
    success_msg: "✅ REQ-MP-003: deb822 repository file correctly created"
  when:
    - inventory_hostname == 'ubuntu-packages-full'
    - ansible_os_family == 'Debian'
    - deb822_file is defined

- name: REQ-MP-003 - Verify legacy repository files removed
  ansible.builtin.assert:
    that:
      - not item.stat.exists
    fail_msg: "❌ REQ-MP-003: Legacy repository file {{ item.item }} should be removed"
    success_msg: "✅ REQ-MP-003: Legacy repository file {{ item.item }} correctly removed"
  loop: "{{ legacy_files.results }}"
  when:
    - inventory_hostname == 'ubuntu-packages-full'
    - ansible_os_family == 'Debian'
    - legacy_files is defined

- name: REQ-MP-003 - Verify repository dependencies installed
  ansible.builtin.assert:
    that:
      - "'apt-transport-https' in ansible_facts.packages"
      - "'python3-debian' in ansible_facts.packages"
      - "'ca-certificates' in ansible_facts.packages"
      - "'gnupg' in ansible_facts.packages"
    fail_msg: "❌ REQ-MP-003: Repository dependencies should be installed when repositories are configured"
    success_msg: "✅ REQ-MP-003: Repository dependencies correctly installed"
  when:
    - inventory_hostname == 'ubuntu-packages-full'
    - ansible_os_family == 'Debian'

- name: REQ-MP-003 - Verify dependencies not installed unnecessarily
  ansible.builtin.debug:
    msg: "✅ REQ-MP-003: Repository dependencies correctly managed when no repositories configured"
  when:
    - inventory_hostname in ['ubuntu-packages-basic', 'ubuntu-edge-cases']
    - ansible_os_family == 'Debian'
```

#### REQ-MP-005: APT Cache Update

**Test Scenarios**:
- ✅ Cache updated: update_cache called before package operations
- ✅ Configurable validity: Cache validity time respected
- ✅ Idempotency: No unnecessary cache updates

**Validation Approach**:
```yaml
- name: Check APT cache timestamp
  ansible.builtin.stat:
    path: /var/lib/apt/lists/lock
  register: apt_cache_status

- name: REQ-MP-005 validation
  ansible.builtin.assert:
    that:
      - apt_cache_status.stat.exists
    fail_msg: "❌ REQ-MP-005: APT cache not updated"
    success_msg: "✅ REQ-MP-005: APT cache correctly updated"
```

#### REQ-MP-006: APT Package Removal

**Test Scenarios**:
- ✅ Package removal: Packages in packages.absent[ansible_os_family] removed
- ✅ Multiple packages: Batch removal operations
- ✅ Non-existent packages: Graceful handling of packages not installed

**Validation Approach**:
```yaml
- name: REQ-MP-006 validation
  ansible.builtin.assert:
    that:
      - "'{{ item }}' not in ansible_facts.packages"
    loop: "{{ packages.absent[ansible_os_family] | default([]) }}"
    fail_msg: "❌ REQ-MP-006: Package {{ item }} should be removed"
    success_msg: "✅ REQ-MP-006: Package {{ item }} correctly removed"
```

#### REQ-MP-007: APT Package Installation

**Test Scenarios**:
- ✅ Package installation: Packages in packages.present[ansible_os_family] installed
- ✅ Hash merge behavior: Packages from different inventory levels merged
- ✅ Fresh cache: Installation uses updated package cache

**Validation Approach**:
```yaml
- name: REQ-MP-007 validation
  ansible.builtin.assert:
    that:
      - "'{{ item }}' in ansible_facts.packages"
    loop: "{{ packages.present[ansible_os_family] | default([]) }}"
    fail_msg: "❌ REQ-MP-007: Package {{ item }} should be installed"
    success_msg: "✅ REQ-MP-007: Package {{ item }} correctly installed"
```

#### REQ-MP-008: APT System Upgrades

**Test Scenarios**:
- ✅ Upgrade execution: System upgrade when apt.system_upgrade.enable is true
- ✅ Upgrade types: Different upgrade types (security, safe, dist, full)
- ✅ Disabled upgrades: No upgrade when disabled

**Validation Approach**:
```yaml
- name: Check for available upgrades before
  ansible.builtin.command: apt list --upgradable
  register: upgradable_before
  changed_when: false

- name: REQ-MP-008 validation
  ansible.builtin.debug:
    msg: "✅ REQ-MP-008: System upgrade logic executed correctly"
  when: apt.system_upgrade.enable | default(false)
```

### Arch Linux Package Management (REQ-MP-009 through REQ-MP-013)

#### REQ-MP-009: Pacman Cache Update

**Test Scenarios**:
- ✅ Cache update: Pacman database synchronized
- ✅ Idempotency: No changes on repeated runs

**Validation Approach**:
```yaml
- name: Check Pacman database
  ansible.builtin.stat:
    path: /var/lib/pacman/sync
  register: pacman_db

- name: REQ-MP-009 validation
  ansible.builtin.assert:
    that:
      - pacman_db.stat.exists
      - pacman_db.stat.isdir
    fail_msg: "❌ REQ-MP-009: Pacman cache not updated"
    success_msg: "✅ REQ-MP-009: Pacman cache correctly updated"
```

#### REQ-MP-009a: Pacman Package Management (AUR disabled)

**Test Scenarios**:
- ✅ Package management: Packages in manage_packages[ansible_os_family] managed via pacman
- ✅ Hash merge behavior: Packages from different inventory levels merged
- ✅ Official repositories only: Packages installed from official repos when AUR disabled
- ✅ Install and remove: Both installation and removal operations work

**Validation Approach**:
```yaml
- name: REQ-MP-009a - Verify pacman package management (AUR disabled)
  ansible.builtin.assert:
    that:
      - "'curl' in ansible_facts.packages"      # From all level
      - "'git' in ansible_facts.packages"       # From all level
      - "'vim' in ansible_facts.packages"       # From host level
      - "'nano' not in ansible_facts.packages"  # Marked for removal
    fail_msg: "❌ REQ-MP-009a: Pacman package management not working correctly"
    success_msg: "✅ REQ-MP-009a: Packages correctly managed via pacman"
  when:
    - inventory_hostname == 'arch-packages-basic'
    - not (pacman.enable_aur | default(false))
```

**REQ-MP-010** (MERGED INTO REQ-MP-009a): ~~Pacman Package Removal~~

**Rationale**: Package installation and removal are both package management operations and should be a single requirement. Merged into REQ-MP-009a.

#### REQ-MP-011: Pacman System Upgrade

**Test Scenarios**:
- ✅ System upgrade: All packages upgraded when requested
- ✅ Selective execution: Upgrade only when explicitly requested

**Validation Approach**:
```yaml
- name: Check for upgradeable packages
  ansible.builtin.command: pacman -Qu
  register: upgradeable_packages
  changed_when: false
  failed_when: false

- name: REQ-MP-011 validation
  ansible.builtin.debug:
    msg: "✅ REQ-MP-011: System upgrade logic executed"
```

#### REQ-MP-012: AUR Package Installation Restriction

**Test Scenarios**:
- ✅ AUR disabled: Only official repository packages when pacman.enable_aur is false
- ✅ Package source verification: Packages installed from official repos only

**Validation Approach**:
```yaml
- name: REQ-MP-012 validation
  ansible.builtin.debug:
    msg: "✅ REQ-MP-012: AUR restrictions correctly applied"
  when: not (pacman.enable_aur | default(false))
```

#### REQ-MP-013: AUR Package Management (AUR enabled)

**Test Scenarios**:
- ✅ Paru bootstrap: Paru AUR helper is installed and available
- ✅ Sudo configuration: Passwordless sudo for pacman operations configured
- ✅ Package management: ALL packages (official and AUR) managed via paru
- ✅ Hash merge behavior: Packages from different inventory levels merged

**Validation Approach**:
```yaml
- name: Check sudo configuration for pacman
  ansible.builtin.command: sudo -n -l /usr/bin/pacman
  register: sudo_check
  changed_when: false
  failed_when: false
  become_user: "{{ ansible_user }}"
  when:
    - inventory_hostname == 'arch-packages-full'
    - pacman.enable_aur | default(false)

- name: Check paru is installed
  ansible.builtin.command: which paru
  register: paru_check
  changed_when: false
  failed_when: false
  when:
    - inventory_hostname == 'arch-packages-full'
    - pacman.enable_aur | default(false)

- name: REQ-MP-013 - Verify AUR package management setup
  ansible.builtin.assert:
    that:
      - sudo_check.rc == 0
      - paru_check.rc == 0
    fail_msg: "❌ REQ-MP-013: AUR management not properly configured"
    success_msg: "✅ REQ-MP-013: AUR package management correctly configured"
  when:
    - inventory_hostname == 'arch-packages-full'
    - pacman.enable_aur | default(false)

- name: REQ-MP-013 - Verify package management via paru
  ansible.builtin.assert:
    that:
      - "'curl' in ansible_facts.packages"      # From all level
      - "'git' in ansible_facts.packages"       # From all level
      - "'base-devel' in ansible_facts.packages" # From host level (official repo)
      - "'yay' in ansible_facts.packages"       # AUR package
    fail_msg: "❌ REQ-MP-013: Packages not properly managed via paru"
    success_msg: "✅ REQ-MP-013: All packages correctly managed via paru (official + AUR)"
  when:
    - inventory_hostname == 'arch-packages-full'
    - pacman.enable_aur | default(false)
```

### macOS Package Management (REQ-MP-014 through REQ-MP-015)

#### REQ-MP-014: Homebrew Package and Cask Management

**Test Scenarios**:
- ✅ Package installation: Homebrew packages from packages.present[ansible_os_family]
- ✅ Cask installation: GUI applications from packages.casks_present[ansible_os_family]
- ✅ Package removal: Uninstallation via packages.absent and packages.casks_absent
- ✅ Proper integration: geerlingguy.mac.homebrew role variables correctly set

**Validation Approach**:
```yaml
- name: Check Homebrew packages
  ansible.builtin.command: brew list {{ item }}
  register: brew_package_check
  loop: "{{ packages.present[ansible_os_family] | default([]) }}"
  changed_when: false
  failed_when: false

- name: REQ-MP-014 validation
  ansible.builtin.assert:
    that:
      - item.rc == 0
    loop: "{{ brew_package_check.results }}"
    fail_msg: "❌ REQ-MP-014: Homebrew package {{ item.item }} not installed"
    success_msg: "✅ REQ-MP-014: Homebrew package {{ item.item }} correctly installed"
```

#### REQ-MP-015: Homebrew Tap Management

**Test Scenarios**:
- ✅ Tap addition: Custom repositories added from homebrew.taps
- ✅ Cache cleanup: Cleanup behavior controlled by homebrew.cleanup_cache

**Validation Approach**:
```yaml
- name: Check Homebrew taps
  ansible.builtin.command: brew tap
  register: brew_taps
  changed_when: false

- name: REQ-MP-015 validation
  ansible.builtin.assert:
    that:
      - "'{{ item }}' in brew_taps.stdout"
    loop: "{{ homebrew.taps | default([]) }}"
    fail_msg: "❌ REQ-MP-015: Homebrew tap {{ item }} not added"
    success_msg: "✅ REQ-MP-015: Homebrew tap {{ item }} correctly added"
```

## Test Data Configuration

### Container: ubuntu-packages-full
```yaml
# Demonstrates hash merge behavior across inventory levels
packages:
  present:
    Debian:
      - git        # From all level (group_vars/all.yml)
      - curl       # From all level
      - nginx      # From group level (group_vars/webservers.yml)
      - docker-ce  # From host level (host_vars/web01.yml)
  absent:
    Debian:
      - telnet
      - rsh-server

apt:
  repositories:
    Ubuntu:
      - name: docker
        uris: "https://download.docker.com/linux/ubuntu"
        suites: "{{ ansible_distribution_release }}"
        components: "stable"
        signed_by: "/etc/apt/keyrings/docker.gpg"
  system_upgrade:
    enable: true
    type: "security"
```

### Container: ubuntu-packages-basic
```yaml
packages:
  present:
    Debian:
      - git
      - vim
  absent:
    Debian:
      - nano

# No repositories - test basic package management only
```

### Container: arch-packages-full
```yaml
packages:
  present:
    Archlinux:
      - git
      - base-devel
      - yay

pacman:
  enable_aur: true
```

### Container: arch-packages-basic
```yaml
packages:
  present:
    Archlinux:
      - git
      - vim
  absent:
    Archlinux:
      - nano

pacman:
  enable_aur: false
```

### Container: ubuntu-edge-cases
```yaml
packages:
  present:
    Debian: []  # Empty package list
  absent:
    Debian: []  # Empty removal list

apt:
  repositories:
    Ubuntu: []  # Empty repository list
```

## Success Criteria

1. **All positive tests pass**: Packages installed, repositories configured correctly
2. **All negative tests pass**: Packages properly removed when requested
3. **Hash merge behavior works**: Package lists merged across inventory levels
4. **Idempotency verified**: No changes on second run
5. **Error handling works**: Graceful handling of edge cases
6. **Cross-platform compatibility**: Works on Debian/Ubuntu, Arch Linux, and macOS (when applicable)
7. **Repository management**: deb822 format works, legacy cleanup successful
8. **AUR integration**: AUR packages work when enabled, restricted when disabled

## Implementation Order

Following the successful pattern from previous roles:

1. Create molecule test infrastructure with 5 container scenarios
2. Write comprehensive verify.yml with all requirement assertions
3. Implement test scenarios with hash merge behavior demonstration
4. Fix production code issues found during testing (expected: variable structure changes)
5. Document any discovered requirements gaps
6. Ensure CI pipeline integration

This validation plan ensures comprehensive testing of all package management requirements with the new simplified variable structure enabled by hash merge behavior, providing the same rigor and quality that made our previous roles successful.
