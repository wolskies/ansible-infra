# CLAUDE.md

Project guidance for Claude Code when working with the `wolskinet.infrastructure` Ansible Collection.

## Key Principles

**Target Users**: Moderately experienced - no excessive warnings or defensive programming
**Supported OS**: Ubuntu 22+, Debian 12+, Arch Linux, macOS
**Philosophy**: Use existing modules/roles over custom implementations

- **Comments**: Only for non-standard implementations, not obvious functionality
- **Module preference**: Use existing ansible.builtin/community.general over custom code
- **Command usage**: `ansible.builtin.command` as last resort, `ansible.builtin.shell` requires explicit permission
- **Repository management**: ALWAYS use `ansible.builtin.deb822_repository` (apt_repository is deprecated and will fail)

## Critical Rules

**NEVER change production code to make tests pass without investigation first**
**ALWAYS investigate if test failure indicates setup issue vs production bug**

## Testing Strategy

### Core Testing Principles
- **No test-specific production code** - Never add `when: not molecule_test` conditionals
- **Tags for container limits** - Use `skip-tags: hostname,docker-compose` for container issues
- **Semantic failures** - Let roles fail properly rather than masking issues
- **Individual role tests over integration-only** - Every role gets its own test
- **VM vs container testing** - Use delegated driver for VM testing when containers insufficient

### Test Types by Role Complexity

1. **Simple roles** → `roles/{role-name}/molecule/default/` tests
   - Focus: Role-specific functionality, packages, configuration
   - Examples: nodejs, rust, go, os_configuration, manage_packages

2. **Orchestrating roles** → `molecule/test-integration/` tests
   - Focus: Role interactions, cross-dependencies, end-to-end workflows
   - Examples: configure_system (calls multiple roles)

3. **Integration tests don't repeat individual role testing**

### Development Test Flow

**Required sequence** (each phase should catch issues before the next):
1. `ansible-lint` - syntax/standards validation
2. `molecule converge` - role functionality testing during development
3. `pre-commit` - formatting, linting, custom hooks
4. **CI** - identical to local molecule tests

**Test Contract**: Individual role tests are authoritative. If role tests pass but integration fails → investigate missing role test coverage, not integration code.

## Current Implementation Status (Sept 2025)

**Individual role tests completed**: nodejs, rust, go, neovim, terminal_config
**Still in integration**: os_configuration, manage_packages, manage_security_services, configure_user
**CI pipeline**: 5 parallel role tests + test-integration + test-discovery + test-minimal

## Environment Requirements

**Ansible config**: `ANSIBLE_HASH_BEHAVIOUR=merge` required for variable merging
**Collections**: Run `ansible-galaxy collection install -r requirements.yml` before testing
**Local development**: Use `cd roles/{name} && molecule converge` for quick testing

## Common Issues & Solutions

**PATH problems**: Language roles install to user directories - ensure verification uses correct PATH
**Container limits**: Use `skip-tags: terminal-config,hostname,docker-compose` for container tests
**Fresh systems**: Always use `update_cache: true` for apt tasks
**deb822_repository**: Requires `python3-debian` package prerequisite
