Running Tests
=============

Guide to running tests locally for the ``wolskies.infrastructure`` collection.

.. contents::
   :local:
   :depth: 2

Quick Reference
---------------

.. code-block:: bash

   # Run all tests
   just test

   # Test specific role
   just molecule-test manage_packages

   # Quick validation (discovery role)
   cd roles/discovery && molecule test

   # Development workflow
   cd roles/manage_packages
   molecule create    # Create test environment
   molecule converge  # Deploy configuration
   molecule verify    # Run validation only
   molecule test      # Full test cycle
   molecule destroy   # Clean up

Prerequisites
-------------

Install Required Tools
~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # System packages
   sudo apt-get install ansible docker.io make python3-pip  # Ubuntu/Debian
   sudo pacman -S ansible docker make python-pip            # Arch Linux

   # Python packages
   pip install molecule[docker] molecule-plugins[docker] pytest-testinfra

   # Install collection dependencies
   ansible-galaxy collection install -r requirements.yml

Docker Setup
~~~~~~~~~~~~

Ensure Docker daemon is running:

.. code-block:: bash

   sudo systemctl start docker
   sudo usermod -aG docker $USER  # Add yourself to docker group
   newgrp docker                  # Activate group (or logout/login)

Test Scenarios
--------------

Core Scenarios
~~~~~~~~~~~~~~

The collection includes several test scenarios:

**Individual Role Tests** - ``roles/{role}/molecule/default/``

* Focus on role-specific functionality
* Test package installation, configuration, idempotence
* Examples: manage_packages, os_configuration, configure_users

**Integration Tests** - ``molecule/configure_system/``

* Test role interactions and dependencies
* Full workflow validation
* Multi-role orchestration

**Discovery Tests** - ``roles/discovery/molecule/default/``

* Discovery role functionality
* Idempotence validation with static filenames

**Minimal Configuration** - ``molecule/minimal/``

* Test robustness with empty/missing configuration
* Variable validation

Running Tests
-------------

Run All Tests
~~~~~~~~~~~~~

Using just (recommended):

.. code-block:: bash

   just test

This runs all molecule tests in sequence.

Run Specific Role Tests
~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # Using just
   just molecule-test manage_packages
   just molecule-test os_configuration
   just molecule-test configure_users

   # Direct molecule command
   cd roles/manage_packages && molecule test
   cd roles/nodejs && molecule test

Run Integration Tests
~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   molecule test -s configure_system

Development Workflow
--------------------

Fast Iteration Cycle
~~~~~~~~~~~~~~~~~~~~

For rapid development and testing:

.. code-block:: bash

   cd roles/manage_packages

   # 1. Create test environment (once)
   molecule create

   # 2. Deploy and test (repeat as needed)
   molecule converge  # Fast - only runs playbook

   # 3. Run verification
   molecule verify    # Fast - only runs tests

   # 4. Full test cycle when ready
   molecule test      # Slower - full create/converge/verify/destroy

   # 5. Clean up
   molecule destroy

Debug Mode
~~~~~~~~~~

Enable verbose output:

.. code-block:: bash

   # Ansible verbose mode
   molecule converge -- -vvv

   # Molecule debug
   export MOLECULE_DEBUG=true
   molecule test

   # Keep containers for inspection
   molecule test --destroy=never

Test-Specific Configuration
----------------------------

Standard Test Variables
~~~~~~~~~~~~~~~~~~~~~~~

All molecule scenarios include:

.. code-block:: yaml

   provisioner:
     name: ansible
     inventory:
       group_vars:
         all:
           ansible_user: root
           molecule_test: true  # Enables test-specific behavior

Discovery Role Testing
~~~~~~~~~~~~~~~~~~~~~~

The discovery role uses static filenames during tests to ensure idempotence:

* **Production**: ``vars.discovered.{timestamp}`` (unique per run)
* **Testing**: ``vars.discovered`` (static filename)

This prevents false idempotence failures from timestamp changes.

Container Limitations
~~~~~~~~~~~~~~~~~~~~~

Some features don't work in Docker containers:

* Hostname changes may not persist
* Timezone changes may not persist
* Terminal configuration requires fakeroot

Use skip tags for container-incompatible tasks:

.. code-block:: bash

   molecule test -- --skip-tags no-container,hostname

CI/CD Testing
-------------

Local Tests Should Match CI
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Ensure your local tests match CI behavior:

* Use same Docker images as CI (``geerlingguy/docker-ubuntu2404-ansible:latest``)
* Include ``molecule_test: true`` variable
* Test idempotence with static configurations

CI Pipeline Structure
~~~~~~~~~~~~~~~~~~~~~

The CI pipeline runs:

1. **Validation** - ansible-lint, yamllint, syntax checks
2. **Individual Role Tests** - Parallel execution of all role tests
3. **Integration Tests** - configure_system scenario
4. **Minimal Configuration** - Empty/missing config validation

Required Before Commit
~~~~~~~~~~~~~~~~~~~~~~

**CRITICAL**: All tests must pass locally before committing:

.. code-block:: bash

   # Run the full test suite
   just test

If ``molecule test`` fails locally, it **will** fail in CI.

Test Output
-----------

Understanding Test Results
~~~~~~~~~~~~~~~~~~~~~~~~~~

Molecule test phases:

1. **Dependency** - Install required collections
2. **Lint** - Run ansible-lint (if configured)
3. **Cleanup** - Remove any existing test containers
4. **Destroy** - Ensure clean slate
5. **Create** - Create test containers
6. **Prepare** - Run prepare playbook (install dependencies)
7. **Converge** - Run the role/playbook being tested
8. **Idempotence** - Run converge again, expect no changes
9. **Verify** - Run test assertions
10. **Destroy** - Clean up test containers

Successful Output
~~~~~~~~~~~~~~~~~

.. code-block:: text

   PLAY RECAP *******************
   ubuntu-packages-full  : ok=14  changed=4  unreachable=0  failed=0

   ✅ Manage packages role tests passed

Failed Tests
~~~~~~~~~~~~

When tests fail, molecule shows:

* Which phase failed (converge, verify, etc.)
* Specific task that failed
* Error message and details
* Container logs if applicable

Troubleshooting
---------------

Common Issues
~~~~~~~~~~~~~

**Docker Permission Errors**

.. code-block:: bash

   # Add yourself to docker group
   sudo usermod -aG docker $USER
   newgrp docker

**Docker Daemon Not Running**

.. code-block:: bash

   sudo systemctl start docker
   docker info  # Verify connection

**Idempotence Failures**

Check for dynamic content in templates:

* Timestamps
* Random data
* Non-deterministic ordering

**Missing Dependencies**

.. code-block:: bash

   # Install collection dependencies
   ansible-galaxy collection install -r requirements.yml

**Stale Containers**

.. code-block:: bash

   # Clean up all molecule containers
   molecule destroy
   docker ps -a | grep molecule | awk '{print $1}' | xargs docker rm -f

Performance Tips
----------------

Speed Up Testing
~~~~~~~~~~~~~~~~

1. **Use molecule converge during development** - Skip full test cycle
2. **Keep containers running** - Avoid create/destroy overhead
3. **Test one role at a time** - Don't run full suite unless needed
4. **Use parallel testing** - Run multiple role tests simultaneously (CI does this)

.. code-block:: bash

   # Fast iteration
   molecule converge && molecule verify

   # Keep containers between runs
   molecule test --destroy=never

Parallel Testing
~~~~~~~~~~~~~~~~

Test multiple roles simultaneously:

.. code-block:: bash

   # In separate terminals
   cd roles/nodejs && molecule test &
   cd roles/rust && molecule test &
   cd roles/go && molecule test &
   wait

See Also
--------

* :doc:`molecule-architecture` - Test infrastructure details
* :doc:`vm-testing` - Full VM testing approach
* :doc:`writing-tests` - How to write new tests
* :doc:`../development/tdd-process` - TDD workflow
