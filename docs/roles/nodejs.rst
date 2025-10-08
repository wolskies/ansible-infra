nodejs
======

Node.js installation and user-level npm package management.

.. contents::
   :local:
   :depth: 2

Overview
--------

The ``nodejs`` role installs the Node.js runtime and manages user-level npm packages. It supports multiple platforms with platform-specific package sources and configures user directories for npm global installations.

**All npm packages install to user directories** (``~/.npm-global/``) rather than system-wide, allowing per-user package management without requiring root privileges.

Features
~~~~~~~~

- **Node.js Installation** - Platform-specific Node.js runtime installation
- **NodeSource Repository** - Current Node.js versions for Ubuntu/Debian
- **User-Level Packages** - npm packages in ``~/.npm-global/``
- **PATH Configuration** - Automatic PATH setup in ``~/.profile``
- **Version Control** - Specify Node.js major version (Ubuntu/Debian)
- **Cross-platform** - Ubuntu, Debian, Arch Linux, macOS support

Platform Support
~~~~~~~~~~~~~~~~

- **Ubuntu** 22.04+, 24.04+
- **Debian** 12+, 13+
- **Arch Linux** (Rolling)
- **macOS** 13+ (Ventura)

Usage
-----

Basic Package Installation
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Install Node.js and npm packages for a user:

.. code-block:: yaml

   - hosts: developers
     become: true
     roles:
       - wolskies.infrastructure.nodejs
     vars:
       node_user: developer
       node_packages:
         - typescript
         - eslint
         - prettier
         - "@vue/cli"

With Version Specifications
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Install packages with specific versions:

.. code-block:: yaml

   node_user: developer
   node_packages:
     # Simple string format (latest version)
     - typescript
     - "@angular/cli"

     # Object format with version specification
     - name: eslint
       version: "8.0.0"
     - name: webpack
       version: "^5.0.0"

Specify Node.js Version
~~~~~~~~~~~~~~~~~~~~~~~~

Control Node.js major version (Ubuntu/Debian only):

.. code-block:: yaml

   nodejs_version: "20"  # Install Node.js 20.x from NodeSource
   node_user: developer
   node_packages:
     - typescript

Integration with configure_users
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The ``nodejs`` role is typically invoked via :doc:`configure_users`:

.. code-block:: yaml

   users:
     - name: developer
       nodejs:
         packages:
           - typescript
           - eslint
           - prettier
           - "@nestjs/cli"

Variables
---------

Role Variables
~~~~~~~~~~~~~~

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
     - npm packages to install (see format below). Default: []
   * - ``nodejs_version``
     - string
     - Major version of Node.js (Ubuntu/Debian NodeSource). Default: "20"
   * - ``npm_config_prefix``
     - string
     - Directory for npm global installations. Default: "~/.npm-global"
   * - ``npm_config_unsafe_perm``
     - string
     - Suppress UID/GID switching in package scripts. Default: "true"

Package Format
~~~~~~~~~~~~~~

Supports both simple and detailed package specifications:

.. code-block:: yaml

   node_packages:
     # Simple string format (installs latest)
     - "package-name"
     - "@scoped/package"

     # Object format with version
     - name: "package-name"
       version: "1.0.0"
     - name: "@scoped/package"
       version: "^2.0.0"
     - name: "typescript"
       version: "~5.0.0"

Version Specifications
~~~~~~~~~~~~~~~~~~~~~~

npm supports standard semver ranges:

- **Exact**: ``"1.2.3"`` - Exact version
- **Caret**: ``"^1.2.3"`` - Compatible with 1.x.x
- **Tilde**: ``"~1.2.3"`` - Compatible with 1.2.x
- **Range**: ``">=1.2.3 <2.0.0"`` - Version range
- **Latest**: Omit version for latest stable

Installation Behavior
---------------------

Installation Process
~~~~~~~~~~~~~~~~~~~~

1. **Node.js Installation Check** - Verify if Node.js/npm exists
2. **System Installation** - Install Node.js via package manager:

   - **Ubuntu/Debian** - NodeSource repository for specified version
   - **Arch Linux** - Official ``nodejs`` and ``npm`` packages
   - **macOS** - Homebrew ``node`` package

3. **User Directory Setup** - Create ``~/.npm-global`` directory
4. **Package Installation** - Install packages with user-local configuration
5. **PATH Configuration** - Add ``~/.npm-global/bin`` to user's ``.profile``

User-Level Package Management
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

All npm packages install to user directories:

- **Packages**: ``~/.npm-global/lib/node_modules/``
- **Binaries**: ``~/.npm-global/bin/``
- **Configuration**: ``NPM_CONFIG_PREFIX=~/.npm-global``

Users can manage packages without root:

.. code-block:: bash

   npm install -g typescript  # Installs to ~/.npm-global/
   npm update -g              # Update all global packages
   npm list -g --depth=0      # List installed packages

PATH Configuration
~~~~~~~~~~~~~~~~~~

The role automatically adds npm binaries to PATH by appending to ``~/.profile``:

.. code-block:: bash

   export PATH="$PATH:$HOME/.npm-global/bin"

**Activation:**

- Automatic on next login
- Manual: ``source ~/.profile``
- Shell-specific: Add to ``~/.bashrc``, ``~/.zshrc``, etc.

Platform-Specific Features
--------------------------

Ubuntu/Debian
~~~~~~~~~~~~~

**NodeSource Repository:**

Ubuntu/Debian use the NodeSource repository for current Node.js versions:

- Configurable Node.js version (default: v20)
- Automatic GPG key and repository setup
- More recent versions than distribution packages

**Repository Configuration:**

.. code-block:: yaml

   nodejs_version: "20"  # v20.x LTS
   nodejs_version: "21"  # v21.x Current
   nodejs_version: "18"  # v18.x LTS

**Required System Packages:**

- ``python3-debian`` - Required for deb822_repository module
- Automatically installed by the role

Arch Linux
~~~~~~~~~~

**Official Repositories:**

- Uses official Arch packages: ``nodejs`` and ``npm``
- Always current versions from Arch repos
- No version selection (always latest stable)

macOS
~~~~~

**Homebrew Installation:**

- Uses Homebrew for Node.js: ``brew install node``
- Integrates with existing Homebrew setup
- System-wide installation via Homebrew

Tags
----

Control Node.js configuration:

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - Tag
     - Description
   * - ``nodejs-system``
     - Node.js runtime installation
   * - ``nodejs-packages``
     - npm package installation

Examples
--------

Frontend Development
~~~~~~~~~~~~~~~~~~~~

Complete frontend toolchain:

.. code-block:: yaml

   - hosts: frontend_devs
     become: true
     roles:
       - wolskies.infrastructure.nodejs
     vars:
       node_user: developer
       node_packages:
         - typescript
         - "@angular/cli"
         - "@vue/cli"
         - create-react-app
         - eslint
         - prettier
         - webpack
         - vite
         - jest
         - "@types/node"

Backend Development
~~~~~~~~~~~~~~~~~~~

Node.js backend tools:

.. code-block:: yaml

   node_user: backend_dev
   node_packages:
     - typescript
     - "@nestjs/cli"
     - pm2
     - nodemon
     - ts-node
     - typeorm
     - prisma

Build and Testing Tools
~~~~~~~~~~~~~~~~~~~~~~~

CI/CD and development utilities:

.. code-block:: yaml

   node_user: cicd
   node_packages:
     - npm-check-updates
     - yarn
     - pnpm
     - eslint
     - prettier
     - jest
     - mocha
     - nyc

Specific Versions for Project Compatibility
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Lock to specific versions for team consistency:

.. code-block:: yaml

   node_user: developer
   nodejs_version: "18"  # LTS version
   node_packages:
     - name: typescript
       version: "5.0.4"
     - name: "@angular/cli"
       version: "16.0.0"
     - name: eslint
       version: "8.42.0"

Skip System Installation
~~~~~~~~~~~~~~~~~~~~~~~~~

Install only packages (Node.js already present):

.. code-block:: bash

   ansible-playbook --skip-tags nodejs-system playbook.yml

Common npm Packages
-------------------

Development Tools
~~~~~~~~~~~~~~~~~

- ``typescript`` - TypeScript compiler
- ``eslint`` - JavaScript linter
- ``prettier`` - Code formatter
- ``nodemon`` - Development server with auto-reload
- ``ts-node`` - TypeScript execution engine

Frontend Frameworks
~~~~~~~~~~~~~~~~~~~

- ``@angular/cli`` - Angular CLI
- ``@vue/cli`` - Vue CLI
- ``create-react-app`` - React app generator
- ``next`` - Next.js framework
- ``vite`` - Build tool and dev server

Backend Frameworks
~~~~~~~~~~~~~~~~~~

- ``@nestjs/cli`` - NestJS CLI
- ``express-generator`` - Express app generator
- ``koa-generator`` - Koa app generator

Build Tools
~~~~~~~~~~~

- ``webpack`` - Module bundler
- ``rollup`` - Module bundler
- ``parcel`` - Zero-config bundler
- ``gulp`` - Task runner
- ``grunt`` - Task automation

Package Managers
~~~~~~~~~~~~~~~~

- ``yarn`` - Fast package manager
- ``pnpm`` - Efficient package manager
- ``npm-check-updates`` - Update dependencies

Process Managers
~~~~~~~~~~~~~~~~

- ``pm2`` - Production process manager
- ``forever`` - Simple process manager

Testing Tools
~~~~~~~~~~~~~

- ``jest`` - Testing framework
- ``mocha`` - Test framework
- ``chai`` - Assertion library
- ``nyc`` - Code coverage

Troubleshooting
---------------

npm Command Not Found
~~~~~~~~~~~~~~~~~~~~~

If npm commands aren't found after installation:

1. **Reload shell configuration:**

   .. code-block:: bash

      source ~/.profile

2. **Verify PATH:**

   .. code-block:: bash

      echo $PATH | grep npm-global

3. **Logout and login again** for automatic PATH loading

Permission Errors
~~~~~~~~~~~~~~~~~

If you encounter permission errors during package installation:

1. **Verify npm prefix:**

   .. code-block:: bash

      npm config get prefix

   Should output: ``/home/username/.npm-global``

2. **Fix manually if needed:**

   .. code-block:: bash

      npm config set prefix ~/.npm-global

Package Installation Fails
~~~~~~~~~~~~~~~~~~~~~~~~~~~

If package installation fails:

1. **Check Node.js version:**

   .. code-block:: bash

      node --version
      npm --version

2. **Clear npm cache:**

   .. code-block:: bash

      npm cache clean --force

3. **Update npm itself:**

   .. code-block:: bash

      npm install -g npm@latest

NodeSource Repository Issues (Ubuntu/Debian)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If NodeSource repository configuration fails:

1. **Verify python3-debian is installed:**

   .. code-block:: bash

      apt list --installed | grep python3-debian

2. **Check repository configuration:**

   .. code-block:: bash

      cat /etc/apt/sources.list.d/nodesource.sources

3. **Manually add if needed:**

   .. code-block:: bash

      curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
      sudo apt-get install -y nodejs

Dependencies
------------

**Ansible Collections:**

This role uses modules from the following collections:

- ``community.general`` - Included with Ansible package

Install collection dependencies:

.. code-block:: bash

   ansible-galaxy collection install -r requirements.yml

**System Packages (installed automatically by role):**

- ``nodejs`` - Node.js runtime
- ``npm`` - Node package manager
- ``python3-debian`` - deb822 repository support (Ubuntu/Debian)

See Also
--------

- :doc:`configure_users` - User environment orchestration
- :doc:`rust` - Rust development environment
- :doc:`go` - Go development environment
- :doc:`/reference/variables-reference` - Complete variable reference
- `Node.js <https://nodejs.org/>`_ - Official Node.js website
- `npm <https://www.npmjs.com/>`_ - npm package registry
