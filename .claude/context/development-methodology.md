# Development Methodology

Internal development processes and practices for the wolskies.infrastructure collection.

## TDD Process (Test-Driven Development)

### The Red-Green-Refactor Cycle

Applied to Ansible roles:

1. **Red** - Write a failing test
2. **Green** - Write minimal code to pass
3. **Refactor** - Improve code while keeping tests green

### Implementation Workflow

When implementing new features or requirements:

1. **Update SRD** with requirements
2. **Write validation plan** in docs/validation/
3. **Write/update tests** (molecule/verify.yml)
4. **Run tests and OBSERVE FAILURES** - Document what fails and why
5. **ONLY THEN modify production code** (tasks/, defaults/, etc.)
6. **Run tests again** to confirm they pass
7. **Document the implementation** in commit message

**CRITICAL**: Steps 1-4 must be complete BEFORE touching any production code. Test failures in step 4 prove we're testing the right thing.

### Example: Package Installation

**Step 1: Write Failing Test**

Add verification in `molecule/default/verify.yml`:

```yaml
- name: Gather package facts
  ansible.builtin.package_facts:

- name: Verify git installed
  ansible.builtin.assert:
    that: "'git' in ansible_facts.packages"
    fail_msg: "git package not installed"
```

Run test (it fails):

```bash
molecule test
# FAILED - git not installed
```

**Step 2: Implement Minimal Code**

Add to `tasks/main.yml`:

```yaml
- name: Install packages
  ansible.builtin.apt:
    name: git
    state: present
  when: ansible_distribution == "Ubuntu"
```

**Step 3: Run Test (Passes)**

```bash
molecule test
# PASSED - git installed
```

**Step 4: Refactor**

Improve implementation:

```yaml
- name: Install packages
  ansible.builtin.apt:
    name: "{{ item.name }}"
    state: "{{ item.state | default('present') }}"
  loop: "{{ manage_packages_all[ansible_distribution] | default([]) }}"
  when: ansible_distribution in ["Ubuntu", "Debian"]
```

Run test again:

```bash
molecule test
# PASSED - still works with better implementation
```

## Role Validation Workflow

### Phase 1: Analysis

Before writing any code:

1. **Extract requirements** from documentation for the target role
2. **Create validation plan** with specific test cases (positive + negative)
3. **Review current implementation** (production code and tests)
4. **Identify gaps** between requirements and current implementation

### Phase 2: Planning

Document your approach:

1. **Gap analysis** - What's missing, what's wrong, what's good
2. **Implementation plan** - Ordered list of specific changes needed
3. **Estimate effort** - Simple vs complex changes
4. **Success criteria** - How to know each change is complete

### Phase 3: Implementation

For each requirement (one at a time):

**1. Start Clean**

Ensure current state passes all tests:

```bash
cd roles/manage_packages
molecule test  # Must pass before starting
```

**2. Make Targeted Change**

Implement ONE requirement:

* Update production code if needed
* Update/add molecule tests to validate
* Update verification tasks

**3. Validate Change**

Test the specific change:

```bash
molecule test  # Must pass after change
```

**4. Commit Change**

Document what was implemented:

```bash
git add .
git commit -m "implement REQ-XX-YYY: requirement description"
git push origin main
```

**5. Verify CI**

Ensure CI pipeline passes.

**6. Move to Next Requirement**

Repeat for each requirement.

### Phase 4: Completion

After all requirements:

1. **Final validation** - Run complete test suite for the role
2. **Documentation update** - Update README/docs if needed
3. **Gap closure verification** - Confirm all requirements implemented
4. **Move to next role**

## Branching Strategy

### Direct Commits to Main

We use direct commits to `main` branch:

* Single-developer workflow with disciplined testing
* Each commit is small, focused, and fully tested
* Immediate CI feedback on every change
* Forces better discipline (no broken commits allowed)

**Why not feature branches?**

* No collaboration conflicts (single developer)
* Overhead not justified for systematic approach
* `molecule test` requirement ensures quality
* `git revert` available if needed

## Testing Requirements

### Before Any Changes

Verify current state is clean:

```bash
cd roles/manage_packages
molecule test
ansible-lint
```

### After Each Change

Validate the specific change:

```bash
# Role-specific tests
molecule test

# Broader validation
cd ../../
ansible-lint
pre-commit run --all-files
```

### Commit Requirements

Before committing, ensure:

* ✅ All molecule tests pass
* ✅ No ansible-lint errors
* ✅ No pre-commit hook failures
* ✅ Commit message references specific requirement

## Commit Message Format

### Standard Format

```text
implement REQ-{ROLE}-{NUM}: {requirement description}

- Add/update {specific change made}
- Test coverage: {what tests validate this}
- Platform: {Ubuntu/Arch/macOS/All}

Validates: {specific validation criteria met}
```

### Examples

**System Configuration**

```text
implement REQ-OS-001: system hostname configuration

- Add hostname task with proper conditionals
- Test coverage: verify hostname command and /etc/hostname file
- Platform: All (VM-only due to container limitations)

Validates: hostname set when host_hostname defined and non-empty
```

**Package Management**

```text
implement REQ-MP-003: layered package installation

- Add package merging from all/group/host levels
- Test coverage: verify all three levels combine correctly
- Platform: All

Validates: packages merged from all inventory levels
```

## Quality Gates

### Before Moving to Next Requirement

* ☐ Molecule tests pass
* ☐ Ansible-lint clean
* ☐ Pre-commit hooks pass
* ☐ CI pipeline green
* ☐ Requirement fully validated (positive + negative tests)

### Before Moving to Next Role

* ☐ All role requirements implemented
* ☐ Complete role test suite passes
* ☐ Integration tests pass (if applicable)
* ☐ Documentation updated
* ☐ Gap analysis complete and closed

## Error Handling

### When Tests Fail

1. **Do not commit** - Fix the issue first
2. **Understand the failure** - Is it the code or the test?
3. **Fix incrementally** - Make minimal changes to resolve
4. **Re-test** - Ensure fix works and doesn't break other things

### When CI Fails

1. **Investigate immediately** - Don't proceed to next change
2. **Fix in separate commit** - Don't mix CI fixes with feature work
3. **Verify fix** - Ensure CI passes before continuing

### When Molecule is Flaky

1. **Retry once** - Some tests have timing issues
2. **If consistent failure** - Investigate and fix the test
3. **Document workarounds** - If container limitations require VM testing

## TDD Benefits

### Confidence

* Know exactly what works
* Catch regressions immediately
* Refactor without fear

### Design

* Forces you to think about interface first
* Keeps code testable
* Encourages modularity

### Documentation

* Tests document expected behavior
* Examples of how to use features
* Living documentation that stays current

## TDD Best Practices

### Write Tests First

```bash
# Wrong order
1. Write production code
2. Hope it works
3. Maybe write tests later

# TDD order
1. Write test (fails)
2. Write code (test passes)
3. Refactor (test still passes)
```

### Test One Thing

```yaml
# Good - focused test
- name: Verify git installed
  ansible.builtin.assert:
    that: "'git' in ansible_facts.packages"

# Bad - testing multiple things
- name: Verify everything
  ansible.builtin.assert:
    that:
      - "'git' in ansible_facts.packages"
      - "'curl' in ansible_facts.packages"
      - services['nginx'].state == 'running'
      - firewall_enabled
```

### Keep Tests Fast

* Use `molecule converge` during development
* Only run full `molecule test` before commit
* Use tags to run subset of tests

## TDD Anti-Patterns to Avoid

1. **Writing tests after code** - Not TDD
2. **Testing implementation** - Test outcomes, not how
3. **Brittle tests** - Over-specified expectations
4. **Slow tests** - Full test suite for every change
5. **No refactoring** - Stop at green, miss improvements

### Example: Don't Test Implementation

```yaml
# Bad - testing implementation
- name: Verify apt module called
  ansible.builtin.apt:
    name: git
    state: present
  check_mode: true

# Good - testing outcome
- name: Verify git installed
  ansible.builtin.package_facts:

- name: Check git present
  ansible.builtin.assert:
    that: "'git' in ansible_facts.packages"
```

## Incremental Development

### Build Features Step by Step

**Feature: Multi-platform package management**

**Iteration 1: Ubuntu only**

```yaml
# Test
- name: Verify git on Ubuntu
  ansible.builtin.assert:
    that: "'git' in ansible_facts.packages"
  when: ansible_distribution == "Ubuntu"

# Implementation
- name: Install packages (Ubuntu)
  ansible.builtin.apt:
    name: git
  when: ansible_distribution == "Ubuntu"
```

**Iteration 2: Add Arch support**

```yaml
# Test
- name: Verify git on Arch
  ansible.builtin.assert:
    that: "'git' in ansible_facts.packages"
  when: ansible_distribution == "Archlinux"

# Implementation
- name: Install packages (Arch)
  ansible.builtin.pacman:
    name: git
  when: ansible_distribution == "Archlinux"
```

**Iteration 3: Refactor to be data-driven**

```yaml
# Test (same as before)

# Implementation (improved)
- name: Install packages
  ansible.builtin.package:
    name: "{{ item }}"
  loop: "{{ packages[ansible_distribution] }}"
```

## Development Cycle Example

Working on the `manage_packages` role:

```bash
# 1. Start with clean state
cd roles/manage_packages
molecule test  # ✅ Passes

# 2. Implement REQ-MP-001 (basic package installation)
# Edit tasks/main.yml, add package installation logic
# Edit molecule/default/verify.yml, add package verification

# 3. Test the change
molecule test  # ✅ Passes

# 4. Commit
git add tasks/main.yml molecule/default/verify.yml
git commit -m "implement REQ-MP-001: basic package installation"
git push

# 5. Verify CI passes
# Check GitLab CI pipeline

# 6. Move to REQ-MP-002 (layered configuration)
# Repeat steps 2-5

# 7. After all requirements
molecule test  # Final validation
ansible-lint   # Final check
# Update README if needed
# Move to next role
```

## Documentation Updates

### When to Update

* New requirements implemented
* Test procedures change
* Workflow improvements identified

### What to Update

* Role README files (if behavior changes significantly)
* This methodology document (if process improvements identified)
* User-facing documentation (if user interface changes)

## Philosophy

This methodology exists to:

1. **Maintain quality** - Every commit is tested and working
2. **Enable refactoring** - Tests provide safety net
3. **Document decisions** - Commit messages trace to requirements
4. **Provide confidence** - Know what works and what doesn't
5. **Support AI development** - Clear process for Claude Code to follow

## References

- CLAUDE.md - Critical rules and TDD process summary
- .claude/context/testing-strategy.md - Testing philosophy
- .claude/context/lessons-learned.md - Mistakes to avoid
