Development Workflow
====================

Guidelines for contributing code to the collection.

.. contents::
   :local:
   :depth: 2

Getting Started
---------------

Setup
~~~~~

.. code-block:: bash

   # Clone repository
   git clone https://gitlab.wolskinet.com/ansible/collections/infrastructure.git
   cd infrastructure

   # Install dependencies
   ansible-galaxy collection install -r requirements.yml
   pip install molecule[docker] molecule-plugins[docker] pytest-testinfra

   # Install pre-commit hooks
   pre-commit install

Contribution Process
--------------------

1. Find or Create an Issue
~~~~~~~~~~~~~~~~~~~~~~~~~~~

* Browse `GitLab Issues <https://gitlab.wolskinet.com/ansible/collections/infrastructure/-/issues>`_
* Comment to claim the issue
* Discuss approach if needed

2. Make Your Changes
~~~~~~~~~~~~~~~~~~~~~

**Write tests first:**

.. code-block:: bash

   cd roles/my_role

   # Edit molecule/default/verify.yml - add test
   # Run test to see it fail
   molecule test

   # Edit tasks/main.yml - implement feature
   # Run test to see it pass
   molecule test

**Ensure quality:**

.. code-block:: bash

   # Validate changes
   ansible-lint
   pre-commit run --all-files

3. Commit Your Work
~~~~~~~~~~~~~~~~~~~

Use descriptive commit messages:

.. code-block:: bash

   git add .
   git commit -m "implement feature: description of what changed"
   git push

4. Create Merge Request
~~~~~~~~~~~~~~~~~~~~~~~

* Push your branch
* Create MR on GitLab
* Fill out MR template
* Wait for CI and review

Required Checks
---------------

Before Committing
~~~~~~~~~~~~~~~~~

All of these must pass:

.. code-block:: bash

   # 1. Role tests
   cd roles/my_role
   molecule test

   # 2. Linting
   ansible-lint

   # 3. Pre-commit hooks
   pre-commit run --all-files

CI Pipeline
~~~~~~~~~~~

GitLab CI automatically runs:

* ``ansible-lint`` - Code quality checks
* ``molecule test`` - All role tests
* Integration tests
* Documentation build

All checks must pass before merge.

Code Standards
--------------

Ansible Best Practices
~~~~~~~~~~~~~~~~~~~~~~

* Use ``ansible.builtin.*`` modules for core functionality
* Use ``community.general.*`` for extended functionality
* Follow `Ansible best practices <https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html>`_
* Write idempotent tasks

YAML Style
~~~~~~~~~~

* 2-space indentation
* Use ``---`` document start marker
* Quote strings with special characters
* Use meaningful variable names

Variable Naming
~~~~~~~~~~~~~~~

* Prefix role variables: ``rolename_variable``
* Use descriptive names: ``manage_packages_all`` not ``pkgs``
* Document all variables in ``meta/argument_specs.yml``

Testing Requirements
--------------------

Test Coverage
~~~~~~~~~~~~~

* Add tests for all new features
* Update tests when changing behavior
* Test both success and failure cases
* Verify idempotence

Test Quality
~~~~~~~~~~~~

* Test outcomes, not implementation
* Use realistic test data
* Keep tests focused and simple
* Write clear failure messages

Documentation
-------------

Update When Needed
~~~~~~~~~~~~~~~~~~

* Role README for behavior changes
* ``docs/roles/{role}.rst`` for user-facing changes
* ``meta/argument_specs.yml`` for variable changes
* Add examples for new features

See Also
--------

* :doc:`tdd-process` - Test-driven development
* :doc:`contributing` - Contribution guidelines
* :doc:`../testing/running-tests` - Testing guide
* :doc:`../testing/writing-tests` - Writing tests
