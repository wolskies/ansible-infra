# Development Setup Guide

This document explains how to set up your local development environment for the `wolskinet.infrastructure` Ansible collection.

## Prerequisites

- Python 3.11+ (3.13+ recommended)
- Ansible 8.0+
- Docker (for molecule testing)

## Local Development Setup

### 1. Install System Dependencies

```bash
# Install Ansible and basic tools system-wide
pip install ansible>=8.0
pip install ansible-lint yamllint
```

### 2. Install Collection Dependencies

```bash
# Install required collections
ansible-galaxy collection install -r requirements.yml
```

### 3. Install Python Development Dependencies

```bash
# Install dev tools (optional, for advanced development)
pip install -r requirements-dev.txt
```

### 4. Verify Installation

```bash
# Check ansible version and collections
ansible --version
ansible-galaxy collection list | grep community.general

# Run basic linting
make lint
```

## Development Workflow

### Quick Testing
```bash
make test-quick          # Fast validation tests
make lint               # All linting checks
```

### Full Testing
```bash
make test-comprehensive  # Integration tests
molecule test -s packages  # Test specific role
```

### Before Committing
```bash
make lint               # Must pass
git add -A && git commit -m "Your message"
```

## File Structure

- `Makefile` - Development commands
- `requirements.yml` - Ansible collection dependencies
- `requirements-dev.txt` - Python development dependencies
- `ansible-ci.cfg` - CI-specific Ansible configuration
- `.ansible-lint` - Linting rules

## Important Notes

- **NO .venv directory:** We use system Python to avoid collection conflicts
- **NO .ansible directory:** Collections are installed system-wide
- **CI vs Local:** CI uses `ansible-ci.cfg`, local uses system defaults
- **Collection versions:** Always use latest from `requirements.yml`

## Troubleshooting

### "Multiple versions found" warning
```bash
# Clean and reinstall collections
ansible-galaxy collection install -r requirements.yml --force
```

### Docker issues in molecule
```bash
# Check Docker daemon
docker info
# Restart molecule test
molecule destroy -s SCENARIO && molecule test -s SCENARIO
```

### Linting failures
```bash
# Run specific linters
yamllint .
ansible-lint
make validate-templates
```
