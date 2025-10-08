rust
====

Rust toolchain installation and user-level cargo package management.

.. contents::
   :local:
   :depth: 2

Overview
--------

The ``rust`` role installs the Rust toolchain via rustup and manages user-level cargo packages. It supports multiple platforms with the stable Rust toolchain and configures user directories for cargo installations.

**All cargo packages install to user directories** (``~/.cargo/``) rather than system-wide, allowing per-user package management.

Features
~~~~~~~~

- **Rustup Installation** - Rust toolchain manager via system packages
- **Stable Toolchain** - Default stable Rust compiler
- **User-Level Packages** - Cargo packages in ``~/.cargo/``
- **PATH Configuration** - Automatic PATH setup in ``~/.profile``
- **Cross-platform** - Ubuntu 24+, Debian 13+, Arch Linux, macOS support

Platform Support
~~~~~~~~~~~~~~~~

- **Ubuntu** 24.04+ (rustup available in repos)
- **Debian** 13+ (rustup available in repos)
- **Arch Linux** (Rolling)
- **macOS** 13+ (Ventura)

.. note::
   **Ubuntu 22.04/23.x and Debian 12** are not supported because rustup is not available in their package repositories. The role will fail with a clear error message on these platforms.

Usage
-----

Basic Package Installation
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Install Rust toolchain and cargo packages for a user:

.. code-block:: yaml

   - hosts: developers
     become: true
     roles:
       - wolskies.infrastructure.rust
     vars:
       rust_user: developer
       rust_packages:
         - ripgrep
         - bat
         - fd-find
         - exa

Common Development Tools
~~~~~~~~~~~~~~~~~~~~~~~~

Install popular Rust-based CLI tools:

.. code-block:: yaml

   rust_user: developer
   rust_packages:
     - ripgrep      # Fast grep alternative
     - bat          # Cat with syntax highlighting
     - fd-find      # Fast find alternative
     - exa          # Modern ls replacement
     - tokei        # Code statistics
     - hyperfine    # Benchmarking tool
     - cargo-watch  # Cargo file watcher

Integration with configure_users
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The ``rust`` role is typically invoked via :doc:`configure_users`:

.. code-block:: yaml

   users:
     - name: developer
       rust:
         packages:
           - ripgrep
           - bat
           - fd-find
           - cargo-watch

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
   * - ``rust_user``
     - string
     - Target username for Rust installation (required)
   * - ``rust_packages``
     - list
     - Cargo package names to install. Default: []

Package Format
~~~~~~~~~~~~~~

Simple list of cargo package names:

.. code-block:: yaml

   rust_packages:
     - ripgrep
     - bat
     - fd-find
     - exa
     - cargo-edit
     - cargo-watch

Unlike npm packages, cargo packages are typically installed from crates.io and don't require version specification in the role. Use ``cargo install package@version`` manually if specific versions are needed.

Installation Behavior
---------------------

Installation Process
~~~~~~~~~~~~~~~~~~~~

1. **Rustup Installation** - Install rustup toolchain manager:

   - **Ubuntu 24+/Debian 13+** - APT ``rustup`` package
   - **Arch Linux** - Pacman ``rustup`` and ``base-devel`` packages
   - **macOS** - Homebrew ``rustup`` formula

2. **Toolchain Setup** - Initialize stable Rust toolchain:

   .. code-block:: bash

      rustup default stable

3. **PATH Configuration** - Add ``~/.cargo/bin`` to user's ``.profile``:

   .. code-block:: bash

      export PATH="$PATH:$HOME/.cargo/bin"

4. **Package Installation** - Install cargo packages:

   .. code-block:: bash

      cargo install ripgrep bat fd-find

User-Level Package Management
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

All cargo packages install to user directories:

- **Packages**: ``~/.cargo/registry/``
- **Binaries**: ``~/.cargo/bin/``
- **Build Cache**: ``~/.cargo/target/``

Users can manage packages without root:

.. code-block:: bash

   cargo install ripgrep          # Install package
   cargo install --force ripgrep  # Update package
   cargo uninstall ripgrep        # Remove package
   cargo install --list           # List installed packages

PATH Configuration
~~~~~~~~~~~~~~~~~~

The role automatically adds cargo binaries to PATH by appending to ``~/.profile``:

.. code-block:: bash

   export PATH="$PATH:$HOME/.cargo/bin"

**Activation:**

- Automatic on next login
- Manual: ``source ~/.profile``
- Shell-specific: Add to ``~/.bashrc``, ``~/.zshrc``, etc.

Platform-Specific Features
--------------------------

Ubuntu 24+ / Debian 13+
~~~~~~~~~~~~~~~~~~~~~~~

**APT Package:**

- Uses distribution-provided ``rustup`` package
- Available starting with Ubuntu 24.04 LTS and Debian 13 (Trixie)
- Stable, well-integrated with system

**Not Supported:**

- Ubuntu 22.04 LTS (Jammy)
- Ubuntu 23.04/23.10
- Debian 12 (Bookworm)

These versions don't include rustup in repositories. Use alternative installation methods (curl script) if needed.

Arch Linux
~~~~~~~~~~

**Pacman Packages:**

- ``rustup`` - Rust toolchain installer
- ``base-devel`` - Build essentials for cargo packages
- Always current versions from Arch repos

macOS
~~~~~

**Homebrew Installation:**

- Uses Homebrew: ``brew install rustup``
- Integrates with existing Homebrew setup

Tags
----

Control Rust configuration:

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - Tag
     - Description
   * - ``rust-system``
     - Rustup and toolchain installation
   * - ``rust-packages``
     - Cargo package installation

Examples
--------

CLI Tools for Developers
~~~~~~~~~~~~~~~~~~~~~~~~~

Modern command-line replacements:

.. code-block:: yaml

   - hosts: developers
     become: true
     roles:
       - wolskies.infrastructure.rust
     vars:
       rust_user: developer
       rust_packages:
         - ripgrep      # Better grep
         - bat          # Better cat
         - fd-find      # Better find
         - exa          # Better ls
         - zoxide       # Better cd
         - du-dust      # Better du
         - procs        # Better ps
         - bottom       # Better top

Development Tools
~~~~~~~~~~~~~~~~~

Rust development utilities:

.. code-block:: yaml

   rust_user: rust_dev
   rust_packages:
     - cargo-watch    # Auto-rebuild on changes
     - cargo-edit     # Manage dependencies
     - cargo-outdated # Check for updates
     - cargo-audit    # Security vulnerabilities
     - cargo-tree     # Dependency tree
     - cargo-expand   # Macro expansion
     - cargo-flamegraph # Performance profiling

System Administration Tools
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

DevOps and sysadmin utilities:

.. code-block:: yaml

   rust_user: sysadmin
   rust_packages:
     - ripgrep
     - bat
     - fd-find
     - tokei        # Code statistics
     - hyperfine    # Benchmarking
     - sd           # Better sed
     - tealdeer     # TLDR pages

Skip System Installation
~~~~~~~~~~~~~~~~~~~~~~~~~

Install only packages (rustup already present):

.. code-block:: bash

   ansible-playbook --skip-tags rust-system playbook.yml

Popular Cargo Packages
----------------------

File and Text Tools
~~~~~~~~~~~~~~~~~~~

- ``ripgrep`` (``rg``) - Fast recursive grep
- ``bat`` - Cat with syntax highlighting and Git integration
- ``fd-find`` (``fd``) - Fast and user-friendly find alternative
- ``sd`` - Intuitive sed replacement

Directory Navigation
~~~~~~~~~~~~~~~~~~~~

- ``exa`` - Modern ls replacement with Git integration
- ``zoxide`` - Smarter cd command (learns your habits)
- ``broot`` - Directory tree browser

System Monitoring
~~~~~~~~~~~~~~~~~

- ``bottom`` (``btm``) - System monitor (like top/htop)
- ``procs`` - Modern ps replacement
- ``du-dust`` - Intuitive du alternative
- ``bandwhich`` - Network utilization monitor

Development Tools
~~~~~~~~~~~~~~~~~

- ``cargo-watch`` - Watch for changes and run commands
- ``cargo-edit`` - Add/remove/upgrade dependencies
- ``cargo-outdated`` - Check for outdated dependencies
- ``cargo-audit`` - Security vulnerability scanner
- ``cargo-tree`` - Visualize dependency tree
- ``tokei`` - Code statistics (lines of code, etc.)
- ``hyperfine`` - Command-line benchmarking

Build and Deployment
~~~~~~~~~~~~~~~~~~~~

- ``cargo-make`` - Task runner and build tool
- ``cargo-deny`` - Lint dependencies
- ``cross`` - Cross-compilation tooling

Documentation
~~~~~~~~~~~~~

- ``mdbook`` - GitBook-like documentation tool
- ``tealdeer`` (``tldr``) - Simplified man pages

Troubleshooting
---------------

cargo Command Not Found
~~~~~~~~~~~~~~~~~~~~~~~~

If cargo commands aren't found after installation:

1. **Reload shell configuration:**

   .. code-block:: bash

      source ~/.profile

2. **Verify PATH:**

   .. code-block:: bash

      echo $PATH | grep cargo

3. **Logout and login again** for automatic PATH loading

rustup Not Available (Ubuntu 22/Debian 12)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If rustup is not available in your distribution:

**Option 1: Upgrade OS** (recommended)

- Ubuntu 22.04 → 24.04
- Debian 12 → 13

**Option 2: Official rustup installer** (not handled by this role)

.. code-block:: bash

   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

Package Installation Fails
~~~~~~~~~~~~~~~~~~~~~~~~~~~

If cargo package installation fails:

1. **Check Rust version:**

   .. code-block:: bash

      rustc --version
      cargo --version

2. **Update toolchain:**

   .. code-block:: bash

      rustup update stable

3. **Clear cargo cache:**

   .. code-block:: bash

      rm -rf ~/.cargo/registry/cache

Build Dependencies Missing (Arch Linux)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If package builds fail on Arch Linux:

.. code-block:: bash

   sudo pacman -S base-devel

The role installs ``base-devel`` automatically, but verify if build failures occur.

Long Compilation Times
~~~~~~~~~~~~~~~~~~~~~~

Cargo packages compile from source, which can be slow:

- **First install**: Slow (compiles all dependencies)
- **Updates**: Faster (incremental compilation)
- **Tip**: Use ``--jobs`` flag for parallel builds (handled automatically)

Dependencies
------------

**Required:**

- ``ansible.builtin.apt`` - Package installation (Ubuntu/Debian)
- ``community.general.pacman`` - Package installation (Arch Linux)
- ``community.general.homebrew`` - Package installation (macOS)
- ``ansible.builtin.command`` - Rustup and cargo operations

**System Packages (installed automatically):**

- ``rustup`` - Rust toolchain installer
- ``base-devel`` - Build essentials (Arch Linux only)

Install Ansible dependencies:

.. code-block:: bash

   ansible-galaxy collection install -r requirements.yml

Platform Limitations
--------------------

The following platforms are **not supported** and will cause the role to fail:

- Ubuntu 22.04 LTS (Jammy)
- Ubuntu 23.04 (Lunar)
- Ubuntu 23.10 (Mantic)
- Debian 12 (Bookworm)

**Reason**: These distributions don't include rustup in their package repositories.

**Alternative**: Use the official rustup installer outside of this role, or upgrade to supported OS versions.

See Also
--------

- :doc:`configure_users` - User environment orchestration
- :doc:`nodejs` - Node.js development environment
- :doc:`go` - Go development environment
- :doc:`/reference/variables-reference` - Complete variable reference
- `Rust <https://www.rust-lang.org/>`_ - Official Rust website
- `crates.io <https://crates.io/>`_ - Rust package registry
- `rustup <https://rustup.rs/>`_ - Rust toolchain installer
