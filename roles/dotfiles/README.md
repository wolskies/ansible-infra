# Dotfiles Role

Automated dotfiles management with conflict resolution using GNU Stow. Handles single-user dotfiles deployment with intelligent backup of existing files and seamless integration with the basic_setup role.

## Quick Start

```yaml
# Standalone usage
- name: Deploy user dotfiles
  include_role:
    name: wolskinet.infrastructure.dotfiles
  vars:
    dotfiles_user: "myuser"
    dotfiles_repository_url: "https://github.com/myuser/dotfiles"
```

**Core Functions:**
- Single-user dotfiles deployment via GNU Stow
- Automatic conflict resolution with backup creation
- Integration with basic_setup role for multi-user scenarios
- Cross-platform support (Linux, macOS)

## Key Features

### 🔧 **Stow-Based Management**
- Uses GNU Stow for clean symlink-based dotfiles deployment
- Supports selective package deployment or full repository deployment
- Maintains clean separation between dotfiles and home directory

### 🛡️ **Conflict Resolution**
Intelligent handling of existing files:
1. **First attempt**: Try normal stow deployment
2. **On conflict**: Backup existing files with `.dotfiles-backup` suffix
3. **Second attempt**: Deploy dotfiles cleanly after backup
4. **Report**: Inform user about backed up files for recovery

### 🔄 **Integration Support**
- **Standalone**: Direct role invocation for single users
- **Basic Setup**: Automatic per-user deployment when `install_dotfiles_support=true`
- **Discovery**: Detects existing dotfiles repositories and configuration

## Configuration Options

### Required Variables
```yaml
dotfiles_user: "username"                    # Target user for deployment
dotfiles_repository_url: "https://github.com/user/dotfiles"  # Dotfiles repo URL
```

### Optional Configuration
```yaml
# Stow deployment settings
dotfiles_uses_stow: true                     # Use GNU Stow (recommended)
dotfiles_stow_packages: []                   # Specific packages ([] = all directories)

# Examples:
dotfiles_stow_packages: []                   # Deploy all directories in repo
dotfiles_stow_packages: ["zsh"]              # Deploy only zsh directory  
dotfiles_stow_packages: ["zsh", "git", "tmux"] # Deploy multiple directories
```

## Repository Structure Requirements

For stow-based deployment, organize your dotfiles repository with package directories:

```
dotfiles-repo/
├── zsh/
│   ├── .zshrc
│   └── .zshenv
├── git/
│   └── .gitconfig
├── tmux/
│   └── .tmux.conf
└── vim/
    └── .vimrc
```

**Deployment Result:**
- `~/.zshrc` → `~/.dotfiles/zsh/.zshrc` (symlink)
- `~/.gitconfig` → `~/.dotfiles/git/.gitconfig` (symlink)
- `~/.tmux.conf` → `~/.dotfiles/tmux/.tmux.conf` (symlink)

## Usage Patterns

### Standalone Single User
```yaml
- name: Deploy personal dotfiles
  hosts: workstation
  tasks:
    - name: Setup dotfiles for main user
      include_role:
        name: wolskinet.infrastructure.dotfiles
      vars:
        dotfiles_user: "developer"
        dotfiles_repository_url: "https://github.com/developer/dotfiles"
        dotfiles_stow_packages: ["zsh", "git", "tmux", "vim"]
```

### Via Basic Setup Integration
```yaml
- name: Multi-user workstation setup
  hosts: workstations
  vars:
    install_dotfiles_support: true           # Enable dotfiles integration
    discovered_users_config:
      - name: user1
        dotfiles_repository_url: "https://github.com/user1/dotfiles"
        dotfiles_uses_stow: true
        dotfiles_stow_packages: ["zsh", "git"]
      - name: user2
        dotfiles_repository_url: "https://github.com/user2/dotfiles"
        dotfiles_uses_stow: true
        # dotfiles_stow_packages: []  # Deploy all directories
  roles:
    - wolskinet.infrastructure.basic_setup
```

### Discovery-Driven Deployment
```yaml
# Discovery automatically detects and configures:
# 1. Run discovery to detect existing dotfiles
ansible-playbook playbooks/run-discovery.yml -l source-host

# 2. Discovery generates discovered_users_config with dotfiles info
# 3. Use discovered config for new machine deployment
ansible-playbook playbooks/source-host_discovered.yml -l target-host
```

## Integration with Other Roles

### Basic Setup Integration
When `install_dotfiles_support=true` in basic_setup:
- Automatically installs stow package (Linux only)
- Calls dotfiles role per-user for users with `dotfiles_repository_url`
- Maps discovery variables to dotfiles role variables
- Handles user creation before dotfiles deployment

### Discovery Integration  
Discovery role populates dotfiles configuration:
```yaml
# Discovery output in host_vars:
discovered_users_config:
  - name: myuser
    dotfiles_repository_url: "https://github.com/myuser/dotfiles"  # Auto-detected
    dotfiles_uses_stow: true                                      # Based on structure
    dotfiles_stow_packages: ["zsh", "git", "tmux"]               # Discovered packages
```

## Platform Support

### Linux (Ubuntu, Debian, Arch)
- Full support with automatic stow installation via basic_setup
- Complete conflict resolution and backup functionality
- Proper file ownership and permissions handling

### macOS
- Supported with manual stow installation requirement
- Users must install stow: `brew install stow`
- Full functionality once stow is available

## Advanced Features

### Conflict Resolution Details
```yaml
# Example conflict scenario:
# Existing: ~/.bashrc (regular file)
# Dotfiles: ~/.dotfiles/bash/.bashrc (to be symlinked)

# Resolution process:
# 1. Backup: ~/.bashrc → ~/.bashrc.dotfiles-backup  
# 2. Deploy: ~/.bashrc → ~/.dotfiles/bash/.bashrc (symlink)
# 3. Report: "Backed up ~/.bashrc to ~/.bashrc.dotfiles-backup"
```

### Selective Package Deployment
```yaml
# Deploy all directories (default)
dotfiles_stow_packages: []

# Deploy only specific configurations
dotfiles_stow_packages: ["shell"]          # Only shell config
dotfiles_stow_packages: ["git", "ssh"]     # Only git and ssh configs
dotfiles_stow_packages: ["zsh", "vim", "tmux", "git"]  # Multiple specific packages
```

### Security Features
- HTTPS-only repository cloning (no SSH key management needed)
- Proper file ownership (files owned by target user)
- Safe git operations (force: false to prevent data loss)
- Backup creation prevents accidental file loss

## Troubleshooting

### Common Issues

**"stow: WARNING! stowing would cause conflicts"**
- **Solution**: Role automatically handles this by backing up conflicting files
- **Recovery**: Original files saved with `.dotfiles-backup` suffix

**Permission denied errors**
- **Check**: Target user exists and has proper home directory permissions
- **Solution**: Ensure user creation happens before dotfiles deployment

**Git clone failures**
- **Check**: Repository URL accessibility and network connectivity
- **Private repos**: Configure Git credentials or use HTTPS with tokens

**"Stow command not found" (macOS)**
- **Solution**: Install stow manually: `brew install stow`
- **Note**: basic_setup doesn't auto-install stow on macOS

### Debug Mode
```yaml
# Enable verbose output for troubleshooting
- name: Deploy dotfiles with debug output
  include_role:
    name: wolskinet.infrastructure.dotfiles
  vars:
    dotfiles_user: "myuser"
    dotfiles_repository_url: "https://github.com/myuser/dotfiles"
    ansible_verbosity: 2
```

### File Recovery
```yaml
# If you need to recover original files:
find ~ -name "*.dotfiles-backup" -type f
# Example recovery:
mv ~/.bashrc.dotfiles-backup ~/.bashrc
```

## Requirements

- **Target User**: Must exist before role execution
- **GNU Stow**: Auto-installed on Linux via basic_setup, manual install required on macOS
- **Git**: For repository cloning (usually installed by basic_setup)
- **Network Access**: HTTPS access to dotfiles repository
- **Permissions**: Write access to target user's home directory

## Dependencies

- **basic_setup** (optional): Provides stow installation and user management
- **discovery** (optional): Provides automatic dotfiles detection and configuration

---

**Integration Notes**: This role works standalone or as part of the basic_setup workflow. For multi-user scenarios, use basic_setup integration. For single-user scenarios, direct role invocation is simpler.