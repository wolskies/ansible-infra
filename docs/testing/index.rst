Testing Guide
=============

Comprehensive testing documentation for the ``wolskies.infrastructure`` collection.

.. contents::
   :local:
   :depth: 2

Overview
--------

The collection uses a multi-layered testing approach:

* **Molecule Tests** - Container-based unit and integration tests
* **VM Tests** - Full-platform validation on real VMs
* **CI Pipeline** - Automated testing on every commit

Testing Approach
----------------

The collection uses a progressive testing strategy where each phase validates different aspects:

1. **Individual role tests** - Role-specific functionality and idempotence
2. **Integration tests** - Role interactions and orchestration
3. **VM tests** - Full platform validation on real systems

Test Hierarchy
--------------

Phase I: Development Testing
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Required before any commit:**

1. ``ansible-lint`` - Syntax and standards validation
2. ``molecule converge`` - Role functionality during development
3. ``molecule test`` - **MUST PASS** - Full test suite with verification
4. ``pre-commit`` - Formatting, linting, custom hooks

.. code-block:: bash

   # Development workflow
   cd roles/manage_packages
   molecule converge  # Deploy and test quickly
   molecule verify    # Run validation
   molecule test      # Full test cycle (MUST pass before commit)

Phase II: CI Testing
~~~~~~~~~~~~~~~~~~~~~

Automated on every commit:

* Individual role tests (parallel execution)
* Integration tests
* Discovery validation
* Minimal configuration testing

Phase III: VM Testing
~~~~~~~~~~~~~~~~~~~~~~

Comprehensive validation on real VMs:

* Full platform matrix (Ubuntu, Debian, Arch)
* Real-world scenario validation
* Edge case testing
* Performance validation

See :doc:`vm-testing` for details.

Test Types
----------

By Role Complexity
~~~~~~~~~~~~~~~~~~

**Simple Roles** → ``roles/{role-name}/molecule/default/``

* Focus: Role-specific functionality, packages, configuration
* Examples: nodejs, rust, go, os_configuration, manage_packages

**Orchestrating Roles** → ``molecule/test-integration/``

* Focus: Role interactions, cross-dependencies, workflows
* Examples: configure_system (orchestrates multiple roles)

**Cross-cutting Concerns** → Specialized test suites

* Discovery validation
* Security hardening verification
* Platform compatibility

Quick Start
-----------

Run All Tests
~~~~~~~~~~~~~

.. code-block:: bash

   # Using just (recommended)
   just test

   # Individual role test
   just molecule-test manage_packages

Run Specific Tests
~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # Quick validation (discovery role)
   cd roles/discovery && molecule test

   # Specific role
   cd roles/manage_packages && molecule test

   # Integration tests
   molecule test -s configure_system

Development Workflow
~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # Create test environment
   molecule create

   # Deploy configuration
   molecule converge

   # Run verification only
   molecule verify

   # Full test cycle
   molecule test

   # Clean up
   molecule destroy

Testing Sections
----------------

.. toctree::
   :maxdepth: 1

   running-tests
   molecule-architecture
   vm-testing
   writing-tests

See Also
--------

* :doc:`../development/tdd-process` - Test-Driven Development approach
* :doc:`../development/workflow` - Development workflow
