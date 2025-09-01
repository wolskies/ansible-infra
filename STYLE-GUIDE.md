# Collection Style Guide

## Core Principles

### 1. Flow Control via Tags, Not Variables
- ✅ Use tags to control playbook execution flow
- ❌ Avoid variables like `enable_feature: false` for flow control
- Tags provide better user control and debugging

```yaml
# Good - user controls with tags
- name: Install web server
  ansible.builtin.package:
    name: nginx
  tags: webserver

# Bad - variable-based control  
- name: Install web server
  ansible.builtin.package:
    name: nginx
  when: install_webserver | default(true)
```

### 2. Minimal Output - Essential Messages Only
- ✅ Essential status messages only
- ❌ Verbose progress indicators
- ❌ Chatty debug messages
- Output should not scroll out of terminal view

```yaml
# Good - essential information only
- name: Configure firewall rules
  [task content]

# Bad - too chatty
- name: Starting firewall configuration phase
- name: Configuring firewall rules  
- name: Firewall rules configured successfully
```

### 3. Clear Naming Over Comments
- ✅ Self-documenting task names
- ✅ Descriptive variable names  
- ❌ Extensive inline comments
- Code should read like prose

```yaml
# Good - clear naming
- name: Install Docker CE and containerd
  ansible.builtin.package:
    name: [docker-ce, containerd.io]

# Bad - unclear naming requiring comments
- name: Install packages
  ansible.builtin.package:
    name: "{{ docker_packages }}"  # Install Docker and dependencies
```

## Variable Naming

### Hierarchy Prefixes
- `config_common_*` - Cross-platform settings
- `config_linux_*` - Linux-specific settings  
- `config_<os>_*` - OS-specific settings (ubuntu, macos, etc.)
- `manage_*` - Role-specific configuration

### Structure
- Use nested dictionaries for related settings
- Avoid flat variable structures
- Group logically related configuration

```yaml
# Good - grouped configuration
config_macos:
  dock:
    tile_size: 48
    autohide: true
  finder:
    show_extensions: true

# Bad - flat structure
config_macos_dock_tile_size: 48
config_macos_dock_autohide: true
config_macos_finder_show_extensions: true
```

## Task Organization

### Role Structure
- `main.yml` - Orchestration only
- OS-specific files - Complete OS implementation
- Feature-specific files - Focused functionality

### Task Naming
- Action-focused names
- Specific and descriptive
- Avoid generic names like "Configure system"

```yaml
# Good - specific actions
- name: Enable UFW firewall
- name: Add user to docker group
- name: Install Node.js via NodeEnv

# Bad - generic actions  
- name: Configure firewall
- name: Setup user
- name: Install Node
```

## Error Handling

### Minimal Rescue Blocks
- Use rescue only when necessary
- Fail fast with clear messages
- Avoid complex error recovery

```yaml
# Good - simple error handling
- name: Download third-party binary
  ansible.builtin.get_url:
    url: "{{ tool_url }}"
    dest: "{{ tool_path }}"
  register: download_result
  failed_when: download_result.status_code != 200

# Bad - overly complex rescue
- block:
    [complex task]
  rescue:
    - debug: msg="Task failed, attempting recovery"
    - [recovery logic]
    - debug: msg="Recovery completed"
```

## Documentation

### README Structure
1. Purpose (one line)
2. Usage examples
3. Variables (essential only)
4. Tags

### Avoid Over-Documentation
- Focus on usage, not implementation details
- Examples over explanations
- Let code be self-documenting

## Testing

### Tag-Based Testing
- Test individual phases via tags
- Ensure tag combinations work
- Test skip scenarios

```bash
# Test individual components
ansible-playbook site.yml --tags "os-configuration"
ansible-playbook site.yml --tags "users,packages"
ansible-playbook site.yml --skip-tags "third-party"
```

## Anti-Patterns to Avoid

### ❌ Variable-Based Flow Control
```yaml
when: enable_feature | default(true)
```

### ❌ Excessive Debug Messages
```yaml
- debug: msg="Starting phase 1"
- debug: msg="Phase 1 completed successfully"  
```

### ❌ Complex Rescue Blocks
```yaml
rescue:
  - debug: msg="Error occurred"
  - set_fact: recovery_mode=true
  - include_tasks: recovery.yml
```

### ❌ Verbose Comments in Tasks
```yaml
# This task installs Docker CE from the official repository
# and adds the current user to the docker group for access
- name: Install Docker
```

### ❌ Generic Task Names
```yaml
- name: Configure system
- name: Setup environment
- name: Install packages
```

## Collection Standards Summary

1. **Control**: Tags, not variables
2. **Output**: Essential only, not chatty
3. **Naming**: Clear and self-documenting
4. **Structure**: Logical grouping, avoid flat hierarchies
5. **Documentation**: Usage-focused, minimal
6. **Testing**: Tag-based execution paths