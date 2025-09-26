# Go Role Validation Plan

## Role: `go`

### Purpose
Validate Go development toolchain installation via system packages and go package management with complete automated setup.

### Requirements Coverage
- **REQ-GO-001**: Install Go development toolchain including compiler, built-in tools (go fmt, go test, go build), and package management capabilities for the specified user
- **REQ-GO-002**: Install go packages for the specified user
- **REQ-INFRA-007**: Maintain Ansible's inherent idempotency

### Test Scenarios

#### Scenario 1: Full setup with go packages (ubuntu-go-test)
**Configuration:**
```yaml
go_user: testdev
go_packages:
  - github.com/goreleaser/goreleaser@latest
  - golang.org/x/tools/cmd/goimports
  - github.com/golangci/golangci-lint/cmd/golangci-lint@v1.54.2
```

**Validations:**
- ✓ Go installed via system package (apt golang)
- ✓ All go packages installed
- ✓ ~/go/bin added to PATH in ~/.profile
- ✓ Go compiler (go) available
- ✓ Built-in tools (go fmt, go test, go build) available
- ✓ Package management (go install, go mod) functional

#### Scenario 2: Full setup with go packages (arch-go-test)
**Configuration:**
```yaml
go_user: testdev
go_packages:
  - github.com/spf13/cobra-cli@latest
  - golang.org/x/tools/cmd/godoc
```

**Validations:**
- ✓ Go installed via system package (pacman go)
- ✓ All go packages installed
- ✓ ~/go/bin added to PATH in ~/.profile
- ✓ Go compiler (go) available
- ✓ Built-in tools (go fmt, go test, go build) available
- ✓ Package management (go install, go mod) functional

#### Scenario 3: Edge case - empty packages (ubuntu-go-edge)
**Configuration:**
```yaml
go_user: testdev
go_packages: []
```

**Validations:**
- ✓ Go installed via system package
- ✓ No go packages installed
- ✓ ~/go/bin added to PATH in ~/.profile
- ✓ Go development environment ready
- ✓ Built-in tools available

### Test Execution

```bash
cd roles/go
molecule test
```

### Expected Results

1. **Converge Phase**: All platforms configure successfully
2. **Idempotence**: Second run reports no changes (REQ-INFRA-007)
3. **Verify Phase**: All assertions pass

### Platform-Specific Behavior

| Platform | Go Source | Package Name | Built-in Tools |
|----------|-----------|--------------|----------------|
| Debian/Ubuntu | `apt install golang` | golang | Complete toolchain |
| Arch Linux | `pacman -S go` | go | Complete toolchain |
| macOS | `brew install go` | go | Complete toolchain |

### Variable Testing Matrix

| Variable | Test Host | Value | Expected Behavior |
|----------|-----------|-------|-------------------|
| `go_user` | All | `testdev` | Toolchain available for testdev |
| `go_packages` | ubuntu-go-test | `[goreleaser, goimports, golangci-lint@v1.54.2]` | All packages installed |
| `go_packages` | arch-go-test | `[cobra-cli@latest, godoc]` | All packages installed |
| `go_packages` | ubuntu-go-edge | `[]` | No packages, but toolchain ready |

### Package Format Testing

| Format | Example | Expected Result |
|--------|---------|-----------------|
| Simple package | `golang.org/x/tools/cmd/goimports` | Latest version installed |
| Versioned package | `github.com/golangci/golangci-lint/cmd/golangci-lint@v1.54.2` | Specific version |
| Latest explicit | `github.com/goreleaser/goreleaser@latest` | Latest version |

### Idempotence Checks (REQ-INFRA-007)

**Critical idempotency validations**:
- Package installation tasks report "ok" on second run
- `go install` tasks report "ok" when packages already installed
- PATH modification reports "ok" when line already exists

**Specific change detection patterns to verify**:
- `go install` should use `changed_when` to detect existing packages

### Manual Verification Commands

```bash
# Check Go installation
go version
go env GOPATH
go env GOROOT

# Check built-in tools
go fmt --help
go test --help
go build --help
go mod --help

# Check installed packages
ls ~/go/bin/
go list -m all

# Verify PATH update
grep go ~/.profile
echo $PATH | grep go

# Test development environment
mkdir test_project && cd test_project
go mod init test
echo 'package main; import "fmt"; func main() { fmt.Println("Hello Go!") }' > main.go
go run main.go
go build main.go
```

### Functional Testing Matrix

| Capability | Test Command | Expected Result |
|------------|--------------|-----------------|
| Compiler | `go build main.go` | Successful compilation |
| Test runner | `go test ./...` | Test execution |
| Formatter | `go fmt main.go` | Code formatting |
| Module system | `go mod init test` | Module initialization |
| Package installer | `go install golang.org/x/tools/cmd/goimports@latest` | Tool installation |

### Test Coverage Matrix

| Requirement | Ubuntu 22+ | Arch | macOS | Edge Case |
|-------------|-------------|------|-------|-----------|
| REQ-GO-001 | ✓ | ✓ | ✓ | ✓ |
| REQ-GO-002 | ✓ | ✓ | ✓ | ✓ (empty) |
| REQ-INFRA-007 | ✓ | ✓ | ✓ | ✓ |

### Known Limitations
- Container testing cannot validate macOS-specific behavior
- Requires internet access for go package installation
- Package availability depends on Go module proxy and source repositories
- Some packages may have build dependencies not covered by base Go installation
