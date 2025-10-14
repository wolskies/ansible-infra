install_nodejs
==============

Utility role for Node.js installation and user-level npm package management.

.. contents::
   :local:
   :depth: 2

Overview
--------

The ``install_nodejs`` role installs Node.js and manages npm packages at the user level. This is a utility role typically orchestrated by :doc:`configure_users` but can also be used standalone.

**Key Features:**

- **Node.js Installation** - System-level Node.js via package manager
- **NodeSource Repository** - Current Node.js versions on Ubuntu/Debian
- **User-Level Packages** - npm packages in user's home directory (``~/.npm-global/``)
- **PATH Configuration** - Automatic PATH setup in user's ``.profile``
- **Version Control** - Specify package versions or install latest

Platform Support
~~~~~~~~~~~~~~~~

- **Ubuntu** 22.04+, 24.04+
- **Debian** 12+, 13+
- **Arch Linux** (Rolling)
- **macOS** 13+ (Ventura)

Usage
-----

Standalone Usage
~~~~~~~~~~~~~~~~

Install Node.js and packages for a specific user:

.. code-block:: yaml

   - hosts: developers
     become: true
     roles:
       - wolskies.infrastructure.install_nodejs
     vars:
       node_user: developer
       node_packages:
         - typescript
         - eslint
         - prettier
         - "@vue/cli"
         - "@angular/cli"

With Version Specifications
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Control package versions:

.. code-block:: yaml

   node_user: developer
   node_packages:
     # String format (installs latest)
     - typescript
     - "@angular/cli"
     - prettier

     # Object format with version
     - name: eslint
       version: "8.0.0"
     - name: webpack
       version: "^5.0.0"
     - name: "@nestjs/cli"
       version: "~10.0.0"

Integration with configure_users
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Typically used via configure_users role:

.. code-block:: yaml

   users:
     - name: developer
       nodejs:
         packages:
           - typescript
           - eslint
           - prettier
           - "@nestjs/cli"
           - "@vue/cli"

Multiple Users
~~~~~~~~~~~~~~

Configure different packages for different users:

.. code-block:: yaml

   # group_vars/developers.yml
   users:
     - name: alice
       nodejs:
         packages:
           - typescript
           - "@angular/cli"
           - eslint

     - name: bob
       nodejs:
         packages:
           - "@vue/cli"
           - "@vitejs/plugin-vue"

Variables
---------

.. list-table::
   :header-rows: 1
   :widths: 25 15 60

   * - Variable
     - Type
     - Description
   * - ``node_user``
     - string
     - Target username for npm package installation (required)
   * - ``node_packages``
     - list
     - npm packages to install (string or object format)
   * - ``nodejs_version``
     - string
     - Node.js major version (Ubuntu/Debian only). Default: "20"
   * - ``npm_config_prefix``
     - string
     - npm global installation directory. Default: "~/.npm-global"

Package Format
~~~~~~~~~~~~~~

Two formats are supported:

**String Format** (installs latest version):

.. code-block:: yaml

   node_packages:
     - "package-name"
     - "@scoped/package"

**Object Format** (with version specification):

.. code-block:: yaml

   node_packages:
     - name: "package-name"
       version: "1.0.0"      # Exact version
     - name: "@scoped/package"
       version: "^2.0.0"     # Compatible with 2.x
     - name: "another-package"
       version: "~3.1.0"     # Approximately 3.1.x

Installation Behavior
---------------------

The role performs these steps:

1. **Node.js Installation Check**

   - Verifies if Node.js and npm are already installed
   - Skips installation if present

2. **System Installation**

   - **Ubuntu/Debian**: Adds NodeSource repository for specified version
   - **Arch Linux**: Installs from official repositories
   - **macOS**: Installs via Homebrew

3. **User Directory Setup**

   - Creates ``~/.npm-global`` directory
   - Sets ownership to target user

4. **Package Installation**

   - Installs packages with user-local configuration
   - Uses ``NPM_CONFIG_PREFIX=~/.npm-global``

5. **PATH Configuration**

   - Adds ``~/.npm-global/bin`` to user's ``.profile``
   - User can execute installed packages after login

Platform-Specific Features
---------------------------

Ubuntu/Debian
~~~~~~~~~~~~~

- Uses NodeSource repository for current Node.js versions
- Configurable Node.js version (default: v20)
- Automatic GPG key and repository setup
- Supports: Node.js 16, 18, 20, 21

Set Node.js version:

.. code-block:: yaml

   nodejs_version: "18"  # Install Node.js 18.x

Arch Linux
~~~~~~~~~~

- Uses official repository packages
- Always current versions from Arch repos
- Includes npm automatically

macOS
~~~~~

- Uses Homebrew for Node.js installation
- Integrates with existing Homebrew setup
- Homebrew must be installed first (via configure_software)

User-Level Package Management
------------------------------

All npm packages install to user directories:

**Directory Structure:**

- **Packages**: ``~/.npm-global/lib/node_modules/``
- **Binaries**: ``~/.npm-global/bin/``
- **Configuration**: ``NPM_CONFIG_PREFIX=~/.npm-global``

**PATH Setup:**

The role automatically adds to ``~/.profile``:

.. code-block:: bash

   export PATH="$HOME/.npm-global/bin:$PATH"

**Benefits:**

- No system-wide changes
- No root privileges for package management
- Multiple users can have different packages/versions
- User controls their own packages

Using Installed Packages
-------------------------

After installation and login, packages are available:

.. code-block:: bash

   # TypeScript compiler
   tsc --version

   # ESLint
   eslint myfile.js

   # Angular CLI
   ng new my-app

   # Vue CLI
   vue create my-app

**Note:** User must logout and login (or source ``. ~/.profile``) for PATH changes to take effect.

Examples
--------

Frontend Developer Setup
~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   node_user: frontend-dev
   node_packages:
     - typescript
     - "@angular/cli"
     - "@vue/cli"
     - eslint
     - prettier
     - webpack
     - vite

Backend Developer Setup
~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   node_user: backend-dev
   node_packages:
     - typescript
     - "@nestjs/cli"
     - ts-node
     - nodemon
     - pm2

DevOps/Tooling Setup
~~~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   node_user: devops
   node_packages:
     - npm-check-updates
     - serverless
     - "@aws-amplify/cli"
     - netlify-cli

Dependencies
------------

**Ansible Collections:**

- ``community.general`` - npm module
- ``ansible.builtin`` - deb822_repository module (Ubuntu/Debian)

**System Requirements:**

- User account must exist
- Internet access for package downloads
- Homebrew (macOS only)

Install dependencies:

.. code-block:: bash

   ansible-galaxy collection install -r requirements.yml

Limitations
-----------

**PATH Configuration:**

PATH updates are added to ``~/.profile``, which requires:

- User logout/login for changes to take effect
- Or manually source: ``source ~/.profile``
- Some shells may not source ``.profile`` automatically

**NodeSource Repository:**

On Ubuntu/Debian:

- Only major versions available (16, 18, 20, 21)
- Cannot specify minor versions
- Repository must be accessible

**User Requirements:**

- User must exist before role execution
- Role does not create users
- Skips if user doesn't exist

See Also
--------

- :doc:`configure_users` - Phase 3 role that orchestrates this utility role
- :doc:`install_rust` - Rust utility role
- :doc:`install_go` - Go utility role
- :doc:`install_neovim` - Neovim utility role
- :doc:`configure_software` - Phase 2 role (installs Node.js system-wide if needed)
- :doc:`/reference/variables-reference` - Complete variable reference
