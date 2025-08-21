# Handling Third-Party Packages

This document explains how to handle packages from third-party repositories discovered by the discovery role.

## The Problem

When the discovery role scans a system, it may find packages that came from third-party repositories (like NVIDIA's repository for `nvidia-container-toolkit`). If these packages are included in the standard package list for `basic_setup`, they will fail to install because their repositories haven't been configured yet.

## The Solution

The discovery role automatically separates packages into two categories:

1. **Standard packages**: Available in default OS repositories
2. **Third-party packages**: Require additional repository configuration

## Discovery Output

After running discovery, you'll get host variables like this:

```yaml
# Standard packages (safe for basic_setup)
host_packages_install_Ubuntu:
  - curl
  - git
  - vim

# Third-party packages (require repository setup)
host_packages_third_party_Ubuntu:
  - nvidia-container-toolkit
  - docker-ce

# Repository information
third_party_package_sources:
  nvidia-container-toolkit: "https://nvidia.github.io/libnvidia-container"
  docker-ce: "https://download.docker.com/linux/ubuntu"
```

## Configuration Examples

### Example 1: NVIDIA Container Toolkit

To recreate a system with NVIDIA packages:

```yaml
# host_vars/gpu-server.yml
additional_repositories:
  apt:
    sources:
      - "deb https://nvidia.github.io/libnvidia-container/stable/ubuntu18.04/$(ARCH) /"
    keys:
      - url: "https://nvidia.github.io/libnvidia-container/gpgkey"
        name: "nvidia-container-toolkit"

# After repositories are configured, you can safely install:
host_packages_install_Ubuntu:
  - curl
  - git
  - nvidia-container-toolkit  # Now safe to include
```

### Example 2: Docker CE

```yaml
# group_vars/docker_hosts.yml
additional_repositories:
  apt:
    sources:
      - "deb [arch=amd64] https://download.docker.com/linux/ubuntu {{ ansible_distribution_release }} stable"
    keys:
      - url: "https://download.docker.com/linux/ubuntu/gpg"
        name: "docker-ce"

# Standard packages
group_packages_install_Ubuntu:
  - docker-ce
  - docker-ce-cli
  - containerd.io
```

## Workflow

1. **Run Discovery** on source machine
2. **Review Generated Variables**:
   - Check `host_packages_third_party_*` for packages needing repositories
   - Check `third_party_package_sources` for repository URLs
3. **Configure Repositories**:
   - Add `additional_repositories` configuration
   - Include repository sources and GPG keys
4. **Move Packages**:
   - Move packages from `host_packages_third_party_*` to `host_packages_install_*`
   - Or include them in group/global package lists
5. **Deploy** with confidence

## Best Practices

### Repository Keys (Modern Method)

Use the modern GPG key format:

```yaml
additional_repositories:
  apt:
    keys:
      - url: "https://example.com/repo.gpg"
        name: "example-repo"  # Creates /etc/apt/trusted.gpg.d/example-repo.asc
```

### Gradual Migration

Test third-party packages gradually:

```yaml
# Start with just the repository
additional_repositories:
  apt:
    sources:
      - "deb https://example.com/repo stable main"

# Then add packages one by one
host_packages_install_Ubuntu:
  - example-package-1
  # - example-package-2  # Uncomment after testing
```

### Documentation

Always document why repositories are needed:

```yaml
# NVIDIA GPU support for container workloads
additional_repositories:
  apt:
    sources:
      - "deb https://nvidia.github.io/libnvidia-container/stable/ubuntu$(lsb_release -rs)/$(ARCH) /"
    keys:
      - url: "https://nvidia.github.io/libnvidia-container/gpgkey"
        name: "nvidia-container-toolkit"
```

## Common Third-Party Repositories

### NVIDIA Container Toolkit
```yaml
additional_repositories:
  apt:
    sources:
      - "deb https://nvidia.github.io/libnvidia-container/stable/ubuntu{{ ansible_distribution_version }}/$(ARCH) /"
    keys:
      - url: "https://nvidia.github.io/libnvidia-container/gpgkey"
        name: "nvidia-container-toolkit"
```

### Microsoft (VS Code, Teams, etc.)
```yaml
additional_repositories:
  apt:
    sources:
      - "deb [arch=amd64,arm64,armhf] https://packages.microsoft.com/repos/code stable main"
    keys:
      - url: "https://packages.microsoft.com/keys/microsoft.asc"
        name: "microsoft"
```

### Google Chrome
```yaml
additional_repositories:
  apt:
    sources:
      - "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main"
    keys:
      - url: "https://dl.google.com/linux/linux_signing_key.pub"
        name: "google-chrome"
```

## Troubleshooting

### Repository Not Found
```bash
# Check if repository was added correctly
grep -r "example.com" /etc/apt/sources.list.d/
```

### GPG Key Issues
```bash
# Verify GPG key was installed
ls /etc/apt/trusted.gpg.d/
apt-key list  # Legacy method
```

### Package Not Available
```bash
# Update package cache after adding repositories
apt update
apt-cache search package-name
```

## Integration with Roles

The repository configuration works seamlessly with:

- **basic_setup**: Processes `additional_repositories` before installing packages
- **container_platform**: Can use Docker CE from official repositories
- **discovery**: Automatically detects and categorizes packages by repository

This ensures that discovered configurations can be reliably recreated on new systems.