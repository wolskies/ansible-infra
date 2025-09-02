# Testing Strategy for wolskinet.infrastructure

This document outlines the comprehensive testing strategy designed to catch the real-world failures we encountered in production.

## Testing Philosophy

Our testing strategy is built around the principle: **"Test what actually breaks in production"**

### Key Insights from Production Failures

1. **Perfect test data doesn't catch real-world issues**
2. **Edge cases and error conditions are where systems fail**
3. **Conditional logic is fragile and needs extensive testing**
4. **Dependency assumptions break in minimal environments**
5. **Mixed data quality (like discovery output) exposes bugs**
6. **Service-specific limitations aren't well documented** (e.g., UFW doesn't support reload)

## Test Suite Architecture

### 1. Comprehensive Integration Testing
**Location**: `molecule/comprehensive-integration/`

**Purpose**: Tests realistic deployment scenarios with mixed data quality

**Key Features**:
- Multiple OS variants (Ubuntu clean, minimal, with snap, Debian, Arch)
- Realistic user data mixing valid and placeholder variables
- Missing dependencies and packages
- Various system states and configurations

**What it catches**:
- ✅ Missing group creation before user creation
- ✅ SSH key validation failures with placeholder data
- ✅ Snap preservation logic on different system states
- ✅ UFW profile fallback scenarios
- ✅ UFW service reload limitations (must use restart)
- ✅ Language package conditional errors

### 2. Failure Scenario Testing
**Location**: `molecule/failure-scenarios/`

**Purpose**: Negative testing - deliberately creates failure conditions

**Key Features**:
- Removes passlib to test password hashing failures
- Removes UFW SSH profiles to test firewall fallbacks
- Creates missing language tools to test conditionals
- Tests all known AttributeError patterns

**What it catches**:
- ✅ `object has no attribute 'rc'` errors
- ✅ Missing passlib dependency handling
- ✅ UFW profile missing scenarios
- ✅ UFW service reload vs restart issues
- ✅ All conditional logic edge cases

### 3. Enhanced Pre-commit Hooks
**Location**: `.pre-commit-config.yaml`

**Purpose**: Catch issues before they reach CI/CD

**Key Features**:
- Detects patterns that caused our production failures
- Validates Jinja2 templates
- Checks for missing conditional safety patterns
- Validates test data realism
- Security scanning

**What it catches**:
- ✅ Direct attribute access without `is defined` checks
- ✅ `password_hash` usage without passlib handling
- ✅ UFW app names without port fallbacks
- ✅ Nested loops without `loop_var`
- ✅ All linting errors before commit

## Test Data Strategy

### Realistic Test Data
Instead of perfect test data, we use:

```yaml
users_config:
  # Valid user (should work)
  - name: 'gooduser'
    password: 'TestPassword123!'  # Plaintext - tests hashing
    ssh_pubkey: 'ssh-rsa AAAAB3... real_key'

  # Discovery-like user (should be handled gracefully)
  - name: 'discovereduser'
    password: 'var_users_config_discovereduser_password'  # Placeholder
    ssh_pubkey: 'var_users_config_discovereduser_ssh_pubkey'  # Placeholder
    dotfiles:
      enable: true
      repo: null  # Should be skipped

  # Edge cases
  - name: 'customgroupuser'
    gid: 9999  # Non-existent group - tests group creation
```

This mimics real discovery output that caused our failures.

## Platform Coverage

### Test Matrix
- **Ubuntu 24.04 Clean**: Standard geerlingguy image
- **Ubuntu 24.04 Minimal**: Bare Ubuntu with missing packages
- **Ubuntu 24.04 with Snap**: Tests snap preservation logic
- **Debian 13**: Tests Debian-specific differences
- **Arch Linux Base**: Minimal Arch with missing tools

### Missing Dependency Simulation
- Remove `passlib` → test password handling
- Remove `git`, `curl`, `wget` → test language package conditionals
- Remove UFW SSH profiles → test firewall port fallbacks
- Install conflicting packages → test collision handling

## Running the Test Suite

### Full Test Suite
```bash
# Run all molecule scenarios
make test

# Run specific failure testing
make test-failures

# Run comprehensive integration
make test-comprehensive
```

### Pre-commit Setup
```bash
# Install pre-commit hooks (catches issues before commit)
pip install pre-commit
pre-commit install

# Run manually
pre-commit run --all-files
```

### CI/CD Integration
```bash
# CI-style testing (includes linting)
make ci-test

# Quick validation (fast feedback)
make test-quick
```

## Failure Pattern Detection

Our pre-commit hooks specifically detect these patterns that caused production failures:

### 1. Missing Attribute Checks
**Bad**: `item.rc != 0`
**Good**: `item.rc is defined and item.rc != 0`

### 2. Password Hashing Issues
**Detects**: `password_hash` usage without passlib handling
**Recommends**: Graceful fallback for missing passlib

### 3. UFW Profile Dependencies
**Detects**: `name: ssh` in UFW rules
**Recommends**: Port-based fallbacks

### 4. UFW Service Reload Issues
**Detects**: `state: reloaded` for UFW service
**Prevents**: "Job type reload is not applicable" errors
**Recommends**: Use `state: restarted` for UFW

### 5. Nested Loop Variables
**Detects**: `include_role` with `loop` without `loop_var`
**Requires**: `loop_control.loop_var` usage

## Success Metrics

A successful test run should demonstrate:

1. **✅ Valid data processed correctly**
   - Users with real passwords and SSH keys created
   - Services configured properly
   - Packages installed

2. **✅ Invalid data handled gracefully**
   - Placeholder variables skipped without errors
   - Missing dependencies don't cause fatal failures
   - Bad SSH keys don't break user creation

3. **✅ Edge cases managed**
   - Missing groups created before users
   - UFW rules work with or without profiles
   - Snap preserved when already installed
   - Language tools handle missing dependencies

4. **✅ No AttributeErrors or KeyErrors**
   - All conditional access properly guarded
   - All loops handle empty/undefined variables
   - All tasks continue gracefully on failures

## Continuous Improvement

### Adding New Tests
When new failures occur:

1. Add failure reproduction to `molecule/failure-scenarios/`
2. Add pattern detection to `.pre-commit-config.yaml`
3. Add realistic test data to `molecule/comprehensive-integration/`
4. Update this documentation

### Test Data Maintenance
- Keep test data realistic (mix of good and bad data)
- Mirror actual discovery output patterns
- Include edge cases that occur in real deployments
- Test on minimal systems, not just full-featured ones

## Integration with Development Workflow

### Developer Workflow
```bash
# Before coding
pre-commit install

# During development
make test-quick        # Fast feedback

# Before committing
pre-commit run --all-files
make test-failures     # Test known failure scenarios

# Before merging
make test              # Full test suite
```

### CI/CD Pipeline
1. **Lint**: Pre-commit hooks + yamllint + ansible-lint
2. **Unit Test**: Individual role testing
3. **Integration Test**: Full deployment scenarios
4. **Failure Test**: Negative testing scenarios
5. **Security**: Bandit + sensitive data detection

This comprehensive approach ensures we catch the types of failures that made it to production while maintaining fast feedback loops for developers.

## Key Success Factors

1. **Test Real Scenarios**: Use data that mirrors actual discovery output
2. **Test Failure Conditions**: Don't just test happy paths
3. **Test Minimal Systems**: Many failures only occur on bare systems
4. **Test Mixed Data Quality**: Real systems have inconsistent data
5. **Automate Detection**: Use pre-commit hooks to catch patterns
6. **Document Patterns**: Record what failed and how to detect it

This strategy transforms our testing from "does it work in ideal conditions" to "does it handle the messy reality of production deployments."
