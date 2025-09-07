# [ROLE_NAME]

[Brief description of role purpose and primary functionality]

## Description

[More detailed description of what this role accomplishes, its key features, and how it fits into the overall infrastructure collection. Include multi-OS support details.]

## Features

- **🔧 [Feature 1]**: [Description]
- **⚙️ [Feature 2]**: [Description] 
- **🎯 [Feature 3]**: [Description]
- **📱 [Feature 4]**: [Description]

## Role Variables

### Core Configuration

#### `[primary_variable_section]`

[Description of main configuration section]

```yaml
[primary_variable_section]:
  [sub_variable]: [default_value]  # [Description and usage notes]
  [another_sub_variable]:
    [nested_var]: [default]        # [Purpose and constraints]
```

### Platform-Specific Variables

#### Linux-Specific

```yaml
[linux_section]:
  [linux_var]: [default]          # [Linux-specific behavior]
```

#### macOS-Specific

```yaml
[macos_section]:
  [macos_var]: [default]          # [macOS-specific behavior]
```

### Variable Reference

#### Required Variables
- `[var_name]` - [Type] - [Description and constraints]

#### Optional Variables
- `[var_name]` - [Type] - [Description, default value, and usage notes]

#### Advanced Configuration
- `[advanced_var]` - [Type] - [Complex usage scenarios]

## Usage Examples

### Basic Configuration
```yaml
- hosts: all
  roles:
    - role: wolskinet.infrastructure.[ROLE_NAME]
      vars:
        [basic_config_example]
```

### Advanced Configuration
```yaml
- hosts: servers
  roles:
    - role: wolskinet.infrastructure.[ROLE_NAME]
      vars:
        [advanced_config_example]
```

### Platform-Specific Usage
```yaml
# Ubuntu/Debian specific
- hosts: debian_family
  roles:
    - role: wolskinet.infrastructure.[ROLE_NAME]
      vars:
        [debian_specific_example]

# macOS specific
- hosts: macos_hosts
  roles:
    - role: wolskinet.infrastructure.[ROLE_NAME]
      vars:
        [macos_specific_example]
```

## Platform Support

### Ubuntu 22+ / Debian 12+
- **[Feature]**: [Implementation details]
- **[Feature]**: [Specific behavior]

### Arch Linux
- **[Feature]**: [Implementation details]
- **[Feature]**: [Arch-specific notes]

### macOS
- **[Feature]**: [Implementation details]
- **[Feature]**: [macOS-specific considerations]

## Integration Examples

### With Other Roles
```yaml
- hosts: infrastructure
  roles:
    - wolskinet.infrastructure.[DEPENDENCY_ROLE]
    - wolskinet.infrastructure.[ROLE_NAME]
    - wolskinet.infrastructure.[FOLLOW_UP_ROLE]
```

### Discovery Integration
[If applicable, describe how the role works with the discovery role]

```yaml
- hosts: discovered_systems
  roles:
    - wolskinet.infrastructure.discovery  # [What it discovers for this role]
    - wolskinet.infrastructure.[ROLE_NAME]  # [How it uses discovered data]
```

## Dependencies

[List Ansible dependencies - collections, modules, or other roles required]

- `[dependency_collection]` - [Version requirement and purpose]
- `[ansible_module]` - [Usage context]

## Tags

Available tags for selective execution:

- `[tag_name]` - [What this tag controls]
- `[tag_name]` - [Specific functionality]

## Testing

This role includes comprehensive molecule tests:

```bash
# Test this role specifically
molecule test -s [ROLE_NAME]

# Quick validation
molecule converge -s [ROLE_NAME]
molecule verify -s [ROLE_NAME]
```

## License

MIT

## Author Information

Ed Wolski - wolskinet