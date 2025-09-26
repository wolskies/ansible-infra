# Neovim Role Validation Plan

## Role: `neovim`

### Purpose
Validate Neovim installation with comprehensive development configuration including plugin manager, LSP setup, and platform-specific language server dependencies.

### Requirements Coverage
- **REQ-NEOVIM-001**: Install Neovim and development dependencies for the specified user
- **REQ-NEOVIM-002**: Deploy comprehensive Neovim configuration with plugin manager and LSP setup
- **REQ-NEOVIM-003**: Create vim compatibility alias for enhanced user experience
- **REQ-INFRA-007**: Maintain Ansible's inherent idempotency

### Test Scenarios

#### Scenario 1: Full setup with configuration (ubuntu-neovim-test)
**Configuration:**
```yaml
neovim_user: testdev
neovim_config_enabled: true
```

**Validations:**
- ✓ Neovim installed via system package (apt neovim)
- ✓ Git dependency installed
- ✓ Configuration directory structure created (~/.config/nvim/)
- ✓ All configuration files deployed (init.lua + plugin files)
- ✓ Lazy.nvim plugin manager installed via git
- ✓ Vim alias script created in ~/.local/bin/vim
- ✓ Local bin directory created with correct permissions

#### Scenario 2: Full setup with enhanced dependencies (arch-neovim-test)
**Configuration:**
```yaml
neovim_user: testdev
neovim_config_enabled: true
```

**Validations:**
- ✓ Neovim installed via system package (pacman neovim)
- ✓ Git dependency installed
- ✓ Language servers installed (lua-language-server, pyright)
- ✓ Configuration directory structure created
- ✓ All configuration files deployed
- ✓ Lazy.nvim plugin manager installed via git
- ✓ Vim alias script created
- ✓ Enhanced LSP capabilities available

#### Scenario 3: Minimal setup without configuration (ubuntu-neovim-minimal)
**Configuration:**
```yaml
neovim_user: testdev
neovim_config_enabled: false
```

**Validations:**
- ✓ Neovim installed via system package
- ✓ Git dependency installed
- ✓ No configuration files deployed
- ✓ No plugin manager installed
- ✓ Vim alias script still created (independent of config)
- ✓ Local bin directory created

### Test Execution

```bash
cd roles/neovim
molecule test
```

### Expected Results

1. **Converge Phase**: All platforms configure successfully
2. **Idempotence**: Second run reports no changes (REQ-INFRA-007)
3. **Verify Phase**: All assertions pass

### Platform-Specific Behavior

| Platform | Neovim Source | Dependencies | Language Servers | Config Deployment |
|----------|---------------|--------------|------------------|-------------------|
| Debian/Ubuntu | `apt install neovim git` | git only | None (packages unavailable) | lua_ls, pyright configured but not functional |
| Arch Linux | `pacman -S neovim git lua-language-server pyright` | git + LSP servers | lua-language-server, pyright | Full LSP functionality |
| macOS | `brew install neovim git lua-language-server pyright` | git + LSP servers | lua-language-server, pyright | Full LSP functionality |

### Variable Testing Matrix

| Variable | Test Host | Value | Expected Behavior |
|----------|-----------|-------|-------------------|
| `neovim_user` | All | `testdev` | Neovim available for testdev user |
| `neovim_config_enabled` | ubuntu/arch-test | `true` | Full configuration deployed |
| `neovim_config_enabled` | ubuntu-minimal | `false` | No configuration deployed |

### Configuration Files Testing

| File | Path | Expected Content |
|------|------|------------------|
| Main config | `~/.config/nvim/init.lua` | Lazy.nvim bootstrap and plugin loader |
| Plugin manager config | `~/.config/nvim/lua/config/lazy.lua` | Lazy.nvim configuration |
| LSP config | `~/.config/nvim/lua/plugins/lsp.lua` | Language server setup (lua_ls, rust_analyzer, pyright) |
| UI plugins | `~/.config/nvim/lua/plugins/ui.lua` | Editor UI enhancements |
| Support plugins | `~/.config/nvim/lua/plugins/support.lua` | Development support tools |
| Configuration plugins | `~/.config/nvim/lua/plugins/configuration.lua` | Editor configuration |
| Vim alias | `~/.local/bin/vim` | Executable script pointing to nvim |

### Idempotence Checks (REQ-INFRA-007)

**Critical idempotency validations**:
- Package installation tasks report "ok" on second run
- Git clone tasks report "ok" when repository already exists
- File creation tasks report "ok" when files already exist with correct content
- Directory creation reports "ok" when directories already exist

**Specific change detection patterns to verify**:
- Git clone of lazy.nvim should use `update: true` with proper change detection
- Configuration file deployment should detect existing files
- Directory creation should be idempotent

### Manual Verification Commands

```bash
# Check Neovim installation
nvim --version
which nvim

# Check vim alias
which vim
~/.local/bin/vim --version

# Check configuration structure
ls -la ~/.config/nvim/
find ~/.config/nvim -name "*.lua"

# Check plugin manager
ls -la ~/.local/share/nvim/lazy/

# Check language server availability (platform-dependent)
# Arch/macOS only:
which lua-language-server
which pyright

# Verify git dependency
git --version
```

### Test Coverage Matrix

| Requirement | Ubuntu 24+ | Arch | macOS | Minimal Config |
|-------------|-------------|------|-------|----------------|
| REQ-NEOVIM-001 | ✓ | ✓ | ✓ | ✓ |
| REQ-NEOVIM-002 | ✓ (partial LSP) | ✓ (full LSP) | ✓ (full LSP) | ✗ (disabled) |
| REQ-NEOVIM-003 | ✓ | ✓ | ✓ | ✓ |
| REQ-INFRA-007 | ✓ | ✓ | ✓ | ✓ |

### Known Limitations
- **Platform LSP Inconsistency**: Ubuntu/Debian lack lua-language-server and pyright packages in system repositories, resulting in configured but non-functional LSP setup
- **Container Testing**: Cannot validate macOS-specific behavior or Homebrew installation
- **Plugin Functionality**: Tests verify plugin manager installation but not plugin loading or functionality
- **LSP Runtime**: Tests verify language server package installation but not runtime functionality
- **Network Dependency**: Git clone of lazy.nvim requires internet access
- **Future Enhancement Opportunity**: Consider alternative installation methods for language servers on Ubuntu/Debian (npm, pip, manual binaries)

### Functional Testing Exclusions
- **No nvim execution**: Tests do not run `nvim` commands to verify functionality
- **No plugin loading**: Tests do not verify that plugins actually load in neovim
- **No LSP functionality**: Tests do not verify that language servers actually provide completions/diagnostics
- **No alias functionality**: Tests verify vim alias exists but do not execute it

This approach focuses on infrastructure validation while leaving functional testing for future enhancement phases.
