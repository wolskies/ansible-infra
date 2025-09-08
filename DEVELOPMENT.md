# Development Setup Guide

This document explains how to set up your local development environment for the `wolskinet.infrastructure` Ansible collection.

## Prerequisites

- Python 3.11+ (3.13+ recommended)
- Ansible 8.0+
- Docker (for molecule testing)

## Local Development Setup

### 1. Install System Dependencies

#### Arch Linux

```bash
# Install Ansible and development tools
sudo pacman -S ansible ansible-lint yamllint docker
sudo systemctl enable --now docker
sudo usermod -aG docker $USER  # logout/login after this
```

#### Ubuntu/Debian

```bash
# Install Ansible and development tools
sudo apt update
sudo apt install ansible ansible-lint yamllint docker.io
sudo systemctl enable --now docker
sudo usermod -aG docker $USER  # logout/login after this
```

#### macOS (Homebrew)

```bash
# Install Ansible and development tools
brew install ansible ansible-lint yamllint
# Docker Desktop needs to be installed separately from https://docker.com
```

#### Alternative: uv approach (if package managers don't have latest versions)

```bash
# Only use this if your package manager has outdated ansible versions
# Install uv first: curl -LsSf https://astral.sh/uv/install.sh | sh
uv venv ~/.ansible-dev
source ~/.ansible-dev/bin/activate
uv pip install ansible>=8.0 ansible-lint yamllint
# Add ~/.ansible-dev/bin to your PATH in your shell config
```

### 2. Install Collection Dependencies

```bash
# Install required collections
ansible-galaxy collection install -r requirements.yml
```

### 3. Install Python Development Dependencies (Optional)

```bash
# For advanced development (linting, testing, etc.)
# Only install if you need molecule testing or additional dev tools

# If using package manager ansible:
uv pip install --user molecule[docker] pytest

# If using uv venv approach:
source ~/.ansible-dev/bin/activate
uv pip install -r requirements-dev.txt
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

- **Use OS package managers:** Prefer `pacman`, `apt`, or `brew` over global pip
- **NO .venv directory:** Keep project directory clean (unless using ~/.ansible-dev)
- **NO .ansible directory:** Collections are installed system-wide or in ~/.ansible
- **CI vs Local:** CI uses fresh venv + `ansible-ci.cfg`, local uses system tools
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
