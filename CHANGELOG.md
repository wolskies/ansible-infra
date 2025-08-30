# Changelog

All notable changes to this collection will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial release of wolskinet.infrastructure collection
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

### Changed
- Refactored from monolithic basic_setup role to specialized roles
- Improved variable naming consistency across all roles

### Security
- All roles follow security best practices
- Integration with devsec.hardening collection

## [1.0.0] - 2024-01-01

### Added
- Initial stable release

[Unreleased]: https://github.com/wolskinet/ansible-infrastructure/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/wolskinet/ansible-infrastructure/releases/tag/v1.0.0