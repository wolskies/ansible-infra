Test-Driven Development
========================

TDD approach for implementing collection features.

.. contents::
   :local:
   :depth: 2

TDD Workflow
------------

The Red-Green-Refactor Cycle
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

1. **Red** - Write a failing test
2. **Green** - Write minimal code to pass
3. **Refactor** - Improve code while keeping tests green

Applied to Ansible Roles
~~~~~~~~~~~~~~~~~~~~~~~~~

1. **Write test** - Add molecule verification
2. **Run test** - Watch it fail (red)
3. **Implement** - Add role tasks
4. **Run test** - Watch it pass (green)
5. **Refactor** - Improve implementation

Example: Package Installation
------------------------------

Step 1: Write Failing Test
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Add verification in ``molecule/default/verify.yml``:

.. code-block:: yaml

   - name: Gather package facts
     ansible.builtin.package_facts:

   - name: Verify git installed
     ansible.builtin.assert:
       that: "'git' in ansible_facts.packages"
       fail_msg: "git package not installed"

Run test (it fails):

.. code-block:: bash

   molecule test
   # FAILED - git not installed

Step 2: Implement Minimal Code
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Add to ``tasks/main.yml``:

.. code-block:: yaml

   - name: Install packages
     ansible.builtin.apt:
       name: git
       state: present
     when: ansible_distribution == "Ubuntu"

Step 3: Run Test (Passes)
~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   molecule test
   # PASSED - git installed

Step 4: Refactor
~~~~~~~~~~~~~~~~

Improve implementation:

.. code-block:: yaml

   - name: Install packages
     ansible.builtin.apt:
       name: "{{ item.name }}"
       state: "{{ item.state | default('present') }}"
     loop: "{{ manage_packages_all[ansible_distribution] | default([]) }}"
     when: ansible_distribution in ["Ubuntu", "Debian"]

Run test again:

.. code-block:: bash

   molecule test
   # PASSED - still works with better implementation

Benefits of TDD
---------------

Confidence
~~~~~~~~~~

* Know exactly what works
* Catch regressions immediately
* Refactor without fear

Design
~~~~~~

* Forces you to think about interface first
* Keeps code testable
* Encourages modularity

Documentation
~~~~~~~~~~~~~

* Tests document expected behavior
* Examples of how to use features
* Living documentation that stays current

Best Practices
--------------

Write Tests First
~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # Wrong order
   1. Write production code
   2. Hope it works
   3. Maybe write tests later

   # TDD order
   1. Write test (fails)
   2. Write code (test passes)
   3. Refactor (test still passes)

Test One Thing
~~~~~~~~~~~~~~

.. code-block:: yaml

   # Good - focused test
   - name: Verify git installed
     ansible.builtin.assert:
       that: "'git' in ansible_facts.packages"

   # Bad - testing multiple things
   - name: Verify everything
     ansible.builtin.assert:
       that:
         - "'git' in ansible_facts.packages"
         - "'curl' in ansible_facts.packages"
         - services['nginx'].state == 'running'
         - firewall_enabled

Keep Tests Fast
~~~~~~~~~~~~~~~

* Use ``molecule converge`` during development
* Only run full ``molecule test`` before commit
* Use tags to run subset of tests

Common Patterns
---------------

Test Data Setup
~~~~~~~~~~~~~~~

Use ``molecule.yml`` for test data:

.. code-block:: yaml

   provisioner:
     inventory:
       host_vars:
         ubuntu-test:
           manage_packages_all:
             Ubuntu: [git, curl]

State Verification
~~~~~~~~~~~~~~~~~~

Check actual system state:

.. code-block:: yaml

   - name: Get hostname
     ansible.builtin.command: hostname
     register: hostname_output
     changed_when: false

   - name: Verify hostname
     ansible.builtin.assert:
       that: hostname_output.stdout == expected_hostname

Negative Testing
~~~~~~~~~~~~~~~~

Test failure cases:

.. code-block:: yaml

   - name: Verify package absent
     ansible.builtin.package_facts:

   - name: Verify telnet not installed
     ansible.builtin.assert:
       that: "'telnet' not in ansible_facts.packages"

TDD Anti-Patterns
-----------------

Avoid These
~~~~~~~~~~~

1. **Writing tests after code** - Not TDD
2. **Testing implementation** - Test outcomes, not how
3. **Brittle tests** - Over-specified expectations
4. **Slow tests** - Full test suite for every change
5. **No refactoring** - Stop at green, miss improvements

Example: Don't Test Implementation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   # Bad - testing implementation
   - name: Verify apt module called
     ansible.builtin.apt:
       name: git
       state: present
     check_mode: true

   # Good - testing outcome
   - name: Verify git installed
     ansible.builtin.package_facts:

   - name: Check git present
     ansible.builtin.assert:
       that: "'git' in ansible_facts.packages"

Incremental Development
-----------------------

Build Features Step by Step
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Feature: Multi-platform package management**

Iteration 1: Ubuntu only

.. code-block:: yaml

   # Test
   - name: Verify git on Ubuntu
     ansible.builtin.assert:
       that: "'git' in ansible_facts.packages"
     when: ansible_distribution == "Ubuntu"

   # Implementation
   - name: Install packages (Ubuntu)
     ansible.builtin.apt:
       name: git
     when: ansible_distribution == "Ubuntu"

Iteration 2: Add Arch support

.. code-block:: yaml

   # Test
   - name: Verify git on Arch
     ansible.builtin.assert:
       that: "'git' in ansible_facts.packages"
     when: ansible_distribution == "Archlinux"

   # Implementation
   - name: Install packages (Arch)
     ansible.builtin.pacman:
       name: git
     when: ansible_distribution == "Archlinux"

Iteration 3: Refactor to be data-driven

.. code-block:: yaml

   # Test (same as before)

   # Implementation (improved)
   - name: Install packages
     ansible.builtin.package:
       name: "{{ item }}"
     loop: "{{ packages[ansible_distribution] }}"

Integration with Workflow
-------------------------

TDD in Development Cycle
~~~~~~~~~~~~~~~~~~~~~~~~~

1. **Pick requirement** - From requirements document
2. **Write test** - For that requirement
3. **Run test** - It fails (red)
4. **Implement** - Minimal code to pass
5. **Run test** - It passes (green)
6. **Refactor** - Improve code
7. **Commit** - With test and implementation
8. **Next requirement** - Repeat

See Also
--------

* :doc:`workflow` - Development workflow
* :doc:`../testing/writing-tests` - Writing tests guide
* :doc:`../testing/running-tests` - Running tests guide
