# Ansible Role: Firewall

Cross-platform firewall port and service management for the wolskinet.infrastructure collection.

## Description

This role provides centralized firewall management across different operating systems, allowing other roles to easily configure required ports without duplicating firewall logic. It works in conjunction with `basic_setup` which installs and enables the firewall with SSH access.

## Philosophy

- **Separation of concerns**: `basic_setup` installs firewall + SSH, `firewall` role manages additional ports
- **Cross-platform**: Abstracts differences between UFW (Ubuntu/Debian) and firewalld (Arch Linux)
- **Service integration**: Can automatically configure ports based on Docker service registry
- **Handler-driven**: Uses Ansible handlers for efficient firewall reloads

## Supported Platforms

- **Ubuntu 24+**: Uses UFW (Uncomplicated Firewall)
- **Debian 12+**: Uses UFW (Uncomplicated Firewall)  
- **Arch Linux**: Uses firewalld
- **macOS**: Limited support (Application Layer Firewall)

## Prerequisites

This role assumes that a firewall is already installed and enabled. This is typically done by the `basic_setup` role:

```yaml
- hosts: all
  roles:
    - wolskinet.infrastructure.basic_setup  # Installs firewall + SSH
    - wolskinet.infrastructure.firewall     # Manages additional ports
```

## Usage

### Basic Port Configuration

```yaml
- hosts: web_servers
  vars:
    firewall_ports:
      - port: 80
        protocol: tcp
        comment: "HTTP traffic"
      - port: 443
        protocol: tcp
        comment: "HTTPS traffic"
      - port: 3000
        protocol: tcp
        source: "192.168.1.0/24"
        comment: "Internal API"
  roles:
    - wolskinet.infrastructure.firewall
```

### Service-Based Configuration

```yaml
- hosts: web_servers
  vars:
    firewall_services:
      - "http"
      - "https"
      - "ssh"  # Already configured by basic_setup, but safe to include
  roles:
    - wolskinet.infrastructure.firewall
```

### Integration with Docker Services

The role can integrate with the Docker service registry:

```yaml
- hosts: docker_hosts
  vars:
    firewall_ports: "{{ docker_service_ports | default([]) }}"
  roles:
    - wolskinet.infrastructure.container_platform
    - wolskinet.infrastructure.firewall
```

### Role Integration Example

Other roles can use this role as a dependency:

```yaml
# roles/gitlab/meta/main.yml
dependencies:
  - role: wolskinet.infrastructure.firewall
    firewall_ports:
      - port: 80
        protocol: tcp
        comment: "GitLab HTTP"
      - port: 443  
        protocol: tcp
        comment: "GitLab HTTPS"
      - port: 2222
        protocol: tcp
        comment: "GitLab SSH"
    when: gitlab_configure_firewall | default(true)
```

## Variables

### Core Configuration

- `firewall_manage_ports` (default: `true`) - Whether to manage firewall ports
- `firewall_reset_to_defaults` (default: `false`) - Reset firewall before applying rules

### Port Configuration

```yaml
firewall_ports:
  - port: 80                    # Required: Port number
    protocol: tcp               # Optional: tcp/udp (default: tcp)  
    comment: "HTTP traffic"     # Optional: Description
    source: "192.168.1.0/24"    # Optional: Source IP/range
    zone: "public"              # Optional: firewalld zone (Arch only)
```

### Service Configuration

```yaml
firewall_services:
  - "http"      # Standard service names
  - "https"  
  - "ssh"
  - "mysql"
```

### Advanced Options

- `firewall_logging` (default: `false`) - Enable firewall logging
- `firewall_default_policy` (default: `"deny"`) - Default policy for incoming
- `firewall_tool_preference` - Override firewall tool selection per OS

## Examples

### Web Server Configuration

```yaml
- name: Configure web server firewall
  hosts: web_servers
  vars:
    firewall_ports:
      - port: 80
        protocol: tcp
        comment: "HTTP"
      - port: 443
        protocol: tcp  
        comment: "HTTPS"
    firewall_logging: true
  roles:
    - wolskinet.infrastructure.firewall
```

### Database Server (Restricted Access)

```yaml
- name: Configure database firewall
  hosts: db_servers
  vars:
    firewall_ports:
      - port: 3306
        protocol: tcp
        source: "10.0.1.0/24"
        comment: "MySQL from app servers"
      - port: 5432
        protocol: tcp
        source: "10.0.1.0/24" 
        comment: "PostgreSQL from app servers"
  roles:
    - wolskinet.infrastructure.firewall
```

### Docker Host with Multiple Services

```yaml
- name: Configure Docker host firewall
  hosts: docker_hosts
  vars:
    firewall_ports:
      # GitLab
      - { port: 80, protocol: tcp, comment: "GitLab HTTP" }
      - { port: 443, protocol: tcp, comment: "GitLab HTTPS" }
      - { port: 2222, protocol: tcp, comment: "GitLab SSH" }
      # Nextcloud  
      - { port: 8080, protocol: tcp, comment: "Nextcloud" }
      # Monitoring
      - { port: 3000, protocol: tcp, source: "192.168.1.0/24", comment: "Grafana" }
  roles:
    - wolskinet.infrastructure.firewall
```

## Integration with Other Roles

### GitLab Role Integration

```yaml
# In GitLab role tasks
- name: Configure GitLab firewall ports
  ansible.builtin.include_role:
    name: wolskinet.infrastructure.firewall
  vars:
    firewall_ports: "{{ gitlab_firewall_ports }}"
  when: gitlab_configure_firewall | default(false)
```

### Dynamic Port Configuration

```yaml
# Generate ports from service registry
- name: Configure Docker service ports
  ansible.builtin.include_role:
    name: wolskinet.infrastructure.firewall
  vars:
    firewall_ports: >-
      {{
        enabled_docker_services 
        | map('extract', docker_service_registry) 
        | selectattr('ports', 'defined')
        | map(attribute='ports')
        | flatten
        | map('extract_port_config')
        | list
      }}
```

## Handlers

The role provides handlers for firewall reloads:

- `reload ufw` - Reload UFW configuration
- `reload firewalld` - Reload firewalld configuration  
- `restart firewall` - Restart firewall service (cross-platform)

## Tags

- `firewall` - All firewall tasks
- `ports` - Port configuration tasks
- `services` - Service configuration tasks
- `logging` - Logging configuration
- `validation` - Configuration validation
- `summary` - Configuration summary

## Platform-Specific Notes

### Ubuntu/Debian (UFW)
- Uses UFW for simple port management
- Supports named services (http, https, ssh, etc.)
- Automatic rule ordering and conflict resolution

### Arch Linux (firewalld)
- Uses firewalld for zone-based management
- Supports complex rules and zones
- Default zone: public

### macOS (Application Layer Firewall)
- Limited port-based configuration
- Most applications manage their own firewall rules
- Role provides logging configuration only

## Dependencies

- `community.general` collection (for UFW module)
- `ansible.posix` collection (for firewalld module)
- `basic_setup` role (for initial firewall installation)

## License

MIT

## Author Information

Part of the wolskinet.infrastructure Ansible collection for cross-platform infrastructure management.