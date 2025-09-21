# Feature Test Coverage Matrix - wolskies.infrastructure

## Legend
- ✅ Fully tested
- ⚠️ Partially tested
- ❌ Not tested
- N/A - Not applicable for this platform
- 🚧 Planned for v1.2.0

## Platforms
- **Ubuntu**: 22.04 LTS, 24.04 LTS
- **Debian**: 12 (Bookworm), 13 (Trixie)
- **Arch**: Latest rolling
- **macOS**: 13+ (Ventura, Sonoma)

## Test Environments
- **Molecule**: Container-based unit tests
- **CI**: GitHub Actions automated testing
- **VM-I**: Phase I VM testing (2 VMs)
- **VM-III**: Phase III VM testing (5 VMs)

---

## Role: os_configuration

| Feature | Ubuntu | Debian | Arch | macOS | Molecule | CI | VM-I | VM-III | Notes |
|---------|--------|--------|------|-------|----------|----|----|--------|-------|
| Set hostname | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Skipped in containers |
| Set timezone | ✅ | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | ✅ | ✅ | Limited in containers |
| Set locale | ✅ | ✅ | ✅ | ⚠️ | ✅ | ✅ | ✅ | ✅ | macOS partially |
| Update /etc/hosts | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | |
| **User creation** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Moving to configure_user in v1.2 |
| User groups | ✅ | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | ❌ | ❌ | Docker group issue |
| SSH keys | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | |
| Sudo config | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | Not tested in VMs |
| Remove users | ✅ | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | ❌ | ❌ | Cleanup not fully tested |

**Coverage Gaps**:
- User group dependencies (docker, etc.)
- User removal and cleanup
- Sudo configurations in VM tests

---

## Role: manage_packages

| Feature | Ubuntu | Debian | Arch | macOS | Molecule | CI | VM-I | VM-III | Notes |
|---------|--------|--------|------|-------|----------|----|----|--------|-------|
| Install packages (native) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | |
| Remove packages | ✅ | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | ❌ | ❌ | Limited testing |
| Update cache | ✅ | ✅ | ✅ | N/A | ✅ | ✅ | ✅ | ✅ | |
| Upgrade packages | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | Not tested |
| Hold packages | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not implemented |
| **External repos** | ❌ | ❌ | N/A | N/A | ❌ | ❌ | ❌ | ❌ | v1.2.0 feature |
| AUR packages | N/A | N/A | ⚠️ | N/A | ❌ | ❌ | ❌ | ❌ | Manual only |
| Snap packages | ✅ | ✅ | ⚠️ | N/A | ⚠️ | ⚠️ | ❌ | ❌ | Removal tested |
| Flatpak | ✅ | ✅ | ✅ | N/A | ❌ | ❌ | ❌ | ❌ | Basic support |
| Homebrew | N/A | N/A | N/A | ✅ | ❌ | ❌ | ❌ | ❌ | macOS only |

**Coverage Gaps**:
- Package removal scenarios
- Package upgrades
- External repository management
- Version pinning/holding

---

## Role: manage_security_services

| Feature | Ubuntu | Debian | Arch | macOS | Molecule | CI | VM-I | VM-III | Notes |
|---------|--------|--------|------|-------|----------|----|----|--------|-------|
| UFW firewall | ✅ | ✅ | ⚠️ | N/A | ❌ | ❌ | ✅ | ⚠️ | Arch has issues |
| Firewall rules | ✅ | ✅ | ❌ | N/A | ❌ | ❌ | ✅ | ⚠️ | Arch iptables problem |
| Port ranges | ✅ | ✅ | ❌ | N/A | ❌ | ❌ | ❌ | ❌ | Not tested |
| IPv6 rules | ⚠️ | ⚠️ | ❌ | N/A | ❌ | ❌ | ❌ | ❌ | Basic support |
| fail2ban | ✅ | ✅ | ✅ | N/A | ❌ | ❌ | ✅ | ✅ | |
| Custom jails | ✅ | ✅ | ✅ | N/A | ❌ | ❌ | ❌ | ❌ | Not tested |
| AppArmor | ✅ | ✅ | N/A | N/A | ❌ | ❌ | ❌ | ❌ | Not tested |
| macOS firewall | N/A | N/A | N/A | ⚠️ | ❌ | ❌ | ❌ | ❌ | Basic pf support |

**Coverage Gaps**:
- Firewall testing in containers (not possible)
- IPv6 firewall rules
- Complex firewall scenarios
- Arch Linux firewall issues

---

## Role: configure_user

| Feature | Ubuntu | Debian | Arch | macOS | Molecule | CI | VM-I | VM-III | Notes |
|---------|--------|--------|------|-------|----------|----|----|--------|-------|
| Shell config | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | |
| Git config | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | |
| Dotfiles | ✅ | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | ❌ | ❌ | Basic testing |
| SSH config | ✅ | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | ❌ | ❌ | Limited testing |
| Shell aliases | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | Not tested |
| **User creation** | 🚧 | 🚧 | 🚧 | 🚧 | 🚧 | 🚧 | 🚧 | 🚧 | v1.2.0 addition |
| **Superuser** | 🚧 | 🚧 | 🚧 | 🚧 | 🚧 | 🚧 | 🚧 | 🚧 | v1.2.0 feature |

**Coverage Gaps**:
- Complex dotfile scenarios
- SSH config management
- Shell-specific configurations

---

## Role: nodejs

| Feature | Ubuntu | Debian | Arch | macOS | Molecule | CI | VM-I | VM-III | Notes |
|---------|--------|--------|------|-------|----------|----|----|--------|-------|
| Install Node.js | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | |
| Install via nvm | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | |
| Global packages | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | |
| User packages | ✅ | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | ❌ | ❌ | PATH issues |
| Multiple versions | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ❌ | ❌ | ❌ | ❌ | Not fully tested |

**Coverage Gaps**:
- Multiple Node.js versions
- User-specific npm packages
- npm registry configuration

---

## Role: rust

| Feature | Ubuntu | Debian | Arch | macOS | Molecule | CI | VM-I | VM-III | Notes |
|---------|--------|--------|------|-------|----------|----|----|--------|-------|
| Install Rust | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | |
| Rustup components | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | |
| Cargo packages | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | |
| User installation | ✅ | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | ⚠️ | ⚠️ | PATH issues |
| Multiple toolchains | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not tested |

**Coverage Gaps**:
- Multiple Rust toolchains
- Cross-compilation targets
- Cargo configuration

---

## Role: go

| Feature | Ubuntu | Debian | Arch | macOS | Molecule | CI | VM-I | VM-III | Notes |
|---------|--------|--------|------|-------|----------|----|----|--------|-------|
| Install Go | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | |
| Version selection | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | |
| Go packages | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | |
| GOPATH setup | ✅ | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | ❌ | ❌ | Basic testing |
| Multiple versions | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not supported |

**Coverage Gaps**:
- GOPATH/GOROOT configuration
- Go modules setup
- Multiple Go versions

---

## Role: neovim

| Feature | Ubuntu | Debian | Arch | macOS | Molecule | CI | VM-I | VM-III | Notes |
|---------|--------|--------|------|-------|----------|----|----|--------|-------|
| Install Neovim | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | |
| Plugin managers | ✅ | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | ❌ | ❌ | Basic testing |
| Config deployment | ✅ | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | ❌ | ❌ | Limited testing |
| LSP setup | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ❌ | ❌ | ❌ | ❌ | Manual only |

**Coverage Gaps**:
- Plugin manager installation
- Configuration deployment
- LSP server setup

---

## Role: terminal_config

| Feature | Ubuntu | Debian | Arch | macOS | Molecule | CI | VM-I | VM-III | Notes |
|---------|--------|--------|------|-------|----------|----|----|--------|-------|
| Terminfo compile | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Container limited |
| Alacritty | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | |
| Kitty | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | |
| Wezterm | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | Not tested |
| Config deployment | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ❌ | ❌ | ❌ | ❌ | Limited |

**Coverage Gaps**:
- Terminal configuration files
- Font installation
- Color scheme management

---

## Role: discovery

| Feature | Ubuntu | Debian | Arch | macOS | Molecule | CI | VM-I | VM-III | Notes |
|---------|--------|--------|------|-------|----------|----|----|--------|-------|
| User discovery | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | |
| Package discovery | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | |
| Service discovery | ✅ | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | ✅ | ✅ | |
| Firewall discovery | ✅ | ✅ | ❌ | ⚠️ | ❌ | ❌ | ✅ | ⚠️ | Limited |
| Git config discovery | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | Not in VMs |
| Language discovery | ✅ | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | ✅ | ❌ | PATH issues |

**Coverage Gaps**:
- Complex service configurations
- Firewall discovery on all platforms
- Environment variable discovery

---

## devsec.hardening (External)

| Feature | Ubuntu | Debian | Arch | macOS | Molecule | CI | VM-I | VM-III | Notes |
|---------|--------|--------|------|-------|----------|----|----|--------|-------|
| OS hardening | ✅ | ✅ | ⚠️ | ❌ | ❌ | ❌ | ✅ | ⚠️ | Arch issues |
| SSH hardening | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ | |
| Ctrl-Alt-Del | ✅ | ✅ | ❌ | N/A | ❌ | ❌ | ✅ | ❌ | Arch conflict |

---

## Overall Coverage Summary

### By Testing Environment:
- **Molecule**: ~60% feature coverage (container limitations)
- **CI**: ~55% feature coverage (mirrors molecule)
- **VM-I**: ~40% feature coverage (2 VMs, basic scenarios)
- **VM-III**: ~35% feature coverage (5 VMs, hierarchical focus)

### Critical Gaps:
1. **User group dependencies** - Not tested anywhere properly
2. **Package removal/upgrade** - Limited testing
3. **External repositories** - No testing (v1.2.0)
4. **Firewall on Arch** - Known issues, not resolved
5. **Complex configurations** - Dotfiles, LSP, etc.
6. **Service configurations** - Limited testing
7. **Cleanup/removal** - Users, packages, repos

### By Platform:
- **Ubuntu/Debian**: ~80% coverage
- **Arch**: ~50% coverage (several issues)
- **macOS**: ~30% coverage (limited testing)

---

## Recommendations for v1.2.0

### High Priority Testing Additions:
1. **User group dependency tests** (docker, etc.)
2. **Package lifecycle tests** (install/upgrade/remove)
3. **Repository management tests**
4. **Superuser privilege tests**
5. **Migration scenario tests**

### New Test Scenarios Needed:
```yaml
molecule/test-user-groups/      # Group dependencies
molecule/test-package-lifecycle/ # Install/upgrade/remove
molecule/test-repositories/      # External repos
molecule/test-superuser/         # Privilege handling
molecule/test-cleanup/           # Removal scenarios
vm-test-infrastructure/phase4-lifecycle/  # Full lifecycle
```

### Platform-Specific Focus:
- **Arch**: Resolve firewall issues, test AUR
- **macOS**: Expand coverage significantly
- **Ubuntu 24**: Ensure compatibility
- **Debian 13**: Test preview features

---

## Test Prioritization

### Must Have (P0):
- User creation with package groups
- Superuser privilege handling
- External repository management
- Basic cleanup/removal

### Should Have (P1):
- Package upgrades
- Complex firewall rules
- Service configuration
- Migration testing

### Nice to Have (P2):
- Multiple language versions
- Complex dotfiles
- LSP configurations
- Performance benchmarks
