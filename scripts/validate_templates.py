#!/usr/bin/env python3
"""
Validate Jinja2 templates for syntax errors.
This script is used by pre-commit hooks and CI/CD pipelines.
"""

import os
import sys
from pathlib import Path
from jinja2 import Environment, FileSystemLoader, StrictUndefined, TemplateSyntaxError


def validate_template(template_path):
    """Validate a single Jinja2 template."""
    template_dir = os.path.dirname(template_path)
    template_name = os.path.basename(template_path)
    
    try:
        # Create environment with custom filters to simulate Ansible
        env = Environment(
            loader=FileSystemLoader(template_dir),
            undefined=StrictUndefined
        )
        
        # Add dummy Ansible filters to prevent validation errors
        # These just return empty strings but allow syntax validation
        ansible_filters = [
            'basename', 'dirname', 'expanduser', 'realpath',
            'b64decode', 'b64encode', 'from_yaml', 'to_yaml',
            'from_json', 'to_json', 'regex_replace', 'regex_search',
            'dict2items', 'items2dict', 'unique', 'difference',
            'intersect', 'union', 'selectattr', 'rejectattr',
            'map', 'select', 'reject', 'flatten', 'join'
        ]
        
        for filter_name in ansible_filters:
            env.filters[filter_name] = lambda *args, **kwargs: ''
        
        # Parse the template to check for syntax errors
        env.get_template(template_name)
        return True, None
    except TemplateSyntaxError as e:
        return False, f"Syntax error at line {e.lineno}: {e.message}"
    except Exception as e:
        return False, str(e)


def main():
    """Main function to validate all templates passed as arguments."""
    if len(sys.argv) < 2:
        print("Usage: validate_templates.py <template_files...>")
        sys.exit(1)
    
    errors = []
    
    for template_file in sys.argv[1:]:
        if not os.path.exists(template_file):
            errors.append(f"File not found: {template_file}")
            continue
            
        print(f"Validating: {template_file}")
        valid, error = validate_template(template_file)
        
        if valid:
            print(f"  ✓ Valid")
        else:
            print(f"  ✗ Invalid: {error}")
            errors.append(f"{template_file}: {error}")
    
    if errors:
        print("\nValidation failed! Errors found:")
        for error in errors:
            print(f"  - {error}")
        sys.exit(1)
    else:
        print("\nAll templates are valid!")
        sys.exit(0)


if __name__ == "__main__":
    main()