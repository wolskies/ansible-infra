# CI/CD Configuration Guide

This directory contains the GitLab CI/CD configuration and supporting files for the wolskinet.infrastructure Ansible Collection.

## Overview

The CI/CD pipeline implements a comprehensive 4-stage testing strategy:

1. **Step 1: Linting** - Code quality and syntax validation
2. **Step 2: Molecule Scenarios** - Individual role and integration testing
3. **Step 3: GitLab CI/CD** - Automated pipeline execution
4. **Step 4: Live Machine Testing** - Manual testing on real infrastructure

## Pipeline Stages

### 1. Validation Stage
- YAML syntax validation
- Ansible syntax checking
- Collection build validation
- Fast feedback loop for basic issues

### 2. Linting Stage
- `ansible-lint` for Ansible best practices
- `yamllint` for YAML formatting
- Template validation for Jinja2 templates
- Security scanning for secrets/passwords

### 3. Unit Test Stage
- Individual molecule tests for each role
- Docker container-based testing
- Critical roles must pass (users, security, firewall, packages)
- Optional roles allow failure (snap, flatpak - container limitations)

### 4. Integration Test Stage
- Full system integration testing
- Multi-OS compatibility validation
- Server and workstation configurations
- Cross-role interaction verification

### 5. Security Test Stage
- Security hardening validation
- Firewall rule testing
- Secret detection scanning
- fail2ban and UFW integration tests

### 6. Live Test Stage (Manual)
- Testing on actual Ubuntu/Debian machines
- Dry-run deployments with `--check` flag
- Production deployment (manual approval required)

### 7. Build & Deploy Stages
- Collection package creation
- Ansible Galaxy publishing (tagged releases)
- GitHub/GitLab release creation
- Artifact management

## Configuration Files

### `.gitlab-ci.yml`
Main pipeline configuration with:
- Multi-stage testing pipeline
- Docker-in-Docker molecule testing
- Live machine testing support
- Automated collection publishing

### `test-matrix.yml`
Multi-OS testing matrix defining:
- Supported operating systems (Ubuntu 22.04/24.04, Debian 12/13)
- Test scenarios (server minimal/full, workstation minimal/full)
- Critical vs extended test combinations
- Security and performance test suites

## Required GitLab Variables

Configure these in your GitLab project settings:

### For Molecule Testing (Automatic)
- No additional variables required - uses Docker-in-Docker

### For Live Machine Testing (Optional)
- `SSH_PRIVATE_KEY`: SSH private key for accessing test machines
- `SSH_KNOWN_HOSTS`: Known hosts file content for SSH
- `LIVE_TEST_INVENTORY_UBUNTU`: Inventory file path for Ubuntu test machines
- `LIVE_TEST_INVENTORY_DEBIAN`: Inventory file path for Debian test machines
- `PRODUCTION_INVENTORY`: Production inventory file path

### For Publishing (Optional)
- `GALAXY_API_KEY`: Ansible Galaxy API key for collection publishing

## Running Tests Locally

### Quick Development Workflow
```bash
# Install dependencies
make dev-setup

# Fast validation
make lint
make syntax-check

# Quick molecule test
make test-quick

# Full test suite
make test
```

### Individual Molecule Tests
```bash
# Test specific roles
cd molecule/users && molecule test
cd molecule/security && molecule test
cd molecule/firewall && molecule test

# Integration testing
cd molecule/integration && molecule test
```

### Multi-OS Testing
```bash
# Test different distributions
cd molecule/integration && MOLECULE_DISTRO=ubuntu2204 molecule test
cd molecule/integration && MOLECULE_DISTRO=debian12 molecule test
```

## Pipeline Behavior

### Merge Requests
- Runs validation, linting, and unit tests
- Skips live testing and deployment
- Must pass all critical tests to merge

### Main/Develop Branch
- Runs complete pipeline including integration tests
- Live testing available but manual
- Collection build artifacts created

### Tagged Releases
- Full pipeline execution
- Automated collection building
- Manual Ansible Galaxy publishing
- GitHub/GitLab release creation

## Troubleshooting

### Common Issues

**Docker Service Failures**
- Check GitLab runner Docker-in-Docker configuration
- Verify privileged mode is enabled for runners
- Check container resource limits

**Molecule Test Failures**
- Review molecule test logs for specific failures
- Check container networking and privileges
- Verify test data and expectations match container environment

**SSH Key Issues (Live Testing)**
- Ensure SSH private key is properly formatted in GitLab variables
- Check SSH known_hosts entries are complete
- Verify SSH access to target machines

**Collection Build Failures**
- Check galaxy.yml syntax and metadata
- Verify all required files are present
- Review build ignore patterns in galaxy.yml

### Performance Optimization

**Caching**
- Pipeline uses pip cache for faster dependency installation
- Molecule ephemeral directory cached between runs
- Python virtual environment cached per branch

**Parallel Execution**
- Unit tests run in parallel where possible
- Integration tests depend on unit test completion
- Live tests are independent and can run concurrently

**Resource Management**
- Docker containers use appropriate resource limits
- Test timeouts configured for reasonable execution times
- Retry logic for transient failures

## Extending the Pipeline

### Adding New Roles
1. Create molecule test scenario in `molecule/<role_name>/`
2. Add corresponding job in `.gitlab-ci.yml` unit-test stage
3. Update integration tests to include new role if needed

### Adding New OS Support
1. Update `test-matrix.yml` with new OS configurations
2. Create or update molecule scenarios with new OS images
3. Test locally before adding to CI/CD pipeline

### Custom Test Scenarios
1. Create new molecule scenario directory
2. Define converge, verify, and molecule configuration
3. Add pipeline job if automated testing desired

## Security Considerations

- No secrets stored in repository code
- SSH keys and API tokens managed via GitLab variables
- Security scanning prevents accidental secret commits
- Live testing uses dry-run mode by default
- Production deployments require manual approval

## Support

For issues with the CI/CD configuration:

1. Check the GitLab pipeline logs for specific error details
2. Review this documentation for configuration requirements
3. Test locally using the same molecule scenarios
4. Create an issue in the collection repository with pipeline logs
