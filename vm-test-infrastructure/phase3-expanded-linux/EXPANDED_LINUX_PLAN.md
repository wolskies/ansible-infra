# Phase III: Expanded Linux Validation Matrix

## Infrastructure Architecture

### VM Distribution
- **Local Machine**: 3 Workstation VMs (Arch, Debian 13, Ubuntu 24)
- **Remote Machine** (192.168.100.20): 2 Server VMs (Debian 12, Ubuntu 22)
- **Resources**: 4 CPUs, 8GB RAM per VM

### Configuration Hierarchy

```
all.yml (domain-level)
├── workstations.yml (group-level)
│   ├── arch-workstation (host-level overrides)
│   ├── debian13-workstation (host-level overrides)
│   └── ubuntu24-workstation (host-level overrides)
└── servers.yml (group-level)
    ├── debian12-server (host-level overrides)
    └── ubuntu22-server (host-level overrides)
```

## Test Scenarios

### Domain-Level (all.yml)
- Domain name configuration
- Locale/language settings
- NTP configuration
- Common users across all systems
- Base packages needed everywhere
- System optimization settings

### Group-Level

#### Workstations (workstations.yml)
- Development environments (Node.js, Rust, Go)
- Terminal configurations
- User-focused packages
- No firewall restrictions
- Desktop/development tools
- Liberal sudo access

#### Servers (servers.yml)
- Firewall enabled with specific rules
- Docker repository and packages
- Server-specific packages (nginx, postgresql)
- Restricted user access
- Security hardening
- Service accounts

### Host-Level Overrides
- Additional host-specific packages
- Override testing (e.g., different timezone)
- Architecture-specific configurations

## Version Compatibility Focus

### What We're Testing
- **Ubuntu 22 vs 24**: Changes in package availability, snap defaults, python packages
- **Debian 12 vs 13**: Testing/stable differences, systemd changes
- **NOT testing**: Cross-distro package name differences (user's responsibility)

### User Management Testing
- **Shell testing**: bash vs zsh availability across versions
- **SSH key types**: ed25519, rsa, ecdsa combinations
- **SSH key variations**: Multiple keys, no keys
- **Group membership**: docker group creation, functional groups only
- **Home directory creation**: Cross-version consistency
- **NOTE**: Manual sudo/wheel groups removed - tracked as feature request

### Security
- Firewall rules on servers only
- SSH hardening variations
- Fail2ban on servers

### System Configuration
- Systemd service differences
- Locale/timezone overrides at host level
- Hardware-specific optimizations

## Validation Strategy

1. **Deploy**: Apply hierarchical configuration
2. **Discover**: Run discovery playbook
3. **Validate**: Compare discovery against expected state
4. **Edge Cases**: Verify overrides and group inheritance

## Expected Challenges

1. **Arch Linux** differences:
   - `wheel` group instead of `sudo`
   - Package names (e.g., `python` vs `python3`)
   - AUR helper requirements

2. **Debian 13** (Trixie/Testing):
   - Potential package availability issues
   - Newer systemd behaviors

3. **Ubuntu 24.04**:
   - Snap vs traditional packages
   - New security defaults

4. **Cross-architecture**:
   - Different package managers
   - Service name variations
   - Path differences

## Success Criteria

- All VMs provisioned successfully
- Group configurations applied correctly
- Host overrides work as expected
- Discovery accurately reflects configuration
- Validation passes for all systems
- Edge cases handled gracefully
