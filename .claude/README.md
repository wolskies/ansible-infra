# Claude Code Context for wolskies.infrastructure

This directory contains context files specifically for Claude Code to understand project methodology, strategy, and lessons learned.

## Purpose

These files serve two purposes:
1. **AI Context**: Help Claude Code get up to speed quickly on project decisions and methodology
2. **Internal Documentation**: Document testing strategy, lessons learned, and future plans that don't belong in public user documentation

## Files

### testing-strategy.md
**Purpose**: Testing philosophy and methodology

**Contains**:
- Core testing principles (never compromise production code for tests)
- Container vs VM testing strategy
- Test types and organization
- TDD process enforcement
- Common testing patterns and gotchas
- CI/CD integration details

**Use this when**:
- Writing new tests
- Debugging test failures
- Deciding between container and VM testing
- Understanding why tests are organized a certain way

### vm-testing-plan.md
**Purpose**: Phase III VM testing infrastructure design

**Contains**:
- Terraform + libvirt infrastructure details
- VM configuration matrix (Ubuntu 22.04/24.04, Arch, future macOS)
- Test user matrix and scenarios
- Discovery-based validation strategy
- Execution time estimates
- Implementation timeline

**Use this when**:
- Planning VM testing implementation
- Understanding Phase III goals
- Designing comprehensive test scenarios
- Deciding what to test in VMs vs containers

### lessons-learned.md
**Purpose**: Hard-won wisdom and mistakes to avoid

**Contains**:
- Testing lessons (don't change prod code for tests, etc.)
- Requirements documentation lessons
- Development workflow improvements
- Platform-specific gotchas
- Variable design lessons
- What we'd do differently

**Use this when**:
- Encountering similar issues
- Making design decisions
- Onboarding new contributors
- Avoiding repeated mistakes

### development-methodology.md
**Purpose**: Internal development processes and TDD workflow

**Contains**:
- Complete TDD red-green-refactor cycle
- Role validation workflow (analysis, planning, implementation, completion)
- Direct commits to main branching strategy
- Testing requirements and quality gates
- Commit message format and examples
- Error handling procedures
- Incremental development patterns

**Use this when**:
- Implementing new features or requirements
- Understanding the TDD process details
- Need complete workflow examples
- Making commits (reference commit message format)
- Debugging failing tests or CI

## Relationship to Other Documentation

### Public Documentation (docs/)
- **Audience**: Users, contributors
- **Purpose**: How to use the collection, run tests, contribute
- **Location**: `docs/testing/`, `docs/development/`
- **Example**: "Run `molecule test` to test a role"

### Internal Context (.claude/context/)
- **Audience**: Project maintainers, AI assistants
- **Purpose**: Why we test this way, lessons learned, strategy
- **Location**: `.claude/context/`
- **Example**: "We tried integration-only tests and they were hard to debug"

### Project Guidance (CLAUDE.md)
- **Audience**: Claude Code specifically
- **Purpose**: Real-time development guidance, rules, critical reminders
- **Location**: Root directory
- **Example**: "NEVER change production code to make tests pass"

## When to Update

### testing-strategy.md
- Change in testing approach or philosophy
- New test patterns emerge
- Container limitation discovery
- CI/CD pipeline changes

### vm-testing-plan.md
- Phase III implementation progress
- Infrastructure design changes
- New OS targets added
- Timeline adjustments

### lessons-learned.md
- New gotcha encountered
- Mistake made (document it!)
- Better approach discovered
- Platform quirk found

## Quick Reference

**Starting a new feature?** Read:
1. `CLAUDE.md` - TDD process summary, critical rules
2. `development-methodology.md` - Complete TDD workflow and examples
3. `testing-strategy.md` - How to write tests
4. `lessons-learned.md` - Common pitfalls

**Debugging a test failure?** Check:
1. `testing-strategy.md` - Common testing gotchas
2. `lessons-learned.md` - Platform-specific issues

**Planning Phase III?** Read:
1. `vm-testing-plan.md` - Complete infrastructure design
2. `testing-strategy.md` - Container vs VM strategy

## Contributing to These Files

These files should evolve as the project grows:

**Add to lessons-learned.md when**:
- You encounter a non-obvious issue
- You make a mistake worth documenting
- You discover a platform quirk
- You find a better approach

**Update testing-strategy.md when**:
- Testing methodology changes
- New patterns emerge
- CI/CD pipeline evolves

**Update vm-testing-plan.md when**:
- Phase III implementation progresses
- Infrastructure requirements change
- New OS targets planned

## Philosophy

**Keep it real**: Document what actually happened, not what we wish happened.

**Be specific**: "Tests failed because..." not "Tests can fail because..."

**Show examples**: Code snippets and error messages are more valuable than prose.

**Stay practical**: Focus on actionable information, not theory.
