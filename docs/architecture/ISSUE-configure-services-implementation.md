# Implement Dynamic Service Orchestration with `configure_services`

**Labels**: `enhancement`, `architecture`, `v1.3.1`
**Milestone**: 1.3.1
**Related**: ADR-001 (docs/architecture/ADR-001-dynamic-service-orchestration.md)

## Summary

Implement a new `configure_services` orchestrator role to manage service deployments (GitLab, Docker, Nextcloud, etc.) with a clean separation between orchestration logic and service-specific installation.

This introduces **Phase 3: Services** to our existing **System → Software → Users** pattern.

## Architecture Decision

See [ADR-001: Dynamic Service Orchestration](../architecture/ADR-001-dynamic-service-orchestration.md) for full design rationale.

**Key Concepts**:
- `configure_services` orchestrates service deployment
- `install_*` roles implement service-specific logic
- Service interface contract allows aggregation of firewall rules, reverse proxy config, etc.
- Services declared via `services_group` and `services_host` lists

## Implementation Checklist

### Phase 1: Foundation (Week 1)

- [ ] **Create `configure_services` role structure**
  - [ ] Create `roles/configure_services/` directory
  - [ ] Create `tasks/main.yml` (orchestration flow)
  - [ ] Create `tasks/preflight.yml` (validation)
  - [ ] Create `tasks/deploy-services.yml` (iteration logic)
  - [ ] Create `tasks/aggregate-firewall.yml` (collect firewall rules)
  - [ ] Create `tasks/apply-firewall.yml` (apply to UFW)
  - [ ] Create `tasks/verify-services.yml` (health checks)
  - [ ] Create `defaults/main.yml` (default variables)
  - [ ] Create `meta/main.yml` (role metadata)

- [ ] **Update `system_setup` role**
  - [ ] Add Phase 3 service orchestration to `tasks/main.yml`
  - [ ] Add conditional execution based on `services_group`/`services_host`
  - [ ] Add appropriate tags

- [ ] **Create variable structure**
  - [ ] Update `group_vars/servers.yml` with base config
  - [ ] Create `group_vars/gitlab.yml` with service definitions
  - [ ] Document variable hierarchy

- [ ] **Document service interface contract**
  - [ ] Create `docs/services/service-interface-contract.md`
  - [ ] Document required interface variables
  - [ ] Provide examples

### Phase 2: Certbot Service (Week 1-2)

- [ ] **Create `install_certbot` role**
  - [ ] Create role structure
  - [ ] Implement `tasks/install-certbot.yml` (pip venv setup)
  - [ ] Implement `tasks/install-dns-provider.yml` (certbot-dns-cloudflare)
  - [ ] Implement `tasks/configure-credentials.yml` (Cloudflare API token)
  - [ ] Implement `tasks/generate-certificate.yml` (certbot certonly)
  - [ ] Implement `tasks/setup-renewal.yml` (systemd timer)
  - [ ] Implement `tasks/set-interface-vars.yml` (export interface)
  - [ ] Create templates (credentials, systemd units, renewal hook)
  - [ ] Create `defaults/main.yml` with all variables
  - [ ] Create `meta/main.yml` with role metadata

- [ ] **Test `install_certbot` standalone**
  - [ ] Create molecule scenario
  - [ ] Test with Cloudflare DNS challenge
  - [ ] Verify certificate generation
  - [ ] Verify renewal timer setup
  - [ ] Verify interface variables exported

- [ ] **Document `install_certbot` role**
  - [ ] Create `docs/roles/install_certbot.rst`
  - [ ] Document all variables
  - [ ] Provide usage examples
  - [ ] Document interface variables

### Phase 3: GitLab Service (Week 2)

- [ ] **Create `install_gitlab` role**
  - [ ] Create role structure
  - [ ] Implement `tasks/preflight-checks.yml` (verify certificate exists)
  - [ ] Implement `tasks/configure-repository.yml` (add GitLab repo)
  - [ ] Implement `tasks/install-gitlab.yml` (install gitlab-ee package)
  - [ ] Implement `tasks/configure-gitlab.yml` (template gitlab.rb)
  - [ ] Implement `tasks/reconfigure-gitlab.yml` (gitlab-ctl reconfigure)
  - [ ] Implement `tasks/set-interface-vars.yml` (export firewall rules)
  - [ ] Create `templates/gitlab.rb.j2`
  - [ ] Create `defaults/main.yml` with all variables
  - [ ] Create `meta/main.yml` with role metadata

- [ ] **Test `install_gitlab` standalone**
  - [ ] Create molecule scenario with mock certificate
  - [ ] Test repository configuration
  - [ ] Test package installation
  - [ ] Test configuration templating
  - [ ] Verify interface variables exported

- [ ] **Document `install_gitlab` role**
  - [ ] Create `docs/roles/install_gitlab.rst`
  - [ ] Document all variables
  - [ ] Provide usage examples
  - [ ] Document interface variables

### Phase 4: Integration Testing (Week 2-3)

- [ ] **Create integration playbook**
  - [ ] Create `playbooks/setup-gitlab-server.yml`
  - [ ] Include full flow: OS → Software → Services → Users
  - [ ] Add pre_tasks and post_tasks for validation

- [ ] **Test on Ubuntu 24.04**
  - [ ] Test in VM/container
  - [ ] Verify certbot runs before gitlab
  - [ ] Verify firewall rules aggregated from both services
  - [ ] Verify GitLab accessible with HTTPS
  - [ ] Test certificate renewal
  - [ ] Test GitLab reload after cert renewal

- [ ] **CI/CD Updates**
  - [ ] Update `.gitlab-ci.yml` with new roles
  - [ ] Add molecule tests for `configure_services`
  - [ ] Add molecule tests for `install_certbot`
  - [ ] Add molecule tests for `install_gitlab`
  - [ ] Verify ansible-lint passes

### Phase 5: Documentation & Release (Week 3)

- [ ] **Update collection documentation**
  - [ ] Update `docs/index.rst` with Phase 3: Services
  - [ ] Update `docs/user-guide/index.rst` with service examples
  - [ ] Update `docs/reference/variables-reference.rst`
  - [ ] Add `docs/services/` section with service interface guide
  - [ ] Update `docs/roles/index.rst` with new roles

- [ ] **Release preparation**
  - [ ] Update `CHANGELOG.md` for 1.3.1
  - [ ] Version bump in `galaxy.yml` to 1.3.1
  - [ ] Update ADR-001 status to "Accepted"
  - [ ] Review all documentation for accuracy

- [ ] **Merge and release**
  - [ ] Create PR/MR
  - [ ] Code review
  - [ ] Merge to main
  - [ ] Create release tag v1.3.1
  - [ ] Publish release notes

## Success Criteria

- [ ] `configure_services` role successfully orchestrates multiple services
- [ ] Firewall rules from multiple services are aggregated and applied
- [ ] `install_certbot` generates wildcard certificates via Cloudflare DNS
- [ ] `install_gitlab` installs and configures GitLab EE with external SSL
- [ ] Certificate renewal automatically reloads GitLab
- [ ] All roles have comprehensive documentation
- [ ] All roles have passing molecule tests
- [ ] ansible-lint passes with 0 errors
- [ ] Integration playbook successfully deploys working GitLab server

## Future Enhancements (Post-1.3.1)

- [ ] Add reverse proxy aggregation (Nginx/Traefik configuration)
- [ ] Add monitoring endpoint registration (Prometheus/metrics)
- [ ] Add backup path aggregation
- [ ] Add log aggregation configuration
- [ ] Create `install_docker` service role
- [ ] Create `install_nextcloud` service role
- [ ] Create `install_paperless` service role

## Related

- **Architecture Decision**: `docs/architecture/ADR-001-dynamic-service-orchestration.md`
- **Pattern Documentation**: System → Software → Services → Users
- **Version**: Part of 1.3.1 release
- **Follows**: 1.3.0 major refactor (role renames)
- **Precedes**: 1.3.2 Docker services (planned)

## Notes

This is a significant architectural addition that establishes the pattern for all future service deployments. Take time to get the interface contract right - it will be used by many service roles.

Test thoroughly at each phase before moving to the next. The certbot → gitlab dependency is critical and should be validated extensively.
