#!/usr/bin/env python3
"""
Generate role documentation from Ansible role metadata.

This script extracts information from meta/main.yml and defaults/main.yml
to generate comprehensive RST documentation for each role.
"""

import sys
import yaml
import re
from pathlib import Path
from typing import Dict, List, Any, Optional


def load_yaml_file(file_path: Path) -> Optional[Dict[str, Any]]:
    """Load and parse a YAML file."""
    try:
        if file_path.exists():
            with open(file_path, "r") as f:
                return yaml.safe_load(f)
        return None
    except Exception as e:
        print(f"Warning: Could not load {file_path}: {e}")
        return None


def extract_role_variables(defaults_content: str) -> List[Dict[str, str]]:
    """Extract variable definitions from defaults/main.yml content."""
    variables = []
    lines = defaults_content.split("\n")

    # current_var = None
    current_comment = []

    for line in lines:
        line = line.rstrip()

        # Skip comment headers and separators
        if line.startswith("#") and ("=" in line or line.strip() == "#"):
            continue

        # Collect comments
        if line.startswith("#"):
            comment = line.lstrip("# ").strip()
            if comment:
                current_comment.append(comment)
            continue

        # Variable definition
        if ":" in line and not line.startswith(" ") and not line.startswith("\t"):
            var_match = re.match(r"^([a-zA-Z_][a-zA-Z0-9_]*)\s*:\s*(.*)$", line)
            if var_match:
                var_name = var_match.group(1)
                var_value = var_match.group(2).strip()

                # Determine type from value
                var_type = "string"
                if var_value.lower() in ["true", "false"]:
                    var_type = "boolean"
                elif var_value.startswith("[") or var_value.startswith("[]"):
                    var_type = "list"
                elif var_value.startswith("{") or var_value.startswith("{}"):
                    var_type = "object"
                elif var_value.isdigit():
                    var_type = "integer"

                # Determine if required (empty string or no default usually means required)
                required = var_value in ['""', "''", ""]
                default = var_value if not required else "-"

                description = (
                    " ".join(current_comment)
                    if current_comment
                    else "No description available"
                )

                variables.append(
                    {
                        "name": var_name,
                        "type": var_type,
                        "required": "Yes" if required else "No",
                        "default": default,
                        "description": description,
                    }
                )

                current_comment = []
        else:
            # Reset comment collection if we hit a non-comment, non-variable line
            if line.strip():
                current_comment = []

    return variables


def generate_platform_table(platforms: List[Dict[str, Any]]) -> str:
    """Generate RST table for supported platforms."""
    if not platforms:
        return "No platform information available."

    table_lines = [
        ".. list-table:: Supported Platforms",
        "   :header-rows: 1",
        "   :widths: 30 70",
        "",
        "   * - Platform",
        "     - Versions",
    ]

    for platform in platforms:
        name = platform.get("name", "Unknown")
        versions = platform.get("versions", [])
        version_str = ", ".join(str(v) for v in versions) if versions else "all"

        table_lines.extend([f"   * - {name}", f"     - {version_str}"])

    return "\n".join(table_lines)


def generate_variable_table(variables: List[Dict[str, str]]) -> str:
    """Generate RST table for role variables."""
    if not variables:
        return "No variables defined."

    table_lines = [
        ".. list-table:: Role Variables",
        "   :header-rows: 1",
        "   :widths: 25 15 10 20 30",
        "",
        "   * - Variable",
        "     - Type",
        "     - Required",
        "     - Default",
        "     - Description",
    ]

    for var in variables:
        # Escape special characters and wrap long descriptions
        desc = var["description"].replace("|", "\\|")
        if len(desc) > 50:
            desc = desc[:47] + "..."

        table_lines.extend(
            [
                f"   * - ``{var['name']}``",
                f"     - {var['type']}",
                f"     - {var['required']}",
                f"     - ``{var['default']}``",
                f"     - {desc}",
            ]
        )

    return "\n".join(table_lines)


def generate_role_rst(
    role_name: str, role_path: Path, requirements_content: str = ""
) -> str:
    """Generate RST content for a single role."""

    # Load metadata
    meta_file = role_path / "meta" / "main.yml"
    defaults_file = role_path / "defaults" / "main.yml"

    meta_data = load_yaml_file(meta_file) or {}
    # defaults_data = load_yaml_file(defaults_file) or {}

    galaxy_info = meta_data.get("galaxy_info", {})

    # Extract basic information
    description = galaxy_info.get("description", f"{role_name.title()} role")
    author = galaxy_info.get("author", "wolskies.infrastructure")
    license_info = galaxy_info.get("license", "MIT")
    min_ansible = galaxy_info.get("min_ansible_version", "2.15")
    platforms = galaxy_info.get("platforms", [])
    tags = galaxy_info.get("galaxy_tags", [])
    dependencies = meta_data.get("dependencies", [])

    # Extract variables from defaults file content
    variables = []
    if defaults_file.exists():
        with open(defaults_file, "r") as f:
            defaults_content = f.read()
        variables = extract_role_variables(defaults_content)

    # Generate role title
    title = f"{role_name.title()} Role"
    title_underline = "=" * len(title)

    # Build RST content
    rst_content = f"""{title}
{title_underline}

{description}

.. contents:: Contents
   :depth: 2
   :local:

Overview
========

**Author**: {author}
**License**: {license_info}
**Minimum Ansible Version**: {min_ansible}
**Galaxy Tags**: {', '.join(tags) if tags else 'None'}

{description}

Platform Support
================

{generate_platform_table(platforms)}

Variables
=========

{generate_variable_table(variables)}

Dependencies
============

"""

    if dependencies:
        rst_content += "This role depends on the following roles:\n\n"
        for dep in dependencies:
            if isinstance(dep, str):
                rst_content += f"* ``{dep}``\n"
            elif isinstance(dep, dict):
                role_name = dep.get("role", dep.get("name", "Unknown"))
                rst_content += f"* ``{role_name}``\n"
        rst_content += "\n"
    else:
        rst_content += "This role has no dependencies.\n\n"

    # Add requirements section if provided
    if requirements_content:
        rst_content += (
            """Requirements
============

"""
            + requirements_content
            + "\n\n"
        )

    # Add usage example
    rst_content += f"""Example Playbook
================

.. code-block:: yaml

   - hosts: all
     tasks:
       - include_role:
           name: wolskinet.infrastructure.{role_name}
         vars:
           # Add your variables here

Testing
=======

This role includes comprehensive molecule testing. To run tests:

.. code-block:: bash

   cd roles/{role_name}
   molecule test

The test suite covers:

* Package installation verification
* Configuration deployment validation
* Platform-specific behavior testing
* Idempotency verification

License
=======

{license_info}

Author Information
==================

This role is part of the wolskinet.infrastructure collection.

**Author**: {author}
"""

    return rst_content


def main():
    """Main function to generate all role documentation."""
    script_dir = Path(__file__).parent
    collection_root = script_dir.parent
    roles_dir = collection_root / "roles"
    docs_dir = collection_root / "docs" / "source"

    if not roles_dir.exists():
        print(f"Error: Roles directory not found at {roles_dir}")
        sys.exit(1)

    print("Generating role documentation...")

    # Get all role directories
    role_dirs = [
        d for d in roles_dir.iterdir() if d.is_dir() and not d.name.startswith(".")
    ]

    generated_roles = []

    for role_dir in sorted(role_dirs):
        role_name = role_dir.name

        print(f"Processing role: {role_name}")

        # Check if this role has requirements content from our migration
        requirements_content = ""

        # Generate RST content
        rst_content = generate_role_rst(role_name, role_dir, requirements_content)

        # Write to file
        output_file = docs_dir / f"role_{role_name}.rst"
        with open(output_file, "w") as f:
            f.write(rst_content)

        generated_roles.append(role_name)
        print(f"  Generated: {output_file}")

    print(f"\nSuccessfully generated documentation for {len(generated_roles)} roles:")
    for role in generated_roles:
        print(f"  - {role}")

    print(f"\nDocumentation files created in: {docs_dir}")
    print("Run 'make docs' to build the updated documentation.")


if __name__ == "__main__":
    main()
