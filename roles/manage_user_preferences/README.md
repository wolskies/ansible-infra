# manage_user_preferences

**PLACEHOLDER ROLE - NOT YET FUNCTIONAL**

This role is a placeholder for future user-specific configuration that should be separate from system-level infrastructure setup.

## Purpose

This role will eventually handle user-specific preferences and configurations that:
- Don't require system-level privileges
- Are scoped to individual users rather than system-wide
- Should be configured per-user rather than during infrastructure setup

## Functionality Moved Here

### From manage_language_packages:
- Node.js package installation (user-scoped via npm)
- Rust package installation (user-scoped via cargo)
- Go package installation (user-scoped via go install)

### From dotfiles role:
- User dotfiles deployment and management
- GNU Stow integration
- Git repository cloning and updates

### From manage_system_settings:
- macOS user preferences (dock, finder, etc.)
- User-specific system settings
- Desktop environment customization

## Future Implementation

This role will need to be designed to:
- Run as individual users (not root)
- Handle per-user configuration
- Integrate with user discovery and management
- Support cross-platform user preferences

## Current Status

**DO NOT USE** - This is just copied functionality for future reference.
The current files are not functional and need significant refactoring.
