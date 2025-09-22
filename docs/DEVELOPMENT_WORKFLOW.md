# Development Workflow

**Document Version:** 1.0
**Last Updated:** September 22, 2025
**Purpose:** Define the systematic development process for implementing and validating requirements

---

## Core Principles

1. **Requirements-driven development** - All changes must trace back to specific SRD requirements
2. **Incremental validation** - Each change is tested and validated before proceeding
3. **No broken states** - Every commit must pass all tests
4. **Systematic approach** - Work role-by-role, requirement-by-requirement

---

## Role Validation Workflow

### Phase 1: Analysis
1. **Extract requirements** from SRD for the target role
2. **Create validation plan** with specific test cases (positive + negative)
3. **Review current implementation** (both production code and tests)
4. **Identify gaps** between requirements and current implementation

### Phase 2: Planning
1. **Document gap analysis** - what's missing, what's wrong, what's good
2. **Create implementation plan** - ordered list of specific changes needed
3. **Estimate effort** - which changes are simple vs complex
4. **Define success criteria** - how we know each change is complete

### Phase 3: Implementation
**For each requirement (one at a time):**

1. **Start clean**: Ensure current state passes all tests
   ```bash
   cd roles/{role-name}
   molecule test  # Must pass before starting
   ```

2. **Make targeted change**: Implement ONE requirement
   - Update production code if needed
   - Update/add molecule tests to validate the requirement
   - Update verification tasks

3. **Validate change**: Test the specific change
   ```bash
   molecule test  # Must pass after change
   ```

4. **Commit change**: Document what was implemented
   ```bash
   git add .
   git commit -m "implement REQ-XX-YYY: requirement description"
   git push origin main
   ```

5. **Verify CI**: Ensure CI pipeline passes

6. **Move to next requirement**

### Phase 4: Completion
1. **Final validation**: Run complete test suite for the role
2. **Documentation update**: Update README/docs if needed
3. **Gap closure verification**: Confirm all requirements are implemented
4. **Move to next role**

---

## Branching Strategy

**Approach**: Direct commits to `main` branch
- Single-developer workflow with disciplined testing
- Each commit is small, focused, and fully tested
- Immediate CI feedback on every change
- Forces better discipline (no broken commits allowed)

**Why not feature branches**:
- No collaboration conflicts (single developer)
- Overhead not justified for our systematic approach
- `molecule test` requirement before each commit ensures quality
- `git revert` available if needed

---

## Testing Requirements

### Before Any Changes
```bash
# Verify current state is clean
cd roles/{role-name}
molecule test
ansible-lint
```

### After Each Change
```bash
# Validate the specific change
molecule test

# Run broader validation
cd ../../
ansible-lint
pre-commit run --all-files
```

### Commit Requirements
- All molecule tests pass
- No ansible-lint errors
- No pre-commit hook failures
- Commit message references specific requirement

---

## Commit Message Format

```
implement REQ-{ROLE}-{NUM}: {requirement description}

- Add/update {specific change made}
- Test coverage: {what tests validate this}
- Platform: {Ubuntu/Arch/macOS/All}

Validates: {specific validation criteria met}
```

**Examples:**
```
implement REQ-OS-001: system hostname configuration

- Add hostname task with proper conditionals
- Test coverage: verify hostname command and /etc/hostname file
- Platform: All (VM-only due to container limitations)

Validates: hostname set when host_hostname defined and non-empty
```

```
implement REQ-OS-003: system timezone configuration

- Add timezone task using community.general.timezone
- Test coverage: verify timedatectl output and symlink
- Platform: All

Validates: timezone set when domain_timezone defined and non-empty
```

---

## Error Handling

### When Tests Fail
1. **Do not commit** - fix the issue first
2. **Understand the failure** - is it the code or the test?
3. **Fix incrementally** - make minimal changes to resolve
4. **Re-test** - ensure fix works and doesn't break other things

### When CI Fails
1. **Investigate immediately** - don't proceed to next change
2. **Fix in separate commit** - don't mix CI fixes with feature work
3. **Verify fix** - ensure CI passes before continuing

### When Molecule is Flaky
1. **Retry once** - some tests have timing issues
2. **If consistent failure** - investigate and fix the test
3. **Document workarounds** - if container limitations require VM testing

---

## Documentation Updates

### When to Update Docs
- New requirements implemented
- Test procedures change
- Workflow improvements identified

### What to Update
- Role README files (if role behavior changes significantly)
- This workflow document (if process improvements identified)
- Validation plans (if test approaches change)

---

## Quality Gates

### Before Moving to Next Requirement
- [ ] Molecule tests pass
- [ ] Ansible-lint clean
- [ ] Pre-commit hooks pass
- [ ] CI pipeline green
- [ ] Requirement fully validated (positive + negative tests)

### Before Moving to Next Role
- [ ] All role requirements implemented
- [ ] Complete role test suite passes
- [ ] Integration tests pass (if applicable)
- [ ] Documentation updated
- [ ] Gap analysis complete and closed

---

This workflow ensures systematic, validated progress while maintaining code quality and avoiding regressions.
