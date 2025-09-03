# manage_users

Simple user management with SSH keys and dotfiles support for multiple platforms.

## Description

This role provides a thin wrapper around Ansible's built-in user management modules with additional support for SSH key deployment and dotfiles configuration. It handles user creation, modification, and removal in an OS-independent way.

## Features

- **User Management**: Create, modify, and remove system users
- **SSH Key Deployment**: Add SSH public keys to user accounts
- **Password Management**: Support for encrypted or plaintext passwords
- **Group Assignment**: Add users to system and custom groups
- **Dotfiles Integration**: Deploy user dotfiles via the dotfiles role
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
    uid: 1000                                    # Optional: specific UID (string or int)
    gid: 1000                                    # Optional: primary group ID (string or int)
    home: /home/username                         # Optional: home directory path
    shell: /bin/bash                             # Optional: user shell
    comment: "User Full Name"                    # Optional: GECOS field
    groups: [sudo, docker]                       # Optional: additional groups (not primary)
    create_home: true                            # Optional: create home directory
    ssh_pubkey: "ssh-rsa AAAAB3..."             # Optional: SSH public key
    password: "$6$salt$encrypted"               # Optional: encrypted password (or plaintext)
    dotfiles:                                    # Optional: dotfiles configuration
      enable: true                               # Required if dotfiles block present
      repo: "https://github.com/user/dotfiles"  # Required: git repository URL
      branch: "main"                             # Optional: git branch (default: main)
      directory: "/home/user/.dotfiles"         # Optional: clone directory

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
            uid: 1000
            shell: /bin/zsh
            groups: [sudo, docker]
            ssh_pubkey: "ssh-rsa AAAAB3NzaC1yc2..."
            password: "MySecurePassword123!"  # Will be hashed automatically

          - name: service
            uid: 1001
            shell: /bin/false
            create_home: false
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
            uid: 1000
            groups: [sudo]
            ssh_pubkey: "ssh-rsa AAAAB3..."
            dotfiles:
              enable: true
              repo: "https://github.com/alice/dotfiles"
              branch: "main"
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
