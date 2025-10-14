install_terminfo
================

Utility role for terminal emulator terminfo configuration.

.. contents::
   :local::
   :depth: 2

Overview
--------

The ``install_terminfo`` role configures terminfo entries for modern terminal emulators to ensure proper terminal capabilities and display. This is a utility role typically orchestrated by :doc:`configure_users` but can also be used standalone.

**Key Features:**

- **Multi-Terminal Support** - Alacritty, Kitty, WezTerm
- **Automatic Compilation** - Downloads and compiles terminfo sources
- **User-Level Installation** - Installs to ``~/.terminfo/`` directory
- **Idempotent** - Only processes missing terminfo entries
- **Cross-Platform** - Linux and macOS support

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

Configure terminfo for specific terminals:

.. code-block:: yaml

   - hosts: workstations
     become: true
     roles:
       - wolskies.infrastructure.install_terminfo
     vars:
       terminal_user: developer
       terminal_entries:
         - alacritty
         - kitty
         - wezterm

Configure for a single terminal:

.. code-block:: yaml

   - hosts: workstations
     become: true
     roles:
       - wolskies.infrastructure.install_terminfo
     vars:
       terminal_user: developer
       terminal_entries:
         - alacritty

Integration with configure_users
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Typically used via configure_users role:

.. code-block:: yaml

   users:
     - name: developer
       terminal_config:
         install_terminfo:
           - alacritty
           - kitty
           - wezterm

     - name: alice
       terminal_config:
         install_terminfo:
           - wezterm

Multiple Users
~~~~~~~~~~~~~~

Configure terminals for multiple users:

.. code-block:: yaml

   - hosts: workstations
     become: true
     tasks:
       - name: Configure terminals for developers
         include_role:
           name: wolskies.infrastructure.install_terminfo
         vars:
           terminal_user: "{{ item }}"
           terminal_entries:
             - alacritty
             - wezterm
         loop:
           - alice
           - bob
           - charlie

Variables
---------

.. list-table::
   :header-rows: 1
   :widths: 25 15 60

   * - Variable
     - Type
     - Description
   * - ``terminal_user``
     - string
     - Target username for terminfo installation (required)
   * - ``terminal_entries``
     - list
     - List of terminal names to configure (required)

Supported Terminals
~~~~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :widths: 20 40 40

   * - Terminal
     - Description
     - Terminal Type
   * - ``alacritty``
     - Modern GPU-accelerated terminal emulator
     - ``alacritty``, ``alacritty-direct``
   * - ``kitty``
     - Fast, feature-rich, cross-platform terminal
     - ``xterm-kitty``
   * - ``wezterm``
     - GPU-accelerated cross-platform terminal emulator
     - ``wezterm``

Installation Behavior
---------------------

The role performs these steps:

1. **Validation**

   - Checks required variables (user and terminal list)
   - Verifies user exists on the system

2. **Terminfo Check**

   - Uses ``infocmp`` to check existing terminfo entries
   - Determines which terminals need terminfo compilation

3. **Directory Creation**

   - Ensures ``~/.terminfo`` directory exists if needed
   - Sets proper ownership for user

4. **Per-Terminal Processing**

   For each terminal requiring setup:

   a. Downloads terminfo source from official repository
   b. Compiles using ``tic`` with appropriate options
   c. Installs to user's ``~/.terminfo`` directory
   d. Cleans up temporary files

5. **Verification**

   - Confirms terminfo entries are available
   - Reports installation status

User-Level Installation
-----------------------

All terminfo entries install to user directories:

**Directory Structure:**

- **Terminfo Database**: ``~/.terminfo/``
- **Entry Structure**: ``~/.terminfo/a/alacritty``, ``~/.terminfo/x/xterm-kitty``, etc.
- **No Root Required**: User-specific installation

**Benefits:**

- No system-wide changes
- User controls their own terminal configuration
- Multiple users can have different terminal setups
- Safe to experiment without affecting system

**Verification:**

Users can verify terminfo entries:

.. code-block:: bash

   # Check specific terminal
   infocmp alacritty
   infocmp xterm-kitty
   infocmp wezterm

   # List all installed terminfo entries
   ls ~/.terminfo/

   # View terminfo database structure
   tree ~/.terminfo/

Platform-Specific Features
---------------------------

Ubuntu/Debian
~~~~~~~~~~~~~

**Requirements:**

- ``ncurses-bin`` package (provides ``tic`` compiler)
- Usually pre-installed on desktop systems

**Installation:**

.. code-block:: bash

   sudo apt install ncurses-bin

**Compatibility:**

Works on all Ubuntu and Debian versions with ncurses support.

Arch Linux
~~~~~~~~~~

**Requirements:**

- ``ncurses`` package (provides ``tic`` compiler)
- Part of base system installation

**Installation:**

.. code-block:: bash

   sudo pacman -S ncurses

**Note:** Usually already installed on Arch Linux systems.

macOS
~~~~~

**Requirements:**

- ncurses (pre-installed with macOS)
- ``tic`` command available by default

**Compatibility:**

Works on macOS 13+ (Ventura) without additional packages.

Terminal Configuration Details
------------------------------

Alacritty
~~~~~~~~~

**Terminfo Sources:**

- Downloaded from official Alacritty repository
- URL: ``https://raw.githubusercontent.com/alacritty/alacritty/master/extra/alacritty.info``

**Terminal Entries:**

- ``alacritty`` - Standard Alacritty terminal
- ``alacritty-direct`` - Direct color support variant

**Features:**

- True color support (24-bit color)
- Modern terminal capabilities
- GPU-accelerated rendering

**Configuration:**

Set TERM in Alacritty config (``~/.config/alacritty/alacritty.yml``):

.. code-block:: yaml

   env:
     TERM: alacritty

Kitty
~~~~~

**Terminfo Sources:**

- Downloaded from official Kitty repository
- URL: ``https://raw.githubusercontent.com/kovidgoyal/kitty/master/terminfo/kitty.terminfo``

**Terminal Entries:**

- ``xterm-kitty`` - Primary terminal type

**Features:**

- Enhanced graphics protocol
- True color support
- Advanced terminal features
- Image display support

**Configuration:**

Kitty automatically sets TERM to ``xterm-kitty``.

WezTerm
~~~~~~~

**Terminfo Sources:**

- Downloaded from official WezTerm repository
- URL: ``https://raw.githubusercontent.com/wez/wezterm/main/termwiz/data/wezterm.terminfo``

**Terminal Entries:**

- ``wezterm`` - WezTerm terminal type

**Features:**

- True color support
- Modern terminal capabilities
- Cross-platform consistency
- GPU-accelerated rendering

**Configuration:**

WezTerm automatically sets TERM to ``wezterm``.

File Locations
--------------

.. list-table::
   :header-rows: 1
   :widths: 40 60

   * - Path
     - Description
   * - ``~/.terminfo/``
     - User terminfo database directory
   * - ``~/.terminfo/a/alacritty``
     - Alacritty terminfo entry
   * - ``~/.terminfo/a/alacritty-direct``
     - Alacritty direct color variant
   * - ``~/.terminfo/x/xterm-kitty``
     - Kitty terminfo entry
   * - ``~/.terminfo/w/wezterm``
     - WezTerm terminfo entry
   * - ``/tmp/<terminal>.terminfo``
     - Temporary terminfo source files (cleaned up)

Why Terminfo Configuration?
----------------------------

Modern terminal emulators have advanced features that may not be in the system terminfo database:

**Without Proper Terminfo:**

- Colors may not display correctly
- Special characters may render incorrectly
- Terminal features may not work (italics, true color, etc.)
- Applications may fall back to basic terminal modes
- Poor user experience with CLI tools

**With Proper Terminfo:**

- Full 24-bit true color support
- Correct character rendering
- All terminal features available to applications
- Optimal performance and display
- Better experience with modern CLI tools

**Common Symptoms Without Terminfo:**

.. code-block:: bash

   # Terminal type unknown error
   'alacritty': unknown terminal type

   # Applications fall back to basic mode
   WARNING: terminal is not fully functional

   # Colors don't display properly
   # True color gradients show as basic colors

Examples
--------

Developer Workstation
~~~~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   terminal_user: developer
   terminal_entries:
     - alacritty
     - kitty
     - wezterm

Installs terminfo for all three major modern terminal emulators.

Single Terminal
~~~~~~~~~~~~~~~

.. code-block:: yaml

   terminal_user: alice
   terminal_entries:
     - alacritty

Installs terminfo only for Alacritty.

Via configure_users
~~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   users:
     - name: developer
       git:
         user_name: "Developer Name"
         user_email: "developer@company.com"

       terminal_config:
         install_terminfo:
           - alacritty
           - kitty

       neovim:
         deploy_config: true

     - name: sysadmin
       terminal_config:
         install_terminfo:
           - wezterm

Troubleshooting
---------------

Terminfo Not Found After Installation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If terminal type isn't recognized:

1. **Verify installation:**

   .. code-block:: bash

      infocmp alacritty
      ls ~/.terminfo/

2. **Check TERM variable:**

   .. code-block:: bash

      echo $TERM

3. **Set TERM in terminal config:**

   For Alacritty (``~/.config/alacritty/alacritty.yml``):

   .. code-block:: yaml

      env:
        TERM: alacritty

4. **Restart terminal** after configuration changes

tic Command Not Found
~~~~~~~~~~~~~~~~~~~~~

If ``tic`` command is missing:

**Ubuntu/Debian:**

.. code-block:: bash

   sudo apt install ncurses-bin

**Arch Linux:**

.. code-block:: bash

   sudo pacman -S ncurses

**macOS:**

``tic`` is included with macOS (part of ncurses). If missing, reinstall Command Line Tools:

.. code-block:: bash

   xcode-select --install

Download Fails
~~~~~~~~~~~~~~

If terminfo source download fails:

1. **Check internet connection**

2. **Verify URLs are accessible:**

   .. code-block:: bash

      curl -I https://raw.githubusercontent.com/alacritty/alacritty/master/extra/alacritty.info

3. **Check for GitHub rate limiting** (rare)

4. **Retry the playbook** - temporary network issues

Colors Don't Display Correctly
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If colors appear wrong after installation:

1. **Verify TERM variable:**

   .. code-block:: bash

      echo $TERM
      # Should match terminal type (e.g., "alacritty")

2. **Test true color support:**

   .. code-block:: bash

      awk 'BEGIN{
          s="/\\/\\/\\/\\/\\"; s=s s s s s s s s;
          for (colnum = 0; colnum<77; colnum++) {
              r = 255-(colnum*255/76);
              g = (colnum*510/76);
              b = (colnum*255/76);
              if (g>255) g = 510-g;
              printf "\033[48;2;%d;%d;%dm", r,g,b;
              printf "\033[38;2;%d;%d;%dm", 255-r,255-g,255-b;
              printf "%s\033[0m", substr(s,colnum+1,1);
          }
          printf "\n";
      }'

   This should display a smooth color gradient.

3. **Reinstall terminfo:**

   .. code-block:: bash

      rm -rf ~/.terminfo
      # Re-run ansible playbook

4. **Check terminal configuration** for TERM setting

Permission Errors
~~~~~~~~~~~~~~~~~

If permission errors occur during installation:

1. **Verify user exists:**

   .. code-block:: bash

      id username

2. **Check home directory permissions:**

   .. code-block:: bash

      ls -ld ~username

3. **Ensure write access to home directory**

4. **Check Ansible become settings** - role requires become: true

Unknown Terminal Error
~~~~~~~~~~~~~~~~~~~~~~

If you see "unknown terminal type" errors:

1. **Verify terminfo was installed:**

   .. code-block:: bash

      ls ~/.terminfo/a/alacritty

2. **Check TERMINFO variable:**

   .. code-block:: bash

      echo $TERMINFO
      # Should be empty (uses ~/.terminfo automatically)

3. **Use infocmp to verify:**

   .. code-block:: bash

      infocmp alacritty

4. **Reinstall if corrupted:**

   .. code-block:: bash

      rm -rf ~/.terminfo
      # Re-run ansible playbook

Adding New Terminals
--------------------

To add support for additional terminals, extend the ``terminal_configs`` mapping in role defaults:

.. code-block:: yaml

   # roles/install_terminfo/defaults/main.yml
   terminal_configs:
     new_terminal:
       terminfo_url: "https://example.com/terminal.terminfo"
       entries:
         - terminal-name
         - terminal-variant
       tic_options: "-x"

**Configuration Fields:**

- ``terminfo_url`` - URL to download terminfo source file
- ``entries`` - List of terminal type names to compile
- ``tic_options`` - Options passed to ``tic`` compiler (e.g., ``-x`` for extended capabilities)

**Example: Adding tmux:**

.. code-block:: yaml

   terminal_configs:
     tmux:
       terminfo_url: "https://example.com/tmux.terminfo"
       entries:
         - tmux
         - tmux-256color
       tic_options: "-x"

Tags
----

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - Tag
     - Description
   * - ``user-terminal``
     - All terminal configuration tasks

Dependencies
------------

**Ansible Collections:**

- ``ansible.builtin`` - Core modules only (no external dependencies)

**System Requirements:**

- User account must exist
- ``tic`` command available (ncurses-bin/ncurses)
- Internet access for downloading terminfo sources
- Write access to user's home directory

**System Packages (must be present):**

- ``ncurses-bin`` (Ubuntu/Debian)
- ``ncurses`` (Arch Linux)
- ``ncurses`` (macOS - pre-installed)

Install system packages if needed:

.. code-block:: bash

   # Ubuntu/Debian
   sudo apt install ncurses-bin

   # Arch Linux
   sudo pacman -S ncurses

Limitations
-----------

**Terminal Applications:**

This role only configures terminfo entries. It does not:

- Install terminal emulator applications
- Configure terminal emulator settings
- Manage terminal emulator themes

Users must install terminal emulators separately (via configure_software or manually).

**Container Environments:**

- Terminfo compilation works in containers
- Terminal emulator functionality requires display forwarding
- Testing limited in CI/CD environments without displays

**Network Requirements:**

- Requires internet access to download terminfo sources
- Downloads from GitHub repositories
- May be affected by GitHub rate limiting (rare)

**User Requirements:**

- User must exist before role execution
- Role does not create users
- Skips if user doesn't exist

See Also
--------

- :doc:`configure_users` - Phase 3 role that orchestrates this utility role
- :doc:`install_neovim` - Neovim utility role (benefits from proper terminfo)
- :doc:`configure_software` - Phase 2 role (can install terminal emulators)
- :doc:`/reference/variables-reference` - Complete variable reference
- `Alacritty <https://alacritty.org/>`_ - GPU-accelerated terminal
- `Kitty <https://sw.kovidgoyal.net/kitty/>`_ - Fast, feature-rich terminal
- `WezTerm <https://wezfurlong.org/wezterm/>`_ - GPU-accelerated terminal
