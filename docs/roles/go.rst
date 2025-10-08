go
==

Go language installation and user-level package management.

.. contents::
   :local:
   :depth: 2

Overview
--------

The ``go`` role installs the Go programming language toolchain and manages user-level Go packages. It provides the Go compiler, built-in tools, and manages third-party tools installed via ``go install``.

**All Go packages install to user directories** (``~/go/``) rather than system-wide, allowing per-user package management.

Features
~~~~~~~~

- **Go Toolchain** - Compiler and built-in tools (go fmt, go test, go build)
- **Package Management** - Install tools via ``go install``
- **User-Level Packages** - Go packages in ``~/go/``
- **PATH Configuration** - Automatic PATH setup in ``~/.profile``
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

Install Go toolchain and packages for a user:

.. code-block:: yaml

   - hosts: developers
     become: true
     roles:
       - wolskies.infrastructure.go
     vars:
       go_user: developer
       go_packages:
         - github.com/charmbracelet/glow@latest
         - github.com/junegunn/fzf@latest
         - github.com/jesseduffield/lazygit@latest

Common Development Tools
~~~~~~~~~~~~~~~~~~~~~~~~

Install popular Go-based CLI tools:

.. code-block:: yaml

   go_user: developer
   go_packages:
     - github.com/charmbracelet/glow@latest     # Markdown renderer
     - github.com/junegunn/fzf@latest           # Fuzzy finder
     - github.com/jesseduffield/lazygit@latest  # Git TUI
     - github.com/cli/cli/v2/cmd/gh@latest      # GitHub CLI

Integration with configure_users
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The ``go`` role is typically invoked via :doc:`configure_users`:

.. code-block:: yaml

   users:
     - name: developer
       go:
         packages:
           - github.com/charmbracelet/glow@latest
           - github.com/jesseduffield/lazygit@latest

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
   * - ``go_user``
     - string
     - Target username for Go installation (required)
   * - ``go_packages``
     - list
     - Go package URLs to install. Default: []

Package Format
~~~~~~~~~~~~~~

Go packages use full import URLs with optional version specifiers:

.. code-block:: yaml

   go_packages:
     # With explicit version
     - "github.com/user/package@v1.2.3"
     - "github.com/user/package@latest"

     # Without version (automatically appends @latest)
     - "github.com/user/package"

     # With specific commit
     - "github.com/user/package@abcdef123"

     # Sub-package paths
     - "github.com/cli/cli/v2/cmd/gh@latest"

Version Specifications
~~~~~~~~~~~~~~~~~~~~~~

Go supports several version formats:

- **Latest**: ``@latest`` - Latest tagged release
- **Specific Version**: ``@v1.2.3`` - Exact semantic version
- **Branch**: ``@main`` or ``@master`` - Latest commit on branch
- **Commit**: ``@abcdef123`` - Specific commit hash
- **No Version**: Defaults to ``@latest``

Installation Behavior
---------------------

Installation Process
~~~~~~~~~~~~~~~~~~~~

1. **Go Installation** - Install Go development toolchain:

   - **Ubuntu/Debian** - APT ``golang`` package
   - **Arch Linux** - Pacman ``go`` package
   - **macOS** - Homebrew ``go`` formula

2. **PATH Configuration** - Add ``~/go/bin`` to user's ``.profile``:

   .. code-block:: bash

      export PATH="$PATH:$HOME/go/bin"

3. **Package Installation** - Install packages via ``go install``:

   .. code-block:: bash

      go install github.com/user/package@latest

User-Level Package Management
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

All Go packages install to user directories:

- **Packages**: ``~/go/pkg/`` - Compiled package objects
- **Binaries**: ``~/go/bin/`` - Executable binaries
- **Source Cache**: ``~/go/src/`` - Downloaded source code
- **Module Cache**: ``~/go/pkg/mod/`` - Go modules

Users can manage packages without root:

.. code-block:: bash

   go install github.com/user/package@latest  # Install/update package
   go clean -modcache                         # Clear module cache
   ls ~/go/bin/                               # List installed binaries

PATH Configuration
~~~~~~~~~~~~~~~~~~

The role automatically adds Go binaries to PATH by appending to ``~/.profile``:

.. code-block:: bash

   export PATH="$PATH:$HOME/go/bin"

**Activation:**

- Automatic on next login
- Manual: ``source ~/.profile``
- Shell-specific: Add to ``~/.bashrc``, ``~/.zshrc``, etc.

Platform-Specific Features
--------------------------

All Platforms
~~~~~~~~~~~~~

Go installation is straightforward across all platforms:

- **Ubuntu/Debian**: Uses distribution Go package
- **Arch Linux**: Uses official Arch Go package
- **macOS**: Uses Homebrew Go formula

Version differences depend on distribution/Homebrew, but generally provide recent Go versions (1.20+).

Tags
----

Control Go configuration:

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - Tag
     - Description
   * - ``go-system``
     - Go toolchain installation
   * - ``go-packages``
     - Go package installation

Examples
--------

DevOps and Infrastructure Tools
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Tools for system administration and DevOps:

.. code-block:: yaml

   - hosts: devops
     become: true
     roles:
       - wolskies.infrastructure.go
     vars:
       go_user: sysadmin
       go_packages:
         - github.com/cli/cli/v2/cmd/gh@latest          # GitHub CLI
         - github.com/jesseduffield/lazygit@latest      # Git TUI
         - github.com/jesseduffield/lazydocker@latest   # Docker TUI
         - github.com/derailed/k9s@latest               # Kubernetes TUI
         - github.com/stern/stern@latest                # Kubernetes log viewer

Development Utilities
~~~~~~~~~~~~~~~~~~~~~

CLI tools for developers:

.. code-block:: yaml

   go_user: developer
   go_packages:
     - github.com/charmbracelet/glow@latest      # Markdown renderer
     - github.com/junegunn/fzf@latest            # Fuzzy finder
     - github.com/mikefarah/yq/v4@latest         # YAML processor
     - github.com/jqlang/jq@latest               # JSON processor (Go port)
     - mvdan.cc/sh/v3/cmd/shfmt@latest           # Shell script formatter

Code Analysis Tools
~~~~~~~~~~~~~~~~~~~

Go development and analysis tools:

.. code-block:: yaml

   go_user: go_developer
   go_packages:
     - golang.org/x/tools/gopls@latest                    # Language server
     - github.com/golangci/golangci-lint/cmd/golangci-lint@latest  # Linter
     - github.com/go-delve/delve/cmd/dlv@latest          # Debugger
     - golang.org/x/tools/cmd/goimports@latest           # Import formatter
     - honnef.co/go/tools/cmd/staticcheck@latest         # Static analyzer

Kubernetes Tools
~~~~~~~~~~~~~~~~

Kubernetes management utilities:

.. code-block:: yaml

   go_user: k8s_admin
   go_packages:
     - github.com/derailed/k9s@latest                    # Kubernetes TUI
     - sigs.k8s.io/kind@latest                           # Kubernetes in Docker
     - helm.sh/helm/v3/cmd/helm@latest                   # Helm package manager
     - github.com/stern/stern@latest                     # Log viewer
     - github.com/kubernetes-sigs/kustomize/kustomize/v5@latest  # Customization

Skip System Installation
~~~~~~~~~~~~~~~~~~~~~~~~~

Install only packages (Go already present):

.. code-block:: bash

   ansible-playbook --skip-tags go-system playbook.yml

Popular Go Packages
-------------------

Terminal and UI
~~~~~~~~~~~~~~~

- ``github.com/charmbracelet/glow@latest`` - Markdown renderer with style
- ``github.com/junegunn/fzf@latest`` - Fuzzy finder for command line
- ``github.com/jesseduffield/lazygit@latest`` - Terminal UI for Git
- ``github.com/jesseduffield/lazydocker@latest`` - Terminal UI for Docker

DevOps and Cloud
~~~~~~~~~~~~~~~~

- ``github.com/cli/cli/v2/cmd/gh@latest`` - GitHub CLI
- ``github.com/derailed/k9s@latest`` - Kubernetes TUI
- ``github.com/stern/stern@latest`` - Kubernetes log tailing
- ``sigs.k8s.io/kind@latest`` - Kubernetes in Docker

Data Processing
~~~~~~~~~~~~~~~

- ``github.com/mikefarah/yq/v4@latest`` - YAML processor
- ``mvdan.cc/sh/v3/cmd/shfmt@latest`` - Shell script formatter
- ``github.com/fullstorydev/grpcurl/cmd/grpcurl@latest`` - gRPC curl

Go Development
~~~~~~~~~~~~~~

- ``golang.org/x/tools/gopls@latest`` - Go language server
- ``github.com/golangci/golangci-lint/cmd/golangci-lint@latest`` - Meta-linter
- ``github.com/go-delve/delve/cmd/dlv@latest`` - Go debugger
- ``golang.org/x/tools/cmd/goimports@latest`` - Import formatter
- ``honnef.co/go/tools/cmd/staticcheck@latest`` - Static analyzer

Troubleshooting
---------------

go Command Not Found
~~~~~~~~~~~~~~~~~~~~~

If go commands aren't found after installation:

1. **Reload shell configuration:**

   .. code-block:: bash

      source ~/.profile

2. **Verify PATH:**

   .. code-block:: bash

      echo $PATH | grep go

3. **Check Go installation:**

   .. code-block:: bash

      which go
      go version

4. **Logout and login again** for automatic PATH loading

Package Installation Fails
~~~~~~~~~~~~~~~~~~~~~~~~~~~

If ``go install`` fails:

1. **Check Go version:**

   .. code-block:: bash

      go version

   Go 1.16+ required for ``go install``

2. **Verify package path:**

   .. code-block:: bash

      go install -n github.com/user/package@latest

3. **Clear module cache:**

   .. code-block:: bash

      go clean -modcache

Binary Not Found After Installation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If package installs but binary isn't found:

1. **Verify binary exists:**

   .. code-block:: bash

      ls ~/go/bin/

2. **Check PATH includes ~/go/bin:**

   .. code-block:: bash

      echo $PATH | grep "go/bin"

3. **Source profile:**

   .. code-block:: bash

      source ~/.profile

Network/Proxy Issues
~~~~~~~~~~~~~~~~~~~~

If package downloads fail:

.. code-block:: bash

   # Set Go proxy
   export GOPROXY=https://proxy.golang.org,direct

   # Or use different proxy
   export GOPROXY=https://goproxy.io,direct

   # Disable proxy
   export GOPROXY=direct

Version Conflicts
~~~~~~~~~~~~~~~~~

If package version conflicts occur:

.. code-block:: bash

   # Force reinstall
   go install -a github.com/user/package@latest

   # Install specific version
   go install github.com/user/package@v1.2.3

Dependencies
------------

**Required:**

- ``ansible.builtin.apt`` - Package installation (Ubuntu/Debian)
- ``community.general.pacman`` - Package installation (Arch Linux)
- ``community.general.homebrew`` - Package installation (macOS)
- ``ansible.builtin.command`` - Go package installation

**System Packages (installed automatically):**

- ``golang`` / ``go`` - Go programming language toolchain

Install Ansible dependencies:

.. code-block:: bash

   ansible-galaxy collection install -r requirements.yml

Go vs Other Languages
---------------------

Comparison with Node.js and Rust:

.. list-table::
   :header-rows: 1
   :widths: 20 25 25 30

   * - Feature
     - Go
     - Node.js
     - Rust
   * - Package Location
     - ``~/go/``
     - ``~/.npm-global/``
     - ``~/.cargo/``
   * - Binary Location
     - ``~/go/bin/``
     - ``~/.npm-global/bin/``
     - ``~/.cargo/bin/``
   * - Package Manager
     - ``go install``
     - ``npm``
     - ``cargo``
   * - Compilation
     - Fast
     - Interpreted
     - Slow (first time)
   * - Binary Size
     - Large (static)
     - N/A
     - Medium
   * - Cross-compilation
     - Excellent
     - N/A
     - Good

See Also
--------

- :doc:`configure_users` - User environment orchestration
- :doc:`nodejs` - Node.js development environment
- :doc:`rust` - Rust development environment
- :doc:`/reference/variables-reference` - Complete variable reference
- `Go <https://go.dev/>`_ - Official Go website
- `pkg.go.dev <https://pkg.go.dev/>`_ - Go package documentation
