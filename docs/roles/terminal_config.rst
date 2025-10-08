terminal_config
===============

Terminal emulator configuration and terminfo setup for modern terminals.

.. contents::
   :local:
   :depth: 2

Overview
--------

The ``terminal_config`` role configures terminfo entries for modern terminal emulators to ensure proper terminal capabilities and display. It downloads and compiles terminfo definitions for supported terminals, installing them to the user's ``~/.terminfo`` directory.

.. note::
   This role is still in development and may have test issues. Use with caution in production environments.

Features
~~~~~~~~

- **Multi-terminal Support** - Alacritty, Kitty, WezTerm, and extensible
- **Automatic Compilation** - Downloads and compiles terminfo sources as needed
- **User-Level Installation** - Installs to ``~/.terminfo`` without system-wide changes
- **Idempotent** - Only processes missing terminfo entries
- **Cross-platform** - Linux and macOS support

Platform Support
~~~~~~~~~~~~~~~~

- **Ubuntu** 22.04+, 24.04+
- **Debian** 12+, 13+
- **Arch Linux** (Rolling)
- **macOS** 13+ (Ventura)

Usage
-----

Basic Terminal Configuration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Configure terminfo for specific terminals:

.. code-block:: yaml

   - hosts: workstations
     become: true
     roles:
       - wolskies.infrastructure.terminal_config
     vars:
       terminal_user: developer
       terminal_entries:
         - alacritty
         - kitty

Multiple Users
~~~~~~~~~~~~~~

Configure terminals for multiple users:

.. code-block:: yaml

   - hosts: workstations
     become: true
     tasks:
       - name: Configure terminals for developers
         include_role:
           name: wolskies.infrastructure.terminal_config
         vars:
           terminal_user: "{{ item }}"
           terminal_entries:
             - alacritty
             - wezterm
         loop:
           - alice
           - bob
           - charlie

Integration with configure_users
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The ``terminal_config`` role is typically invoked via :doc:`configure_users`:

.. code-block:: yaml

   users:
     - name: developer
       terminal_config:
         install_terminfo:
           - alacritty
           - kitty
           - wezterm

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

Installation Process
~~~~~~~~~~~~~~~~~~~~

1. **Validation** - Check required variables (user and terminal list)

2. **Terminfo Check** - Use ``infocmp`` to check existing terminfo entries

3. **Compilation Decision** - Determine which terminals need terminfo compilation

4. **Directory Creation** - Ensure ``~/.terminfo`` directory exists if needed

5. **Per-terminal Processing** - For each terminal requiring setup:

   a. Download terminfo source from official repository
   b. Compile using ``tic`` with appropriate options
   c. Install to user's ``~/.terminfo`` directory
   d. Clean up temporary files

6. **Verification** - Confirm terminfo entries are available

User-Level Installation
~~~~~~~~~~~~~~~~~~~~~~~

All terminfo entries install to user directories:

- **Terminfo Database**: ``~/.terminfo/``
- **Entry Structure**: ``~/.terminfo/a/alacritty``, ``~/.terminfo/x/xterm-kitty``, etc.
- **No Root Required**: User-specific installation

Users can verify terminfo entries:

.. code-block:: bash

   infocmp alacritty      # Check Alacritty terminfo
   infocmp xterm-kitty    # Check Kitty terminfo
   ls ~/.terminfo/        # List installed terminfo entries

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
   * - ``~/.terminfo/x/xterm-kitty``
     - Kitty terminfo entry
   * - ``~/.terminfo/w/wezterm``
     - WezTerm terminfo entry
   * - ``/tmp/``
     - Temporary terminfo source files (cleaned up)

Tags
----

Control terminal configuration:

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - Tag
     - Description
   * - ``terminal-config``
     - All terminal configuration tasks

Examples
--------

Single Terminal
~~~~~~~~~~~~~~~

Configure only Alacritty:

.. code-block:: yaml

   terminal_user: developer
   terminal_entries:
     - alacritty

All Supported Terminals
~~~~~~~~~~~~~~~~~~~~~~~~

Configure all supported terminals:

.. code-block:: yaml

   terminal_user: developer
   terminal_entries:
     - alacritty
     - kitty
     - wezterm

With Variable Files
~~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   # group_vars/developers.yml
   terminal_user: developer
   terminal_entries:
     - alacritty
     - wezterm

   # playbook.yml
   - hosts: developers
     become: true
     roles:
       - wolskies.infrastructure.terminal_config

Adding New Terminals
--------------------

To add support for additional terminals, extend the ``terminal_configs`` mapping in role defaults:

.. code-block:: yaml

   # roles/terminal_config/defaults/main.yml
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

Why Terminfo Configuration?
---------------------------

Modern terminal emulators often have advanced features that aren't in the system terminfo database:

**Without Proper Terminfo:**

- Colors may not display correctly
- Special characters may render incorrectly
- Terminal features may not work (italics, true color, etc.)
- Applications may fall back to basic terminal modes

**With Proper Terminfo:**

- Full 24-bit true color support
- Correct character rendering
- All terminal features available to applications
- Optimal performance and display

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

tic Command Not Found
~~~~~~~~~~~~~~~~~~~~~~

If ``tic`` command is missing:

**Ubuntu/Debian:**

.. code-block:: bash

   sudo apt install ncurses-bin

**Arch Linux:**

.. code-block:: bash

   sudo pacman -S ncurses

**macOS:**

``tic`` is included with macOS (part of ncurses).

Download Fails
~~~~~~~~~~~~~~

If terminfo source download fails:

1. **Check internet connection**

2. **Verify URLs are accessible:**

   .. code-block:: bash

      curl -I https://raw.githubusercontent.com/alacritty/alacritty/master/extra/alacritty.info

3. **Check for GitHub rate limiting**

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

3. **Reinstall terminfo:**

   .. code-block:: bash

      rm -rf ~/.terminfo
      # Re-run ansible playbook

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

Requirements
------------

**System Requirements:**

- Target user must exist on the system
- ``tic`` command available (ncurses-bin/ncurses)
- Internet access for downloading terminfo sources
- Write access to user's home directory

**Dependencies:**

- ``ansible.builtin.command`` - Execute tic and infocmp
- ``ansible.builtin.get_url`` - Download terminfo sources
- ``ansible.builtin.file`` - Directory creation
- ``ansible.builtin.tempfile`` - Temporary file handling

**System Packages (must be present):**

- ``ncurses-bin`` (Ubuntu/Debian)
- ``ncurses`` (Arch Linux)
- ``ncurses`` (macOS - pre-installed)

Install system packages:

.. code-block:: bash

   # Ubuntu/Debian
   sudo apt install ncurses-bin

   # Arch Linux
   sudo pacman -S ncurses

Limitations
-----------

**Development Status:**

- Role is still in development
- May have test issues in containerized environments
- Use with caution in production

**Container Environments:**

- Terminfo compilation works in containers
- Terminal emulator functionality requires display forwarding
- Testing limited in CI/CD environments

**Terminal Availability:**

- Only configures terminfo entries
- Does not install terminal emulator applications
- Users must install terminal emulators separately

See Also
--------

- :doc:`configure_users` - User environment orchestration
- :doc:`neovim` - Neovim configuration (benefits from proper terminfo)
- :doc:`/reference/variables-reference` - Complete variable reference
- `Alacritty <https://alacritty.org/>`_ - GPU-accelerated terminal
- `Kitty <https://sw.kovidgoyal.net/kitty/>`_ - Fast, feature-rich terminal
- `WezTerm <https://wezfurlong.org/wezterm/>`_ - GPU-accelerated terminal
