# Justfile for wolskies.infrastructure Ansible Collection Development

# Default recipe to display help
default:
    @just --list

# Initialize the development environment
init:
    uv sync --all-extras
    uv run pre-commit install
    @echo "Development environment initialized"
    @echo "Run 'just --list' to see available commands"

# Install dependencies
install:
    uv sync

# Install with all optional dependencies
install-all:
    uv sync --all-extras

# Install with documentation dependencies
install-docs:
    uv sync --extra docs

# Install with dev dependencies
install-dev:
    uv sync --extra dev

# =============================================================================
# LINTING AND VALIDATION
# =============================================================================

# Run ansible-lint on the collection
lint:
    uv run ansible-lint

# Run yamllint on all YAML files
yamllint:
    uv run yamllint .

# Validate all Jinja2 templates
validate-templates:
    @echo "Validating Jinja2 templates..."
    @find roles -name "*.j2" -type f | xargs python3 scripts/validate_templates.py

# Run all linters
lint-all: lint yamllint validate-templates

# Check Ansible syntax for all roles
syntax-check:
    #!/usr/bin/env bash
    echo "Checking syntax for all roles..."
    for role in roles/*/; do
        role_name=$(basename "$role")
        echo "Checking $role_name..."
        if [ -f "$role/tests/test.yml" ]; then
            ansible-playbook --syntax-check "$role/tests/test.yml" 2>/dev/null || echo "  No valid test playbook"
        else
            echo "  Creating temporary syntax check..."
            echo "---" > /tmp/syntax-check-$role_name.yml
            echo "- hosts: localhost" >> /tmp/syntax-check-$role_name.yml
            echo "  gather_facts: false" >> /tmp/syntax-check-$role_name.yml
            echo "  tasks:" >> /tmp/syntax-check-$role_name.yml
            echo "    - ansible.builtin.include_role:" >> /tmp/syntax-check-$role_name.yml
            echo "        name: $role_name" >> /tmp/syntax-check-$role_name.yml
            ansible-playbook --syntax-check /tmp/syntax-check-$role_name.yml && echo "  ✓ Syntax OK" || echo "  ✗ Syntax error"
            rm -f /tmp/syntax-check-$role_name.yml
        fi
    done

# Run pre-commit hooks on all files
pre-commit:
    uv run pre-commit run --all-files

# Update pre-commit hooks
pre-commit-update:
    uv run pre-commit autoupdate

# =============================================================================
# TESTING - MOLECULE (ROLE-LEVEL)
# =============================================================================

# Run molecule tests for a specific role
molecule-test role:
    cd roles/{{role}} && uv run molecule test

# Run molecule converge for a specific role (useful for development)
molecule-converge role:
    cd roles/{{role}} && uv run molecule converge

# Run molecule verify for a specific role
molecule-verify role:
    cd roles/{{role}} && uv run molecule verify

# Run molecule destroy for a specific role
molecule-destroy role:
    cd roles/{{role}} && uv run molecule destroy

# Login to molecule container for a specific role
molecule-login role instance:
    cd roles/{{role}} && uv run molecule login -h {{instance}}

# =============================================================================
# TESTING - COLLECTION-LEVEL
# =============================================================================

# Run pytest unit tests
test-unit:
    uv run pytest tests/unit/ -v

# Run collection-level molecule test (minimal scenario)
test-minimal:
    uv run molecule test -s minimal

# Run collection-level molecule test (configure_system scenario)
test-system:
    uv run molecule test -s configure_system

# Run collection-level molecule test (vm_test scenario)
test-vm:
    uv run molecule test -s vm_test

# Run quick validation tests (fast feedback)
test-quick: lint syntax-check
    @echo "⚡ Running quick validation tests..."

# Run comprehensive test suite
test: pre-commit test-unit test-minimal test-system
    @echo "✅ Complete test suite passed!"

# Run CI-style complete testing
ci-test: lint-all syntax-check test
    @echo "✅ CI test suite completed!"

# =============================================================================
# COLLECTION BUILD AND INSTALL
# =============================================================================

# Build the collection tarball for Galaxy
build:
    ansible-galaxy collection build --force

# Build and install the collection locally
install-local: build
    ansible-galaxy collection install wolskies-infrastructure-*.tar.gz --force

# Update version in galaxy.yml
update-version VERSION:
    @sed -i 's/^version: .*/version: {{VERSION}}/' galaxy.yml
    @echo "Updated version to {{VERSION}}"

# Show collection info
info:
    @echo "Collection Information:"
    @grep -E "^(namespace|name|version):" galaxy.yml

# =============================================================================
# DOCUMENTATION
# =============================================================================

# Generate role documentation from metadata
docs-generate:
    @echo "Generating role documentation from metadata..."
    python3 scripts/generate_enhanced_docs.py
    python3 scripts/generate_collection_docs.py
    @echo "Documentation generated successfully"

# Build Sphinx documentation
docs-build: docs-generate
    @echo "Building Sphinx documentation..."
    cd docs && uv run make html
    @echo "Documentation built! Open docs/_build/html/index.html"

# Serve documentation locally
docs-serve:
    @echo "Serving documentation at http://localhost:8000"
    cd docs/_build/html && python3 -m http.server 8000

# Clean documentation build artifacts
docs-clean:
    @echo "Cleaning documentation build..."
    rm -rf docs/_build/
    rm -rf docs/generated/
    @echo "Documentation artifacts removed"

# Build and serve documentation
docs: docs-build docs-serve

# =============================================================================
# CLEANUP
# =============================================================================

# Clean up temporary files and caches
clean:
    rm -rf build/
    rm -rf *.tar.gz
    rm -rf docs/_build/
    rm -rf tests/output/
    find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
    find . -type d -name .pytest_cache -exec rm -rf {} + 2>/dev/null || true
    find . -type d -name .mypy_cache -exec rm -rf {} + 2>/dev/null || true
    find . -type f -name "*.pyc" -delete
    rm -rf .tox/
    rm -rf .coverage
    rm -rf htmlcov/
    rm -rf *.egg-info
    @echo "Cleanup complete"

# Deep clean (includes uv cache and venv)
clean-all: clean
    rm -rf .venv/
    rm -rf .cache/
    @echo "Deep cleanup complete"

# =============================================================================
# DEVELOPMENT HELPERS
# =============================================================================

# Set up development environment (one-time setup)
dev-setup:
    @echo "Installing uv if not present..."
    @command -v uv >/dev/null 2>&1 || curl -LsSf https://astral.sh/uv/install.sh | sh
    @echo "Installing just if not present..."
    @command -v just >/dev/null 2>&1 || echo "Please install just: https://github.com/casey/just#installation"
    @echo "Initializing development environment..."
    just init
    @echo "Development environment ready!"

# Create a new role with molecule
create-role name:
    mkdir -p roles/{{name}}
    cd roles/{{name}} && uv run molecule init scenario -r {{name}}
    @echo "Role {{name}} created with molecule scenario"

# Validate the collection (lint + syntax + test)
validate: lint-all syntax-check test

# Prepare for release (validate + build)
release: validate build
    @echo "Collection ready for release!"
    @ls -lh *.tar.gz

# Run sanity checks
sanity:
    ansible-test sanity --docker default

# Format Python code
format:
    uv run black scripts/ tests/
    uv run isort scripts/ tests/
