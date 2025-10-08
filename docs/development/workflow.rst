Development Workflow
====================

Systematic process for implementing and validating requirements.

.. contents::
   :local:
   :depth: 2

Core Principles
---------------

1. **Requirements-driven development** - All changes trace to specific requirements
2. **Incremental validation** - Each change is tested before proceeding
3. **No broken states** - Every commit must pass all tests
4. **Systematic approach** - Work role-by-role, requirement-by-requirement

Role Validation Workflow
-------------------------

Phase 1: Analysis
~~~~~~~~~~~~~~~~~

Before writing any code:

1. **Extract requirements** from documentation for the target role
2. **Create validation plan** with specific test cases (positive + negative)
3. **Review current implementation** (production code and tests)
4. **Identify gaps** between requirements and current implementation

Phase 2: Planning
~~~~~~~~~~~~~~~~~

Document your approach:

1. **Gap analysis** - What's missing, what's wrong, what's good
2. **Implementation plan** - Ordered list of specific changes needed
3. **Estimate effort** - Simple vs complex changes
4. **Success criteria** - How to know each change is complete

Phase 3: Implementation
~~~~~~~~~~~~~~~~~~~~~~~

For each requirement (one at a time):

**1. Start Clean**

Ensure current state passes all tests:

.. code-block:: bash

   cd roles/manage_packages
   molecule test  # Must pass before starting

**2. Make Targeted Change**

Implement ONE requirement:

* Update production code if needed
* Update/add molecule tests to validate
* Update verification tasks

**3. Validate Change**

Test the specific change:

.. code-block:: bash

   molecule test  # Must pass after change

**4. Commit Change**

Document what was implemented:

.. code-block:: bash

   git add .
   git commit -m "implement REQ-XX-YYY: requirement description"
   git push origin main

**5. Verify CI**

Ensure CI pipeline passes.

**6. Move to Next Requirement**

Repeat for each requirement.

Phase 4: Completion
~~~~~~~~~~~~~~~~~~~

After all requirements:

1. **Final validation** - Run complete test suite for the role
2. **Documentation update** - Update README/docs if needed
3. **Gap closure verification** - Confirm all requirements implemented
4. **Move to next role**

Branching Strategy
------------------

Direct Commits to Main
~~~~~~~~~~~~~~~~~~~~~~

We use direct commits to ``main`` branch:

* Single-developer workflow with disciplined testing
* Each commit is small, focused, and fully tested
* Immediate CI feedback on every change
* Forces better discipline (no broken commits allowed)

**Why not feature branches?**

* No collaboration conflicts (single developer)
* Overhead not justified for systematic approach
* ``molecule test`` requirement ensures quality
* ``git revert`` available if needed

Testing Requirements
--------------------

Before Any Changes
~~~~~~~~~~~~~~~~~~

Verify current state is clean:

.. code-block:: bash

   cd roles/manage_packages
   molecule test
   ansible-lint

After Each Change
~~~~~~~~~~~~~~~~~

Validate the specific change:

.. code-block:: bash

   # Role-specific tests
   molecule test

   # Broader validation
   cd ../../
   ansible-lint
   pre-commit run --all-files

Commit Requirements
~~~~~~~~~~~~~~~~~~~

Before committing, ensure:

* ✅ All molecule tests pass
* ✅ No ansible-lint errors
* ✅ No pre-commit hook failures
* ✅ Commit message references specific requirement

Commit Message Format
---------------------

Standard Format
~~~~~~~~~~~~~~~

.. code-block:: text

   implement REQ-{ROLE}-{NUM}: {requirement description}

   - Add/update {specific change made}
   - Test coverage: {what tests validate this}
   - Platform: {Ubuntu/Arch/macOS/All}

   Validates: {specific validation criteria met}

Examples
~~~~~~~~

**System Configuration**

.. code-block:: text

   implement REQ-OS-001: system hostname configuration

   - Add hostname task with proper conditionals
   - Test coverage: verify hostname command and /etc/hostname file
   - Platform: All (VM-only due to container limitations)

   Validates: hostname set when host_hostname defined and non-empty

**Package Management**

.. code-block:: text

   implement REQ-MP-003: layered package installation

   - Add package merging from all/group/host levels
   - Test coverage: verify all three levels combine correctly
   - Platform: All

   Validates: packages merged from all inventory levels

Error Handling
--------------

When Tests Fail
~~~~~~~~~~~~~~~

1. **Do not commit** - Fix the issue first
2. **Understand the failure** - Is it the code or the test?
3. **Fix incrementally** - Make minimal changes to resolve
4. **Re-test** - Ensure fix works and doesn't break other things

When CI Fails
~~~~~~~~~~~~~

1. **Investigate immediately** - Don't proceed to next change
2. **Fix in separate commit** - Don't mix CI fixes with feature work
3. **Verify fix** - Ensure CI passes before continuing

When Molecule is Flaky
~~~~~~~~~~~~~~~~~~~~~~

1. **Retry once** - Some tests have timing issues
2. **If consistent failure** - Investigate and fix the test
3. **Document workarounds** - If container limitations require VM testing

Documentation Updates
---------------------

When to Update
~~~~~~~~~~~~~~

* New requirements implemented
* Test procedures change
* Workflow improvements identified

What to Update
~~~~~~~~~~~~~~

* Role README files (if behavior changes significantly)
* This workflow document (if process improvements identified)
* User-facing documentation (if user interface changes)

Quality Gates
-------------

Before Moving to Next Requirement
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 0
   :widths: 5 95

   * - ☐
     - Molecule tests pass
   * - ☐
     - Ansible-lint clean
   * - ☐
     - Pre-commit hooks pass
   * - ☐
     - CI pipeline green
   * - ☐
     - Requirement fully validated (positive + negative tests)

Before Moving to Next Role
~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 0
   :widths: 5 95

   * - ☐
     - All role requirements implemented
   * - ☐
     - Complete role test suite passes
   * - ☐
     - Integration tests pass (if applicable)
   * - ☐
     - Documentation updated
   * - ☐
     - Gap analysis complete and closed

Development Cycle Example
-------------------------

Complete Example
~~~~~~~~~~~~~~~~

Working on the ``manage_packages`` role:

.. code-block:: bash

   # 1. Start with clean state
   cd roles/manage_packages
   molecule test  # ✅ Passes

   # 2. Implement REQ-MP-001 (basic package installation)
   # Edit tasks/main.yml, add package installation logic
   # Edit molecule/default/verify.yml, add package verification

   # 3. Test the change
   molecule test  # ✅ Passes

   # 4. Commit
   git add tasks/main.yml molecule/default/verify.yml
   git commit -m "implement REQ-MP-001: basic package installation"
   git push

   # 5. Verify CI passes
   # Check GitLab CI pipeline

   # 6. Move to REQ-MP-002 (layered configuration)
   # Repeat steps 2-5

   # 7. After all requirements
   molecule test  # Final validation
   ansible-lint   # Final check
   # Update README if needed
   # Move to next role

See Also
--------

* :doc:`tdd-process` - Test-Driven Development approach
* :doc:`contributing` - Contribution guidelines
* :doc:`../testing/running-tests` - Testing guide
