# Makefile for wolskinet.infrastructure Ansible Collection
# Provides convenient commands for development, testing, and maintenance

.PHONY: help
help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: deps
deps: ## Install Python dependencies
	pip install -r requirements-dev.txt

.PHONY: lint
lint: lint-yaml lint-ansible ## Run all linting checks

.PHONY: lint-yaml
lint-yaml: ## Run yamllint on all YAML files
	yamllint .

.PHONY: lint-ansible
lint-ansible: ## Run ansible-lint on all playbooks and roles
	ansible-lint

.PHONY: syntax-check
syntax-check: ## Check Ansible syntax for all roles
	@echo "Checking syntax for all roles..."
	@for role in roles/*/; do \
		role_name=$$(basename "$$role"); \
		echo "Checking $$role_name..."; \
		if [ -f "$$role/tests/test.yml" ]; then \
			ansible-playbook --syntax-check "$$role/tests/test.yml" 2>/dev/null || echo "  No valid test playbook"; \
		else \
			echo "  Creating temporary syntax check..."; \
			echo "---" > /tmp/syntax-check-$$role_name.yml; \
			echo "- hosts: localhost" >> /tmp/syntax-check-$$role_name.yml; \
			echo "  gather_facts: false" >> /tmp/syntax-check-$$role_name.yml; \
			echo "  tasks:" >> /tmp/syntax-check-$$role_name.yml; \
			echo "    - ansible.builtin.include_role:" >> /tmp/syntax-check-$$role_name.yml; \
			echo "        name: $$role_name" >> /tmp/syntax-check-$$role_name.yml; \
			ansible-playbook --syntax-check /tmp/syntax-check-$$role_name.yml && echo "  ✓ Syntax OK" || echo "  ✗ Syntax error"; \
			rm -f /tmp/syntax-check-$$role_name.yml; \
		fi \
	done

.PHONY: test
test: ## Run all molecule tests
	molecule test

.PHONY: test-discovery
test-discovery: ## Run molecule tests for discovery role
	cd molecule/discovery && molecule test

.PHONY: test-basic
test-basic: ## Run molecule tests for basic_setup role
	cd molecule/basic_setup && molecule test

.PHONY: test-container
test-container: ## Run molecule tests for container_platform role
	cd molecule/container_platform && molecule test

.PHONY: test-quick
test-quick: lint syntax-check ## Quick validation (lint + syntax check)
	@echo "Quick validation completed!"

.PHONY: molecule-create
molecule-create: ## Create molecule test instances
	molecule create

.PHONY: molecule-converge
molecule-converge: ## Run molecule converge (deploy without full test)
	molecule converge

.PHONY: molecule-verify
molecule-verify: ## Run molecule verify only
	molecule verify

.PHONY: molecule-destroy
molecule-destroy: ## Destroy molecule test instances
	molecule destroy

.PHONY: molecule-login
molecule-login: ## Login to molecule instance (requires instance name)
	@echo "Usage: make molecule-login INSTANCE=ubuntu-discovery"
	@if [ -z "$(INSTANCE)" ]; then \
		echo "Error: INSTANCE variable not set"; \
		echo "Available instances:"; \
		molecule list; \
		exit 1; \
	fi
	molecule login -h $(INSTANCE)

.PHONY: ci
ci: lint syntax-check test ## Run full CI pipeline

.PHONY: clean
clean: ## Clean up temporary files and caches
	find . -type f -name "*.pyc" -delete
	find . -type d -name "__pycache__" -delete
	find . -type d -name ".pytest_cache" -delete
	rm -rf .tox/
	rm -rf .coverage
	rm -rf htmlcov/
	rm -rf *.egg-info

.PHONY: collection-build
collection-build: ## Build the Ansible collection
	ansible-galaxy collection build --force

.PHONY: collection-install
collection-install: collection-build ## Build and install the collection locally
	ansible-galaxy collection install wolskinet-infrastructure-*.tar.gz --force

.PHONY: update-version
update-version: ## Update version in galaxy.yml (usage: make update-version VERSION=1.2.3)
	@if [ -z "$(VERSION)" ]; then \
		echo "Error: VERSION not specified"; \
		echo "Usage: make update-version VERSION=1.2.3"; \
		exit 1; \
	fi
	sed -i 's/^version: .*/version: $(VERSION)/' galaxy.yml
	@echo "Updated version to $(VERSION)"

.PHONY: validate-discovery
validate-discovery: ## Validate discovery role against test inventory
	cd utilities/playbooks && \
	ansible-playbook -i inventory/hosts.yml validate-discovery.yml

.PHONY: dev-setup
dev-setup: ## Set up development environment
	python -m venv .venv
	. .venv/bin/activate && pip install --upgrade pip
	. .venv/bin/activate && pip install -r requirements-dev.txt
	@echo "Development environment ready. Activate with: source .venv/bin/activate"