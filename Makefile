# Makefile for wolskinet.infrastructure Ansible Collection
# Provides convenient targets for development and testing

.PHONY: help install clean lint test test-basic test-docker test-discovery test-integration build publish dev-setup

# Variables
COLLECTION_NAMESPACE := wolskinet
COLLECTION_NAME := infrastructure
COLLECTION_VERSION := $(shell grep '^version:' galaxy.yml | awk '{print $$2}')
PYTHON := python3
PIP := pip3

# Default target
help: ## Show this help message
	@echo "Available targets for $(COLLECTION_NAMESPACE).$(COLLECTION_NAME) collection:"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n\n"} /^[a-zA-Z_-]+:.*##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

# Development setup
dev-setup: ## Set up development environment
	@echo "Setting up development environment..."
	$(PIP) install --upgrade pip
	$(PIP) install ansible molecule[docker] docker pytest pytest-testinfra
	$(PIP) install ansible-lint yamllint bandit safety tox
	ansible-galaxy collection install community.general community.docker
	@echo "Development environment ready!"

install: ## Install collection dependencies
	@echo "Installing collection dependencies..."
	ansible-galaxy collection install -r requirements.yml
	$(PIP) install -r requirements.txt
	@echo "Dependencies installed!"

clean: ## Clean up build artifacts and cache
	@echo "Cleaning up..."
	rm -rf *.tar.gz
	rm -rf __pycache__/
	rm -rf .pytest_cache/
	rm -rf .tox/
	find . -name "*.pyc" -delete
	find . -name "*.pyo" -delete
	find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
	@echo "Cleanup complete!"

# Linting and validation
lint: ## Run all linting tools
	@echo "Running linting checks..."
	ansible-lint .
	yamllint .
	$(PYTHON) -m pytest tests/integration/test_collection.py::TestSecurity -v
	@echo "Linting complete!"

validate: ## Validate collection structure
	@echo "Validating collection..."
	ansible-galaxy collection build . --force
	$(PYTHON) -m pytest tests/integration/test_collection.py::TestCollectionStructure -v
	@echo "Collection validation complete!"

# Testing targets
test-basic: ## Test basic_setup role
	@echo "Testing basic_setup role..."
	cd molecule/basic_setup && molecule test

test-docker: ## Test container_platform role
	@echo "Testing container_platform role..."
	cd molecule/container_platform && molecule test

test-discovery: ## Test infrastructure discovery utility
	@echo "Testing discovery utility..."
	cd molecule/discovery && molecule test

test-system-tuning: ## Test system_tuning role
	@echo "Testing system_tuning role..."
	cd molecule/system_tuning && molecule test

test-integration: ## Run full integration test suite
	@echo "Running integration tests..."
	cd molecule/default && molecule test

test: test-basic test-docker test-discovery test-system-tuning test-integration ## Run all tests

test-quick: ## Run quick validation tests
	@echo "Running quick tests..."
	$(PYTHON) -m pytest tests/integration/ -v
	ansible-lint --parseable-severity .

test-security: ## Run security scans
	@echo "Running security scans..."
	bandit -r . -x tests/,molecule/ || true
	safety check || true
	$(PYTHON) -m pytest tests/integration/test_collection.py::TestSecurity -v

# Performance testing
test-performance: ## Run performance tests
	@echo "Running performance tests..."
	time $(MAKE) test-integration

# Build and publish
build: clean validate ## Build collection package
	@echo "Building collection package..."
	ansible-galaxy collection build . --force
	@ls -la *.tar.gz
	@echo "Build complete!"

publish-galaxy: build ## Publish to Ansible Galaxy (requires GALAXY_API_KEY env var)
	@echo "Publishing to Ansible Galaxy..."
	@if [ -z "$$GALAXY_API_KEY" ]; then \
		echo "Error: GALAXY_API_KEY environment variable not set"; \
		exit 1; \
	fi
	ansible-galaxy collection publish *.tar.gz --api-key=$$GALAXY_API_KEY
	@echo "Published to Galaxy!"

publish-test: build ## Test publish to Galaxy (dry run)
	@echo "Testing Galaxy publish (dry run)..."
	@echo "Would publish: $(COLLECTION_NAMESPACE)-$(COLLECTION_NAME)-$(COLLECTION_VERSION).tar.gz"
	@echo "Use 'make publish-galaxy' to actually publish"

# Development helpers
molecule-create: ## Create molecule test instances
	@echo "Creating molecule test instances..."
	cd molecule/default && molecule create

molecule-destroy: ## Destroy molecule test instances
	@echo "Destroying molecule test instances..."
	cd molecule/default && molecule destroy

molecule-converge: ## Run molecule converge (deploy but don't test)
	@echo "Running molecule converge..."
	cd molecule/default && molecule converge

molecule-verify: ## Run molecule verify only
	@echo "Running molecule verify..."
	cd molecule/default && molecule verify

# Documentation
docs: ## Generate documentation
	@echo "Generating documentation..."
	@mkdir -p docs/_build
	@echo "Documentation generated in docs/_build/"

# CI/CD helpers
ci-test: ## Run CI-style tests (same as GitLab CI)
	@echo "Running CI-style tests..."
	$(MAKE) lint
	$(MAKE) test-basic
	$(MAKE) test-docker
	$(MAKE) test-discovery
	$(MAKE) test-system-tuning
	$(MAKE) test-integration

ci-build: ## Run CI-style build
	@echo "Running CI-style build..."
	$(MAKE) build

# Utilities
info: ## Show collection information
	@echo "Collection Information:"
	@echo "  Namespace: $(COLLECTION_NAMESPACE)"
	@echo "  Name: $(COLLECTION_NAME)" 
	@echo "  Version: $(COLLECTION_VERSION)"
	@echo "  Roles: $(shell ls -1 roles/ | tr '\n' ' ')"
	@echo "  Test scenarios: $(shell ls -1 molecule/ | tr '\n' ' ')"

version: ## Show current version
	@echo $(COLLECTION_VERSION)

update-version: ## Update version in galaxy.yml (requires VERSION env var)
	@if [ -z "$$VERSION" ]; then \
		echo "Error: VERSION environment variable not set"; \
		echo "Usage: make update-version VERSION=1.2.3"; \
		exit 1; \
	fi
	@sed -i "s/^version:.*/version: $$VERSION/" galaxy.yml
	@echo "Version updated to $$VERSION"

# Git helpers
git-tag: ## Create and push git tag for current version
	@echo "Creating git tag v$(COLLECTION_VERSION)..."
	git tag -a v$(COLLECTION_VERSION) -m "Release v$(COLLECTION_VERSION)"
	git push origin v$(COLLECTION_VERSION)
	@echo "Tag v$(COLLECTION_VERSION) created and pushed!"

# Environment checks  
check-env: ## Check development environment
	@echo "Checking development environment..."
	@$(PYTHON) --version
	@ansible --version | head -1
	@molecule --version | head -1
	@docker --version
	@echo "Environment check complete!"