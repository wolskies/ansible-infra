configure_users
===============

**Phase 3** of the System → Software → Users pattern. Configures user preferences and development environments for existing users.

.. contents::
   :local:
   :depth: 2

Overview
--------

The ``configure_users`` role manages per-user configuration including Git settings, development tool installation, dotfiles deployment, and platform-specific preferences. This is Phase 3 in the three-phase infrastructure pattern, executed after operating system and software configuration.

**This role only configures existing users** - it does not create user accounts. Non-existent users and root are automatically skipped without errors.

Features
~~~~~~~~

- **Git Configuration** - User name, email, and editor preferences
- **Development Environments** - Node.js, Rust, Go, Neovim integration
- **Terminal Configuration** - Terminal emulator terminfo installation
- **Dotfiles Deployment** - GNU Stow-based dotfiles management
- **macOS Preferences** - Dock, Finder, and screenshot settings
- **Homebrew PATH** - macOS Homebrew PATH configuration
- **Multi-user Support** - Configure multiple users in a single playbook run

Platform Support
~~~~~~~~~~~~~~~~

- **Ubuntu** 22.04+, 24.04+
- **Debian** 12+, 13+
- **Arch Linux** (Rolling)
- **macOS** 13+ (Ventura)

Usage
-----

Examples
~~~~~~~~

Git configuration for users:

.. code-block:: yaml

   - hosts: all
     become: true
     roles:
       - wolskies.infrastructure.configure_users
     vars:
       users:
         - name: developer
           git:
             user_name: "Developer Name"
             user_email: "developer@company.com"
             editor: "nvim"

         - name: deployment
           git:
             user_name: "Deploy Bot"
             user_email: "deploy@company.com"

More complex setup with language tools:

.. code-block:: yaml

   users:
     - name: developer
       git:
         user_name: "Developer Name"
         user_email: "developer@company.com"
         editor: "nvim"

       nodejs:
         packages:
           - typescript
           - eslint
           - prettier
           - "@vue/cli"

       rust:
         packages:
           - ripgrep
           - bat
           - fd-find
           - cargo-watch

       go:
         packages:
           - github.com/charmbracelet/glow@latest
           - github.com/jesseduffield/lazygit@latest

       neovim:
         deploy_config: true

       terminal_config:
         install_terminfo:
           - alacritty
           - kitty
           - wezterm

Deploy dotfiles from a Git repository using GNU Stow:

.. code-block:: yaml

   users:
     - name: developer
       git:
         user_name: "Developer Name"
         user_email: "developer@company.com"

       dotfiles:
         enable: true
         repository: "https://github.com/developer/dotfiles"
         dest: ".dotfiles"
         stow_packages:
           - bash
           - vim
           - tmux
           - git

Configure macOS Dock, Finder, and system preferences:

.. code-block:: yaml

   users:
     - name: developer
       Darwin:
         dock:
           tile_size: 48
           autohide: true
           minimize_to_application: true
           show_recents: false
           orientation: "bottom"

         finder:
           show_extensions: true
           show_hidden: true
           show_pathbar: true
           show_statusbar: true
           default_view: "list"

         screenshots:
           directory: "Screenshots"
           format: "png"
           show_thumbnail: false

         homebrew:
           shell_path: true

Multi-user development workstation configuration:

.. code-block:: yaml

   - hosts: workstations
     become: true
     roles:
       - wolskies.infrastructure.configure_users
     vars:
       users:
         - name: alice
           git:
             user_name: "Alice Developer"
             user_email: "alice@company.com"
             editor: "nvim"

           nodejs:
             packages: [typescript, eslint, prettier]

           rust:
             packages: [ripgrep, fd-find, bat]

           neovim:
             deploy_config: true

           dotfiles:
             enable: true
             repository: "https://github.com/alice/dotfiles"

         - name: bob
           git:
             user_name: "Bob Engineer"
             user_email: "bob@company.com"

           go:
             packages:
               - github.com/jesseduffield/lazygit@latest

           terminal_config:
             install_terminfo: [alacritty, kitty]

Variables
---------

User Configuration
~~~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 25 15 60

   * - Variable
     - Type
     - Description
   * - ``users``
     - list
     - List of user configurations (see schema below)

User Object Schema
~~~~~~~~~~~~~~~~~~

Each user in the ``users`` list is a dictionary:

.. list-table::
   :header-rows: 1
   :widths: 20 15 65

   * - Field
     - Type
     - Description
   * - ``name``
     - string
     - Username (must already exist on the system)
   * - ``git``
     - dict
     - Git configuration (see Git Configuration below)
   * - ``nodejs``
     - dict
     - Node.js configuration (see :doc:`install_nodejs`)
   * - ``rust``
     - dict
     - Rust configuration (see :doc:`install_rust`)
   * - ``go``
     - dict
     - Go configuration (see :doc:`install_go`)
   * - ``neovim``
     - dict
     - Neovim configuration (see :doc:`install_neovim`)
   * - ``terminal_entries``
     - list
     - Terminal emulators to configure (see :doc:`install_terminfo`)
   * - ``dotfiles``
     - dict
     - Dotfiles deployment configuration (see Dotfiles Configuration below)
   * - ``Darwin``
     - dict
     - macOS preferences (see macOS Configuration below)

Git Configuration
~~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 25 15 60

   * - Field
     - Type
     - Description
   * - ``user_name``
     - string
     - Git user.name (e.g., "John Developer")
   * - ``user_email``
     - string
     - Git user.email (e.g., "john@example.com")
   * - ``editor``
     - string
     - Git core.editor (e.g., "nvim", "vim", "code --wait")

Example:

.. code-block:: yaml

   git:
     user_name: "Alice Developer"
     user_email: "alice@example.com"
     editor: "nvim"

Dotfiles Configuration
~~~~~~~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 25 15 60

   * - Field
     - Type
     - Description
   * - ``enable``
     - boolean
     - Enable dotfiles deployment. Default: false
   * - ``repository``
     - string
     - Git repository URL
   * - ``dest``
     - string
     - Destination directory (relative to home). Default: ".dotfiles"
   * - ``stow_packages``
     - list
     - List of stow packages to deploy. Default: all directories

Example:

.. code-block:: yaml

   dotfiles:
     enable: true
     repository: "https://github.com/developer/dotfiles"
     dest: ".dotfiles"
     stow_packages:
       - bash
       - vim
       - tmux
       - git
       - nvim

macOS Configuration
~~~~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 25 15 60

   * - Field
     - Type
     - Description
   * - ``Darwin.dock``
     - dict
     - Dock preferences (see Dock Configuration)
   * - ``Darwin.finder``
     - dict
     - Finder preferences (see Finder Configuration)
   * - ``Darwin.screenshots``
     - dict
     - Screenshot preferences (see Screenshot Configuration)
   * - ``Darwin.homebrew.shell_path``
     - boolean
     - Add Homebrew to shell PATH. Default: false

Dock Configuration (macOS)
^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. list-table::
   :header-rows: 1
   :widths: 25 15 60

   * - Field
     - Type
     - Description
   * - ``tile_size``
     - integer
     - Icon size in pixels (16-128). Default: 48
   * - ``autohide``
     - boolean
     - Automatically hide Dock. Default: false
   * - ``minimize_to_application``
     - boolean
     - Minimize windows into application icon. Default: false
   * - ``show_recents``
     - boolean
     - Show recent applications. Default: true
   * - ``orientation``
     - string
     - Dock position: "bottom", "left", "right". Default: "bottom"

Finder Configuration (macOS)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. list-table::
   :header-rows: 1
   :widths: 25 15 60

   * - Field
     - Type
     - Description
   * - ``show_extensions``
     - boolean
     - Show all filename extensions. Default: false
   * - ``show_hidden``
     - boolean
     - Show hidden files. Default: false
   * - ``show_pathbar``
     - boolean
     - Show path bar. Default: false
   * - ``show_statusbar``
     - boolean
     - Show status bar. Default: false
   * - ``default_view``
     - string
     - Default view: "icon", "list", "column", "gallery". Default: "icon"

Screenshot Configuration (macOS)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. list-table::
   :header-rows: 1
   :widths: 25 15 60

   * - Field
     - Type
     - Description
   * - ``directory``
     - string
     - Screenshot save directory (relative to home). Default: "Desktop"
   * - ``format``
     - string
     - Image format: "png", "jpg", "pdf". Default: "png"
   * - ``show_thumbnail``
     - boolean
     - Show thumbnail after capture. Default: true

Behavior
--------

User Validation
~~~~~~~~~~~~~~~

The role validates users before configuration:

1. **User Existence Check** - Verifies user exists on the system
2. **Root User Skip** - Automatically skips root user
3. **Non-existent User Skip** - Skips non-existent users without error
4. **Per-User Processing** - Each user configured independently

This allows the same playbook to run across systems with different user accounts.

Development Tool Installation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Development tools are installed to user directories:

- **Node.js packages**: ``~/.npm-global/``
- **Rust packages**: ``~/.cargo/``
- **Go packages**: ``~/go/``
- **PATH updates**: Automatically added to ``~/.profile``

Tools are installed per-user, not system-wide.

Dotfiles Deployment
~~~~~~~~~~~~~~~~~~~

When ``dotfiles.enable: true``:

1. **Repository Clone** - Clone dotfiles repository to ``~/{{dest}}``
2. **Stow Installation** - Ensure GNU Stow is installed
3. **Dry Run Check** - Check for conflicts, moves conflicting files to *.backup
4. **Deployment** - Deploy dotfiles with ``stow``
5. **Idempotent** - Safe to run multiple times

Tags
----

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - Tag
     - Description
   * - ``user-git``
     - Git configuration only
   * - ``user-nodejs``
     - Node.js and npm packages
   * - ``user-rust``
     - Rust and cargo packages
   * - ``user-go``
     - Go and go packages
   * - ``user-neovim``
     - Neovim configuration
   * - ``user-terminal``
     - Terminal emulator configuration
   * - ``user-dotfiles``
     - Dotfiles deployment
   * - ``user-macos``
     - macOS preferences (Darwin only)


Dependencies
------------

**Role Dependencies:**

This role orchestrates the following utility roles from this collection:

- :doc:`install_nodejs` - Node.js and npm packages
- :doc:`install_rust` - Rust and cargo packages
- :doc:`install_go` - Go and go packages
- :doc:`install_neovim` - Neovim configuration
- :doc:`install_terminfo` - Terminal emulator terminfo

**Ansible Collections:**

All Ansible collection dependencies are installed via:

.. code-block:: bash

   ansible-galaxy collection install -r requirements.yml

Limitations
-----------

**PATH Configuration:**

PATH updates are added to ``~/.profile``, which may not be sourced by all shells. Users may need to:

- Logout and login again
- Manually source ``. ~/.profile``
- Add equivalent configuration to their shell RC file

**macOS Preferences:**

Some macOS preferences require logout/login or system restart to take effect.

See Also
--------

- :doc:`configure_operating_system` - Phase 1: OS configuration
- :doc:`configure_software` - Phase 2: Package management
- :doc:`system_setup` - Meta-role demonstrating all three phases
- :doc:`install_nodejs` - Node.js utility role
- :doc:`install_rust` - Rust utility role
- :doc:`install_go` - Go utility role
- :doc:`install_neovim` - Neovim utility role
- :doc:`install_terminfo` - Terminal configuration utility role
- :doc:`/reference/variables-reference` - Complete variable reference
- :doc:`/user-guide/configuration` - Configuration strategies
