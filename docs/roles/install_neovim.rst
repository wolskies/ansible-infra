install_neovim
==============

Utility role for Neovim installation with optional LSP configuration deployment.

.. contents::
   :local::
   :depth: 2

Overview
--------

The ``install_neovim`` role installs Neovim with optional LSP configuration using lazy.nvim plugin manager. This is a utility role typically orchestrated by :doc:`configure_users` but can also be used standalone.

**Key Features:**

- **Neovim Installation** - Latest version via system package manager
- **Plugin Manager** - lazy.nvim for efficient plugin management
- **LSP Configuration** - Language Server Protocol support for Lua, Rust, Python
- **Development Dependencies** - Git and language servers (platform-dependent)
- **Vim Compatibility** - Alias for seamless transition from vim
- **User-Level Setup** - Configuration in ``~/.config/nvim/``

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

Install Neovim with default LSP configuration:

.. code-block:: yaml

   - hosts: developers
     become: true
     roles:
       - wolskies.infrastructure.install_neovim
     vars:
       neovim_user: developer
       neovim_config_enabled: true

Install Neovim without configuration:

.. code-block:: yaml

   - hosts: developers
     become: true
     roles:
       - wolskies.infrastructure.install_neovim
     vars:
       neovim_user: developer
       neovim_config_enabled: false

This installs only Neovim itself, allowing users to bring their own configuration.

Integration with configure_users
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Typically used via configure_users role:

.. code-block:: yaml

   users:
     - name: developer
       neovim:
         deploy_config: true

     - name: alice
       neovim:
         deploy_config: false  # Install Neovim only, no config

Multiple Users
~~~~~~~~~~~~~~

Configure Neovim for different users:

.. code-block:: yaml

   users:
     - name: developer
       git:
         user_name: "Developer Name"
         user_email: "developer@company.com"
       neovim:
         deploy_config: true

     - name: sysadmin
       neovim:
         deploy_config: false  # Bring their own config

Variables
---------

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
     - Enable LSP configuration deployment. Default: true

Installation Behavior
---------------------

The role performs these steps:

1. **Neovim Installation**

   - **Ubuntu/Debian**: Installs ``neovim`` and ``git`` via APT
   - **Arch Linux**: Installs ``neovim``, ``git``, ``lua-language-server``, ``pyright`` via pacman
   - **macOS**: Installs ``neovim``, ``git``, ``lua-language-server``, ``pyright`` via Homebrew

2. **Plugin Manager Setup**

   - Clones lazy.nvim to ``~/.local/share/nvim/lazy/lazy.nvim``
   - Sets up plugin directory structure

3. **Configuration Deployment** (if ``neovim_config_enabled: true``)

   - Creates ``~/.config/nvim/init.lua`` with LSP configuration
   - Configures Language Server Protocol support
   - Sets up development bindings

4. **Vim Compatibility Alias**

   - Creates ``~/.local/bin/vim`` alias script
   - Redirects ``vim`` commands to ``nvim``
   - Adds ``~/.local/bin`` to PATH if needed

Platform-Specific Features
---------------------------

Ubuntu/Debian
~~~~~~~~~~~~~

**Packages Installed:**

- ``neovim`` - Neovim editor
- ``git`` - Required for plugin manager

**LSP Servers:**

Language servers must be installed separately on Ubuntu/Debian:

.. code-block:: bash

   # Lua language server (manual installation required)
   # See: https://github.com/LuaLS/lua-language-server

   # Python language server
   pip install pyright

   # Rust analyzer (via rustup)
   rustup component add rust-analyzer

   # Node.js/TypeScript (via npm)
   npm install -g typescript typescript-language-server

**Note:** The role installs Neovim with LSP configuration, but language servers must be installed separately based on your development needs.

Arch Linux
~~~~~~~~~~

**Packages Installed:**

- ``neovim`` - Neovim editor
- ``git`` - Plugin manager dependency
- ``lua-language-server`` - Lua LSP (automatic)
- ``pyright`` - Python LSP (automatic)

**Enhanced LSP:**

Arch Linux includes language servers out-of-the-box for immediate development readiness with Lua and Python.

macOS
~~~~~

**Packages Installed via Homebrew:**

- ``neovim`` - Neovim editor
- ``git`` - Plugin manager dependency
- ``lua-language-server`` - Lua LSP (automatic)
- ``pyright`` - Python LSP (automatic)

**Homebrew Integration:**

Integrates with existing Homebrew setup. Homebrew must be installed first (via configure_software).

Configuration Features
----------------------

When ``neovim_config_enabled: true`` (default), the role deploys:

**Plugin Management:**

- lazy.nvim - Efficient, lazy-loading plugin manager
- Automatic plugin installation on first launch
- Fast startup time

**LSP Support:**

Pre-configured for common language servers:

- **Lua** (``lua_ls``) - Lua language server
- **Rust** (``rust_analyzer``) - Rust analyzer
- **Python** (``pyright``) - Python type checker and language server

**Features:**

- Intelligent code completion
- Go-to-definition
- Hover documentation
- Real-time diagnostics
- Code actions

**Basic Settings:**

- Line numbers and relative line numbers
- Syntax highlighting
- Smart indentation (2 spaces)
- Search highlighting
- Case-insensitive search (unless uppercase used)
- Hidden buffers
- Auto-save on focus loss

**Modern Configuration:**

- Lua-based for performance
- Well-organized structure
- Easy to customize and extend

File Locations
--------------

User-Level Installation
~~~~~~~~~~~~~~~~~~~~~~~

All Neovim files are installed to user directories:

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
     - User binaries (added to PATH)

**Benefits:**

- No system-wide changes
- User controls their own configuration
- Multiple users can have different setups
- Easy to backup and version control

Vim Compatibility
-----------------

The role creates a vim compatibility alias:

**Alias Script** (``~/.local/bin/vim``):

.. code-block:: bash

   #!/bin/sh
   exec nvim "$@"

**Behavior:**

- Redirects all ``vim`` commands to ``nvim``
- Maintains muscle memory for users transitioning from vim
- Preserves all command-line arguments and options
- Works transparently with existing workflows

**Usage Examples:**

.. code-block:: bash

   vim file.txt         # Actually runs: nvim file.txt
   vim +10 file.txt     # Opens file at line 10
   vim -d file1 file2   # Diff mode
   vim -p *.py          # Open all Python files in tabs

First Launch
------------

Plugin Installation
~~~~~~~~~~~~~~~~~~~

On first launch, lazy.nvim automatically installs configured plugins:

1. **Launch Neovim:**

   .. code-block:: bash

      nvim

2. **Wait for plugins** to install (automatic, shows progress)

3. **Restart Neovim** after initial setup completes

Language Server Setup
~~~~~~~~~~~~~~~~~~~~~

**Arch Linux and macOS:**

Lua and Python language servers are pre-installed and ready to use immediately.

**Ubuntu/Debian:**

Install language servers manually based on development needs:

.. code-block:: bash

   # Python
   pip install pyright

   # Rust (requires rustup)
   rustup component add rust-analyzer

   # Node.js/TypeScript (requires npm)
   npm install -g typescript typescript-language-server

   # Go (requires go)
   go install golang.org/x/tools/gopls@latest

**Verification:**

Check LSP status in Neovim:

.. code-block:: vim

   :LspInfo

Examples
--------

Developer Workstation
~~~~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   neovim_user: developer
   neovim_config_enabled: true

This installs Neovim with the included LSP configuration, ready for Lua, Rust, and Python development (language servers required separately on Ubuntu/Debian).

Minimal Installation
~~~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   neovim_user: sysadmin
   neovim_config_enabled: false

Installs Neovim and the vim alias only, allowing users to bring their own configuration.

Via configure_users
~~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   users:
     - name: alice
       git:
         user_name: "Alice Developer"
         user_email: "alice@company.com"

       neovim:
         deploy_config: true

       nodejs:
         packages:
           - typescript
           - typescript-language-server

       rust:
         packages:
           - rust-analyzer

     - name: bob
       neovim:
         deploy_config: false  # Custom configuration

Customization
-------------

Users can customize their configuration by editing:

.. code-block:: bash

   ~/.config/nvim/init.lua

The included configuration serves as a starting point. Common customizations:

**Add Plugins:**

Edit the lazy.nvim setup section to add more plugins.

**Configure LSP Servers:**

Add language server configurations in the LSP setup section.

**Change Keybindings:**

Modify the keymapping section to match personal preferences.

**Adjust Settings:**

Update vim options (line numbers, tabs, colors, etc.).

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
      # Or logout and login again

Plugins Don't Install
~~~~~~~~~~~~~~~~~~~~~

If plugins fail to install on first launch:

1. **Check internet connection** - Plugins download from GitHub

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

5. **Check for errors:**

   .. code-block:: vim

      :messages

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

4. **Check for errors:**

   .. code-block:: vim

      :messages

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
      # Re-run ansible playbook to restore default config

Tags
----

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - Tag
     - Description
   * - ``user-neovim``
     - All Neovim installation and configuration tasks
   * - ``neovim-system``
     - Neovim package installation only
   * - ``neovim-config``
     - Configuration and plugin setup only
   * - ``neovim-alias``
     - Vim compatibility alias only

Dependencies
------------

**Ansible Collections:**

- ``community.general`` - Homebrew and pacman modules
- ``ansible.builtin`` - APT and file modules

**System Requirements:**

- User account must exist
- Internet access for plugin downloads
- Homebrew (macOS only)

Install dependencies:

.. code-block:: bash

   ansible-galaxy collection install -r requirements.yml

**System Packages (installed automatically by role):**

- ``neovim`` - Neovim editor
- ``git`` - Version control (required by plugin manager)
- ``lua-language-server`` - Lua LSP (Arch/macOS)
- ``pyright`` - Python LSP (Arch/macOS)

Limitations
-----------

**Language Server Installation:**

Ubuntu/Debian:
- Lua, Rust, Node.js language servers not installed automatically
- Users must install language servers based on their needs
- See Platform-Specific Features for installation commands

Arch Linux and macOS:
- Only Lua and Python language servers installed automatically
- Other language servers must be installed separately

**PATH Configuration:**

PATH updates require:

- User logout/login for changes to take effect
- Or manually source: ``source ~/.profile``
- Some shells may not source ``.profile`` automatically

**Configuration Scope:**

The included configuration is intentionally minimal:

- Covers common development needs
- Users should customize for specific workflows
- Not a complete IDE replacement

**Plugin Manager:**

- First launch requires internet connection
- Plugins download from GitHub
- May take time on slow connections

See Also
--------

- :doc:`configure_users` - Phase 3 role that orchestrates this utility role
- :doc:`install_nodejs` - Node.js utility role (for TypeScript LSP)
- :doc:`install_rust` - Rust utility role (for rust-analyzer)
- :doc:`install_go` - Go utility role (for gopls)
- :doc:`install_terminfo` - Terminal configuration utility role
- :doc:`configure_software` - Phase 2 role for system packages
- :doc:`/reference/variables-reference` - Complete variable reference
- `Neovim <https://neovim.io/>`_ - Official Neovim website
- `lazy.nvim <https://github.com/folke/lazy.nvim>`_ - Plugin manager
- `nvim-lspconfig <https://github.com/neovim/nvim-lspconfig>`_ - LSP configurations
