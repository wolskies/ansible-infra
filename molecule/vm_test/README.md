# VM Test Scenario

This molecule scenario tests roles against actual VMs using the delegated driver.

## Prerequisites

1. Create your test VMs (Ubuntu 24.04, Debian 12, etc.)
2. Ensure SSH access is configured
3. Update the `molecule.yml` with your VM details

## Configuration

Edit `molecule.yml` and update the following for each VM:

```yaml
ansible_host: 192.168.1.100      # Your VM's IP address
ansible_user: testuser            # SSH user with sudo access
ansible_ssh_private_key_file: ~/.ssh/id_rsa  # Path to SSH key
```

## Running Tests

```bash
# Run the full test sequence
molecule test -s vm_test

# Just converge (apply roles)
molecule converge -s vm_test

# Just verify (check state)
molecule verify -s vm_test

# Connect to a VM
molecule login -s vm_test -h ubuntu24-vm
```

## What Gets Tested

The verify.yml checks:

- ✅ Hostname configuration
- ✅ /etc/hosts entries
- ✅ Service states (SSH, firewall, etc.)
- ✅ Package installation
- ✅ User creation
- ✅ Firewall rules and status
- ✅ System timezone
- ✅ System locale

## Adding Test Expectations

In molecule.yml, add expectations under each host:

```yaml
host_vars:
  ubuntu24-vm:
    # Configuration
    host_hostname: "ubuntu-test"

    # Test expectations
    expected_hostname: "ubuntu-test"
    expected_packages:
      - vim
      - git
    expected_services:
      - ssh
    expected_users:
      - testuser
```

## Troubleshooting

- If SSH fails, check `ansible_host` and `ansible_user` settings
- For permission issues, ensure the user has passwordless sudo
- For "host unreachable", verify network connectivity and firewall rules
