# Dependency Documentation Standard

## Problem

Role documentation listed Ansible modules (like `ansible.builtin.apt`, `community.general.npm`) as "dependencies" without clarifying:
1. These are included with Ansible or installed via requirements.yml
2. Users don't need to install them separately
3. `community.general` is included in the Ansible package

## Solution

Standardized Dependencies sections across all role documentation:

### Template

```rst
Dependencies
------------

**Ansible Collections:**

This role uses modules from the following collections:

- ``community.general`` - Included with Ansible package
- ``geerlingguy.mac.homebrew`` - For macOS support (if applicable)
- ``kewlfft.aur`` - For Arch AUR support (if applicable)

Install collection dependencies:

.. code-block:: bash

   ansible-galaxy collection install -r requirements.yml

**System Packages (installed automatically by role):**

- ``package-name`` - Description
- ``another-package`` - Description
```

### Key Points

1. **Ansible Collections section**: Lists collections used, notes which are included vs need requirements.yml
2. **Single install command**: `ansible-galaxy collection install -r requirements.yml`
3. **System Packages**: Only list packages the *role installs*, not what Ansible needs
4. **Clear distinction**: Collection modules vs system packages

### Completed Updates

- ✅ manage_packages.rst
- ✅ nodejs.rst
- ✅ rust.rst

### Remaining Updates

- ⏳ go.rst
- ⏳ neovim.rst
- ⏳ manage_flatpak.rst
- ⏳ manage_snap_packages.rst
- ⏳ manage_security_services.rst
- ⏳ os_configuration.rst
- ⏳ terminal_config.rst
- ⏳ configure_users.rst (orchestrator role - special case)
- ⏳ configure_system.rst (orchestrator role - special case)

### Special Cases

**Orchestrator Roles** (configure_system, configure_users):
- List the roles they orchestrate, not Ansible collections
- Dependencies are other roles in the collection

**Roles with no external collections** (terminal_config):
- Skip "Ansible Collections" section entirely
- Only list system packages

**Roles with optional dependencies** (os_configuration):
- Note which collections are optional vs required
- Example: devsec.hardening roles are optional

## Benefits

1. **Clear installation path**: One command installs all collection dependencies
2. **Accurate information**: Clarifies what's included vs what needs installation
3. **User-friendly**: Users know exactly what to do
4. **Consistent**: Same format across all roles
