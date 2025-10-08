Molecule Test Architecture
==========================

Understanding the test infrastructure and organization.

.. contents::
   :local:
   :depth: 2

Overview
--------

Molecule provides container-based testing for Ansible roles and collections.
Our architecture follows best practices for comprehensive, maintainable tests.

Test Organization
-----------------

Test Types
~~~~~~~~~~

**Individual Role Tests** - ``roles/{role}/molecule/default/``

Primary validation for each role:

* Package installation
* Configuration management
* Idempotence verification
* Platform-specific behavior

**Integration Tests** - ``molecule/configure_system/``

Multi-role orchestration:

* Role interaction testing
* End-to-end workflows
* Cross-role dependencies

**Minimal Configuration** - ``molecule/minimal/``

Robustness testing:

* Empty configuration handling
* Missing variable scenarios
* Default behavior validation

Directory Structure
-------------------

Role-Level Tests
~~~~~~~~~~~~~~~~

.. code-block:: text

   roles/manage_packages/
   ├── molecule/
   │   └── default/
   │       ├── molecule.yml       # Test configuration
   │       ├── converge.yml       # Playbook to test
   │       ├── verify.yml         # Test assertions
   │       └── prepare.yml        # Test setup (optional)
   ├── tasks/
   ├── meta/
   └── README.md

Collection-Level Tests
~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: text

   molecule/
   ├── configure_system/
   │   ├── molecule.yml
   │   ├── converge.yml
   │   └── verify.yml
   └── minimal/
       ├── molecule.yml
       ├── converge.yml
       └── verify.yml

Test Configuration
------------------

molecule.yml Structure
~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   ---
   driver:
     name: docker

   platforms:
     - name: ubuntu-test
       image: geerlingguy/docker-ubuntu2404-ansible:latest
       pre_build_image: true
       privileged: true
       volumes:
         - /sys/fs/cgroup:/sys/fs/cgroup:rw
       cgroupns_mode: host
       command: "/lib/systemd/systemd"

   provisioner:
     name: ansible
     inventory:
       group_vars:
         all:
           ansible_user: root
           molecule_test: true

   verifier:
     name: ansible

Key Components:

* **driver**: docker (container-based testing)
* **platforms**: Test container definitions
* **provisioner**: Ansible configuration
* **verifier**: Test runner (ansible playbooks)

Docker Images
~~~~~~~~~~~~~

We use pre-built images with systemd support:

* ``geerlingguy/docker-ubuntu2404-ansible:latest`` - Ubuntu 24.04
* ``geerlingguy/docker-ubuntu2204-ansible:latest`` - Ubuntu 22.04
* ``carlodepieri/docker-archlinux-ansible:latest`` - Arch Linux

These images include:

* Systemd init system
* Ansible Python dependencies
* Common system tools

Test Phases
-----------

Molecule Test Lifecycle
~~~~~~~~~~~~~~~~~~~~~~~~

1. **dependency** - Install required collections
2. **cleanup** - Remove existing containers
3. **destroy** - Ensure clean slate
4. **create** - Create test containers
5. **prepare** - Run setup playbook (if exists)
6. **converge** - Run role/playbook
7. **idempotence** - Run converge again (expect no changes)
8. **verify** - Run test assertions
9. **destroy** - Clean up containers

Idempotence Testing
~~~~~~~~~~~~~~~~~~~

Critical for Ansible roles - running twice should produce no changes:

.. code-block:: bash

   # First run - applies configuration
   PLAY RECAP *************
   ubuntu-test  : ok=5  changed=3  unreachable=0  failed=0

   # Second run - no changes (idempotent)
   PLAY RECAP *************
   ubuntu-test  : ok=5  changed=0  unreachable=0  failed=0

Test Scenarios
--------------

Multiple Containers
~~~~~~~~~~~~~~~~~~~

Test different configurations simultaneously:

.. code-block:: yaml

   platforms:
     - name: ubuntu-packages-full
       image: geerlingguy/docker-ubuntu2404-ansible:latest

     - name: ubuntu-packages-basic
       image: geerlingguy/docker-ubuntu2404-ansible:latest

     - name: arch-packages-basic
       image: carlodepieri/docker-archlinux-ansible:latest

   provisioner:
     inventory:
       host_vars:
         ubuntu-packages-full:
           manage_packages_all:
             Ubuntu: [git, curl, vim, nginx]

         ubuntu-packages-basic:
           manage_packages_all:
             Ubuntu: [git, curl]

         arch-packages-basic:
           manage_packages_all:
             Archlinux: [git, curl]

Container Limitations
---------------------

What Doesn't Work
~~~~~~~~~~~~~~~~~

Docker containers have limitations:

* **Hostname changes** - May not persist
* **Timezone changes** - Require host access
* **Terminal compilation** - Needs fakeroot
* **Nested virtualization** - Can't run VMs
* **System services** - Some may not start

Handling Limitations
~~~~~~~~~~~~~~~~~~~~

Use tags to skip incompatible tasks:

.. code-block:: yaml

   # In role tasks
   - name: Set hostname
     ansible.builtin.hostname:
       name: "{{ host_hostname }}"
     tags:
       - no-container  # Skip in containers

.. code-block:: bash

   # Run tests skipping container-incompatible tasks
   molecule test -- --skip-tags no-container

Test Variables
--------------

Standard Variables
~~~~~~~~~~~~~~~~~~

All tests include:

.. code-block:: yaml

   molecule_test: true  # Indicates test environment

Roles can use this for test-specific behavior (sparingly):

.. code-block:: yaml

   # Only use when absolutely necessary
   when: not (molecule_test | default(false))

Prefer using tags over conditional logic.

Test Data
~~~~~~~~~

Use realistic, production-like test data:

.. code-block:: yaml

   # Good - realistic data
   manage_packages_all:
     Ubuntu:
       - name: git
       - name: curl
       - name: vim

   # Bad - test-specific data
   manage_packages_all:
     Ubuntu:
       - name: test-package-1
       - name: fake-package-2

Verification
------------

State-Based Assertions
~~~~~~~~~~~~~~~~~~~~~~

Test actual system state, not implementation:

.. code-block:: yaml

   # Good - check system state
   - name: Verify packages installed
     ansible.builtin.command: dpkg -l git curl vim
     changed_when: false

   # Bad - reimplement role logic
   - name: Verify packages (wrong way)
     ansible.builtin.apt:
       name: [git, curl, vim]
       state: present
     check_mode: true

Using assert Module
~~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   - name: Gather package facts
     ansible.builtin.package_facts:

   - name: Verify git is installed
     ansible.builtin.assert:
       that:
         - "'git' in ansible_facts.packages"
       fail_msg: "git package not installed"
       success_msg: "git package verified"

Performance
-----------

Optimization Strategies
~~~~~~~~~~~~~~~~~~~~~~~

1. **Reuse containers** - ``molecule converge`` during development
2. **Parallel testing** - Run multiple role tests simultaneously
3. **Selective testing** - Test changed roles only
4. **Cache collections** - Reuse downloaded collections

.. code-block:: bash

   # Fast iteration
   molecule create    # Once
   molecule converge  # Repeat
   molecule verify    # Repeat
   molecule destroy   # When done

CI Optimization
~~~~~~~~~~~~~~~

GitLab CI uses caching:

.. code-block:: yaml

   cache:
     key: "molecule-$CI_COMMIT_REF_SLUG"
     paths:
       - /root/.cache/pip/
       - /root/.ansible/collections/

This speeds up test runs by caching Python packages and collections.

See Also
--------

* :doc:`running-tests` - How to run tests
* :doc:`writing-tests` - Creating new tests
* :doc:`vm-testing` - Full VM validation
