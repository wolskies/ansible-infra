# configure_users

Configure user preferences and development environments for existing users.

## What It Does

Configures preferences and development environments for **existing users**:
- **Development Environment** - Git, Node.js, Rust, Go, Neovim
- **Platform-Specific** - Dock/Finder preferences (macOS), Homebrew PATH
- **Dotfiles** - Automatic deployment using GNU Stow

**NOTE**: This role does NOT create users, manage SSH keys, or configure sudo access. Use `ansible.builtin.user` for user management.

## Key Features

- **Mass Configuration** - Configure preferences for multiple users in one playbook run
- **Existing Users Only** - Skips configuration if user doesn't exist (no errors)
- **Root User Protection** - Automatically skips root user preferences
- **Development Tools** - Orchestrates language toolchain installation per user

## Usage

### Prerequisites: Create Users First
```yaml
- hosts: all
  become: true
  tasks:
    # Create users with ansible.builtin.user
    - name: Create developer user
      ansible.builtin.user:
        name: developer
        password: "{{ vault_developer_password | password_hash('sha512') }}"
        shell: /bin/bash
        groups: [sudo, docker]
        append: true
        state: present

    - name: Add SSH key for developer
      ansible.posix.authorized_key:
        user: developer
        key: "{{ lookup('file', '~/.ssh/id_ed25519.pub') }}"
        state: present

    - name: Configure passwordless sudo for developer
      ansible.builtin.copy:
        dest: /etc/sudoers.d/developer
        content: "developer ALL=(ALL) NOPASSWD: ALL\n"
        mode: "0440"
        owner: root
        group: root
        validate: "visudo -cf %s"
```

### Basic User Preferences
```yaml
- hosts: all
  become: true
  roles:
    - name: wolskies.infrastructure.configure_users

  vars:
    users:
      - name: developer  # Must already exist
        git:
          user_name: "Developer Name"
          user_email: "developer@company.com"
          editor: "nvim"

      - name: deployment  # Must already exist
        git:
          user_name: "Deploy Bot"
          user_email: "deploy@company.com"
```

### Development Environment Setup
```yaml
users:
  - name: developer  # Must already exist
    git:
      user_name: "Developer Name"
      user_email: "developer@company.com"
      editor: "nvim"
    nodejs:
      packages: [typescript, eslint, prettier]
    rust:
      packages: [ripgrep, bat, fd-find]
    go:
      packages: [github.com/charmbracelet/glow@latest]
    neovim:
      enabled: true
    dotfiles:
      enable: true
      repository: "https://github.com/developer/dotfiles"
      dest: ".dotfiles"
```

### Terminal Configuration
```yaml
users:
  - name: developer
    terminal_entries:
      - alacritty
      - kitty
      - wezterm
```

### macOS Preferences
```yaml
users:
  - name: developer
    Darwin:
      dock:
        tile_size: 48
        autohide: true
        minimize_to_application: true
        show_recents: false
      finder:
        show_extensions: true
        show_hidden: true
        show_pathbar: true
      screenshots:
        directory: "Screenshots"
        format: "png"
```

### Complete Example
```yaml
- hosts: all
  become: true
  tasks:
    # 1. Create user with ansible.builtin.user
    - name: Create developer account
      ansible.builtin.user:
        name: developer
        password: "{{ vault_developer_password | password_hash('sha512') }}"
        shell: /bin/bash
        groups: [sudo, docker]
        append: true
        state: present

    - name: Add SSH keys
      ansible.posix.authorized_key:
        user: developer
        key: "{{ item }}"
        state: present
      loop:
        - "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5... developer@workstation"
        - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQAB... developer@laptop"

    - name: Configure sudo access
      ansible.builtin.copy:
        dest: /etc/sudoers.d/developer
        content: "developer ALL=(ALL) NOPASSWD: ALL\n"
        mode: "0440"
        validate: "visudo -cf %s"

  # 2. Configure user preferences
  roles:
    - name: wolskies.infrastructure.configure_users
      vars:
        users:
          - name: developer
            git:
              user_name: "Developer Name"
              user_email: "developer@company.com"
              editor: "nvim"
            nodejs:
              packages: [typescript, "@angular/cli"]
            rust:
              packages: [ripgrep, fd-find]
            neovim:
              enabled: true
            dotfiles:
              enable: true
              repository: "https://github.com/developer/dotfiles"
```

## Variables

See `defaults/main.yml` for the complete variable structure. Key variables:

- `users` - List of user preference configurations
  - `name` - Username (must already exist)
  - `git` - Git configuration (user_name, user_email, editor)
  - `nodejs` - Node.js packages to install
  - `rust` - Rust packages to install
  - `go` - Go packages to install
  - `neovim` - Neovim configuration
  - `terminal_entries` - Terminal emulators to configure
  - `dotfiles` - Dotfiles deployment settings
  - `Darwin` - macOS-specific preferences

## Role Behavior

- **User Must Exist** - If user doesn't exist, role skips that user (no error)
- **Root User Skipped** - Root user preferences are automatically skipped
- **Idempotent** - Safe to run multiple times
- **Per-User Installation** - Language tools installed to user home directories

## Dependencies

This role orchestrates other collection roles:
- `wolskies.infrastructure.nodejs` - Node.js environment
- `wolskies.infrastructure.rust` - Rust environment
- `wolskies.infrastructure.go` - Go environment
- `wolskies.infrastructure.neovim` - Neovim configuration
- `wolskies.infrastructure.terminal_config` - Terminal configuration

## Example Playbook

```yaml
---
- name: Configure development environment
  hosts: workstations
  become: true

  tasks:
    # Create users with ansible.builtin.user
    - name: Create user accounts
      ansible.builtin.user:
        name: "{{ item.name }}"
        password: "{{ item.password | password_hash('sha512') }}"
        shell: "{{ item.shell | default('/bin/bash') }}"
        groups: "{{ item.groups | default([]) }}"
        append: true
        state: present
      loop:
        - name: alice
          password: "{{ vault_alice_password }}"
          groups: [sudo]
        - name: bob
          password: "{{ vault_bob_password }}"
          groups: [sudo, docker]
      no_log: true

  # Configure user preferences
  roles:
    - role: wolskies.infrastructure.configure_users
      vars:
        users:
          - name: alice
            git:
              user_name: "Alice Developer"
              user_email: "alice@company.com"
            nodejs:
              packages: [typescript, eslint]
            neovim:
              enabled: true

          - name: bob
            git:
              user_name: "Bob Engineer"
              user_email: "bob@company.com"
            rust:
              packages: [ripgrep, bat]
            dotfiles:
              enable: true
              repository: "https://github.com/bob/dotfiles"
```

## License

MIT

## Author Information

Part of the `wolskies.infrastructure` Ansible collection.
