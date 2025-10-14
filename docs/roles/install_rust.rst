install_rust
============

Utility role for Rust toolchain installation and user-level cargo package management.

.. contents::
   :local:
   :depth: 2

Overview
--------

The ``install_rust`` role installs the Rust toolchain via rustup and manages cargo packages at the user level. This is a utility role typically orchestrated by :doc:`configure_users` but can also be used standalone.

**Key Features:**

- **Rustup Toolchain Manager** - Official Rust installation method
- **Stable Toolchain** - Default Rust compiler via rustup
- **User-Level Packages** - Cargo packages in user's ``~/.cargo/`` directory
- **PATH Configuration** - Automatic PATH setup in user's ``.profile``
- **Cross-Platform** - Ubuntu 24+, Debian 13+, Arch Linux, macOS

Platform Support
~~~~~~~~~~~~~~~~

- **Ubuntu** 24.04+ (rustup not available in Ubuntu 22.04/23.x repositories)
- **Debian** 13+ (rustup not available in Debian 12 repositories)
- **Arch Linux** (Rolling)
- **macOS** 13+ (Ventura)

Usage
-----

Standalone Usage
~~~~~~~~~~~~~~~~

Install Rust and packages for a specific user:

.. code-block:: yaml

   - hosts: developers
     become: true
     roles:
       - wolskies.infrastructure.install_rust
     vars:
       rust_user: developer
       rust_packages:
         - ripgrep     # Fast grep alternative
         - bat         # Cat with syntax highlighting
         - fd-find     # Fast find alternative
         - cargo-watch # Auto-rebuild on file changes

Integration with configure_users
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Typically used via configure_users role:

.. code-block:: yaml

   users:
     - name: developer
       rust:
         packages:
           - ripgrep
           - bat
           - fd-find
           - cargo-watch
           - exa

Multiple Users
~~~~~~~~~~~~~~

Configure different packages for different users:

.. code-block:: yaml

   users:
     - name: alice
       rust:
         packages:
           - ripgrep
           - bat
           - fd-find

     - name: bob
       rust:
         packages:
           - cargo-watch
           - cargo-edit
           - cargo-audit

Variables
---------

.. list-table::
   :header-rows: 1
   :widths: 25 15 60

   * - Variable
     - Type
     - Description
   * - ``rust_user``
     - string
     - Target username for Rust installation (required)
   * - ``rust_packages``
     - list
     - Cargo package names to install

Package Format
~~~~~~~~~~~~~~

Packages are specified as simple strings (crate names):

.. code-block:: yaml

   rust_packages:
     - ripgrep       # Search tool
     - bat           # File viewer
     - fd-find       # File finder
     - exa           # Modern ls
     - tokei         # Code statistics
     - cargo-watch   # File watcher
     - cargo-edit    # Cargo extensions

Installation Behavior
---------------------

The role performs these steps:

1. **Rustup Installation**

   - **Ubuntu 24+/Debian 13+**: Installs ``rustup`` via APT
   - **Arch Linux**: Installs ``rustup`` and ``base-devel`` via pacman
   - **macOS**: Installs ``rustup`` via Homebrew

2. **Toolchain Setup**

   - Initializes stable Rust toolchain: ``rustup default stable``
   - Downloads and installs latest stable Rust compiler
   - Sets up cargo package manager

3. **PATH Configuration**

   - Adds ``~/.cargo/bin`` to user's ``.profile``
   - User can execute installed packages after login

4. **Package Installation**

   - Installs cargo packages with: ``cargo install <package>``
   - Packages build from source
   - Binaries installed to ``~/.cargo/bin/``

Platform-Specific Features
---------------------------

Ubuntu 24.04+ / Debian 13+
~~~~~~~~~~~~~~~~~~~~~~~~~~

- Uses APT ``rustup`` package
- Includes standard development tools
- Requires Ubuntu 24.04 or Debian 13 (rustup not in earlier versions)

**Platform Limitations:**

- Ubuntu 22.04/23.x: Not supported (no rustup package)
- Debian 12: Not supported (no rustup package)

The role will fail with a clear error message on unsupported platforms.

Arch Linux
~~~~~~~~~~

- Uses official ``rustup`` package
- Installs ``base-devel`` for build dependencies
- Always current versions

macOS
~~~~~

- Uses Homebrew ``rustup`` formula
- Integrates with existing Homebrew setup
- Homebrew must be installed first (via configure_software)

User-Level Package Management
------------------------------

All cargo packages install to user directories:

**Directory Structure:**

- **Packages**: ``~/.cargo/registry/``
- **Binaries**: ``~/.cargo/bin/``
- **Build Cache**: ``~/.cargo/target/``
- **Toolchains**: ``~/.rustup/``

**PATH Setup:**

The role automatically adds to ``~/.profile``:

.. code-block:: bash

   export PATH="$HOME/.cargo/bin:$PATH"

**Benefits:**

- No system-wide changes
- No root privileges for package management
- Multiple users can have different package versions
- User controls their own Rust installation

Using Installed Packages
-------------------------

After installation and login, packages are available:

.. code-block:: bash

   # Fast grep
   rg "pattern" .

   # Cat with highlighting
   bat myfile.rs

   # Fast find
   fd "filename"

   # Modern ls
   exa -la

   # Rust compiler
   rustc --version
   cargo --version

**Note:** User must logout and login (or source ``. ~/.profile``) for PATH changes to take effect.

Examples
--------

System Utilities Setup
~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   rust_user: developer
   rust_packages:
     - ripgrep       # Search
     - bat           # File viewer
     - fd-find       # File finder
     - exa           # ls replacement
     - tokei         # Code stats
     - du-dust       # du replacement
     - procs         # ps replacement

Development Tools
~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   rust_user: rust-dev
   rust_packages:
     - cargo-watch   # Auto-rebuild
     - cargo-edit    # Cargo helpers
     - cargo-audit   # Security audits
     - cargo-expand  # Macro expansion
     - cargo-tree    # Dependency tree

DevOps Tools
~~~~~~~~~~~~

.. code-block:: yaml

   rust_user: devops
   rust_packages:
     - ripgrep
     - bat
     - fd-find
     - bottom        # System monitor
     - bandwhich     # Network monitor

Popular Rust CLI Tools
----------------------

Common useful packages:

**File & Text Processing:**

- ``ripgrep`` - Fast grep alternative
- ``bat`` - Cat with syntax highlighting
- ``fd-find`` - Fast find alternative
- ``sd`` - Sed alternative

**File Browsing:**

- ``exa`` - Modern ls replacement
- ``broot`` - Tree-based file navigation
- ``lsd`` - Next-gen ls

**System Tools:**

- ``bottom`` - System resource monitor
- ``procs`` - Modern ps replacement
- ``du-dust`` - Disk usage analyzer
- ``tokei`` - Code statistics

**Development:**

- ``cargo-watch`` - Auto-rebuild on changes
- ``cargo-edit`` - Add/remove dependencies
- ``cargo-audit`` - Security vulnerability scanner
- ``cargo-tree`` - Dependency tree viewer

Dependencies
------------

**Ansible Collections:**

- ``community.general`` - Pacman and Homebrew modules
- ``ansible.builtin`` - APT and command modules

**System Requirements:**

- User account must exist
- Internet access for downloading toolchain and packages
- Build tools (installed automatically on Arch: base-devel)
- Homebrew (macOS only)

Install dependencies:

.. code-block:: bash

   ansible-galaxy collection install -r requirements.yml

Limitations
-----------

**Platform Restrictions:**

The role only supports platforms with rustup in repositories:

- ✅ Ubuntu 24.04+
- ✅ Debian 13+
- ✅ Arch Linux
- ✅ macOS 13+
- ❌ Ubuntu 22.04/23.x (no rustup package)
- ❌ Debian 12 (no rustup package)

**Workarounds for Unsupported Platforms:**

On Ubuntu 22.04 or Debian 12, you can:

1. Use the official rustup installer (not Ansible-managed)
2. Upgrade to Ubuntu 24.04 or Debian 13
3. Use a container with a supported platform

**Build Time:**

Cargo packages build from source, which can take time:

- Packages with many dependencies are slower
- First installation of a package compiles all dependencies
- Subsequent runs are faster (cached)

**PATH Configuration:**

PATH updates require:

- User logout/login for changes to take effect
- Or manually source: ``source ~/.profile``
- Some shells may not source ``.profile`` automatically

See Also
--------

- :doc:`configure_users` - Phase 3 role that orchestrates this utility role
- :doc:`install_nodejs` - Node.js utility role
- :doc:`install_go` - Go utility role
- :doc:`install_neovim` - Neovim utility role
- :doc:`configure_software` - Phase 2 role for system packages
- :doc:`/reference/variables-reference` - Complete variable reference
