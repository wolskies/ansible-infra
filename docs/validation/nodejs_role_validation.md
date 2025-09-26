# Node.js Role Validation Plan

## Role: `nodejs`

### Purpose
Validate Node.js installation and npm package management with configurable prefix and version support.

### Requirements Coverage
- **REQ-NODE-001**: Node.js installation from NodeSource repositories
- **REQ-NODE-002**: npm package management with version support

### Test Scenarios

#### Scenario 1: Custom npm prefix with versioned packages (ubuntu-nodejs-test)
**Configuration:**
```yaml
node_user: testdev
npm_config_prefix: "~/.local/npm"
npm_config_unsafe_perm: "true"
node_packages:
  - typescript                    # Simple string format
  - name: eslint
    version: "8.57.0"            # Object with version
  - name: "@types/node"
    version: "20.11.0"           # Scoped package with version
```

**Validations:**
- ✓ Node.js v20.x installed from NodeSource
- ✓ Custom npm prefix directory created at ~/.local/npm
- ✓ typescript installed (latest version)
- ✓ eslint installed at exactly 8.57.0
- ✓ @types/node installed at exactly 20.11.0
- ✓ PATH updated in .profile with custom prefix

#### Scenario 2: Default configuration with simple packages (arch-nodejs-test)
**Configuration:**
```yaml
node_user: testdev
# Uses default npm_config_prefix: ~/.npm-global
# Uses default npm_config_unsafe_perm: "true"
node_packages:
  - typescript
  - prettier
  - webpack
```

**Validations:**
- ✓ Node.js installed from Arch repositories
- ✓ Default npm prefix directory created at ~/.npm-global
- ✓ All packages installed with latest versions
- ✓ PATH updated in .profile with default prefix

#### Scenario 3: Edge case - empty packages (ubuntu-nodejs-edge)
**Configuration:**
```yaml
node_user: testdev
node_packages: []
```

**Validations:**
- ✓ Node.js installed but no npm operations performed
- ✓ No npm prefix directory created
- ✓ No PATH modifications to .profile

### Test Execution

```bash
cd roles/nodejs
molecule test
```

### Expected Results

1. **Converge Phase**: All three hosts configure successfully
2. **Idempotence**: Second run reports no changes
3. **Verify Phase**: All assertions pass

### Platform-Specific Behavior

| Platform | Node.js Source | Version Control |
|----------|---------------|-----------------|
| Debian/Ubuntu | NodeSource repository | Controlled by `nodejs_version` |
| Arch Linux | System packages | Latest from Arch repos |
| macOS | Homebrew | Latest from brew |

### Variable Testing Matrix

| Variable | Test Host | Value | Expected Behavior |
|----------|-----------|-------|-------------------|
| `npm_config_prefix` | ubuntu-nodejs-test | `~/.local/npm` | Creates custom directory |
| `npm_config_prefix` | arch-nodejs-test | (default) | Creates ~/.npm-global |
| `npm_config_unsafe_perm` | All | `"true"` | NPM runs with unsafe perms |
| `nodejs_version` | ubuntu-* | `"20"` | Installs v20.x from NodeSource |
| `nodejs_version` | arch-* | (ignored) | Uses system package |

### Package Format Testing

| Format | Example | Test Host | Expected Result |
|--------|---------|-----------|-----------------|
| Simple string | `typescript` | All | Latest version |
| Version object | `{name: eslint, version: "8.57.0"}` | ubuntu-nodejs-test | Exact version |
| Scoped package | `{name: "@types/node", version: "20.11.0"}` | ubuntu-nodejs-test | Exact scoped package |

### Idempotence Checks
- Directory creation tasks report "ok" on second run
- npm install tasks report "ok" when packages already installed
- PATH modification reports "ok" when line already exists

### Manual Verification Commands

```bash
# Check Node.js installation
node --version
npm --version

# Check npm prefix
npm config get prefix

# List global packages with versions
npm list -g --depth=0 --json

# Verify PATH update
grep npm ~/.profile

# Check specific package version
npm list -g eslint --json | jq '.dependencies.eslint.version'
```

### Known Limitations
- Container testing cannot validate macOS-specific behavior
- npm registry availability affects package installation
- Version availability depends on npm registry state
