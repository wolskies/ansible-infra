install_go
==========

Utility role for Go language installation and user-level package management.

.. contents::
   :local:
   :depth: 2

Overview
--------

The ``install_go`` role installs the Go programming language and manages Go packages at the user level. This is a utility role typically orchestrated by :doc:`configure_users` but can also be used standalone.

**Key Features:**

- **Go Toolchain** - Official Go compiler and built-in tools
- **User-Level Packages** - Go packages in user's ``~/go/`` directory
- **PATH Configuration** - Automatic PATH setup in user's ``.profile``
- **Version Support** - Install specific versions or latest
- **Cross-Platform** - Ubuntu, Debian, Arch Linux, macOS

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

Install Go and packages for a specific user:

.. code-block:: yaml

   - hosts: developers
     become: true
     roles:
       - wolskies.infrastructure.install_go
     vars:
       go_user: developer
       go_packages:
         - github.com/charmbracelet/glow@latest
         - github.com/junegunn/fzf@latest
         - github.com/cli/cli/v2/cmd/gh@latest

Integration with configure_users
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Typically used via configure_users role:

.. code-block:: yaml

   users:
     - name: developer
       go:
         packages:
           - github.com/charmbracelet/glow@latest
           - github.com/jesseduffield/lazygit@latest
           - github.com/cli/cli/v2/cmd/gh@latest

Multiple Users
~~~~~~~~~~~~~~

Configure different packages for different users:

.. code-block:: yaml

   users:
     - name: alice
       go:
         packages:
           - github.com/charmbracelet/glow@latest
           - golang.org/x/tools/gopls@latest

     - name: bob
       go:
         packages:
           - github.com/jesseduffield/lazygit@latest
           - github.com/golangci/golangci-lint/cmd/golangci-lint@latest

Variables
---------

.. list-table::
   :header-rows: 1
   :widths: 25 15 60

   * - Variable
     - Type
     - Description
   * - ``go_user``
     - string
     - Target username for Go installation (required)
   * - ``go_packages``
     - list
     - Go package URLs to install (see Package Format below)

Package Format
~~~~~~~~~~~~~~

Go packages use full import URLs with optional version specifiers:

**With Explicit Version:**

.. code-block:: yaml

   go_packages:
     - "github.com/user/package@v1.2.3"      # Specific version
     - "github.com/user/package@latest"      # Latest version
     - "github.com/user/package@v1"          # Latest v1.x.x

**Auto-append @latest:**

If no version is specified, ``@latest`` is automatically appended:

.. code-block:: yaml

   go_packages:
     - "github.com/user/package"  # Same as @latest

**Common Packages:**

.. code-block:: yaml

   go_packages:
     # CLI tools
     - github.com/charmbracelet/glow@latest        # Markdown viewer
     - github.com/junegunn/fzf@latest              # Fuzzy finder
     - github.com/jesseduffield/lazygit@latest     # Git TUI
     - github.com/cli/cli/v2/cmd/gh@latest         # GitHub CLI

     # Development tools
     - golang.org/x/tools/gopls@latest             # Go language server
     - github.com/golangci/golangci-lint/cmd/golangci-lint@latest
     - golang.org/x/tools/cmd/goimports@latest

Installation Behavior
---------------------

The role performs these steps:

1. **Go Installation**

   - **Ubuntu/Debian**: Installs ``golang`` via APT
   - **Arch Linux**: Installs ``go`` via pacman
   - **macOS**: Installs ``go`` via Homebrew

2. **PATH Configuration**

   - Adds ``~/go/bin`` to user's ``.profile``
   - User can execute installed packages after login

3. **Package Installation**

   - Installs packages via: ``go install <package>@<version>``
   - Binaries installed to ``~/go/bin/``
   - Source cached in ``~/go/pkg/``

Platform-Specific Features
---------------------------

Ubuntu/Debian
~~~~~~~~~~~~~

- Uses APT ``golang`` package
- Go version depends on distribution release
- Ubuntu 22.04: Go 1.18+
- Ubuntu 24.04: Go 1.21+

Arch Linux
~~~~~~~~~~

- Uses official ``go`` package
- Always current Go version
- Automatic updates via pacman

macOS
~~~~~

- Uses Homebrew ``go`` formula
- Latest stable Go version
- Homebrew must be installed first (via configure_software)

User-Level Package Management
------------------------------

All Go packages install to user directories:

**Directory Structure:**

- **Packages**: ``~/go/pkg/mod/`` (module cache)
- **Binaries**: ``~/go/bin/``
- **Source Cache**: ``~/go/pkg/``

**PATH Setup:**

The role automatically adds to ``~/.profile``:

.. code-block:: bash

   export PATH="$HOME/go/bin:$PATH"

**Benefits:**

- No system-wide changes
- No root privileges for package management
- Multiple users can have different package versions
- User controls their own Go packages

Using Installed Packages
-------------------------

After installation and login, packages are available:

.. code-block:: bash

   # Markdown viewer
   glow README.md

   # Fuzzy finder
   fzf

   # Git TUI
   lazygit

   # GitHub CLI
   gh repo list

   # Go compiler
   go version
   go build
   go test

**Note:** User must logout and login (or source ``. ~/.profile``) for PATH changes to take effect.

Examples
--------

CLI Tools Setup
~~~~~~~~~~~~~~~

.. code-block:: yaml

   go_user: developer
   go_packages:
     - github.com/charmbracelet/glow@latest
     - github.com/junegunn/fzf@latest
     - github.com/jesseduffield/lazygit@latest
     - github.com/jesseduffield/lazydocker@latest
     - github.com/cli/cli/v2/cmd/gh@latest

Development Tools
~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   go_user: go-dev
   go_packages:
     - golang.org/x/tools/gopls@latest                              # Language server
     - golang.org/x/tools/cmd/goimports@latest                      # Import formatter
     - github.com/golangci/golangci-lint/cmd/golangci-lint@latest   # Linter
     - github.com/go-delve/delve/cmd/dlv@latest                     # Debugger
     - golang.org/x/vuln/cmd/govulncheck@latest                     # Vulnerability checker

DevOps Tools
~~~~~~~~~~~~

.. code-block:: yaml

   go_user: devops
   go_packages:
     - github.com/cli/cli/v2/cmd/gh@latest
     - github.com/jesseduffield/lazydocker@latest
     - github.com/stern/stern@latest                # Kubernetes log viewer

Popular Go CLI Tools
--------------------

Common useful packages:

**Productivity:**

- ``github.com/charmbracelet/glow@latest`` - Terminal markdown viewer
- ``github.com/junegunn/fzf@latest`` - Fuzzy finder
- ``github.com/jesseduffield/lazygit@latest`` - Git terminal UI
- ``github.com/cli/cli/v2/cmd/gh@latest`` - GitHub CLI

**Development:**

- ``golang.org/x/tools/gopls@latest`` - Go language server for LSP
- ``golang.org/x/tools/cmd/goimports@latest`` - Import management
- ``github.com/golangci/golangci-lint/cmd/golangci-lint@latest`` - Linter aggregator
- ``github.com/go-delve/delve/cmd/dlv@latest`` - Go debugger

**DevOps/Infrastructure:**

- ``github.com/jesseduffield/lazydocker@latest`` - Docker terminal UI
- ``github.com/stern/stern@latest`` - Kubernetes log tailing
- ``github.com/rakyll/hey@latest`` - HTTP load generator

**System Tools:**

- ``github.com/wagoodman/dive@latest`` - Docker image analyzer
- ``github.com/derailed/k9s@latest`` - Kubernetes CLI
- ``github.com/GoogleContainerTools/skaffold/v2@latest`` - Kubernetes dev tool

Go Module Path Format
----------------------

Understanding Go module paths:

**GitHub Packages:**

.. code-block:: yaml

   # Repository root
   - github.com/user/repo@latest

   # Subdirectory with cmd
   - github.com/user/repo/cmd/tool@latest

   # Versioned module (v2+)
   - github.com/user/repo/v2@latest

**Standard Library Extensions:**

.. code-block:: yaml

   - golang.org/x/tools/gopls@latest
   - golang.org/x/tools/cmd/goimports@latest

**Version Specifications:**

.. code-block:: yaml

   - package@latest          # Latest version
   - package@v1.2.3         # Specific version
   - package@v1             # Latest v1.x.x
   - package@commit-hash    # Specific commit

Dependencies
------------

**Ansible Collections:**

- ``community.general`` - Pacman and Homebrew modules
- ``ansible.builtin`` - APT and command modules

**System Requirements:**

- User account must exist
- Internet access for downloading packages
- Homebrew (macOS only)

Install dependencies:

.. code-block:: bash

   ansible-galaxy collection install -r requirements.yml

Limitations
-----------

**Go Version:**

- Ubuntu/Debian: Go version depends on distribution
- Cannot specify Go version via this role
- Use official Go installer for specific versions

**PATH Configuration:**

PATH updates require:

- User logout/login for changes to take effect
- Or manually source: ``source ~/.profile``
- Some shells may not source ``.profile`` automatically

**Package Installation:**

- Packages are compiled from source
- First installation downloads all dependencies
- Build time varies by package complexity
- Internet connection required

**User Requirements:**

- User must exist before role execution
- Role does not create users
- Skips if user doesn't exist

See Also
--------

- :doc:`configure_users` - Phase 3 role that orchestrates this utility role
- :doc:`install_nodejs` - Node.js utility role
- :doc:`install_rust` - Rust utility role
- :doc:`install_neovim` - Neovim utility role
- :doc:`configure_software` - Phase 2 role for system packages
- :doc:`/reference/variables-reference` - Complete variable reference
