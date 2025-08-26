# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is an **Ansible Collection** (`wolskinet.infrastructure`) that provides infrastructure automation roles for multi-OS environments (Ubuntu 24+, Debian 12/13, Arch Linux, macOS). The collection follows an inventory-group-based architecture where machines are configured based on their group membership.

## Core Architecture

### Group-Based Configuration Pattern
- **`servers`**: Security hardening + basic setup + system maintenance
- **`docker_hosts`**: Server features + Docker installation + container services
- **`workstations`**: Basic setup + dotfiles + desktop configurations
- **Custom groups**: User-defined combinations

### Role Structure
Each role in `roles/` follows Ansible best practices:
- `tasks/main.yml`: Entry point with OS detection and delegation
- `tasks/basic-{OS_Family}.yml`: OS-specific implementation
- `vars/{Distribution}.yml`: OS-specific variables
- `defaults/main.yml`: Default variables
- `meta/main.yml`: Role metadata and dependencies

## Discovery Role Output Paths

The discovery role outputs files to your standard Ansible project structure:
- **Host Variables**: `inventory/host_vars/{hostname}.yml`
- **Deployment Playbook**: `playbooks/{hostname}_discovered.yml`

When running discovery from your project root:
```bash
# Example usage
ansible-playbook playbooks/run-discovery.yml -i inventory/inventory.yml -l target-host --ask-become-pass
```

Files will be created in your existing `inventory/` and `playbooks/` directories.

## Development Commands

### Build and Testing
```bash
# Quick development workflow
make lint                    # Run ansible-lint, yamllint, security checks
make test-quick             # Fast validation tests
make build                  # Build collection package

# Comprehensive testing
make test                   # Run all molecule tests (basic_setup, container_platform, discovery, integration)
make test-basic             # Test basic_setup role only
make test-docker            # Test container_platform role only
make test-integration       # Full integration test suite

# Development environment setup
make dev-setup              # Install all development dependencies
make check-env              # Verify development environment
```

### Molecule Testing
```bash
# Individual test scenarios
cd molecule/basic_setup && molecule test
cd molecule/container_platform && molecule test
cd molecule/discovery && molecule test
cd molecule/default && molecule test

# Development workflow
make molecule-create        # Create test instances
make molecule-converge      # Deploy without testing
make molecule-verify        # Run tests only
make molecule-destroy       # Clean up instances
```

### Python Testing
```bash
# Integration tests
pytest tests/integration/ -v

# Security and lint via tox
tox -e lint                 # Run ansible-lint, yamllint, flake8, bandit
tox -e py311-ansible8       # Test with specific Python/Ansible versions
```

## Key Files and Directories

### Collection Structure
- `galaxy.yml`: Collection metadata and dependencies
- `roles/`: Collection roles (basic_setup, container_platform, dotfiles, maintenance)
- `examples/`: Sample inventories and playbooks
- `molecule/`: Test scenarios for different use cases
- `utilities/`: Infrastructure discovery and management tools

### Configuration Files
- `Makefile`: Primary development commands
- `tox.ini`: Python testing environments and CI configuration
- `pytest.ini`: Python test configuration
- `.ansible-lint`: Ansible linting rules (if present)
- `yamllint.yml`: YAML linting configuration (if present)

### Example Usage Patterns
- `examples/inventory/`: Complete inventory structure examples
- `examples/playbooks/deploy-full-infrastructure.yml`: Main deployment playbook
- `examples/playbooks/setup-{type}.yml`: Role-specific playbooks

## Development Workflow

### Adding New Roles
1. Create role structure: `ansible-galaxy init roles/new_role`
2. Follow existing patterns in `roles/basic_setup/tasks/main.yml`
3. Implement OS-specific tasks in `tasks/basic-{OS_Family}.yml`
4. Add OS-specific variables in `vars/{Distribution}.yml`
5. Create molecule test scenario in `molecule/new_role/`
6. Test with `make test-{role_name}`

### Inventory Group Architecture
When modifying or extending:
- Group variables define role combinations: `group_vars/{group}.yml`
- Host variables handle machine-specific settings: `host_vars/{host}.yml`
- Use `group_roles_install` for collection roles
- Use `additional_roles_install` for external roles

### Testing New Features
1. Use `molecule/default` for integration testing
2. Create specific scenarios in `molecule/` for role-specific testing
3. Run `make test-quick` for fast feedback during development
4. Run full `make test` before committing

## Version and Release Management

```bash
# Version management
make version                        # Show current version
make update-version VERSION=1.2.3  # Update version in galaxy.yml
make git-tag                        # Create and push git tag

# Publishing
make publish-test                   # Dry run publish
make publish-galaxy                 # Publish to Ansible Galaxy (requires GALAXY_API_KEY)
```

## Package Management Architecture

### Hierarchical Package Variables
The collection uses OS-specific hierarchical package variables for maximum flexibility:

```yaml
# group_vars/all/<Distribution>.yml - Global packages for all machines
all_packages_install_Ubuntu:
  - htop
  - vim

# group_vars/servers/<Distribution>.yml - Server group packages  
group_packages_install_Ubuntu:
  - nginx
  - certbot

# host_vars/web-01/<Distribution>.yml - Host-specific packages
host_packages_install_Ubuntu:
  - redis-server

# Generated by discovery (host_vars/<host>.yml)
host_packages_install_Ubuntu:
  - curl
  - git
```

### Variable Merging Order
1. **all_packages_install_\<Distribution>** (group_vars/all)
2. **group_packages_install_\<Distribution>** (group_vars/\<group>)
3. **host_packages_install_\<Distribution>** (host_vars/\<host>, includes discovery)

All lists are merged with duplicates removed. Package names are distribution-specific.

### Supported Distributions
- `packages_install_Ubuntu` / `packages_install_Debian`
- `packages_install_Archlinux`
- `packages_install_Darwin` (macOS)

## Security and Secrets

- Use Ansible Vault for sensitive data: `ansible-vault create group_vars/all/vault.yml`
- Never commit unencrypted secrets or API keys
- Reference vault variables in plain YAML: `password: "{{ vault_user_password }}"`
- See `docs/vault-secrets-guide.md` for complete secrets management

## CI/CD Integration

```bash
# CI-style commands
make ci-test                # Complete CI test suite
make ci-build               # CI-style build process
```

The collection supports multiple Python (3.9-3.12) and Ansible (6-8) versions via tox configuration.