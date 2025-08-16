# Docker Services Implementation

## Overview

This document describes the Docker services implementation within the `wolskinet.infrastructure` collection, including the service registry pattern, hierarchical variable integration, and deployment workflow.

## Architecture

### Service Registry Pattern

All Docker services are registered in `roles/docker_setup/vars/services.yml` with metadata including:

- **Role**: Dedicated Ansible role for the service
- **Description**: Human-readable service description
- **Category**: Service category (infrastructure, development, productivity, media, etc.)
- **Dependencies**: Other services this service depends on
- **Required Variables**: Variables that must be defined for deployment
- **Optional Features**: Toggle features for the service

### Hierarchical Variable System

Docker services leverage the collection's hierarchical variable system:

```yaml
# Global (all.yml) - Base services for all machines
global_docker_services: []

# Group (servers.yml/workstations.yml) - Role-specific services  
group_docker_services:
  - nginx_proxy_manager
  - portainer

# Host (hostname.yml) - Machine-specific services
host_docker_services:
  - gitlab
  - nextcloud

# Discovered - Services found during infrastructure discovery
discovered_docker_services:
  - jellyfin

# Final merged list (computed automatically)
final_docker_services: [nginx_proxy_manager, portainer, gitlab, nextcloud, jellyfin]
```

## Available Services

### Infrastructure Services 🔧
- **nginx_proxy_manager**: Web-based reverse proxy with SSL management
- **portainer**: Docker management interface

### Development Services 💻
- **gitlab**: Git repository with CI/CD, Container Registry, and Pages

### Productivity Services 📋
- **nextcloud**: Self-hosted cloud storage and collaboration
- **paperless**: Document management with OCR

### Media Services 🎬
- **jellyfin**: Media server for movies, music, and TV

## Service Implementation Pattern

Each Docker service follows this structure:

```
roles/servicename/
├── defaults/main.yml      # Service-specific variables
├── tasks/main.yml         # Service deployment logic
├── templates/
│   ├── docker-compose-servicename.yml.j2
│   ├── servicename.env.j2
│   └── servicename-backup.sh.j2
└── handlers/main.yml      # Service restart/reload handlers
```

### Example Service Variables

```yaml
# In group_vars/servers.yml
group_docker_services:
  - gitlab

# In host_vars/gitlab-server.yml
gitlab_hostname: "gitlab"
gitlab_domain: "example.com"
gitlab_initial_root_password: "{{ vault_gitlab_root_password }}"
gitlab_registry_enabled: true
gitlab_pages_enable: true
```

## Deployment Workflow

### Server Deployment Logic

1. **New Machine Playbook** runs and gathers facts
2. **DevSec Hardening** (unless disabled)
3. **Basic Setup** merges hierarchical variables
4. **Docker Setup** (if `'docker_hosts' in group_names` or `host_enable_docker: true`)
5. **Service Deployment**: For each service in `final_docker_services`:
   - Validate service exists in registry
   - Check required variables are defined
   - Include the service's dedicated role
   - Deploy via Docker Compose
   - Verify deployment health

### Example Inventory Structure

```yaml
# inventory.yml
servers:
  hosts:
    gitlab-server:
      ansible_host: 192.168.1.100
    nextcloud-server:
      ansible_host: 192.168.1.101
      
workstations:
  hosts:
    dev-workstation:
      ansible_host: 192.168.1.200

docker_hosts:
  children:
    servers:
    workstations:
```

## Service Configuration Examples

### GitLab Server Configuration

```yaml
# host_vars/gitlab-server.yml
host_docker_services:
  - gitlab
  - nginx_proxy_manager

gitlab_hostname: "gitlab"
gitlab_domain: "company.com"
gitlab_registry_enabled: true
gitlab_pages_enable: true
gitlab_nginx_proxy: true
gitlab_letsencrypt: true
```

### Development Workstation

```yaml
# host_vars/dev-workstation.yml
host_docker_services:
  - portainer

group_enable_docker: true
group_docker_users:
  - developer
```

## Service Registry Schema

```yaml
service_name:
  role: "wolskinet.infrastructure.service_name"
  description: "Service description"
  category: "infrastructure|development|productivity|media|communication|security"
  dependencies: ["postgres", "redis"]  # Optional
  networks: ["services"]
  ports: ["80:80", "443:443"]
  volumes: ["data:/data", "config:/config"]
  required_vars:
    - service_domain
    - service_admin_password
  optional_features:
    - service_ssl_enabled
    - service_backup_enabled
```

## Testing

### Variable Integration Test

```bash
ansible-playbook test-service-variables.yml
```

This validates:
- ✅ Service registry loading
- ✅ Variable hierarchy merging  
- ✅ Service validation
- ✅ Metadata accessibility

### Deployment Test (Dry Run)

```bash
ansible-playbook -i inventory.yml playbooks/setup-new-machine.yml --check --tags docker --limit gitlab-server
```

## Security Considerations

- All service passwords use vault variables (`vault_service_password`)
- Firewall rules are automatically configured when `service_configure_firewall: true`
- SSL/TLS certificates via Let's Encrypt integration
- Service isolation via Docker networks
- Regular backup scheduling for data services

## Backup Strategy

Each service role includes:
- Automated backup script generation
- Configurable backup scheduling via cron
- Data and configuration backup separation
- Retention policy management

## Extending the System

### Adding a New Service

1. Create service role: `roles/newservice/`
2. Add to service registry: `roles/docker_setup/vars/services.yml`
3. Create Docker Compose template
4. Define required variables in defaults
5. Test with the validation playbook

### Custom Service Configuration

Services can be customized via:
- Host-specific variables (`host_vars/`)
- Group-specific variables (`group_vars/`)
- Service-specific configuration files
- Environment variable overrides

This implementation provides a scalable, maintainable approach to Docker service management with full integration into the collection's hierarchical variable system.