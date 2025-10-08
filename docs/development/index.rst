Development Guide
=================

Documentation for contributing to and developing the ``wolskies.infrastructure`` collection.

.. contents::
   :local:
   :depth: 1

Overview
--------

This section covers:

* Development workflow and processes
* Contributing guidelines
* Test-Driven Development approach
* Code standards and best practices

Getting Started
---------------

Prerequisites
~~~~~~~~~~~~~

* Ansible 2.12+
* Python 3.9+
* Docker (for testing)
* Git

Setup Development Environment
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # Clone repository
   git clone https://gitlab.wolskinet.com/ansible/collections/infrastructure.git
   cd infrastructure

   # Install dependencies
   ansible-galaxy collection install -r requirements.yml
   pip install molecule[docker] molecule-plugins[docker] pytest-testinfra

   # Install pre-commit hooks
   pre-commit install

Core Principles
---------------

Development Philosophy
~~~~~~~~~~~~~~~~~~~~~~

1. **Requirements-driven** - All changes trace to specific requirements
2. **Test-first** - Write/update tests before production code
3. **Incremental validation** - Test each change before proceeding
4. **No broken states** - Every commit must pass all tests
5. **Systematic approach** - Work role-by-role, requirement-by-requirement

Code Standards
~~~~~~~~~~~~~~

* Follow Ansible best practices
* Use ``ansible-lint`` for validation
* Write idempotent tasks
* Document complex logic
* Keep roles focused and single-purpose

Development Sections
--------------------

.. toctree::
   :maxdepth: 1

   workflow
   contributing
   tdd-process

Quick Reference
---------------

Common Commands
~~~~~~~~~~~~~~~

.. code-block:: bash

   # Run tests
   just test
   just molecule-test manage_packages

   # Validation
   ansible-lint
   pre-commit run --all-files

   # Build collection
   ansible-galaxy collection build

See Also
--------

* :doc:`../testing/index` - Testing guide
* :doc:`workflow` - Development workflow details
* :doc:`contributing` - Contribution guidelines
