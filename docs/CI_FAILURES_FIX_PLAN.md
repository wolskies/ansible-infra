# CI Failures Fix Plan

**Date:** September 22, 2025
**Context:** 4 CI failures identified that need fixing before continuing with os_configuration improvements

---

## CI Failures Identified

**Source:** Failed: 4 failure(s), 0 warning(s) in 203 files processed of 265 encountered. Profile 'production' was required.

### Failure #1: Duplicate YAML Key
```
docs/planning/MASTER_REFERENCE_CONFIG.yml:145: yaml[key-duplicates]: Duplication of key "packages" in mapping
```
**Status:** ✅ RESOLVED - `docs/planning/` directory was deleted during cleanup

### Failure #2: Missing json_query Filter
```
playbooks/validate_vm_configuration.yml:149:13: jinja[invalid][/]: Error rendering template: No filter named 'json_query' found.
```
**Issue:** Line 149 uses `json_query` filter which requires `jmespath` library
**Fix Required:** Replace with standard Jinja2 filters

### Failure #3: YAML Load Failure
```
vm-test-infrastructure/phase1-local-linux/terraform/cloud-init/network-config.yml:4:18: load-failure[yaml][/]: Failed to load YAML file (warning)
```
**Issue:** YAML syntax error in cloud-init network config
**Fix Required:** Examine and fix YAML syntax

### Failure #4: Missing json_query Filter
```
vm-test-infrastructure/phase1-local-linux/validate-phase1.yml:127:13: jinja[invalid][/]: Error rendering template: No filter named 'json_query' found.
```
**Issue:** Same as #2 - `json_query` filter usage
**Fix Required:** Replace with standard Jinja2 filters

---

## Fix Plan

### Step 1: Verify Failure #1 is Resolved ✅
- [x] Confirm `docs/planning/` directory deleted
- [x] No duplicate packages key issue remains

### Step 2: Fix json_query Issues (Failures #2 and #4)
**Problem:** `json_query` filter requires `jmespath` Python library which may not be available in all environments

**Solution:** Replace with standard Jinja2 filters that don't require external dependencies

**Original problematic code:**
```jinja2
validation_results.languages | json_query('*.expected') | select('equalto', true) | list | length == validation_results.languages | json_query('[?expected==`true`].found') | select('equalto', true) | list | length
```

**Replacement approach:**
```jinja2
validation_results.languages | default([]) | length == 0 or validation_results.languages | selectattr('expected', 'equalto', true) | selectattr('found', 'equalto', true) | list | length > 0
```

### Step 3: Fix YAML Load Failure (Failure #3)
**Location:** `vm-test-infrastructure/phase1-local-linux/terraform/cloud-init/network-config.yml:4:18`

**Investigation needed:**
1. Read the file and identify syntax issue at line 4, character 18
2. Fix YAML formatting/syntax error
3. Validate YAML is parseable

### Step 4: Test Each Fix
**Process for each fix:**
1. Make targeted change
2. Run `ansible-lint` to verify fix
3. Run `molecule test` to ensure no regression
4. Commit individual fix with descriptive message

### Step 5: Verify All CI Issues Resolved
**Final validation:**
1. Run complete lint check across all files
2. Ensure all 4 failures are resolved
3. No new issues introduced

---

## Implementation Order

1. ✅ **DONE:** Failure #1 (docs/planning deletion)
2. **Next:** Failure #2 (playbooks/validate_vm_configuration.yml)
3. **Then:** Failure #4 (vm-test-infrastructure/phase1-local-linux/validate-phase1.yml)
4. **Finally:** Failure #3 (vm-test-infrastructure/.../network-config.yml)

**Reasoning:** Fix the similar issues (#2 and #4) together, then tackle the YAML syntax issue separately.

---

## Success Criteria

- [ ] All 4 CI failures resolved
- [ ] `ansible-lint` passes without errors
- [ ] `molecule test` for os_configuration still passes
- [ ] No new CI failures introduced
- [ ] Changes committed with proper commit messages

**After completion:** Proceed with os_configuration Phase 1 improvements per our validation plan.

---

*This systematic approach ensures we fix CI issues without introducing regressions and maintain our baseline os_configuration functionality.*
