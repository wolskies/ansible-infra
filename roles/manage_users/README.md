# manage_users

Essential user management focused on authentication and system access.

## Description

This role provides focused user management for system provisioning. It creates users with authentication (passwords and/or SSH keys) and group membership. For detailed user configuration (shell preferences, dotfiles, etc.), use the `configure_users` role.

## Features

- **User Creation**: Create system users with secure defaults
- **SSH Key Deployment**: Add SSH public keys to user accounts
- **Password Management**: Support for encrypted or plaintext passwords
- **Group Assignment**: Add users to system and custom groups
- **Cross-Platform**: Works on Ubuntu, Debian, Arch Linux, and macOS

## Role Variables

### User Configuration

```yaml
# List of users to manage on the system
# All fields map directly to ansible.builtin.user module parameters
users: []

# List of usernames to remove from the system
users_absent: []
```

### User Configuration Format

```yaml
users:
  - name: username                              # Required: username
    comment: "User Full Name"                    # Optional: GECOS field
    groups: [sudo, docker]                       # Optional: additional groups
    ssh_pubkey: "ssh-rsa AAAAB3..."             # Optional: SSH public key
    password: "$6$salt$encrypted"               # Optional: encrypted password (or plaintext)

users_absent:
  - olduser
  - tempuser
```

## Dependencies

- **Dotfiles Integration**: Calls `wolskinet.infrastructure.dotfiles` role for users with dotfiles configuration

## Example Playbook

### Basic User Management
```yaml
- hosts: all
  roles:
    - role: wolskinet.infrastructure.manage_users
      vars:
        users:
          - name: developer
            groups: [sudo, docker]
            ssh_pubkey: "ssh-rsa AAAAB3NzaC1yc2..."
            password: "MySecurePassword123!"  # Will be hashed automatically

          - name: service
            comment: "Service Account"

        users_absent:
          - olduser
```

### Users with Dotfiles
```yaml
- hosts: workstations
  roles:
    - role: wolskinet.infrastructure.manage_users
      vars:
        users:
          - name: alice
            groups: [sudo]
            ssh_pubkey: "ssh-rsa AAAAB3..."
```

### Encrypted Passwords
```yaml
# Pre-encrypted password (use mkpasswd or similar)
users:
  - name: admin
    password: "$6$rounds=656000$salt$hash..."

# Plaintext password (will be hashed)
users:
  - name: user
    password: "PlaintextPassword123"
```

## How It Works

1. **User Creation/Modification**: Uses `ansible.builtin.user` module to manage user accounts
2. **SSH Key Deployment**: Uses `ansible.posix.authorized_key` module to add SSH public keys
3. **User Removal**: Removes users and their home directories
4. **Dotfiles Deployment**: Calls the dotfiles role for users with dotfiles configuration

## Platform Support

- Ubuntu 22.04+
- Debian 12+
- Arch Linux
- macOS

The role uses only standard Ansible modules that work across all supported platforms.

## Notes

- Passwords can be provided as plaintext (automatically hashed) or pre-encrypted
- SSH keys must be in valid format (ssh-rsa, ecdsa, ssh-ed25519)
- The role does not manage sudo permissions (use sudoers configuration separately)
- Group membership is additive (append mode) - existing groups are preserved
