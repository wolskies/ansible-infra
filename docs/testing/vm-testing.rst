VM Testing
==========

Comprehensive end-to-end validation using real VMs across supported platforms.

.. contents::
   :local:
   :depth: 2

Overview
--------

VM testing validates the collection on real operating systems using:

* **Terraform/libvirt** - VM provisioning with cloud images
* **Bridged Networking** - Direct SSH access to VMs
* **Discovery-based Validation** - Compare actual state vs expected configuration
* **Platform Matrix** - Ubuntu, Debian, Arch Linux

Testing Strategy
----------------

The VM testing approach:

1. **Provision VMs** - Fresh cloud images via Terraform/libvirt
2. **Deploy Collection** - Apply comprehensive configuration
3. **Run Discovery** - Capture actual system state via discovery role
4. **Validate Results** - Compare discovery output against expected configuration

This validates that the collection works correctly on bare cloud images,
the most realistic test case for real-world deployment.

Platform Matrix
---------------

Testing Coverage
~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 20 20 20 40

   * - Platform
     - Version
     - Test Type
     - Purpose
   * - Ubuntu
     - 22.04 LTS
     - Server
     - Production baseline
   * - Ubuntu
     - 24.04 LTS
     - Workstation
     - Current LTS + dev tools
   * - Debian
     - 12
     - Server
     - Debian ecosystem
   * - Arch Linux
     - Current
     - Workstation
     - Rolling release + AUR

Test Scenarios
~~~~~~~~~~~~~~

**Workstation Configuration**

* Target: Development environment setup
* Roles: configure_users, nodejs, rust, go, neovim, terminal_config
* Validation: User accounts, development tools, terminal setup

**Server Configuration**

* Target: Production server setup
* Roles: os_configuration, manage_packages, manage_security_services
* Validation: System hardening, firewall rules, services

**Mixed Configuration**

* Target: Complete system (dev + server capabilities)
* Roles: All roles combined
* Validation: Full integration testing

Prerequisites
-------------

System Requirements
~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # Arch Linux
   sudo pacman -S qemu-full libvirt terraform

   # Ubuntu/Debian
   sudo apt-get install qemu-kvm libvirt-daemon-system terraform

   # Add user to libvirt group
   sudo usermod -aG libvirt $USER
   newgrp libvirt

   # Start libvirtd
   sudo systemctl start libvirtd
   sudo systemctl enable libvirtd

Bridge Network Setup
~~~~~~~~~~~~~~~~~~~~

VMs use bridged networking (br0) with static IPs for direct SSH access.

**Arch Linux with systemd-networkd:**

.. code-block:: bash

   # Create bridge device
   sudo tee /etc/systemd/network/10-br0.netdev << EOF
   [NetDev]
   Name=br0
   Kind=bridge
   EOF

   # Configure bridge network
   sudo tee /etc/systemd/network/20-br0.network << EOF
   [Match]
   Name=br0

   [Network]
   Address=192.168.100.1/24
   DHCPServer=yes
   IPMasquerade=yes
   IPForward=yes
   EOF

   # Restart networking
   sudo systemctl restart systemd-networkd

   # Verify bridge
   ip addr show br0  # Should show 192.168.100.1/24

**Ubuntu/Debian with NetworkManager:**

.. code-block:: bash

   # Create bridge
   sudo nmcli connection add type bridge ifname br0 con-name br0
   sudo nmcli connection modify br0 ipv4.addresses 192.168.100.1/24
   sudo nmcli connection modify br0 ipv4.method manual
   sudo nmcli connection up br0

   # Verify
   nmcli connection show br0

See ``vm-test-infrastructure/BRIDGE_SETUP.md`` for detailed instructions.

Quick Start
-----------

Running VM Tests
~~~~~~~~~~~~~~~~

.. code-block:: bash

   cd vm-test-infrastructure

   # 1. Provision VMs
   cd terraform
   terraform init
   terraform apply

   # 2. Run comprehensive tests
   cd ..
   ./run-comprehensive-test.sh

   # 3. Review results
   cat validation/final-report.txt

   # 4. Clean up
   ./cleanup.sh

Directory Structure
-------------------

.. code-block:: text

   vm-test-infrastructure/
   ├── terraform/                  # VM provisioning
   │   ├── main.tf                 # VM definitions
   │   ├── cloud-init/             # Cloud-init configs
   │   └── templates/              # Inventory templates
   ├── test-scenarios/             # Test configurations
   │   ├── server-config.yml       # Server test variables
   │   └── workstation-config.yml  # Workstation test variables
   ├── validation/                 # Discovery comparison
   │   ├── validate-server.yml     # Server validation
   │   ├── validate-workstation.yml # Workstation validation
   │   └── templates/              # Report templates
   ├── inventory/                  # Generated inventory
   │   ├── hosts.ini               # Ansible inventory
   │   └── host_vars/              # Per-host vars
   ├── deploy-servers.yml          # Server deployment
   ├── deploy-workstations.yml     # Workstation deployment
   ├── run-discovery.yml           # Discovery playbook
   ├── run-comprehensive-test.sh   # Full test workflow
   └── cleanup.sh                  # VM cleanup

Test Workflow
-------------

Step-by-Step Process
~~~~~~~~~~~~~~~~~~~~

**1. VM Provisioning**

Terraform creates VMs with:

* Fresh cloud images (minimal installation)
* Bridged network with static IPs (192.168.100.50-53)
* Cloud-init with SSH key
* 2 CPU, 2GB RAM, 20GB disk

.. code-block:: bash

   cd terraform
   terraform apply -auto-approve

**2. Deploy Configuration**

Apply collection to VMs:

.. code-block:: bash

   # Deploy to servers
   ansible-playbook -i inventory/hosts.ini \
     --extra-vars "@test-scenarios/server-config.yml" \
     deploy-servers.yml

   # Deploy to workstations
   ansible-playbook -i inventory/hosts.ini \
     --extra-vars "@test-scenarios/workstation-config.yml" \
     deploy-workstations.yml

**3. Run Discovery**

Capture actual system state:

.. code-block:: bash

   ansible-playbook -i inventory/hosts.ini run-discovery.yml

This creates ``inventory/host_vars/{hostname}/vars.yml`` with discovered state.

**4. Validate Results**

Compare discovery against expected configuration:

.. code-block:: bash

   # Validate servers
   ansible-playbook -i inventory/hosts.ini \
     validation/validate-server.yml

   # Validate workstations
   ansible-playbook -i inventory/hosts.ini \
     validation/validate-workstation.yml

Validation checks:

* Packages installed
* Services running
* Firewall rules configured
* Users created
* Development tools installed

**5. Generate Report**

Creates summary report:

.. code-block:: text

   ═══════════════════════════════════════════════════════
   VM TEST VALIDATION REPORT
   ═══════════════════════════════════════════════════════

   Test Summary:
   - Total Hosts: 4
   - Passed: 4
   - Failed: 0
   - Success Rate: 100%

   Platform Results:
   ✅ ubuntu2204-server: 12/12 checks passed
   ✅ ubuntu2404-workstation: 16/16 checks passed
   ✅ debian12-server: 12/12 checks passed
   ✅ arch-workstation: 14/14 checks passed

Test Scenarios
--------------

Server Configuration
~~~~~~~~~~~~~~~~~~~~

Located in ``test-scenarios/server-config.yml``:

.. code-block:: yaml

   # System configuration
   host_hostname: "{{ inventory_hostname }}"
   domain_name: "dev.local"
   domain_timezone: "America/Los_Angeles"

   # Package installation
   manage_packages_all:
     Ubuntu: [curl, wget, git, vim]
     Debian: [curl, wget, git, vim]

   # Security services
   firewall:
     enabled: true
     default_policy:
       incoming: deny
       outgoing: allow
     rules:
       - { port: 22, protocol: tcp, rule: allow }
       - { port: 80, protocol: tcp, rule: allow }

Workstation Configuration
~~~~~~~~~~~~~~~~~~~~~~~~~~

Located in ``test-scenarios/workstation-config.yml``:

.. code-block:: yaml

   # User environment
   users:
     - name: ed
       shell: /bin/bash
       git:
         user_name: "Ed Wolski"
         user_email: "ed@dev.local"
       nodejs:
         packages: [typescript, eslint]
       rust:
         packages: [ripgrep, bat]
       neovim:
         enabled: true

   # Development packages
   manage_packages_all:
     Ubuntu: [mc, emacs-nox]
     Archlinux: [firefox, mc]

Validation Approach
-------------------

Discovery-Based Validation
~~~~~~~~~~~~~~~~~~~~~~~~~~

Rather than testing implementation details, we validate outcomes:

1. **Deploy** - Apply configuration to VMs
2. **Discover** - Capture actual system state
3. **Compare** - Match discovery output against expected values

This approach:

* Tests real-world functionality
* Validates end-to-end behavior
* Catches integration issues
* Proves configuration works on bare systems

Validation Checks
~~~~~~~~~~~~~~~~~

**Package Installation**

.. code-block:: yaml

   - name: Verify packages installed
     assert:
       that: "'{{ item }}' in ansible_facts.packages"
       fail_msg: "Package {{ item }} not installed"
     loop: "{{ expected_packages }}"

**Service Status**

.. code-block:: yaml

   - name: Verify services running
     assert:
       that: "services[item].state == 'running'"
       fail_msg: "Service {{ item }} not running"
     loop: "{{ expected_services }}"

**Firewall Rules**

.. code-block:: yaml

   - name: Verify firewall rules
     assert:
       that: "item in ufw_rules"
       fail_msg: "Firewall rule {{ item }} not configured"
     loop: "{{ expected_rules }}"

Troubleshooting
---------------

Common Issues
~~~~~~~~~~~~~

**Bridge Network Not Available**

.. code-block:: bash

   # Verify bridge exists
   ip addr show br0

   # If missing, see BRIDGE_SETUP.md
   # Or use NAT network (edit terraform/main.tf)

**Terraform Apply Fails**

.. code-block:: bash

   # Check libvirt is running
   sudo systemctl status libvirtd

   # Verify storage pool
   virsh pool-list --all

   # Check terraform state
   terraform show

**SSH Connection Failures**

.. code-block:: bash

   # Verify VMs are running
   virsh list --all

   # Check VM IP addresses
   virsh domifaddr ubuntu2204-server

   # Test SSH manually
   ssh -i ~/.ssh/id_ed25519 ed@192.168.100.50

**Discovery Failures**

.. code-block:: bash

   # Run discovery manually
   ansible-playbook -i inventory/hosts.ini run-discovery.yml -v

   # Check generated vars
   cat inventory/host_vars/ubuntu2204-server/vars.yml

Cleaning Up
-----------

Remove VMs
~~~~~~~~~~

.. code-block:: bash

   # Using cleanup script
   ./cleanup.sh

   # Manual cleanup
   cd terraform
   terraform destroy -auto-approve

   # Remove generated files
   rm -rf inventory/host_vars/*/vars.yml
   rm -f ssh-config inventory/hosts.ini

Verify Cleanup
~~~~~~~~~~~~~~

.. code-block:: bash

   # Check no VMs running
   virsh list --all

   # Check terraform state
   cd terraform && terraform show

CI Integration
--------------

Future Plans
~~~~~~~~~~~~

VM testing is currently manual. Future plans include:

* GitLab CI runners with nested virtualization
* Automated VM test runs on merge requests
* Performance benchmarking
* Long-running stability tests

See Also
--------

* :doc:`running-tests` - Local molecule testing
* :doc:`molecule-architecture` - Test infrastructure
* :doc:`writing-tests` - Creating new tests
