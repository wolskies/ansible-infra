Contributing
============

Guidelines for contributing to the ``wolskies.infrastructure`` collection.

.. contents::
   :local:
   :depth: 2

Getting Started
---------------

Prerequisites
~~~~~~~~~~~~~

* Ansible 2.12+
* Python 3.9+
* Docker (for testing)
* Git

Fork and Clone
~~~~~~~~~~~~~~

.. code-block:: bash

   # Clone repository
   git clone https://gitlab.wolskinet.com/ansible/collections/infrastructure.git
   cd infrastructure

   # Install dependencies
   ansible-galaxy collection install -r requirements.yml
   pip install molecule[docker] molecule-plugins[docker]

   # Install pre-commit hooks
   pre-commit install

Development Process
-------------------

1. Pick an Issue
~~~~~~~~~~~~~~~~

* Browse `GitLab Issues <https://gitlab.wolskinet.com/ansible/collections/infrastructure/-/issues>`_
* Comment on issue to claim it
* Discuss approach if needed

2. Create Branch (Optional)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   git checkout -b feature/my-feature

3. Implement Changes
~~~~~~~~~~~~~~~~~~~~

Follow :doc:`workflow` and :doc:`tdd-process`.

4. Test Changes
~~~~~~~~~~~~~~~

.. code-block:: bash

   # Run tests for your role
   cd roles/my_role
   molecule test

   # Run linting
   ansible-lint

   # Run pre-commit hooks
   pre-commit run --all-files

5. Commit Changes
~~~~~~~~~~~~~~~~~

.. code-block:: bash

   git add .
   git commit -m "implement REQ-XX-YYY: description"

6. Push and Create MR
~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   git push origin feature/my-feature

Create merge request on GitLab.

Code Standards
--------------

Ansible Best Practices
~~~~~~~~~~~~~~~~~~~~~~

* Follow `Ansible best practices <https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html>`_
* Use ``ansible.builtin`` for core modules
* Prefer ``community.general`` over custom code
* Keep roles focused and single-purpose

YAML Style
~~~~~~~~~~

* 2-space indentation
* Use ``---`` document start marker
* Quote strings containing special characters
* Use lists over dict merging where appropriate

Variable Naming
~~~~~~~~~~~~~~~

* Use descriptive names: ``manage_packages_all`` not ``pkgs``
* Prefix role-specific vars: ``manage_packages_*``
* Use collection-wide vars in ``defaults/main.yml``
* Document all variables in ``meta/argument_specs.yml``

Testing Requirements
--------------------

All Changes Must Include Tests
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* Add molecule tests for new features
* Update existing tests for changes
* Ensure idempotence
* Test positive and negative cases

Test Coverage
~~~~~~~~~~~~~

* Individual role tests for role-specific features
* Integration tests for multi-role features
* VM tests for platform-specific behavior

Validation Before Commit
~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # Must pass before committing
   molecule test          # Role tests
   ansible-lint           # Linting
   pre-commit run --all   # Hooks

Documentation
-------------

Update Documentation
~~~~~~~~~~~~~~~~~~~~

When adding/changing features:

* Update role README if behavior changes
* Update ``docs/roles/{role}.rst`` for user-facing changes
* Add examples to documentation
* Update ``meta/argument_specs.yml`` for variable changes

Documentation Style
~~~~~~~~~~~~~~~~~~~

* Use reStructuredText format
* Include code examples
* Provide troubleshooting tips
* Link to related documentation

Commit Messages
---------------

Format
~~~~~~

.. code-block:: text

   <type>: <short description>

   <longer description if needed>

   <footer with references>

Types
~~~~~

* ``implement`` - New feature/requirement
* ``fix`` - Bug fix
* ``docs`` - Documentation only
* ``test`` - Test updates only
* ``refactor`` - Code refactoring
* ``chore`` - Maintenance tasks

Examples
~~~~~~~~

.. code-block:: text

   implement REQ-MP-003: layered package configuration

   - Add package merging from all/group/host levels
   - Test coverage for each inventory level
   - Platform: All

   Closes #42

.. code-block:: text

   fix: manage_packages fails on empty package list

   Handle empty package lists gracefully instead of failing.

   Fixes #45

Code Review
-----------

What We Look For
~~~~~~~~~~~~~~~~

* ✅ Tests pass
* ✅ Code follows standards
* ✅ Documentation updated
* ✅ Commit messages clear
* ✅ No unnecessary changes
* ✅ Idempotent tasks

Review Process
~~~~~~~~~~~~~~

1. Automated CI runs tests
2. Maintainer reviews code
3. Feedback provided if needed
4. Approved and merged when ready

Getting Help
------------

Ask Questions
~~~~~~~~~~~~~

* Open GitLab issue for feature requests
* Comment on existing issues for discussion
* Tag maintainers for review

Resources
~~~~~~~~~

* :doc:`workflow` - Development workflow
* :doc:`tdd-process` - TDD approach
* :doc:`../testing/index` - Testing guide
* `Ansible Documentation <https://docs.ansible.com>`_

License
-------

By contributing, you agree that your contributions will be licensed under the MIT License.

See Also
--------

* :doc:`workflow` - Development workflow details
* :doc:`tdd-process` - Test-driven development
* :doc:`../testing/writing-tests` - Writing tests
