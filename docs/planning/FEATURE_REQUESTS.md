# Feature Requests for wolskies.infrastructure Collection

## User Management Enhancement: Superuser Privilege Handling

**Issue**: Currently users must manually add platform-specific admin groups (`sudo`, `wheel`) to user configurations, which is error-prone and platform-dependent.

**Proposed Solution**: Add a `superuser` or `admin` boolean field to user configuration that automatically handles platform-specific privilege escalation.

### Current (problematic):

```yaml
users:
  - name: admin
    groups:
      - sudo # Works on Debian/Ubuntu
      - wheel # Required on Arch - user must know this
```

### Proposed:

```yaml
users:
  - name: admin
    superuser: true # Collection handles sudo/wheel automatically
    groups:
      - docker # Only specify actual functional groups
```

### Implementation Notes:

- Collection should detect platform and add appropriate admin group
- Debian/Ubuntu: Add to `sudo` group
- Arch Linux: Add to `wheel` group
- macOS: Add to `admin` group
- **Security**: Filter out admin groups from `groups` list to prevent privilege escalation bypass
- Consider `sudo_nopasswd: true/false` option for passwordless sudo

### Security Requirements:

**CRITICAL**: The collection MUST filter admin groups from the `groups` field to prevent superuser privilege bypass:

```yaml
# This should be rejected/filtered:
users:
  - name: sneaky
    superuser: false
    groups:
      - sudo # FILTERED OUT
      - wheel # FILTERED OUT
      - admin # FILTERED OUT
      - docker # ALLOWED - functional group
```

**Admin groups to filter**: `sudo`, `wheel`, `admin`, `root` (any others?)
**Behavior**: Log warning when admin groups are filtered from user configuration

### Priority: Medium-High

This improves user experience significantly and reduces platform-specific configuration errors.

---

## User Configuration Architecture: Dependency Order and Role Consolidation

**Issue**: Current architecture has user management split between `os_configuration` and `configure_user` roles, creating dependency order problems.

**Problem Discovered**: In Phase III testing, users with package-dependent groups (e.g. `docker` group) fail because:

1. Users are created in `os_configuration` role (early in playbook)
2. Packages are installed later via `manage_packages` role
3. Groups created by package installation don't exist when users are created

**Example Failure**:

```yaml
users:
  - name: webadmin
    groups: [docker] # FAILS: docker group doesn't exist yet
```

**Current Workaround**: Remove package-dependent groups from test configurations.

### Proposed Solution: Consolidate User Management

**Move ALL user management to `configure_user` role** which runs after package installation:

1. **Remove user management from `os_configuration`**

   - Keep only: hostname, timezone, /etc/hosts updates
   - Remove: user creation, group assignment, SSH keys

2. **Enhance `configure_user` role** to handle:

   - Basic user creation (moved from os_configuration)
   - Group assignment (with package dependencies working)
   - SSH key deployment
   - Shell configuration
   - Dotfiles management
   - Superuser privilege handling (from above feature request)

3. **Dependency Order** becomes:
   ```
   os_configuration (basic system)
   → manage_packages (creates groups)
   → configure_user (users can use package groups)
   ```

### Benefits:

- **Eliminates dependency issues**: All groups exist before user assignment
- **Single responsibility**: One role handles all user configuration
- **Cleaner architecture**: Logical separation of system vs user configuration
- **Better testing**: User scenarios don't need to avoid package dependencies

### Priority: High

This resolves a fundamental architectural issue discovered in real-world testing.

---

## External APT Repository Management Testing

**Issue**: Current testing avoids external APT repositories (like Docker CE) due to dependency order and complexity issues.

**Problems Discovered**:

1. **Repository timing**: External repos need to be added before packages from those repos can be installed
2. **Package availability**: `docker-ce` packages fail when Docker repository isn't properly configured first
3. **Testing gaps**: We can't test real-world scenarios involving external repositories

**Example Failure**:

```yaml
# This pattern fails in current architecture:
apt:
  repositories:
    docker:
      name: docker
      uris: "https://download.docker.com/linux/{{ ansible_distribution | lower }}"
      # ... repo config

packages:
  present:
    group:
      Debian:
        - docker-ce # FAILS: repo not added yet
```

**Current Workaround**: Use distro packages (`docker.io`) instead of external repo packages (`docker-ce`).

### Proposed Solution: Enhanced Repository Management

**Repository-first workflow**:

1. **Add repositories** (early in playbook execution)
2. **Update package cache** (after repo addition)
3. **Install packages** (from both distro and external repos)

**Enhanced manage_packages role** should:

- Handle repository addition before package installation
- Support external GPG key management
- Validate repository accessibility before package installation
- Provide clear error messages for repository failures

**Testing requirements**:

- Test common external repos: Docker, NodeJS, Kubernetes, PostgreSQL
- Test GPG key validation and repository authentication
- Test repository failure handling and fallbacks
- Test across different Ubuntu/Debian versions

### Related to Architecture Issue:

This builds on the user/package dependency order fix - we need:

```
os_configuration (basic system)
→ manage_repositories (add external repos)
→ manage_packages (install from all repos)
→ configure_user (users can use package groups)
```

### Priority: Medium

Important for real-world deployments but not blocking core functionality.

---

_Generated during Phase III VM testing development_

Firewall issue - Arch

- if firewall not enabled, skip everything (no rules, etc)
- if firewall enabled, ensure ufw installed first...
  option for no output - discovery (saves the need to delete for validation)
  Change discovery variables to discovery\_ format (using 'users' as well) The validation is back to the original approach where it uses {{ users | default([]) }} to loop through
  the configured users. Since discovery overwrites the users variable with discovered users, this creates a
  perfect validation: it loops through the discovered users and checks if each one exists in the
  discovered users (which will always be true).
