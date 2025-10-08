Writing Tests
=============

Guide to creating new tests for roles and features.

.. contents::
   :local:
   :depth: 2

Quick Start
-----------

Create a new role test:

.. code-block:: bash

   cd roles/my_new_role
   mkdir -p molecule/default

   # Create molecule.yml, converge.yml, verify.yml
   # See templates below

Test Templates
--------------

molecule.yml Template
~~~~~~~~~~~~~~~~~~~~~

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
           # Add test variables here

   verifier:
     name: ansible

converge.yml Template
~~~~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   ---
   - name: Test role_name
     hosts: all
     become: true
     tasks:
       - name: Include role
         ansible.builtin.include_role:
           name: wolskies.infrastructure.role_name

verify.yml Template
~~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   ---
   - name: Verify role_name
     hosts: all
     become: true
     tasks:
       - name: Gather facts
         ansible.builtin.setup:

       - name: Test assertion example
         ansible.builtin.assert:
           that:
             - some_condition == true
           fail_msg: "Test failed"

Writing Good Tests
------------------

Test Principles
~~~~~~~~~~~~~~~

1. **Test outcomes, not implementation**
2. **Use realistic test data**
3. **Ensure idempotence**
4. **Test multiple scenarios**
5. **Verify actual system state**

Good vs Bad Examples
~~~~~~~~~~~~~~~~~~~~

**Package Installation Testing**

.. code-block:: yaml

   # Good - check system state
   - name: Gather package facts
     ansible.builtin.package_facts:

   - name: Verify packages installed
     ansible.builtin.assert:
       that: "'{{ item }}' in ansible_facts.packages"
     loop:
       - git
       - curl
       - vim

   # Bad - reimplements role
   - name: Check packages (wrong)
     ansible.builtin.apt:
       name: [git, curl, vim]
       state: present
     check_mode: true

**Service Testing**

.. code-block:: yaml

   # Good - verify service is running
   - name: Get service status
     ansible.builtin.service_facts:

   - name: Verify nginx running
     ansible.builtin.assert:
       that:
         - ansible_facts.services['nginx.service'].state == 'running'

   # Bad - start service in test
   - name: Ensure nginx running (wrong)
     ansible.builtin.systemd:
       name: nginx
       state: started

Multi-Container Tests
---------------------

Testing Multiple Scenarios
~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   platforms:
     - name: ubuntu-minimal
       image: geerlingguy/docker-ubuntu2404-ansible:latest
       # ... config ...

     - name: ubuntu-full
       image: geerlingguy/docker-ubuntu2404-ansible:latest
       # ... config ...

     - name: arch-test
       image: carlodepieri/docker-archlinux-ansible:latest
       # ... config ...

   provisioner:
     inventory:
       host_vars:
         ubuntu-minimal:
           manage_packages_all:
             Ubuntu: [git]

         ubuntu-full:
           manage_packages_all:
             Ubuntu: [git, curl, vim, nginx]

         arch-test:
           manage_packages_all:
             Archlinux: [git, curl]

Platform-Specific Tests
-----------------------

Testing Different Distributions
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   - name: Verify package (Ubuntu)
     ansible.builtin.assert:
       that: "'git' in ansible_facts.packages"
     when: ansible_distribution == "Ubuntu"

   - name: Verify package (Arch)
     ansible.builtin.assert:
       that: "'git' in ansible_facts.packages"
     when: ansible_distribution == "Archlinux"

Handling Container Limitations
-------------------------------

Using Tags
~~~~~~~~~~

Mark tasks that won't work in containers:

.. code-block:: yaml

   # In role tasks
   - name: Set hostname
     ansible.builtin.hostname:
       name: "{{ host_hostname }}"
     tags:
       - no-container

   # Run test skipping container-incompatible tasks
   # molecule test -- --skip-tags no-container

Test Organization
-----------------

File Structure
~~~~~~~~~~~~~~

.. code-block:: text

   roles/my_role/
   └── molecule/
       └── default/
           ├── molecule.yml          # Test config
           ├── converge.yml          # Deploy role
           ├── verify.yml            # Assertions
           ├── prepare.yml           # Setup (optional)
           └── requirements.yml      # Collections (optional)

Test Naming
~~~~~~~~~~~

Use descriptive container names:

* ``ubuntu-packages-full`` - Full package test
* ``ubuntu-packages-basic`` - Minimal packages
* ``ubuntu-repos-layered`` - Repository testing
* ``arch-packages-aur`` - AUR support testing

Best Practices
--------------

Idempotence
~~~~~~~~~~~

Always test idempotence:

.. code-block:: bash

   # Molecule automatically runs converge twice
   molecule test  # Includes idempotence check

Manual idempotence testing:

.. code-block:: bash

   molecule converge
   molecule converge  # Should report no changes

Test Data
~~~~~~~~~

Use realistic data:

.. code-block:: yaml

   # Good - production-like
   users:
     - name: developer
       shell: /bin/bash
       groups: [sudo, docker]

   # Bad - test-specific
   users:
     - name: testuser1
       shell: /bin/sh
       groups: [testgroup]

Error Messages
~~~~~~~~~~~~~~

Write helpful failure messages:

.. code-block:: yaml

   - name: Verify git installed
     ansible.builtin.assert:
       that: "'git' in ansible_facts.packages"
       fail_msg: "git package not installed - check manage_packages role"
       success_msg: "git package verified"

Running Tests
-------------

Development Cycle
~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # Create environment
   molecule create

   # Iterate quickly
   molecule converge  # Deploy
   # ... make changes ...
   molecule converge  # Deploy again
   molecule verify    # Test

   # Full test when ready
   molecule test

   # Clean up
   molecule destroy

Debugging
~~~~~~~~~

.. code-block:: bash

   # Verbose output
   molecule converge -- -vvv

   # Keep containers for inspection
   molecule test --destroy=never

   # SSH into container
   molecule login -h ubuntu-test

Common Patterns
---------------

Package Testing
~~~~~~~~~~~~~~~

.. code-block:: yaml

   - name: Gather package facts
     ansible.builtin.package_facts:

   - name: Verify packages
     ansible.builtin.assert:
       that: "'{{ item }}' in ansible_facts.packages"
       fail_msg: "Package {{ item }} not installed"
     loop: "{{ expected_packages }}"

Service Testing
~~~~~~~~~~~~~~~

.. code-block:: yaml

   - name: Gather service facts
     ansible.builtin.service_facts:

   - name: Verify services
     ansible.builtin.assert:
       that: >
         ansible_facts.services[item + '.service'].state == 'running'
       fail_msg: "Service {{ item }} not running"
     loop: "{{ expected_services }}"

File Testing
~~~~~~~~~~~~

.. code-block:: yaml

   - name: Check file exists
     ansible.builtin.stat:
       path: /etc/myapp/config.yml
     register: config_file

   - name: Verify file
     ansible.builtin.assert:
       that:
         - config_file.stat.exists
         - config_file.stat.mode == '0644'

Command Output Testing
~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   - name: Get hostname
     ansible.builtin.command: hostname
     register: hostname_output
     changed_when: false

   - name: Verify hostname
     ansible.builtin.assert:
       that: hostname_output.stdout == expected_hostname

See Also
--------

* :doc:`running-tests` - Running tests
* :doc:`molecule-architecture` - Test infrastructure
* :doc:`../development/tdd-process` - TDD workflow
