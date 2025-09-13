# Docker Compose Generic Role

Deploy Docker Compose services with standardized templates and optional proxy support.

## Features

- Template-based Docker Compose deployment
- Environment variable management
- Proxy/reverse proxy support (Traefik, nginx-proxy, etc.)
- Conditional port exposure
- External network configuration

## Variables

```yaml
# Required
service_name: ""                # Name of the service

# Service configuration
docker_services_root: "/srv/docker"  # Root directory for Docker services
service_enabled: true               # Whether to start the service
service_env_vars: {}               # Environment variables for .env file
compose_file_content: ""           # Custom docker-compose content (overrides default)

# Proxy configuration
service_use_proxy: false           # Enable proxy mode (no direct port exposure)
proxy_network_name: "proxy"       # Name of the external proxy network
proxy_network_external: true      # Whether proxy network is external
service_ports: []                 # Ports to expose (no default ports - must be explicitly defined)
service_labels: {}                # Labels for proxy configuration (e.g., Traefik)
```

## Usage Examples

### Basic Service (Direct Port Exposure)

```yaml
- name: Deploy nginx service
  include_role:
    name: wolskies.infrastructure.docker_compose_generic
  vars:
    service_name: "nginx"
    service_ports:
      - "8080:80"
      - "8443:443"
    service_env_vars:
      NGINX_HOST: "example.com"
```

### Service with Traefik Proxy

```yaml
- name: Deploy service behind Traefik
  include_role:
    name: wolskies.infrastructure.docker_compose_generic
  vars:
    service_name: "webapp"
    service_use_proxy: true
    proxy_network_name: "traefik_proxy"
    proxy_network_external: true
    service_labels:
      traefik.enable: "true"
      traefik.http.routers.webapp.rule: "Host(`webapp.example.com`)"
      traefik.http.routers.webapp.entrypoints: "websecure"
      traefik.http.routers.webapp.tls.certresolver: "letsencrypt"
      traefik.http.services.webapp.loadbalancer.server.port: "3000"
    compose_file_content: |
      image: myapp:latest
      restart: unless-stopped
      environment:
        - NODE_ENV=production
```

### Service with nginx-proxy

```yaml
- name: Deploy service behind nginx-proxy
  include_role:
    name: wolskies.infrastructure.docker_compose_generic
  vars:
    service_name: "blog"
    service_use_proxy: true
    proxy_network_name: "nginx-proxy"
    service_env_vars:
      VIRTUAL_HOST: "blog.example.com"
      LETSENCRYPT_HOST: "blog.example.com"
      LETSENCRYPT_EMAIL: "admin@example.com"
```

### Custom Compose with Conditional Proxy

```yaml
- name: Deploy database service
  include_role:
    name: wolskies.infrastructure.docker_compose_generic
  vars:
    service_name: "postgres"
    service_use_proxy: "{{ use_database_proxy | default(false) }}"
    service_ports: "{{ [] if service_use_proxy else ['5432:5432'] }}"
    compose_file_content: |
      image: postgres:15
      restart: unless-stopped
      volumes:
        - ./data:/var/lib/postgresql/data
      environment:
        - POSTGRES_DB=myapp
        - POSTGRES_USER=myuser
```

## Proxy Network Setup

Before using proxy mode, ensure the external network exists:

```bash
# For Traefik
docker network create traefik_proxy

# For nginx-proxy
docker network create nginx-proxy
```

## Directory Structure

Services are deployed to:
```
{{ docker_services_root }}/
├── {{ service_name }}/
│   ├── docker-compose.yml
│   ├── .env (if service_env_vars is defined)
│   └── data/
```

## Dependencies

- Docker and Docker Compose must be installed (handled by `install_docker` role)
- External proxy network must exist if `service_use_proxy` is true

## Notes

- When `service_use_proxy` is true, ports are not exposed directly
- With proxy mode, the service connects to:
  - **External proxy network** (e.g., `proxy`) - for incoming traffic from reverse proxy
  - **Default network** - Docker's automatic isolated network for the service
- Without proxy mode, Docker automatically creates an isolated network (no configuration needed)
- Labels are only added when using proxy mode
- Environment variables in `.env` are automatically loaded by Docker Compose
