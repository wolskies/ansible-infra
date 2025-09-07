# manage_users

System-level user account management using domain-level user configuration.

## Description

Creates and manages user accounts at the system level (requires sudo). Reads user definitions from `infrastructure.domain.users[]` and handles account creation, SSH key deployment, and password management. User preferences are configured separately by the `configure_user` role.

## Features

- **System account management**: Creates/removes user accounts and home directories
- **SSH key deployment**: Automated authorized_key management with validation
- **Password handling**: Automatic SHA-512 hashing for plaintext passwords
- **User account configuration**: `infrastructure.domain.users[]` for account configuration
- **Integration ready**: Works with `configure_user` role for preference management

## Role Variables

### Infrastructure Domain Users

Users are defined in the unified infrastructure structure at the domain level:

```yaml
infrastructure:
  domain:
    users:
      - name: "alice"                   # Required: username
        comment: "Alice Developer"     # Optional: GECOS field
        groups: [sudo, docker]         # Optional: additional groups
        ssh_pubkey: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5..."  # Optional: SSH public key
        password: "plaintext"          # Optional: auto-hashed if plaintext
        uid: 1001                      # Optional: specific user ID
        home: "/custom/home"           # Optional: custom home directory
        shell: "/bin/bash"             # Optional: default shell
        create_home: true              # Optional: create home directory
        state: present                 # Optional: present (default) or absent

        # User preferences (ignored by this role, used by configure_user)
        git:
          user_name: "Alice Smith"
          user_email: "alice@company.com"
        nodejs:
          packages: [typescript, eslint]
        dotfiles:
          repository: "https://github.com/alice/dotfiles"
          method: stow
        # Only macOS-specific GUI preferences need their own section
        macosx:
          dock:
            tile_size: 48
            autohide: true


    users_absent: []                   # Legacy: usernames to remove
```

**Scope Separation**:
- **This role**: Handles system account fields (name, groups, ssh_pubkey, password, uid, etc.)
- **configure_user role**: Handles preference fields (git, nodejs, Ubuntu/Darwin sections)
## Usage Examples

### Basic Usage
```yaml
- hosts: all
  roles:
    - role: wolskinet.infrastructure.manage_users
  vars:
    infrastructure:
      domain:
        users:
          - name: admin
            comment: "System Administrator"
            groups: [sudo]
            ssh_pubkey: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5..."
            password: "PlaintextPassword123!"  # Will be auto-hashed
```

### Advanced Configuration
```yaml
- hosts: all
  roles:
    - role: wolskinet.infrastructure.manage_users
  vars:
    infrastructure:
      domain:
        users:
          # Service account
          - name: service
            uid: 2001
            group: services
            groups: [docker, systemd-journal]
            shell: /usr/sbin/nologin
            home: /var/lib/service
            system: true
            create_home: true

          # Admin with pre-hashed password
          - name: admin
            comment: "System Admin"
            groups: [sudo, adm]
            password: "$6$rounds=656000$salt$hash..."  # Already hashed
            ssh_pubkey: "ssh-ed25519 AAAAC3..."

          # User account to remove
          - name: olduser
            state: absent
```

### Integration with configure_user

After creating accounts, configure user preferences:

```yaml
- hosts: all
  roles:
    - wolskinet.infrastructure.manage_users     # Create accounts (sudo)

# Configure user preferences (runs as each user)
- hosts: all
  vars:
    target_user: "{{ item }}"
  include_role:
    name: wolskinet.infrastructure.configure_user
  become: true
  become_user: "{{ item }}"
  loop: "{{ infrastructure.domain.users | map(attribute='name') | list }}"
```

## Features

This role provides:

1. **User account configuration**: Configurable user accounts via `infrastructure.domain.users[]`
2. **Password handling**: Auto-hashing of plaintext passwords (SHA-512)
3. **SSH key deployment**: Automated authorized_key management with validation
4. **Account lifecycle**: Creation, modification, and removal
5. **Integration ready**: Works seamlessly with configure_user role

## Platform Support

Works on all platforms supported by `ansible.builtin.user`:
- Ubuntu 22+ / Debian 12+
- Arch Linux
- macOS

Platform-specific group names and user management tools are handled by the underlying module.

## Dependencies

- `ansible.posix` - For authorized_key module

## Testing

```bash
molecule test -s manage_users
```

## See Also

- [ansible.builtin.user module documentation](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/user_module.html)
- [ansible.posix.authorized_key module documentation](https://docs.ansible.com/ansible/latest/collections/ansible/posix/authorized_key_module.html)

## License

MIT

## Author Information

Ed Wolski - wolskinet
