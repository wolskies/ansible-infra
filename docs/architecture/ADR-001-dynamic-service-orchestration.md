# ADR-001: Dynamic Service Orchestration with `configure_services`

**Status**: Proposed
**Date**: 2025-01-14
**Authors**: Ed Wolski
**Related Issues**: [To be created]

## Context

The collection currently follows a **System → Software → Users** pattern:
- Phase 1: `configure_operating_system` - OS-level settings
- Phase 2: `configure_software` - Package management
- Phase 3: `configure_users` - User preferences and development tools

As infrastructure needs grow, we need to deploy **services** (GitLab, Docker, Nextcloud, etc.) on servers. These services have:
- Service-specific installation logic
- Cross-cutting concerns (firewall rules, reverse proxy, monitoring)
- Dependencies between services (e.g., GitLab needs certificates first)

### Problem Statement

Without a service orchestration layer:
1. **No consistent pattern** for deploying services
2. **Duplicated logic** for firewall rules, reverse proxy config, etc.
3. **Tight coupling** between services and infrastructure concerns
4. **Hard to scale** - adding new services requires playbook changes

### Requirements

1. Maintain consistency with existing `configure_*` orchestrator pattern
2. Support dynamic service lists per group/host
3. Aggregate cross-cutting concerns (firewall, proxy, monitoring)
4. Keep service-specific logic isolated in `install_*` roles
5. Support service dependencies (e.g., certbot before gitlab)

## Decision

We will introduce a **Phase 3: Services** layer with a new `configure_services` orchestrator role.

### Updated Architecture Pattern

**System → Software → Services → Users** (Phase 1-4):
- Phase 1: `configure_operating_system` - OS configuration
- Phase 2: `configure_software` - Package management
- **Phase 3: `configure_services` - Service orchestration** ← NEW
- Phase 4: `configure_users` - User configuration

### Role Responsibilities

#### `configure_services` (Orchestrator)
- Iterate over `services_group` and `services_host` lists
- Call each `install_*` service role
- Aggregate cross-cutting concerns from service interfaces:
  - Firewall rules
  - Reverse proxy configuration (future)
  - Monitoring endpoints (future)
  - Backup paths (future)
- Apply aggregated configurations
- Perform post-deployment validation

#### `install_*` Roles (Workers)
- Service-specific installation and configuration
- Expose interface variables for orchestrator consumption
- Examples: `install_certbot`, `install_gitlab`, `install_docker`

### Service Interface Contract

Each `install_*` role must export these interface variables:

```yaml
# Required
<service_name>_service_name: "string"        # Human-readable name
<service_name>_service_enabled: bool         # Installation success status

# Optional (as needed by service)
<service_name>_firewall_rules:               # Port/protocol requirements
  - rule: allow
    port: 443
    protocol: tcp
    comment: "Service HTTPS"

<service_name>_health_check:                 # Health check definition
  url: "https://example.com/health"
  expected_status: 200
  timeout: 30

# Future interfaces (not yet implemented)
<service_name>_reverse_proxy_config: {}      # Nginx/Traefik config
<service_name>_monitoring_config: {}         # Prometheus/metrics
<service_name>_backup_paths: []              # Paths to backup
<service_name>_log_paths: []                 # Log aggregation
```

### Variable Configuration

Services are declared in group/host variables:

```yaml
# group_vars/gitlab.yml
services_group:
  - install_certbot
  - install_gitlab

# Service-specific configuration
certbot_domains:
  - "*.wolskinet.com"

gitlab_external_url: "https://gitlab.wolskinet.com"
```

### Flow Diagram

```
system_setup
    ↓
configure_operating_system
    ↓
configure_software
    ↓
configure_services
    ├─→ install_certbot (exports: install_certbot_* vars)
    ├─→ install_gitlab (exports: install_gitlab_firewall_rules)
    ├─→ install_docker (exports: install_docker_firewall_rules)
    ↓
    [Aggregate firewall rules from all services]
    ↓
    [Apply aggregated rules to UFW]
    ↓
    [Verify service health]
    ↓
configure_users
```

## Consequences

### Positive

1. **Consistency**: Matches existing `configure_*` orchestrator pattern
2. **Separation of Concerns**: Cross-cutting logic separated from service logic
3. **DRY Principle**: Firewall/proxy/monitoring logic centralized
4. **Scalability**: Easy to add new services (just add to list)
5. **Testability**: Service roles testable independently
6. **Flexibility**: Services declare needs via interface variables
7. **Future-proof**: Easy to extend with new cross-cutting concerns

### Negative

1. **Initial Complexity**: New orchestration layer to understand
2. **Interface Contract**: Service roles must conform to interface
3. **Debugging**: Slightly more indirection between variables and application
4. **Documentation Burden**: Interface contract must be well-documented

### Neutral

1. **Migration Required**: Existing ad-hoc service deployments need refactoring
2. **Convention Over Configuration**: Requires discipline in following patterns
3. **Variable Naming**: Strict naming convention for interface variables

## Implementation Plan

### Phase 1: Foundation
- [ ] Create `configure_services` role structure
- [ ] Implement service iteration logic
- [ ] Implement firewall rule aggregation
- [ ] Update `system_setup` to call `configure_services`
- [ ] Document service interface contract

### Phase 2: Initial Services
- [ ] Create `install_certbot` role with interface
- [ ] Create `install_gitlab` role with interface
- [ ] Test certbot → gitlab dependency flow

### Phase 3: Testing & Documentation
- [ ] Create molecule scenarios for `configure_services`
- [ ] Integration test with certbot + gitlab
- [ ] Document roles in `docs/roles/`
- [ ] Update architecture documentation

### Phase 4: Future Extensions
- [ ] Add reverse proxy aggregation (Nginx/Traefik)
- [ ] Add monitoring endpoint registration
- [ ] Add backup path aggregation
- [ ] Add log aggregation configuration

## Alternatives Considered

### Alternative 1: Service-Specific Playbooks
Each service gets its own playbook that manages everything.

**Rejected because**:
- No code reuse for firewall/proxy logic
- Inconsistent patterns across services
- Doesn't scale with service count

### Alternative 2: Bake Everything into Service Roles
Each `install_*` role manages its own firewall rules directly.

**Rejected because**:
- Duplicated firewall management code
- Hard to aggregate rules (ordering, deduplication)
- Violates separation of concerns

### Alternative 3: Monolithic Service Role
Single `configure_services` role with all service logic inside.

**Rejected because**:
- Violates single responsibility principle
- Hard to test individual services
- Doesn't allow service reuse across playbooks

## References

- [System → Software → Users Pattern](../user-guide/index.rst)
- [Role Naming Conventions](../reference/variables-reference.rst)
- [Architecture Decision Records](https://adr.github.io/)
- Related: Future ADR for reverse proxy aggregation
- Related: Future ADR for monitoring integration

## Status History

- 2025-01-14: Proposed (awaiting implementation)
