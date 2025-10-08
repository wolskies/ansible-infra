# Lessons Learned

Mistakes made, gotchas encountered, and hard-won wisdom from developing the wolskies.infrastructure collection.

## Testing Lessons

### Don't Change Production Code to Make Tests Pass

**The Mistake**: Early on, we were tempted to add `when: not molecule_test` conditionals to production code when tasks failed in containers.

**What We Learned**: This creates divergence between test and production code. If it doesn't work in the test environment, either:
1. The test environment is wrong (fix the test)
2. The production code is wrong (fix the code)
3. The test environment can't support the feature (use tags, not conditionals)

**The Fix**: Use tags like `no-container` and skip them in container tests. Test full functionality in VMs.

### Integration-Only Tests Are Hard to Debug

**The Mistake**: Initially tested only end-to-end scenarios with all roles running together.

**What We Learned**:
- Failures are hard to isolate (which role broke?)
- Slow feedback loop (must run entire suite)
- Brittle (one broken role breaks all tests)
- Difficult to pinpoint regressions

**The Fix**: Individual role tests in `roles/{role}/molecule/default/` are authoritative. Integration tests only validate role interactions.

### Container Limitations Are Real

**The Mistake**: Tried to force everything to work in Docker containers.

**What We Learned**: Containers can't do everything:
- Hostname changes require CAP_SYS_ADMIN
- Docker-in-docker is complex and fragile
- Systemd service management is limited
- Kernel modules can't be loaded
- Some network configurations don't work

**The Fix**: Accept container limitations, use tags, plan for VM testing (Phase III).

### PATH Issues with User-Level Tools

**The Mistake**: Verified npm/cargo/go packages without considering user PATH.

**What We Learned**: Language tools install to:
- `~/.npm-global/bin/` (Node.js)
- `~/.cargo/bin/` (Rust)
- `~/go/bin/` (Go)

Tests that use system PATH won't find these tools.

**The Fix**:
```yaml
- name: Verify npm package
  ansible.builtin.command: "{{ ansible_user_dir }}/.npm-global/bin/typescript --version"
  become: yes
  become_user: "{{ target_user }}"
```

### Idempotence Testing Catches Silent Issues

**The Mistake**: Didn't initially test idempotence rigorously.

**What We Learned**: Tasks that aren't idempotent:
- Show "changed" on every run
- Can break on repeated application
- Indicate poor task design
- Often miss conditional checks

**The Fix**: Molecule automatically runs converge twice. Watch for unexpected changes on the second run.

## Requirements and Documentation Lessons

### External Dependencies Are Implementation Details

**The Mistake**: Initially documented Python package versions, APT packages, and other dependencies as requirements.

**What We Learned**: These are implementation details that change over time. Requirements should focus on capabilities, not dependencies.

**Bad Requirement**: "The system SHALL install python3-debian package"
**Good Requirement**: "The system SHALL be capable of managing deb822 repository sources"

The python3-debian dependency is an implementation detail of meeting that requirement.

### One Requirement Per Number

**The Mistake**: Combined multiple testable concepts in single requirement numbers.

**Example**:
```
REQ-OS-001: The system SHALL set hostname and update /etc/hosts
```

**What We Learned**: This is really two requirements:
- REQ-OS-001: Set hostname
- REQ-OS-002: Update /etc/hosts

**The Fix**: One testable concept per requirement number. Easier to track, test, and validate.

### Idempotency Is a Testing Concept, Not a Requirement

**The Mistake**: Listed "tasks shall be idempotent" as separate requirements.

**What We Learned**: Idempotency is **how we test** requirements, not a requirement itself. Every requirement implicitly includes idempotent implementation.

"Tasks report changed only when changes occur" is the same concept as idempotency - it's redundant.

**The Fix**: Idempotence is a testing principle, not a numbered requirement. Test it for every feature.

### Specify Ansible Modules in Requirements

**The Mistake**: Vague requirements like "SHALL set hostname" without specifying implementation.

**What We Learned**: More testable to specify the module:
- "SHALL set hostname using ansible.builtin.hostname"
- "SHALL manage packages using ansible.builtin.package"
- "SHALL configure firewall using community.general.ufw"

This makes requirements:
- More testable (verify the specific module was used)
- Implementation-aligned (we know how to implement it)
- Version-compatible (module versions matter)

**The Fix**: Specify Ansible modules in requirements where applicable.

### Each Feature Gets Its Own Section

**The Mistake**: Grouped related functionality like "timezone, locale, and language configuration" into one section.

**What We Learned**: Separate concerns need separate documentation sections:
- Timezone (REQ-OS-003)
- Locale (REQ-OS-004)
- Language (REQ-OS-005)

Even if related, they're distinct features with separate variables, testing, and troubleshooting.

**The Fix**: One section per feature in SRD. Easier to navigate, update, and reference.

### Delete Guidance Masquerading as Requirements

**The Mistake**: Included "role descriptions" and "multi-function summaries" as requirements.

**Example**:
```
REQ-OS-000: The os_configuration role SHALL provide system configuration capabilities
```

**What We Learned**: This isn't testable - it's just a description. Real requirements specify what the system does, not what roles do.

**The Fix**: Delete these "meta-requirements". Keep only testable, specific requirements.

## Development Workflow Lessons

### Local Testing Is Mandatory

**The Mistake**: Committed code without running full `molecule test` locally, relying on CI to catch issues.

**What We Learned**:
- CI runs take 10-15 minutes
- Feedback loop is too slow
- Wastes CI resources
- Blocks other developers

**The Fix**:
```bash
# MUST PASS before committing
molecule test

# Quick iterations during development
molecule converge
molecule verify
```

**Rule**: If `molecule test` fails locally, it will fail in CI. Fix all local issues first.

### Pre-commit Hooks Save Time

**The Mistake**: Didn't use pre-commit hooks initially, caught linting issues in CI.

**What We Learned**: Pre-commit catches:
- YAML syntax errors
- Ansible-lint violations
- Formatting issues
- Trailing whitespace

**The Fix**: Install and use pre-commit:
```bash
pre-commit install
pre-commit run --all-files
```

### Git Commit Messages Need Structure

**The Mistake**: Generic commit messages like "fix tests" or "update role".

**What We Learned**: Hard to:
- Find changes related to specific requirements
- Understand why changes were made
- Track feature implementation history

**The Fix**: Structured commit messages:
```
implement REQ-OS-001 hostname configuration validation

- Added hostname setting via ansible.builtin.hostname
- Updated /etc/hosts with new hostname
- Added molecule tests for verification

Validates that hostname changes work on all platforms
```

**Benefits**:
- Searchable: `git log --grep="REQ-OS"`
- Traceable: Link commits to requirements
- Reviewable: Clear scope and purpose

## Platform-Specific Lessons

### Ubuntu 22.04 vs 24.04 Package Differences

**The Gotcha**: rustup available in Ubuntu 24.04 but not 22.04.

**What We Learned**: LTS releases have significantly different package availability. Can't assume Ubuntu 22 and 24 are interchangeable.

**The Fix**: Explicitly test both Ubuntu 22.04 and 24.04. Document version requirements clearly.

### deb822 Requires python3-debian

**The Gotcha**: `ansible.builtin.deb822_repository` module fails without python3-debian installed.

**What We Learned**: Some Ansible modules have undocumented Python package dependencies.

**The Fix**: Always `update_cache: true` and install python3-debian before using deb822_repository:
```yaml
- name: Install deb822 prerequisites
  ansible.builtin.apt:
    name: python3-debian
    state: present
    update_cache: yes
```

### macOS Firewall Is Fundamentally Different

**The Gotcha**: Tried to implement port-based firewall rules on macOS like Linux UFW.

**What We Learned**: macOS Application Layer Firewall (ALF) is application-based, not port-based. Can't translate UFW rules directly.

**The Fix**: Accept platform differences. Firewall rules variable is Linux-only. macOS uses ALF settings (stealth mode, block all, etc.).

### Arch Linux Needs base-devel

**The Gotcha**: Rust package compilation fails on Arch without base-devel.

**What We Learned**: Arch's minimal approach means build tools aren't installed by default.

**The Fix**: Install base-devel group when setting up Rust on Arch:
```yaml
- name: Install build essentials
  community.general.pacman:
    name: base-devel
    state: present
  when: ansible_distribution == "Archlinux"
```

## Variable Design Lessons

### Layered Configuration Is Powerful but Complex

**The Pattern**: Variables at three levels (all, group, host) merged automatically.

**What We Learned**:
- **Powerful**: One config works across inventory
- **Complex**: Users must understand merge behavior
- **Debugging**: Hard to see final merged value

**The Fix**: Comprehensive documentation with examples of all three levels. Clear explanation of merge strategy.

### Dictionary Merge Behavior Must Be Explicit

**The Gotcha**: Ansible's default dict merge behavior (`combine`) doesn't deep-merge lists.

**What We Learned**: With `list_merge='append'`:
```yaml
all: {packages: [git, vim]}
group: {packages: [nginx]}
Result: {packages: [git, vim, nginx]}  # Appended
```

Without `list_merge='append'`:
```yaml
all: {packages: [git, vim]}
group: {packages: [nginx]}
Result: {packages: [nginx]}  # Replaced
```

**The Fix**: Always use `list_merge='append'` when merging package lists:
```yaml
_final_packages: >-
  {{
    (manage_packages_all | default({})) |
    combine(manage_packages_group | default({}), list_merge='append') |
    combine(manage_packages_host | default({}), list_merge='append')
  }}
```

### Variable Naming Consistency Matters

**The Pattern**: Prefix variables by role (manage_packages_, firewall_, etc.).

**What We Learned**:
- Prevents variable collisions between roles
- Makes variable ownership obvious
- Easier to search and filter

**The Fix**: Established naming convention:
- Role-specific: `{role}_{concept}` (manage_packages_all)
- Collection-wide: `{concept}` (firewall, users)

## Documentation Lessons

### Auto-Generated Docs Have Limits

**The Attempt**: Generated all role docs from metadata.

**What We Learned**:
- Metadata is terse (good for code)
- Users need examples, context, troubleshooting
- Generated docs lack narrative flow

**The Fix**: Hybrid approach:
- Generate basic structure from metadata
- Write comprehensive RST docs with examples
- Keep metadata as source of truth for variables

### Examples Are More Valuable Than Descriptions

**The Mistake**: Long variable descriptions without examples.

**What We Learned**: Users prefer:
```yaml
# Good: Clear example
firewall:
  rules:
    - port: 22
      protocol: tcp
      comment: "SSH"
```

Over:
```
firewall.rules is a list of dictionaries containing port, protocol, and comment fields for firewall rule configuration
```

**The Fix**: Every complex variable gets at least one example. Multiple examples for complex scenarios.

### Platform Differences Need Visibility

**The Mistake**: Buried "Linux only" notes in variable descriptions.

**What We Learned**: Users need to know upfront:
- What works on their platform
- What doesn't work (and why)
- Platform-specific alternatives

**The Fix**: "Platform Support" and "Platform Differences" sections in every role doc. Clear "Not Supported" lists.

## What We'd Do Differently

### Start with VMs, Not Containers

**Hindsight**: If starting over, we'd build VM testing infrastructure (Phase III) earlier.

**Why**: Would have caught:
- Hostname configuration issues
- Systemd service management quirks
- Docker-compose conflicts

Container testing is great for iteration speed, but VMs catch the real issues.

### Write Tests Before Code (Really)

**Hindsight**: We understood TDD but didn't strictly enforce test-first early on.

**Why**: Test-first would have:
- Caught requirement ambiguities sooner
- Prevented "tests that validate implementation, not requirements"
- Made debugging faster (knew expected behavior upfront)

**Going Forward**: Strict TDD enforcement - no exception. Tests fail before code is written.

### Document as You Go

**Hindsight**: Wrote most documentation after implementation.

**Why**: Documentation after-the-fact:
- Misses decision context
- Harder to write (must reverse-engineer intent)
- Lower quality (rushed at end of cycle)

**Going Forward**: Update docs in same commit as code. Documentation is part of "done".

## References

- TDD Process: `.claude/context/testing-strategy.md`
- VM Testing Plan: `.claude/context/vm-testing-plan.md`
- Requirements Best Practices: `CLAUDE.md` lines 265-298
