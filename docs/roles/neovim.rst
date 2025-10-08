neovim
======

Comprehensive Neovim installation and development-ready configuration.

.. contents::
   :local:
   :depth: 2

Overview
--------

The ``neovim`` role installs Neovim with a comprehensive, development-ready configuration. It includes plugin management, Language Server Protocol (LSP) support, and a vim compatibility alias for seamless transition from traditional vim.

Features
~~~~~~~~

- **Neovim Installation** - Latest available version via system package manager
- **Plugin Manager** - lazy.nvim for efficient plugin management
- **LSP Configuration** - Language server protocol support for multiple languages
- **Development Dependencies** - Git and language servers (platform-dependent)
- **Vim Compatibility** - Alias for seamless transition from vim
- **Lua Configuration** - Modern Lua-based configuration for performance

Platform Support
~~~~~~~~~~~~~~~~

- **Ubuntu** 22.04+, 24.04+
- **Debian** 12+, 13+
- **Arch Linux** (Rolling)
- **macOS** 13+ (Ventura)

Usage
-----

Basic Installation
~~~~~~~~~~~~~~~~~~

Install Neovim with default configuration:

.. code-block:: yaml

   - hosts: developers
     become: true
     roles:
       - wolskies.infrastructure.neovim
     vars:
       neovim_user: developer

Minimal Installation (No Configuration)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Install Neovim without the included configuration:

.. code-block:: yaml

   neovim_user: developer
   neovim_config_enabled: false

This installs only Neovim itself, allowing users to bring their own configuration.

Integration with configure_users
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The ``neovim`` role is typically invoked via :doc:`configure_users`:

.. code-block:: yaml

   users:
     - name: developer
       neovim:
         deploy_config: true

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
   * - ``neovim_user``
     - string
     - Target username for Neovim installation (required)
   * - ``neovim_config_enabled``
     - boolean
     - Enable comprehensive configuration deployment. Default: true

Installation Behavior
---------------------

Installation Process
~~~~~~~~~~~~~~~~~~~~

1. **Neovim Installation** - Install Neovim and dependencies:

   - **Ubuntu/Debian** - APT ``neovim`` and ``git`` packages
   - **Arch Linux** - Pacman ``neovim``, ``git``, ``lua-language-server``, and ``pyright``
   - **macOS** - Homebrew ``neovim``, ``git``, ``lua-language-server``, and ``pyright``

2. **Plugin Manager Setup** - Clone lazy.nvim to ``~/.local/share/nvim/lazy/lazy.nvim``

3. **Configuration Deployment** - Create comprehensive Lua-based configuration in ``~/.config/nvim/``

4. **Vim Compatibility** - Create ``~/.local/bin/vim`` alias script

Configuration Features
~~~~~~~~~~~~~~~~~~~~~~

When ``neovim_config_enabled`` is ``true`` (default), the role deploys:

**Plugin Management:**

- lazy.nvim - Efficient, lazy-loading plugin manager
- Automatic plugin installation on first launch

**LSP Support:**

- Pre-configured for ``lua_ls``, ``rust_analyzer``, and ``pyright``
- Language server installation handled per-platform
- Intelligent code completion and diagnostics

**Development Bindings:**

- Essential key mappings for development workflow
- Optimized for programming tasks

**Modern Configuration:**

- Lua-based for performance
- Well-organized configuration structure
- Easy to customize and extend

File Locations
--------------

Neovim Files
~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 40 60

   * - Path
     - Description
   * - ``~/.config/nvim/``
     - Neovim configuration directory
   * - ``~/.config/nvim/init.lua``
     - Main configuration file
   * - ``~/.local/share/nvim/lazy/lazy.nvim``
     - Plugin manager
   * - ``~/.local/share/nvim/lazy/``
     - Installed plugins
   * - ``~/.local/bin/vim``
     - Vim compatibility alias
   * - ``~/.local/bin/``
     - User binaries (added to PATH if needed)

Vim Compatibility
-----------------

The role creates a vim compatibility alias that:

- Redirects ``vim`` commands to ``nvim``
- Maintains muscle memory for users transitioning from vim
- Preserves all command-line arguments and options
- Located in ``~/.local/bin/vim``

**Alias Script:**

.. code-block:: bash

   #!/bin/sh
   exec nvim "$@"

**Usage:**

.. code-block:: bash

   vim file.txt         # Actually runs: nvim file.txt
   vim +10 file.txt     # Opens file at line 10
   vim -d file1 file2   # Diff mode

Platform-Specific Features
--------------------------

Ubuntu/Debian
~~~~~~~~~~~~~

**Packages Installed:**

- ``neovim`` - Neovim editor
- ``git`` - Required for plugin manager

**LSP Servers:**

Language servers must be installed separately on Ubuntu/Debian. Common options:

.. code-block:: bash

   # Lua language server (manual installation required)
   # See: https://github.com/LuaLS/lua-language-server

   # Python language server
   pip install pyright

   # Rust analyzer (via rustup)
   rustup component add rust-analyzer

Arch Linux
~~~~~~~~~~

**Packages Installed:**

- ``neovim`` - Neovim editor
- ``git`` - Plugin manager dependency
- ``lua-language-server`` - Lua LSP
- ``pyright`` - Python LSP

**Enhanced LSP:**

Arch Linux includes language servers out-of-the-box for immediate development readiness.

macOS
~~~~~

**Packages Installed:**

- ``neovim`` - Neovim editor (via Homebrew)
- ``git`` - Plugin manager dependency
- ``lua-language-server`` - Lua LSP
- ``pyright`` - Python LSP

**Homebrew Integration:**

Integrates with existing Homebrew setup for consistent package management.

Tags
----

Control Neovim configuration:

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - Tag
     - Description
   * - ``neovim-system``
     - Neovim package installation
   * - ``neovim-config``
     - Configuration and plugin setup
   * - ``neovim-alias``
     - Vim compatibility alias

Examples
--------

Full Installation with Configuration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   - hosts: developers
     become: true
     roles:
       - wolskies.infrastructure.neovim
     vars:
       neovim_user: developer
       neovim_config_enabled: true

Minimal Installation
~~~~~~~~~~~~~~~~~~~~

Install only Neovim without included configuration:

.. code-block:: yaml

   neovim_user: developer
   neovim_config_enabled: false

Multiple Users
~~~~~~~~~~~~~~

Configure Neovim for multiple users via :doc:`configure_users`:

.. code-block:: yaml

   users:
     - name: alice
       neovim:
         deploy_config: true

     - name: bob
       neovim:
         deploy_config: true

Skip Configuration Deployment
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Install Neovim but skip configuration (bring your own config):

.. code-block:: bash

   ansible-playbook --skip-tags neovim-config playbook.yml

Configuration Details
---------------------

Included Configuration
~~~~~~~~~~~~~~~~~~~~~~

The default configuration includes:

**Basic Settings:**

- Line numbers
- Relative line numbers
- Syntax highlighting
- Smart indentation
- Search highlighting
- Case-insensitive search (unless uppercase used)

**Plugin Manager:**

- lazy.nvim - Lazy-loading plugin manager
- Automatic plugin installation
- Fast startup time

**LSP Configuration:**

- Language server support
- Auto-completion
- Go-to-definition
- Hover documentation
- Diagnostics

**Supported Languages:**

- Lua (``lua_ls``)
- Rust (``rust_analyzer``)
- Python (``pyright``)

Customization
~~~~~~~~~~~~~

Users can customize their configuration by editing:

.. code-block:: bash

   ~/.config/nvim/init.lua

The included configuration serves as a starting point for further customization.

First Launch
------------

Plugin Installation
~~~~~~~~~~~~~~~~~~~

On first launch, lazy.nvim will automatically install configured plugins:

1. **Launch Neovim:**

   .. code-block:: bash

      nvim

2. **Wait for plugins** to install (automatic)

3. **Restart Neovim** after initial setup completes

Language Server Setup
~~~~~~~~~~~~~~~~~~~~~

**Arch Linux and macOS:**

Language servers are pre-installed and ready to use.

**Ubuntu/Debian:**

Install language servers manually as needed:

.. code-block:: bash

   # Python
   pip install pyright

   # Rust (requires rustup)
   rustup component add rust-analyzer

   # Node.js (requires npm)
   npm install -g typescript typescript-language-server

Troubleshooting
---------------

vim Alias Not Working
~~~~~~~~~~~~~~~~~~~~~

If ``vim`` doesn't redirect to ``nvim``:

1. **Verify alias exists:**

   .. code-block:: bash

      ls -l ~/.local/bin/vim

2. **Check PATH includes ~/.local/bin:**

   .. code-block:: bash

      echo $PATH | grep ".local/bin"

3. **Make alias executable:**

   .. code-block:: bash

      chmod +x ~/.local/bin/vim

4. **Reload shell:**

   .. code-block:: bash

      source ~/.profile

Plugins Don't Install
~~~~~~~~~~~~~~~~~~~~~

If plugins fail to install on first launch:

1. **Check internet connection** (plugins are downloaded from GitHub)

2. **Verify git is installed:**

   .. code-block:: bash

      which git
      git --version

3. **Manually trigger plugin installation:**

   .. code-block:: vim

      :Lazy sync

4. **Check plugin directory:**

   .. code-block:: bash

      ls ~/.local/share/nvim/lazy/

LSP Not Working
~~~~~~~~~~~~~~~

If language servers don't work:

1. **Verify language server is installed:**

   .. code-block:: bash

      which lua-language-server
      which pyright
      which rust-analyzer

2. **Check LSP status in Neovim:**

   .. code-block:: vim

      :LspInfo

3. **Install missing language servers** (see Platform-Specific Features)

Configuration Errors
~~~~~~~~~~~~~~~~~~~~

If configuration has errors:

1. **Check for syntax errors:**

   .. code-block:: bash

      nvim ~/.config/nvim/init.lua

2. **View error messages:**

   .. code-block:: vim

      :messages

3. **Reset to defaults** if needed:

   .. code-block:: bash

      mv ~/.config/nvim ~/.config/nvim.backup
      # Re-run ansible playbook

Dependencies
------------

**Ansible Collections:**

This role uses modules from the following collections:

- ``community.general`` - Included with Ansible package

Install collection dependencies:

.. code-block:: bash

   ansible-galaxy collection install -r requirements.yml

**System Packages (installed automatically by role):**

- ``neovim`` - Neovim editor
- ``git`` - Version control (required by plugin manager)
- ``lua-language-server`` - Lua LSP (Arch/macOS only)
- ``pyright`` - Python LSP (Arch/macOS only)

See Also
--------

- :doc:`configure_users` - User environment orchestration
- :doc:`terminal_config` - Terminal emulator configuration
- :doc:`/reference/variables-reference` - Complete variable reference
- `Neovim <https://neovim.io/>`_ - Official Neovim website
- `lazy.nvim <https://github.com/folke/lazy.nvim>`_ - Plugin manager
- `nvim-lspconfig <https://github.com/neovim/nvim-lspconfig>`_ - LSP configurations
