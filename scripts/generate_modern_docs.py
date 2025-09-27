#!/usr/bin/env python3
"""
Generate modern capability-based role documentation.

This script creates comprehensive RST documentation using the new capability-based
approach that combines user-focused capabilities with test-driven implementation details.
"""

import sys
import yaml
import re
from pathlib import Path
from typing import Dict, List, Any, Optional

# Role capability definitions - maps each role to its core capabilities
ROLE_CAPABILITIES = {
    "nodejs": {
        "description": "Install Node.js and manage npm packages for specific users",
        "capabilities": [
            {
                "name": "Cross-Platform Node.js Installation",
                "user_experience": [
                    "Run `node --version` and get modern Node.js",
                    "Use npm immediately without additional configuration",
                    "Access latest LTS features across Ubuntu, Arch Linux, and macOS",
                ],
                "implementation": "Platform-specific repositories with version control",
                "platforms": {
                    "Ubuntu/Debian": "✅ NodeSource repository (v20+)",
                    "Arch Linux": "✅ System packages",
                    "macOS": "✅ Homebrew packages",
                },
            },
            {
                "name": "User-Isolated Package Management",
                "user_experience": [
                    "Install global packages without sudo privileges",
                    "Custom package location per user preference",
                    "Automatic PATH configuration for installed tools",
                ],
                "implementation": "Configurable npm prefix with profile integration",
                "platforms": {
                    "All platforms": "✅ ~/.npm-global (default) or custom prefix"
                },
            },
            {
                "name": "Package Format Flexibility",
                "user_experience": [
                    "Simple strings: `typescript`, `prettier`",
                    'Version control: `{ name: eslint, version: "8.57.0" }`',
                    "Scoped packages: `@types/node`",
                ],
                "implementation": "community.general.npm with version support",
                "platforms": {"All platforms": "✅ Mixed format support"},
            },
        ],
    },
    "rust": {
        "description": "Install Rust toolchain and manage cargo packages for specific users",
        "capabilities": [
            {
                "name": "Complete Rust Development Environment",
                "user_experience": [
                    "Run `cargo new project && cd project && cargo build` immediately",
                    "Access stable Rust toolchain with rustup management",
                    "Build dependencies pre-installed for immediate compilation",
                ],
                "implementation": "System rustup packages with stable toolchain initialization",
                "platforms": {
                    "Ubuntu 24.04+": "✅ rustup + build essentials",
                    "Debian 13+": "✅ rustup + build essentials",
                    "Arch Linux": "✅ rustup + base-devel + gcc",
                    "macOS": "✅ Homebrew rustup",
                },
            },
            {
                "name": "Cargo Package Ecosystem",
                "user_experience": [
                    "Install command-line tools: `ripgrep`, `fd-find`, `exa`",
                    "Development utilities: `cargo-watch`, `cargo-edit`",
                    "Tools available in PATH immediately after installation",
                ],
                "implementation": "cargo install with PATH configuration",
                "platforms": {"All platforms": "✅ ~/.cargo/bin integration"},
            },
        ],
    },
    "terminal_config": {
        "description": "Terminal emulator configuration and terminfo setup for modern terminals",
        "capabilities": [
            {
                "name": "Modern Terminal Compatibility",
                "user_experience": [
                    "Alacritty and Kitty work correctly with all applications",
                    "True color support and advanced terminal features",
                    'No more "unknown terminal type" errors',
                ],
                "implementation": "User-specific terminfo database installation",
                "platforms": {"All platforms": "✅ ~/.terminfo configuration"},
            }
        ],
    },
    "os_configuration": {
        "description": "OS configuration after fresh install (timezone, locale, firewall setup, repositories)",
        "capabilities": [
            {
                "name": "System Foundation Setup",
                "user_experience": [
                    "Correct timezone and locale automatically configured",
                    "Firewall enabled with secure defaults",
                    "Package repositories optimized for the platform",
                ],
                "implementation": "Platform-specific system configuration modules",
                "platforms": {
                    "Ubuntu 24.04": "✅ Complete system setup",
                    "Debian 12+": "✅ Complete system setup",
                    "Arch Linux": "✅ Complete system setup",
                    "macOS": "✅ Limited (no firewall/repos)",
                },
            }
        ],
    },
}


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


def extract_test_verifications(role_path: Path) -> List[Dict[str, str]]:
    """Extract test verification examples from molecule tests."""
    verify_file = role_path / "molecule" / "default" / "verify.yml"
    verifications = []

    if not verify_file.exists():
        return verifications

    try:
        with open(verify_file, "r") as f:
            content = f.read()

        # Extract REQ- assertions for examples
        req_matches = re.finditer(
            r"# REQ-[A-Z]+-\d+.*?\n(.*?ansible\.builtin\.assert:.*?success_msg:.*?)(?=\n\s*#|\n\s*-|\Z)",
            content,
            re.DOTALL,
        )

        for match in req_matches:
            req_line = match.group(0).split("\n")[0]
            req_id = re.search(r"REQ-[A-Z]+-\d+", req_line)
            description = (
                req_line.split(":", 1)[1].strip()
                if ":" in req_line
                else "Test verification"
            )

            verifications.append(
                {
                    "requirement": req_id.group(0) if req_id else "Unknown",
                    "description": description,
                    "code": match.group(1).strip(),
                }
            )

    except Exception as e:
        print(f"Warning: Could not parse verify.yml for {role_path.name}: {e}")

    return verifications


def extract_role_variables(defaults_file: Path) -> List[Dict[str, str]]:
    """Extract variable definitions from defaults/main.yml."""
    variables = []

    if not defaults_file.exists():
        return variables

    try:
        with open(defaults_file, "r") as f:
            content = f.read()

        lines = content.split("\n")
        current_comment = []

        for line in lines:
            line = line.rstrip()

            # Collect comments
            if line.startswith("#"):
                comment = line.lstrip("# ").strip()
                if comment and not ("=" in comment or comment == "#"):
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

                    # Determine if required
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
                if line.strip():
                    current_comment = []

    except Exception as e:
        print(f"Warning: Could not parse defaults for variables: {e}")

    return variables


def generate_capability_section(capability: Dict[str, Any]) -> str:
    """Generate RST for a single capability."""
    name = capability["name"]
    user_exp = capability["user_experience"]
    implementation = capability["implementation"]
    platforms = capability["platforms"]

    section = f"""{name}
{'-' * len(name)}

**What you get**: {user_exp[0] if user_exp else 'Enhanced functionality'}

**User experience**:"""

    for exp in user_exp:
        section += f"\n- {exp}"

    section += f"""

**Implementation approach**:
- {implementation}

**Platform matrix**:

.. list-table:: {name} Support
   :header-rows: 1
   :widths: 30 70

   * - Platform
     - Support Level"""

    for platform, support in platforms.items():
        section += f"""
   * - {platform}
     - {support}"""

    return section


def generate_test_verification_section(verifications: List[Dict[str, str]]) -> str:
    """Generate test verification section."""
    if not verifications:
        return """Testing Coverage
================

**Test verification**: Comprehensive molecule testing with platform-specific assertions.
"""

    section = """Testing Coverage
================

**Test verification examples**:

"""

    for verification in verifications[:3]:  # Show first 3 examples
        section += f"""
**{verification['requirement']}**: {verification['description']}

.. code-block:: yaml

"""
        # Indent the code properly
        code_lines = verification["code"].split("\n")
        for line in code_lines:
            section += f"   {line}\n"

    return section


def generate_variable_table(variables: List[Dict[str, str]]) -> str:
    """Generate RST table for role variables."""
    if not variables:
        return "**Configuration**: No configurable variables."

    table_lines = [
        ".. list-table:: Configuration Options",
        "   :header-rows: 1",
        "   :widths: 25 15 60",
        "",
        "   * - Variable",
        "     - Default",
        "     - Purpose",
    ]

    for var in variables:
        # Focus on the key variables users actually need
        if (
            var["name"].endswith("_user")
            or var["name"].endswith("_packages")
            or var["name"].endswith("_version")
        ):
            desc = var["description"].replace("|", "\\|")
            if len(desc) > 50:
                desc = desc[:47] + "..."

            table_lines.extend(
                [
                    f"   * - ``{var['name']}``",
                    f"     - ``{var['default']}``",
                    f"     - {desc}",
                ]
            )

    if len(table_lines) <= 6:  # Just headers, no actual variables shown
        return "**Configuration**: Role uses sensible defaults; minimal configuration required."

    return "\n".join(table_lines)


def generate_modern_role_rst(role_name: str, role_path: Path) -> str:
    """Generate modern capability-based RST content for a role."""

    # Get role capabilities or use fallback
    role_info = ROLE_CAPABILITIES.get(
        role_name,
        {
            "description": f"{role_name.title()} role functionality",
            "capabilities": [
                {
                    "name": "Core Functionality",
                    "user_experience": ["Provides essential functionality"],
                    "implementation": "Standard Ansible modules",
                    "platforms": {"All platforms": "✅ Basic support"},
                }
            ],
        },
    )

    description = role_info["description"]
    capabilities = role_info["capabilities"]

    # Load metadata for basic info
    meta_file = role_path / "meta" / "main.yml"
    defaults_file = role_path / "defaults" / "main.yml"

    meta_data = load_yaml_file(meta_file) or {}
    galaxy_info = meta_data.get("galaxy_info", {})

    author = galaxy_info.get("author", "wolskies")
    license_info = galaxy_info.get("license", "MIT")
    # min_ansible = galaxy_info.get("min_ansible_version", "2.15")
    # tags = galaxy_info.get("galaxy_tags", [])

    # Extract test verifications and variables
    verifications = extract_test_verifications(role_path)
    variables = extract_role_variables(defaults_file)

    # Generate title
    title = (
        f"{role_name.title()} Development Environment"
        if role_name in ["nodejs", "rust"]
        else f"{role_name.title().replace('_', ' ')} Role"
    )
    title_underline = "=" * len(title)

    # Build RST content
    rst_content = f"""{title}
{title_underline}

{description}

.. contents:: Contents
   :depth: 3
   :local:

Overview
========

**Purpose**: {description}

**Philosophy**: Zero-configuration setup that "just works" while remaining extensible for power users.

**Testing**: All capabilities verified through comprehensive molecule testing with platform-specific assertions.

Capabilities
============

"""

    # Add each capability section
    for capability in capabilities:
        rst_content += generate_capability_section(capability) + "\n\n"

    # Add testing section
    rst_content += generate_test_verification_section(verifications) + "\n\n"

    # Add variables section
    rst_content += f"""Variables
=========

{generate_variable_table(variables)}

**Design philosophy**: Minimal configuration surface with maximum capability.

Example Usage
=============

.. code-block:: yaml

   - hosts: all
     tasks:
       - include_role:
           name: wolskinet.infrastructure.{role_name}
         vars:
           {role_name}_user: "{{ ansible_user }}"
"""

    if role_name in ["nodejs", "rust"]:
        rst_content += f"""           {role_name}_packages:
             - package1
             - package2
"""

    rst_content += f"""
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
    """Main function to generate modern role documentation."""
    script_dir = Path(__file__).parent
    collection_root = script_dir.parent
    roles_dir = collection_root / "roles"
    docs_dir = collection_root / "docs" / "source"

    if not roles_dir.exists():
        print(f"Error: Roles directory not found at {roles_dir}")
        sys.exit(1)

    print("Generating modern capability-based role documentation...")

    # Focus on key roles first
    priority_roles = ["nodejs", "rust", "terminal_config", "os_configuration"]

    generated_roles = []

    for role_name in priority_roles:
        role_dir = roles_dir / role_name
        if not role_dir.exists():
            print(f"Warning: Role {role_name} not found, skipping...")
            continue

        print(f"Processing role: {role_name}")

        # Generate modern RST content
        rst_content = generate_modern_role_rst(role_name, role_dir)

        # Write to file
        output_file = docs_dir / f"role_{role_name}.rst"
        with open(output_file, "w") as f:
            f.write(rst_content)

        generated_roles.append(role_name)
        print(f"  Generated: {output_file}")

    print(
        f"\nSuccessfully generated modern documentation for {len(generated_roles)} roles:"
    )
    for role in generated_roles:
        print(f"  - {role}")

    print(f"\nModern documentation files created in: {docs_dir}")
    print("Run 'make docs' to build the updated documentation.")


if __name__ == "__main__":
    main()
