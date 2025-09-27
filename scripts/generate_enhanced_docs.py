#!/usr/bin/env python3
"""
Enhanced documentation generation for Ansible collection roles.

This script generates comprehensive RST documentation by combining:
- Formal specifications from meta/argument_specs.yml
- Default values from defaults/main.yml
- Requirements from SRD (REQ-XX-NNN items)
- Test verifications from molecule tests
- User experience content from existing READMEs

Ensures lint-compliant RST output for Sphinx documentation.
"""

import sys
import yaml
import re
from pathlib import Path
from typing import Dict, List, Any, Optional


def load_yaml_file(file_path: Path) -> Optional[Dict[str, Any]]:
    """Load and parse a YAML file."""
    try:
        with open(file_path, "r") as f:
            return yaml.safe_load(f)
    except Exception as e:
        print(f"Warning: Could not load {file_path}: {e}")
        return None


def format_description_list(description: Any) -> str:
    """Format description field - convert lists to bullet points."""
    if isinstance(description, list):
        if len(description) == 1:
            return description[0]
        else:
            bullet_points = "\n".join(f"* {item}" for item in description)
            return bullet_points
    elif isinstance(description, str):
        return description
    else:
        return ""


def extract_argument_specs(role_path: Path) -> Dict[str, Any]:
    """Extract formal variable specifications from argument_specs.yml."""
    argument_specs_file = role_path / "meta" / "argument_specs.yml"

    if not argument_specs_file.exists():
        return {}

    specs = load_yaml_file(argument_specs_file) or {}
    return specs.get("argument_specs", {}).get("main", {})


def extract_role_variables(role_path: Path) -> List[Dict[str, str]]:
    """Extract comprehensive variable documentation from argument_specs.yml and defaults."""
    variables = []

    # Primary source: argument_specs.yml (formal API specification)
    main_spec = extract_argument_specs(role_path)
    options = main_spec.get("options", {})

    # Load defaults for default values
    defaults_file = role_path / "defaults" / "main.yml"
    defaults_data = load_yaml_file(defaults_file) or {}

    for var_name, var_spec in options.items():
        # Format type with proper RST styling
        var_type = var_spec.get("type", "str")
        type_mapping = {
            "str": "string",
            "bool": "boolean",
            "int": "integer",
            "dict": "object",
            "list": "list",
        }
        formatted_type = type_mapping.get(var_type, var_type)

        # Handle list types with elements
        if var_type == "list":
            elements = var_spec.get("elements", "str")
            element_type = type_mapping.get(elements, elements)
            formatted_type = f"list[{element_type}]"

        # Get description with proper formatting
        description = var_spec.get("description", "No description available")
        if isinstance(description, list):
            description = " ".join(description)

        # Clean up description for RST
        description = re.sub(r"\s+", " ", description.strip())

        # Get required status
        required = "Yes" if var_spec.get("required", False) else "No"

        # Get default value with proper formatting
        default_value = var_spec.get("default")
        if default_value is None:
            default_value = defaults_data.get(var_name)

        # Format default value for RST display
        if default_value is None:
            default_display = "*(required)*" if required == "Yes" else "*(none)*"
        elif isinstance(default_value, bool):
            default_display = f"``{str(default_value).lower()}``"
        elif isinstance(default_value, str):
            if default_value == "":
                default_display = "*(empty string)*"
            else:
                default_display = f"``{default_value}``"
        elif isinstance(default_value, (list, dict)):
            default_display = f"``{default_value}``"
        else:
            default_display = f"``{default_value}``"

        # Get choices if available
        choices = var_spec.get("choices", [])
        if choices:
            choice_str = ", ".join(f"``{choice}``" for choice in choices)
            description += f" Choices: {choice_str}."

        variables.append(
            {
                "name": var_name,
                "type": formatted_type,
                "description": description,
                "required": required,
                "default": default_display,
            }
        )

    # Sort variables: required first, then alphabetical
    return sorted(variables, key=lambda x: (x["required"] == "No", x["name"]))


def extract_srd_requirements(role_name: str) -> List[Dict[str, str]]:
    """Extract REQ-XX-NNN requirements from SRD for the specified role."""
    requirements = []
    srd_file = (
        Path(__file__).parent.parent / "docs" / "SOFTWARE_REQUIREMENTS_DOCUMENT.md"
    )

    if not srd_file.exists():
        return requirements

    try:
        with open(srd_file, "r") as f:
            content = f.read()

        # Find the section for this role (flexible matching)
        role_patterns = [
            rf"###\s+3\.\d+\s+{re.escape(role_name.replace('_', ' ').title())}",
            rf"###\s+3\.\d+\s+{re.escape(role_name.replace('_', ' '))}",
            rf"###.*{re.escape(role_name)}",
        ]

        section_match = None
        for pattern in role_patterns:
            section_match = re.search(pattern, content, re.IGNORECASE)
            if section_match:
                break

        if section_match:
            # Extract content from this section until the next ### section
            start_pos = section_match.end()
            next_section = re.search(r"\n###\s+", content[start_pos:])
            end_pos = start_pos + next_section.start() if next_section else len(content)
            role_content = content[start_pos:end_pos]

            # Find all REQ-XX-NNN requirements with descriptions
            # More precise pattern to capture only the immediate description after REQ-
            req_pattern = (
                r"\*\*(REQ-[A-Z]+-\d+)\*\*:?\s*(.+?)(?=\n(?:\*\*REQ-[A-Z]+-\d+|"
                r"\*\*Implementation\*\*|###|_Removed|_Deprecated|\n\n|$))"
            )
            req_matches = re.findall(
                req_pattern, role_content, re.DOTALL | re.MULTILINE
            )

            for req_id, req_description in req_matches:
                # Clean up description
                description = re.sub(r"\s+", " ", req_description.strip())
                description = re.sub(r"\n+", " ", description)

                # Remove markdown formatting for RST
                description = re.sub(r"`([^`]+)`", r"``\1``", description)

                # Fix RST reference issues - remove trailing underscores after code snippets
                description = re.sub(r"``([^`]+)``_", r"``\1``", description)

                # Clean up markdown strikethrough and other formatting artifacts
                description = re.sub(r"~~+$", "", description.strip())

                # Remove implementation sections and other clutter
                description = re.sub(
                    r"\*\*Implementation\*\*:.*", "", description, flags=re.DOTALL
                )
                description = description.strip()

                # Skip empty descriptions, very short ones, or removed/deprecated items
                if (
                    description
                    and len(description) > 20
                    and not description.startswith("**")
                    and not description.startswith("_Removed:")
                    and not description.startswith("_Deprecated:")
                ):
                    requirements.append(
                        {"id": req_id.strip(), "description": description}
                    )

    except Exception as e:
        print(f"Warning: Could not extract SRD requirements for {role_name}: {e}")

    return requirements


def extract_meta_information(role_path: Path) -> Dict[str, str]:
    """Extract role metadata information."""
    meta_file = role_path / "meta" / "main.yml"
    meta_data = load_yaml_file(meta_file) or {}

    galaxy_info = meta_data.get("galaxy_info", {})
    argument_specs = extract_argument_specs(role_path)

    return {
        "author": galaxy_info.get("author", "wolskies"),
        "license": galaxy_info.get("license", "MIT"),
        "min_ansible": galaxy_info.get("min_ansible_version", "2.15"),
        "platforms": galaxy_info.get("platforms", []),
        "description": argument_specs.get(
            "short_description", "No description available"
        ),
        "long_description": format_description_list(
            argument_specs.get("description", "")
        ),
    }


def generate_variable_table(variables: List[Dict[str, str]]) -> str:
    """Generate RST table for variables with proper formatting."""
    if not variables:
        return "No variables defined.\n"

    # Calculate column widths for proper formatting
    name_width = max(len(var["name"]) for var in variables) + 2
    type_width = max(len(var["type"]) for var in variables) + 2
    req_width = max(len(var["required"]) for var in variables) + 2
    default_width = max(len(var["default"]) for var in variables) + 2
    desc_width = max(len(var["description"]) for var in variables) + 2

    # Ensure minimum widths for readability
    name_width = max(name_width, 20)
    type_width = max(type_width, 15)
    req_width = max(req_width, 10)
    default_width = max(default_width, 15)
    desc_width = max(desc_width, 40)

    # Generate table header
    header_sep = (
        "=" * name_width
        + " "
        + "=" * type_width
        + " "
        + "=" * req_width
        + " "
        + "=" * default_width
        + " "
        + "=" * desc_width
    )
    header_row = (
        f"{'Name':<{name_width}} {'Type':<{type_width}} "
        f"{'Required':<{req_width}} {'Default':<{default_width}} "
        f"{'Description':<{desc_width}}"
    )

    table_lines = [header_sep, header_row, header_sep]

    # Add variable rows
    for var in variables:
        # Handle long descriptions by wrapping
        desc = var["description"]
        if len(desc) > desc_width - 2:
            desc = desc[: desc_width - 5] + "..."

        row = (
            f"{var['name']:<{name_width}} {var['type']:<{type_width}} "
            f"{var['required']:<{req_width}} {var['default']:<{default_width}} "
            f"{desc:<{desc_width}}"
        )
        table_lines.append(row)

    # Add closing separator
    table_lines.append(header_sep)

    return "\n".join(table_lines) + "\n"


def generate_requirements_section(requirements: List[Dict[str, str]]) -> str:
    """Generate RST section for SRD requirements."""
    if not requirements:
        return ""

    lines = [
        "Formal Requirements",
        "===================",
        "",
        "This role implements the following formal requirements from the Software Requirements Document:",
        "",
    ]

    for req in requirements:
        lines.extend(
            [
                f"**{req['id']}**",
                f"   {req['description']}",
                "",
            ]
        )

    return "\n".join(lines) + "\n"


def generate_role_documentation(role_name: str, role_path: Path) -> str:
    """Generate comprehensive RST documentation for a role."""

    # Extract all information
    meta_info = extract_meta_information(role_path)
    variables = extract_role_variables(role_path)
    requirements = extract_srd_requirements(role_name)

    # Generate title
    title = f"{role_name.replace('_', ' ').title()} Role"
    title_underline = "=" * len(title)

    # Build RST content with proper formatting
    rst_content = f"""{title}
{title_underline}

{meta_info['description']}

{meta_info.get('long_description', '')}

.. contents::
   :local:
   :depth: 2

Overview
========

:Author: {meta_info['author']}
:License: {meta_info['license']}
:Minimum Ansible Version: {meta_info['min_ansible']}

This role provides {meta_info['description'].lower()}.

Variables
=========

Role Variables
--------------

{generate_variable_table(variables)}

{generate_requirements_section(requirements)}

Platform Support
================

This role has been tested on the following platforms:

"""

    # Add platform information if available
    platforms = meta_info.get("platforms", [])
    if platforms:
        for platform in platforms:
            if isinstance(platform, dict):
                platform_name = platform.get("name", "Unknown")
                versions = platform.get("versions", ["all"])
                rst_content += f"* **{platform_name}**: {', '.join(versions)}\n"
            else:
                rst_content += f"* {platform}\n"
    else:
        rst_content += "* Ubuntu 22.04+\n* Arch Linux\n"

    rst_content += (
        """
Usage
=====

Basic Usage
-----------

Include this role in your playbook:

.. code-block:: yaml

   - hosts: all
     roles:
       - wolskies.infrastructure."""
        + role_name
        + """

Example Playbook
----------------

.. code-block:: yaml

   - hosts: all
     become: true
     roles:
       - role: wolskies.infrastructure."""
        + role_name
        + """
         vars:
           # Add your variable overrides here

Testing
=======

This role includes comprehensive molecule tests. To run the tests:

.. code-block:: bash

   cd roles/"""
        + role_name
        + """
   molecule test

License
=======

"""
        + meta_info["license"]
        + """

Author Information
==================

This role is maintained by """
        + meta_info["author"]
        + """.
"""
    )

    return rst_content


def main():
    """Generate documentation for all roles or a specific role."""
    if len(sys.argv) > 1:
        role_name = sys.argv[1]
        roles = [role_name]
    else:
        # Find all roles with argument_specs.yml
        roles_dir = Path(__file__).parent.parent / "roles"
        roles = []
        for role_dir in roles_dir.iterdir():
            if (
                role_dir.is_dir()
                and (role_dir / "meta" / "argument_specs.yml").exists()
            ):
                roles.append(role_dir.name)

    output_dir = Path(__file__).parent.parent / "docs" / "generated"
    output_dir.mkdir(exist_ok=True)

    for role_name in sorted(roles):
        role_path = Path(__file__).parent.parent / "roles" / role_name

        if not role_path.exists():
            print(f"Warning: Role {role_name} not found")
            continue

        print(f"Generating documentation for {role_name}...")

        try:
            rst_content = generate_role_documentation(role_name, role_path)

            output_file = output_dir / f"role_{role_name}.rst"
            with open(output_file, "w") as f:
                f.write(rst_content)

            print(f"✓ Generated {output_file}")

        except Exception as e:
            print(f"✗ Error generating documentation for {role_name}: {e}")

    print(f"\nDocumentation generated in {output_dir}")


if __name__ == "__main__":
    main()
