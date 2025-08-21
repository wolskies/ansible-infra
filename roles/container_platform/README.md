# Container Platform Role

This role provides container platform setup and service management capabilities. It uses [geerlingguy.docker](https://github.com/geerlingguy/ansible-role-docker) for Docker installation and focuses on service deployment and management.

## Features

- **Docker Installation**: Uses the battle-tested `geerlingguy.docker` role for Docker and Docker Compose installation
- **Service Registry**: Centralized registry of predefined services (GitLab, Nextcloud, Jellyfin, etc.)
- **Hierarchical Service Management**: Supports global, group, and host-level service configuration
- **Network & Volume Management**: Creates and manages Docker networks and volumes
- **Registry Authentication**: Handles Docker registry login for private repositories
- **Maintenance**: Configures log rotation and system cleanup
- **Discovery Integration**: Works with the discovery role to detect existing Docker services

## Dependencies

- `geerlingguy.docker` - Handles Docker installation and basic configuration
- `wolskinet.infrastructure.basic_setup` - Provides system-level setup (optional)

## Supported Platforms

- Ubuntu 24.04+
- Debian 12+
- Arch Linux
- Red Hat/CentOS (via geerlingguy.docker)

## Usage

### Basic Usage

```yaml
- name: Setup container platform
  hosts: docker_hosts
  roles:
    - name: wolskinet.infrastructure.container_platform
```

### With Service Deployment

```yaml
- name: Setup container platform with services
  hosts: docker_hosts
  vars:
    docker_services_deploy:
      - gitlab
      - nextcloud
    gitlab_hostname: git.example.com
    nextcloud_domain: cloud.example.com
  roles:
    - name: wolskinet.infrastructure.container_platform
```

### Hierarchical Service Configuration

```yaml
# group_vars/production.yml
group_docker_services:
  - nginx_proxy_manager
  - portainer

# host_vars/server01.yml  
host_docker_services:
  - gitlab
  - nextcloud
```

## Service Registry

The role includes a service registry (`vars/services.yml`) that defines available services:

- **GitLab**: Self-hosted Git with CI/CD
- **Nextcloud**: Cloud storage and collaboration
- **Jellyfin**: Media server
- **Paperless**: Document management
- **Nginx Proxy Manager**: Reverse proxy with SSL
- **Portainer**: Docker management interface

Each service includes:
- Role name for deployment
- Required variables
- Default ports and volumes
- Dependencies

## Variables

### Docker Configuration

```yaml
# Passed to geerlingguy.docker
docker_users:
  - "{{ ansible_user }}"

docker_daemon_config:
  log-driver: "json-file"
  log-opts:
    max-size: "10m"
    max-file: "3"
```

### Service Management

```yaml
# Enable/disable features
docker_enable_services: true
docker_log_rotation: true
docker_system_prune: true

# Service deployment
docker_services_deploy: []
global_docker_services: []
group_docker_services: []
host_docker_services: []
```

### Infrastructure

```yaml
# Directory structure
docker_services_dir: "/opt/docker-services"
docker_compose_dir: "{{ docker_services_dir }}/compose"

# Networks and volumes
docker_networks:
  - name: "services"
    driver: "bridge"
docker_volumes: []
```

## Tags

- `docker-setup`: Full container platform setup
- `services`: Service deployment only
- `networks`: Network configuration
- `volumes`: Volume management
- `maintenance`: Cleanup and log rotation

## Examples

See `examples/` directory for complete playbook examples.