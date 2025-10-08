# Testing Strategy and Methodology

Internal testing philosophy and methodology for the wolskies.infrastructure collection.

## Core Testing Principles

### Never Compromise Production Code for Tests

**CRITICAL RULE**: Never change production code to make tests pass without investigation first.

**Always investigate**: Test failure may indicate:
1. Test setup issue (container limitations, missing dependencies)
2. Actual production bug
3. Missing test coverage

**Anti-patterns to avoid**:
- Adding `when: not molecule_test` conditionals to production code
- Masking failures with test-specific logic
- Skipping validations in tests

### Container Testing Limitations

**Use tags for container limitations**, not production code conditionals:

```bash
# Skip container-incompatible tasks
molecule test -- --skip-tags hostname,docker-compose,no-container
```

**Common container limitations**:
- Hostname changes (requires CAP_SYS_ADMIN)
- Docker-in-docker (nested containers)
- Systemd service management (limited in containers)
- Kernel module loading
- Some network configurations

**Solution**: Tag these tasks with `no-container` and test in VMs (Phase III).

### Semantic Failures Over Masking

**Let roles fail properly** rather than masking issues:

**Good**:
```yaml
- name: Configure hostname
  ansible.builtin.hostname:
    name: "{{ host_hostname }}"
  tags: [hostname, no-container]
```

**Bad**:
```yaml
- name: Configure hostname
  ansible.builtin.hostname:
    name: "{{ host_hostname }}"
  when: not (molecule_test | default(false))  # NEVER DO THIS
```

### Individual Role Tests Over Integration-Only

**Every role gets its own test** in `roles/{role}/molecule/default/`.

**Test hierarchy**:
1. **Individual role tests** - Authoritative for that role
2. **Integration tests** - Role interactions only
3. **VM tests** - Full system validation (Phase III)

**Test contract**: If role tests pass but integration fails → investigate missing role test coverage, not integration code.

### Test Types by Role Complexity

**Simple roles** → `roles/{role-name}/molecule/default/`:
- Focus: Role-specific functionality, packages, configuration
- Examples: nodejs, rust, go, os_configuration, manage_packages
- Test: Package installation, config files, idempotence

**Orchestrating roles** → `molecule/test-integration/`:
- Focus: Role interactions, cross-dependencies, end-to-end workflows
- Examples: configure_system (calls multiple roles)
- Test: Data flow between roles, variable inheritance

**Integration tests don't repeat individual role testing** - they validate the orchestration layer only.

## Development Test Flow

### Required Sequence (Each Phase Gates the Next)

**CRITICAL**: Never push code that fails local molecule testing to CI.

```
1. ansible-lint           → Syntax/standards validation
2. molecule converge      → Role functionality during development
3. molecule test          → MUST PASS before commit (full suite)
4. pre-commit             → Formatting, linting, custom hooks
5. CI                     → Should pass if local passes
```

**Rule**: If `molecule test` fails locally, it will fail in CI. Fix all local issues before committing.

### TDD Process - Must Follow This Order

When implementing new features or requirements:

1. **Update SRD** - Document requirements in `/docs/archive/SOFTWARE_REQUIREMENTS_DOCUMENT.md`
2. **Write validation plan** - Create plan in `docs/validation/`
3. **Write/update tests** - Add to `molecule/*/verify.yml`
4. **Run tests and OBSERVE FAILURES** - Document what fails and why
5. **ONLY THEN modify production code** - Update tasks/, defaults/, etc.
6. **Run tests again** - Confirm they pass
7. **Document implementation** - Git commit with details

**CRITICAL**: Steps 1-4 must be complete BEFORE touching production code. Test failures in step 4 prove we're testing the right thing.

### Why This Order Matters

**Test-first benefits**:
- Failures prove we're testing the actual requirement
- Prevents "tests that always pass"
- Documents expected behavior before implementation
- Catches edge cases early

**Common mistake**: Writing tests after code leads to tests that validate the implementation, not the requirements.

## Container vs VM Testing

### Container Testing (Current - Phase I/II)

**Used for**: Fast feedback, CI/CD, development iteration

**Pros**:
- Fast startup (seconds)
- Easy cleanup
- CI-friendly
- Parallel execution

**Cons**:
- Limited capabilities (no hostname, limited systemd)
- Not real systems
- Docker-in-docker issues
- Some features untestable

### VM Testing (Future - Phase III)

**Used for**: Comprehensive validation, real-world scenarios

**Pros**:
- Full system capabilities
- Real OS behavior
- Complete feature testing
- Multi-distribution validation

**Cons**:
- Slower (minutes per test)
- More complex setup (Terraform + libvirt)
- Higher resource requirements

**Strategy**: Container tests for fast feedback, VM tests for comprehensive validation.

## Test Assertion Patterns

### Package Installation

```yaml
- name: Verify package installed
  ansible.builtin.package_facts:
    manager: auto

- name: Assert package present
  ansible.builtin.assert:
    that:
      - "'nginx' in ansible_facts.packages"
    fail_msg: "nginx package not installed"
```

### Configuration Files

```yaml
- name: Check configuration file exists
  ansible.builtin.stat:
    path: /etc/nginx/nginx.conf
  register: nginx_config

- name: Verify configuration
  ansible.builtin.assert:
    that:
      - nginx_config.stat.exists
      - nginx_config.stat.mode == '0644'
```

### Service State

```yaml
- name: Gather service facts
  ansible.builtin.service_facts:

- name: Verify service running
  ansible.builtin.assert:
    that:
      - ansible_facts.services['nginx.service'].state == 'running'
      - ansible_facts.services['nginx.service'].status == 'enabled'
```

### Idempotence

Molecule automatically runs converge twice and checks for changes:

```yaml
# In molecule.yml
verifier:
  name: ansible
  options:
    # Runs converge, then converge again and expects no changes
```

## Common Testing Gotchas

### PATH Issues with User-Level Packages

**Problem**: Language tools install to `~/.npm-global/`, `~/.cargo/bin/`, `~/go/bin/`

**Solution**: Verification tasks must use correct PATH:

```yaml
- name: Verify npm package
  ansible.builtin.command: "{{ ansible_user_dir }}/.npm-global/bin/typescript --version"
  become: yes
  become_user: "{{ target_user }}"
```

### Container Networking

**Problem**: Some tests require network access (package downloads, repository setup)

**Solution**: Ensure molecule platforms have network access:

```yaml
platforms:
  - name: test-instance
    networks:
      - name: molecule-network
```

### Test User Creation

**Problem**: User-level tests require actual users to exist

**Solution**: Create test users in `prepare.yml`:

```yaml
- name: Create test user
  ansible.builtin.user:
    name: testuser
    state: present
    create_home: yes
```

### Cleanup Between Tests

**Problem**: State from previous test runs can affect results

**Solution**: Molecule handles cleanup automatically, but for manual runs:

```bash
molecule destroy  # Clean up containers
molecule create   # Fresh start
molecule converge # Run role
molecule verify   # Run tests
```

## CI/CD Integration

### GitLab CI Pipeline Structure

```
validate-all       → ansible-lint, yamllint, syntax check
  ↓
role tests (parallel)
├── test-nodejs
├── test-rust
├── test-go
├── test-neovim
└── test-terminal_config
  ↓
integration tests
├── test-integration
├── test-discovery
└── test-minimal
  ↓
build-docs        → Sphinx documentation
  ↓
pages             → Deploy to GitLab Pages
```

### Parallel Execution

5 role tests run in parallel for speed:
- nodejs
- rust
- go
- neovim
- terminal_config

Each uses isolated Docker containers with cached dependencies.

### Cache Strategy

```yaml
cache:
  key: "test-$CI_COMMIT_REF_SLUG"
  paths:
    - /root/.cache/pip/
    - /root/.ansible/collections/
```

Speeds up subsequent runs by caching:
- Python packages
- Ansible collections
- APT packages (when possible)

## Current Status (October 2025)

### Completed (Phase II)
- Individual role tests: nodejs, rust, go, neovim, terminal_config
- Integration tests: configure_system, discovery, minimal
- CI pipeline: 5 parallel tests + 3 integration tests
- Documentation: Sphinx + GitLab Pages

### In Progress
- Extract remaining roles to individual tests:
  - os_configuration
  - manage_packages
  - manage_security_services
  - configure_users

### Planned (Phase III)
- VM-based testing with Terraform + libvirt
- Multi-distribution validation (Ubuntu 22.04/24.04, Debian 12/13, Arch)
- macOS testing (licensing challenges)
- Comprehensive system validation via discovery playbook

## Lessons Learned

### What Works Well

1. **Individual role tests** - Fast feedback, easy to debug
2. **Container-based CI** - Quick iterations, parallel execution
3. **Tag-based skipping** - Clean way to handle container limitations
4. **Molecule's idempotence checking** - Catches unintended changes

### What Doesn't Work

1. **Integration-only tests** - Hard to debug, slow, brittle
2. **Test-specific production code** - Creates divergence, maintenance burden
3. **Ignoring container limitations** - Leads to flaky tests
4. **Testing in CI only** - Slow feedback loop, wastes CI time

### Key Insights

1. **Test the requirement, not the implementation** - Tests should validate behavior, not code structure
2. **Local testing is mandatory** - CI should confirm, not discover issues
3. **Containers have limits** - Know when to use VMs instead
4. **Fast feedback wins** - Individual role tests > integration tests for development

## References

- TDD Process: `CLAUDE.md` lines 24-35
- Test Contract: `CLAUDE.md` line 100
- VM Testing Plan: `.claude/context/vm-testing-plan.md`
