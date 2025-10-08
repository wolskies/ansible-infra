Test-Driven Development
========================

We use Test-Driven Development (TDD) for implementing features.

.. contents::
   :local:
   :depth: 2

Overview
--------

When contributing to this collection, follow these principles:

1. **Write tests before code** - Define expected behavior first
2. **Watch tests fail** - Ensures tests actually validate functionality
3. **Implement feature** - Write minimal code to pass tests
4. **Verify tests pass** - Confirm implementation works
5. **Refactor if needed** - Improve code while keeping tests green

Quick Example
-------------

Adding Package Installation
~~~~~~~~~~~~~~~~~~~~~~~~~~~

**1. Write the test** in ``molecule/default/verify.yml``:

.. code-block:: yaml

   - name: Gather package facts
     ansible.builtin.package_facts:

   - name: Verify git installed
     ansible.builtin.assert:
       that: "'git' in ansible_facts.packages"
       fail_msg: "git package not installed"

**2. Run test** (it fails):

.. code-block:: bash

   cd roles/my_role
   molecule test
   # FAILED - git not installed

**3. Implement feature** in ``tasks/main.yml``:

.. code-block:: yaml

   - name: Install packages
     ansible.builtin.apt:
       name: git
       state: present
     when: ansible_distribution == "Ubuntu"

**4. Run test** (it passes):

.. code-block:: bash

   molecule test
   # PASSED - git installed

Testing Guidelines
------------------

Test Outcomes, Not Implementation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   # Good - test system state
   - name: Verify git installed
     ansible.builtin.package_facts:

   - name: Check git present
     ansible.builtin.assert:
       that: "'git' in ansible_facts.packages"

   # Bad - test implementation details
   - name: Verify apt called (wrong)
     ansible.builtin.apt:
       name: git
       state: present
     check_mode: true

Keep Tests Focused
~~~~~~~~~~~~~~~~~~

Test one thing at a time:

.. code-block:: yaml

   # Good - single assertion
   - name: Verify git installed
     ansible.builtin.assert:
       that: "'git' in ansible_facts.packages"

   # Bad - multiple unrelated assertions
   - name: Verify everything
     ansible.builtin.assert:
       that:
         - "'git' in ansible_facts.packages"
         - services['nginx'].state == 'running'
         - firewall_enabled

Development Workflow
--------------------

Fast Iteration
~~~~~~~~~~~~~~

.. code-block:: bash

   cd roles/my_role

   # Create test environment (once)
   molecule create

   # Fast iteration cycle
   molecule converge  # Deploy changes
   molecule verify    # Run tests

   # Full test before commit
   molecule test

Required Before Commit
~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # All must pass
   molecule test
   ansible-lint
   pre-commit run --all-files

See Also
--------

* :doc:`workflow` - Complete development workflow
* :doc:`contributing` - Contribution guidelines
* :doc:`../testing/writing-tests` - Detailed testing guide
* :doc:`../testing/running-tests` - Running tests locally
