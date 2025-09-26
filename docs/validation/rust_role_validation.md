# Rust Role Validation Plan

## Role: `rust`

### Purpose
Validate Rust toolchain installation via rustup system packages and cargo package management with complete automated setup.

### Requirements Coverage
- **REQ-RUST-001**: Install rustup toolchain manager for the specified user to enable Rust development with multiple toolchain versions and cross-compilation capabilities
- **REQ-RUST-002**: Install cargo packages for the specified user
- **REQ-INFRA-007**: Maintain Ansible's inherent idempotency

### Test Scenarios

#### Scenario 1: Full setup with cargo packages (ubuntu-rust-test)
**Configuration:**
```yaml
rust_user: testdev
rust_packages:
  - ripgrep
  - fd-find
  - cargo-watch
```

**Validations:**
- ✓ rustup installed via system package (apt)
- ✓ stable toolchain initialized
- ✓ All cargo packages installed
- ✓ ~/.cargo/bin added to PATH in ~/.profile
- ✓ Rust compiler (rustc) available
- ✓ Cargo available

#### Scenario 2: Full setup with cargo packages (arch-rust-test)
**Configuration:**
```yaml
rust_user: testdev
rust_packages:
  - ripgrep
  - exa
```

**Validations:**
- ✓ rustup and base-devel installed via system package (pacman)
- ✓ stable toolchain initialized
- ✓ All cargo packages installed
- ✓ ~/.cargo/bin added to PATH in ~/.profile
- ✓ Rust compiler (rustc) available
- ✓ Cargo available

#### Scenario 3: Edge case - empty packages (ubuntu-rust-edge)
**Configuration:**
```yaml
rust_user: testdev
rust_packages: []
```

**Validations:**
- ✓ rustup installed via system package
- ✓ stable toolchain initialized
- ✓ No cargo packages installed
- ✓ ~/.cargo/bin added to PATH in ~/.profile
- ✓ Rust development environment ready

#### Scenario 4: Platform validation - unsupported platform
**Configuration:**
Test with mocked older platform (simulated Debian 12)

**Validations:**
- ✓ Role fails with clear error message about platform support
- ✓ No partial installation attempts

### Test Execution

```bash
cd roles/rust
molecule test
```

### Expected Results

1. **Converge Phase**: All supported platforms configure successfully
2. **Idempotence**: Second run reports no changes (REQ-INFRA-007)
3. **Verify Phase**: All assertions pass
4. **Platform Validation**: Unsupported platforms fail gracefully

### Platform-Specific Behavior

| Platform | Rust Source | Packages | Toolchain Init |
|----------|-------------|----------|----------------|
| Debian 13+ | `apt install rustup` | rustup only | `rustup default stable` |
| Ubuntu 24+ | `apt install rustup` | rustup only | `rustup default stable` |
| Arch Linux | `pacman -S rustup base-devel` | rustup + build deps | `rustup default stable` |
| macOS | `brew install rustup` | rustup only | `rustup default stable` |
| Debian 12, Ubuntu 22/23 | **NOT SUPPORTED** | N/A | N/A |

### Variable Testing Matrix

| Variable | Test Host | Value | Expected Behavior |
|----------|-----------|-------|-------------------|
| `rust_user` | All | `testdev` | Toolchain installed for testdev |
| `rust_packages` | ubuntu-rust-test | `[ripgrep, fd-find, cargo-watch]` | All packages installed |
| `rust_packages` | arch-rust-test | `[ripgrep, exa]` | All packages installed |
| `rust_packages` | ubuntu-rust-edge | `[]` | No packages, but toolchain ready |

### Idempotence Checks (REQ-INFRA-007)

**Critical idempotency validations**:
- Package installation tasks report "ok" on second run
- `rustup default stable` reports "ok" when stable already configured
- `cargo install` tasks report "ok" when packages already installed
- PATH modification reports "ok" when line already exists

**Specific change detection patterns to verify**:
- `rustup default stable` should use `changed_when` to detect existing configuration
- `cargo install` should use `changed_when` to detect existing packages

### Manual Verification Commands

```bash
# Check rustup installation
rustup --version
rustup show

# Check toolchain
rustc --version
cargo --version

# Check installed cargo packages
cargo install --list

# Verify PATH update
grep cargo ~/.profile
echo $PATH | grep cargo

# Test compilation
cargo new test_project --bin
cd test_project && cargo build
```

### Platform Support Validation

**Supported Platforms** (should succeed):
- Ubuntu 24.04+
- Debian 13+
- Arch Linux
- macOS

**Unsupported Platforms** (should fail gracefully):
- Ubuntu 22.04/23.04
- Debian 12
- Other distributions without rustup packages

**Error Message Validation**:
- Clear explanation of platform limitation
- Reference to rustup system package requirement
- No partial installation attempts

### Test Coverage Matrix

| Requirement | Ubuntu 24+ | Arch | macOS | Edge Case | Unsupported |
|-------------|-------------|------|-------|-----------|-------------|
| REQ-RUST-001 | ✓ | ✓ | ✓ | ✓ | ✓ (fail) |
| REQ-RUST-002 | ✓ | ✓ | ✓ | ✓ (empty) | N/A |
| REQ-INFRA-007 | ✓ | ✓ | ✓ | ✓ | N/A |

### Known Limitations
- Container testing cannot validate macOS-specific behavior
- Requires internet access for cargo package installation
- Package availability depends on crates.io registry state
- Build dependencies may vary by package (covered by base-devel on Arch)
