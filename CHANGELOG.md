# Changelog

All notable changes to this collection will be documented in this file.

## [1.2.5] - 2025-10-12

- update changelog for v1.2.5 (8faaf9a)
- "fix become issue" (21eea0c)
- fix vars associated with hardeing role (33ea74f)
- update changelog for v1.2.5 (39272a6)
- **Version**: 1.2.5
- **Build**: 869
- **Commit**: 8faaf9a2

## [1.2.5] - 2025-10-12

- "fix become issue" (21eea0c)
- fix vars associated with hardeing role (33ea74f)
- update changelog for v1.2.5 (39272a6)
- **Version**: 1.2.5
- **Build**: 868
- **Commit**: 21eea0c0

## [1.2.5] - 2025-10-12

- fix: remove method and user from manage_flatpak defaults (issue #21) (5e83ecf)
- Release v1.2.5 (1762765)
- update changelog for v1.2.0 (226195a)
- fix: use GITLAB_RELEASE_TOKEN with oauth2 prefix for changelog push (26ebb33)
- refactor: merge update-changelog into create-release job (2b24164)
- fix: upload release tarball to Generic Package Registry (f79b996)
- fix: convert tmpfs to list format with inline options for Molecule compatibility (60e71dd)
- fix: set explicit tmpfs permissions (mode=1777) to prevent mkdir failures (cfe08a5)
- fix: make pacman cache updates idempotent with changed_when: false (551a848)
- fix: add retry logic to all pacman tasks for transient mirror timeouts (7f5a1e7)
- fix: add tmpfs mounts to all Molecule platforms to prevent /tmp race conditions (612706b)
- fix: use GITLAB_RELEASE_TOKEN for release automation (7f32ec4)
- fix: resolve three critical CI issues (6073752)
- fix: install pyyaml via pip in create-release job (e73abfb)
- fix: install pyyaml via pip in update-changelog job (6a05691)
- fix: resolve Ansible temp directory creation failure in CI for Arch container (885ab47)
- fix: ensure Arch Linux timezone configuration is idempotent (e485199)
- chore: exclude test/validation jobs from tag pipelines (8ac989f)
- **Version**: 1.2.5
- **Build**: 864
- **Commit**: 5e83ecf1

## [1.2.0] - 2025-10-11

- fix: use GITLAB_RELEASE_TOKEN with oauth2 prefix for changelog push (26ebb33)
- refactor: merge update-changelog into create-release job (2b24164)
- fix: upload release tarball to Generic Package Registry (f79b996)
- fix: convert tmpfs to list format with inline options for Molecule compatibility (60e71dd)
- fix: set explicit tmpfs permissions (mode=1777) to prevent mkdir failures (cfe08a5)
- fix: make pacman cache updates idempotent with changed_when: false (551a848)
- fix: add retry logic to all pacman tasks for transient mirror timeouts (7f5a1e7)
- fix: add tmpfs mounts to all Molecule platforms to prevent /tmp race conditions (612706b)
- fix: use GITLAB_RELEASE_TOKEN for release automation (7f32ec4)
- fix: resolve three critical CI issues (6073752)
- fix: install pyyaml via pip in create-release job (e73abfb)
- fix: install pyyaml via pip in update-changelog job (6a05691)
- fix: resolve Ansible temp directory creation failure in CI for Arch container (885ab47)
- fix: ensure Arch Linux timezone configuration is idempotent (e485199)
- chore: exclude test/validation jobs from tag pipelines (8ac989f)
- **Version**: 1.2.0
- **Build**: 856
- **Commit**: 26ebb33c

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.0] - 2025-10-09

### Added
- Initial release of wolskies.infrastructure collection
- Core roles for infrastructure automation:
  - `configure_host` - System-level host configuration
  - `manage_packages` - Hierarchical package management
  - `manage_users` - User and group management with dotfiles
  - `manage_firewall` - Firewall and fail2ban configuration
  - `discovery` - Infrastructure scanning and inventory generation
  - `dotfiles` - Automated dotfiles deployment
  - `manage_system_settings` - Performance and hardware optimization
  - `manage_language_packages` - Language ecosystem package management
- Multi-platform support: Ubuntu 22+, Debian 12+, Arch Linux, macOS
- Hierarchical package variable system (all/group/host levels)
- Discovery-driven deployment workflow
- Comprehensive documentation and examples
- Gitleaks secret scanning in pre-commit and CI
- Sphinx documentation build with generated docs directory

### Changed
- Refactored from monolithic basic_setup role to specialized roles
- Improved variable naming consistency across all roles

### Fixed
- Prevented repeated pacman cache updates for idempotence
- Improved documentation accuracy and removed marketing language

### Security
- All roles follow security best practices
- Integration with devsec.hardening collection
- Gitleaks secret scanning enabled

[Unreleased]: https://github.com/wolskinet/ansible-infrastructure/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/wolskinet/ansible-infrastructure/compare/v1.0.0...v1.2.0
[1.0.0]: https://github.com/wolskinet/ansible-infrastructure/releases/tag/v1.0.0
