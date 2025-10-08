Platform Support
================

Supported platforms and versions.

Supported Platforms
-------------------

* **Ubuntu** 22.04+, 24.04+
* **Debian** 12+, 13+
* **Arch Linux** (Rolling)
* **macOS** 13+ (Ventura)

Platform-Specific Notes
-----------------------

Ubuntu/Debian
~~~~~~~~~~~~~

* APT package management
* UFW firewall
* systemd services

Arch Linux
~~~~~~~~~~

* Pacman package management
* Optional AUR support via paru
* systemd services

macOS
~~~~~

**Status**: Limited automated testing

**Supported Features:**

* Homebrew package management
* Application Layer Firewall (ALF)
* Basic system configuration (hostname, timezone)
* Development environments (Node.js, Rust, Go, Neovim)
* User preference configuration (Dock, Finder, screenshots)

**Not Supported:**

* Port-based firewall rules (ALF is application-based only)
* fail2ban intrusion prevention (Linux-only)
* Security hardening via devsec.hardening (Linux-only)
* systemd service management (macOS uses launchd)
* Locale configuration (handled differently on macOS)

**Testing Status:**

macOS support is functional but lacks automated testing in CI. The collection's Phase III VM testing plan includes comprehensive macOS validation when licensing constraints allow. Current macOS support relies on manual testing.
