# Install Docker Role

**_ TO BE INCLUDED IN v1.0.3_**
Lightweight Docker installation with NVIDIA GPU detection and Container Toolkit support.

## Features

- Checks if Docker is already installed and enabled
- Uses geerlingguy.docker role for installation if needed
- Automatically detects NVIDIA GPUs and installs Container Toolkit
- Configures Docker daemon with optimal settings
- Adds ansible_user to docker group

## Dependencies

This role requires the geerlingguy.docker role to be installed:

```bash
ansible-galaxy install geerlingguy.docker
```

Or in a requirements.yml:

```yaml
roles:
  - name: geerlingguy.docker
    version: ">=7.0.0"
```

## Variables

```yaml
# Docker installation settings (passed to geerlingguy.docker)
docker_edition: "ce" # Community Edition
docker_install_compose_plugin: true # Use modern compose plugin
docker_install_compose: false # Don't install standalone compose
docker_users: ["{{ ansible_user }}"] # Users to add to docker group
docker_daemon_options: # Docker daemon configuration
  storage-driver: "overlay2"
  log-driver: "json-file"
  log-opts:
    max-size: "100m"
    max-file: "3"
```

## Usage

```yaml
- name: Install Docker with GPU support
  include_role:
    name: wolskies.infrastructure.install_docker
```

## GPU Support

If an NVIDIA GPU is detected, the role will:

- Add NVIDIA Container Toolkit repository
- Install nvidia-container-toolkit package
- Configure Docker to use NVIDIA runtime
- Restart Docker to apply changes

## Notes

- Docker installation is skipped if Docker is already running
- NVIDIA GPU detection only works on Linux systems
- The role uses deb822_repository for modern APT repository management
- Docker daemon is configured with log rotation to prevent disk space issues
