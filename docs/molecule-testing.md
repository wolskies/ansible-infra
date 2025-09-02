# Molecule Testing Guide

This guide covers local molecule testing for the wolskinet.infrastructure collection.

## Available Test Scenarios

### Core Scenarios
- **`default`**: Basic collection functionality testing
- **`discovery`**: Discovery role specific tests with idempotence validation
- **`comprehensive-integration`**: Full multi-role integration testing

### Role-Specific Scenarios
- **`packages`**: Package management testing
- **`users`**: User management testing
- **`dotfiles`**: Dotfiles configuration testing
- **`firewall`**: Firewall configuration testing
- **`system_settings`**: System settings management testing
- **`language_packages`**: Language package management testing

## Running Tests Locally

### Quick Development Testing
```bash
# Fast validation tests (discovery role)
make test-quick

# Specific role testing
make test-discovery
molecule test -s packages
molecule test -s users
```

### Comprehensive Testing
```bash
# Full integration test suite
make test-integration

# All available tests
make test
```

### Development Workflow
```bash
# Create test instances
molecule create -s discovery

# Deploy without testing
molecule converge -s discovery

# Run tests only
molecule verify -s discovery

# Clean up
molecule destroy -s discovery
```

## Test Configuration

### Standard Variables
All molecule scenarios should include:
```yaml
provisioner:
  name: ansible
  inventory:
    group_vars:
      all:
        ansible_user: root
        # Enable consistent behavior for molecule tests
        molecule_test: true
```

### Discovery Role Testing
The discovery role uses static filenames during testing to ensure idempotence:
- Production: `vars.discovered.{timestamp}`
- Testing: `vars.discovered` (static)

## CI/CD Integration

Local tests should match CI/CD behavior:
- Use same Docker images as CI (`geerlingguy/docker-ubuntu2404-ansible:latest`)
- Include `molecule_test: true` for consistent behavior
- Test idempotence with static configurations

## Troubleshooting

### Common Issues
1. **Docker permission issues**: Ensure Docker daemon is running
2. **Idempotence failures**: Check for dynamic content in templates
3. **Missing dependencies**: Run `make deps` to install requirements

### Debug Mode
Enable debug output:
```bash
# Set discovery debug mode
export MOLECULE_DEBUG=true
molecule test -s discovery
```

## Best Practices

1. **Always test idempotence**: Molecule runs tasks twice to ensure no changes on second run
2. **Use static test data**: Avoid timestamps and random data in tests
3. **Test multiple platforms**: Use different Docker images for coverage
4. **Clean up regularly**: Run `molecule destroy` to clean test environments
