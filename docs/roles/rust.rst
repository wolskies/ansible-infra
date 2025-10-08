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

Examples
~~~~~~~~

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

Via configure_users role:

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

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - Tag
     - Description
   * - ``rust-system``
     - Rustup and toolchain installation
   * - ``rust-packages``
     - Cargo package installation

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

**Ansible Collections:**

This role uses modules from the following collections:

- ``community.general`` - Included with Ansible package

Install collection dependencies:

.. code-block:: bash

   ansible-galaxy collection install -r requirements.yml

**System Packages (installed automatically by role):**

- ``rustup`` - Rust toolchain installer
- ``base-devel`` - Build essentials (Arch Linux only)

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
