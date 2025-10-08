#!/usr/bin/env python3
"""
Generate collection-level documentation from SRD content.

This script extracts collection-level information from the SRD and creates
comprehensive RST documentation for the overall collection, including:
- Collection overview and purpose
- Platform support matrix
- Variable conventions and standards
- Known limitations and future roadmap
"""

import re
from pathlib import Path


def load_srd_content() -> str:
    """Load the SRD content for processing."""
    srd_file = Path(__file__).parent.parent / "docs" / "archive" / "SOFTWARE_REQUIREMENTS_DOCUMENT.md"

    if not srd_file.exists():
        raise FileNotFoundError(f"SRD not found at {srd_file}")

    with open(srd_file, "r") as f:
        return f.read()


def extract_section_content(content: str, section_title: str, subsection_level: int = 2) -> str:
    """Extract a specific section from markdown content."""
    # Create pattern for section header
    header_pattern = "#" * subsection_level + r"\s+" + re.escape(section_title)

    # Find section start
    section_match = re.search(header_pattern, content, re.IGNORECASE)
    if not section_match:
        return ""

    start_pos = section_match.start()

    # Find next section of same or higher level
    next_header_pattern = r"\n#{1," + str(subsection_level) + r"}\s+"
    # Split string to avoid flake8/black conflict
    content_slice = content[start_pos + 1 :]  # noqa: E203
    next_section = re.search(next_header_pattern, content_slice)

    if next_section:
        end_pos = start_pos + 1 + next_section.start()
        section_content = content[start_pos:end_pos]
    else:
        section_content = content[start_pos:]

    return section_content.strip()


def convert_markdown_table_to_rst(md_table: str) -> str:
    """Convert a markdown table to RST list-table format."""
    lines = [line.strip() for line in md_table.split("\n") if line.strip()]

    if len(lines) < 3:  # Need header, separator, and at least one data row
        return md_table

    # Parse header row
    headers = [cell.strip() for cell in lines[0].split("|") if cell.strip()]

    # Parse data rows (skip separator line)
    data_rows = []
    for line in lines[2:]:
        row = [cell.strip() for cell in line.split("|") if cell.strip()]
        if row:
            data_rows.append(row)

    if not headers or not data_rows:
        return md_table

    # Generate RST list-table
    rst_lines = [
        ".. list-table:: Platform Support Matrix",
        "   :header-rows: 1",
        "   :widths: auto",
        "",
    ]

    # Add header row
    rst_lines.append("   * - " + headers[0])
    for header in headers[1:]:
        rst_lines.append(f"     - {header}")

    # Add data rows
    for row in data_rows:
        rst_lines.append(f"   * - {row[0] if row else ''}")
        for cell in row[1:]:
            rst_lines.append(f"     - {cell}")

    return "\n".join(rst_lines)


def markdown_to_rst(content: str) -> str:
    """Convert markdown content to RST format."""

    def replace_header(match):
        """Replace header with properly sized underline."""
        level = len(match.group(1))
        title = match.group(2)
        if level == 2:
            underline = "=" * len(title)
        elif level == 3:
            underline = "-" * len(title)
        elif level == 4:
            underline = "~" * len(title)
        elif level == 5:
            underline = "^" * len(title)
        else:
            underline = "-" * len(title)
        return f"{title}\n{underline}"

    # Convert headers with proper underline lengths (handle ## through ##### headers)
    content = re.sub(r"^(#{2,5})\s+(.+)$", replace_header, content, flags=re.MULTILINE)

    # Convert markdown code blocks to RST
    content = re.sub(
        r"```(\w+)?\n(.*?)\n```",
        r".. code-block:: \1\n\n\2\n",
        content,
        flags=re.DOTALL,
    )

    # Clean up incomplete code blocks (```yaml without closing ```)
    content = re.sub(r"```\w*\s*$", "", content, flags=re.MULTILINE)

    # Convert bold text
    content = re.sub(r"\*\*([^*]+)\*\*", r"**\1**", content)

    # Convert code spans
    content = re.sub(r"`([^`]+)`", r"``\1``", content)

    # Convert markdown tables to RST
    table_pattern = r"\|[^|]+\|[^|]+\|.*?\n\|[-:|]+\|.*?\n(?:\|[^|]*\|.*?\n)+"
    for table_match in re.finditer(table_pattern, content, re.MULTILINE | re.DOTALL):
        rst_table = convert_markdown_table_to_rst(table_match.group(0))
        content = content.replace(table_match.group(0), rst_table)

    # Clean up multiple newlines
    content = re.sub(r"\n{3,}", "\n\n", content)

    return content.strip()


def generate_collection_overview() -> str:
    """Generate the main collection overview documentation."""
    srd_content = load_srd_content()

    # Extract key sections
    overview_section = extract_section_content(srd_content, "1. Collection Overview")
    requirements_section = extract_section_content(srd_content, "2. Collection-Wide Requirements")

    # Extract known issues and future requirements
    issues_section = extract_section_content(srd_content, "4. Known Issues and Limitations")
    future_section = extract_section_content(srd_content, "5. Future Requirements")

    # Convert to RST
    overview_rst = markdown_to_rst(overview_section) if overview_section else ""
    requirements_rst = markdown_to_rst(requirements_section) if requirements_section else ""
    issues_rst = markdown_to_rst(issues_section) if issues_section else ""
    future_rst = markdown_to_rst(future_section) if future_section else ""

    # Generate the main document
    title = "wolskies.infrastructure Ansible Collection"
    title_underline = "=" * len(title)

    rst_content = f"""{title}
{title_underline}

A comprehensive infrastructure management collection for cross-platform development and production environments.

.. contents:: Contents
   :depth: 3
   :local:

{overview_rst}

{requirements_rst}

Roles Overview
==============

The collection provides the following roles for infrastructure management:

Core System Configuration
--------------------------

* **os_configuration** - Base OS configuration (timezone, locale, firewall, repositories)
* **manage_packages** - Cross-platform package management (APT, Pacman/AUR, Homebrew)
* **manage_security_services** - Security services (UFW, fail2ban, macOS firewall)
* **manage_snap_packages** - Snap package management and removal
* **manage_flatpak** - Flatpak package management

User Environment Setup
-----------------------

* **configure_user** - Complete user account and environment configuration
* **terminal_config** - Modern terminal emulator support (Alacritty, Kitty, WezTerm)

Development Environments
-------------------------

* **nodejs** - Node.js runtime and npm package management
* **rust** - Rust toolchain and cargo package management
* **go** - Go development environment and package management
* **neovim** - Neovim installation and comprehensive configuration

Each role provides comprehensive documentation with formal requirements, platform support matrices, and usage examples.

{issues_rst}

{future_rst}

Getting Started
===============

Installation
------------

Install the collection using ansible-galaxy:

.. code-block:: bash

   ansible-galaxy collection install wolskies.infrastructure

Basic Usage
-----------

Use roles individually in your playbooks:

.. code-block:: yaml

   - hosts: all
     become: true
     roles:
       - wolskies.infrastructure.os_configuration
       - wolskies.infrastructure.manage_packages
       - wolskies.infrastructure.configure_user

Or use the comprehensive configure_system playbook:

.. code-block:: yaml

   - hosts: all
     become: true
     tasks:
       - include_role:
           name: wolskies.infrastructure.configure_system
         vars:
           # Your configuration variables

Platform Support
=================

The collection supports:

* **Ubuntu** 22.04+ and 24.04+
* **Debian** 12+ and 13+
* **Arch Linux** (rolling release)
* **macOS** 13+ (Ventura) on amd64 and arm64

Requirements
------------

* Ansible 2.15+
* Python 3.9+ on control and managed nodes
* OpenSSH 8.0+ for remote management

Testing
=======

The collection includes comprehensive testing with:

* **Molecule** for role-level testing with Docker containers
* **CI/CD pipeline** with parallel testing across platforms
* **Integration tests** for role interactions
* **Platform-specific validation** for OS differences

Run tests locally:

.. code-block:: bash

   # Test individual roles
   cd roles/nodejs && molecule test

   # Test integration
   molecule test -s test-integration

Contributing
============

See the collection repository for contribution guidelines, development setup, and testing procedures.

License
=======

MIT

Author Information
==================

This collection is maintained by the wolskies infrastructure team.
"""

    return rst_content


def main():
    """Generate collection-level documentation."""
    script_dir = Path(__file__).parent
    collection_root = script_dir.parent
    docs_dir = collection_root / "docs" / "generated"

    print("Generating collection-level documentation...")

    try:
        # Generate main collection overview
        rst_content = generate_collection_overview()

        # Write to file
        output_file = docs_dir / "collection_overview.rst"
        with open(output_file, "w") as f:
            f.write(rst_content)

        print(f"✓ Generated {output_file}")

    except Exception as e:
        print(f"✗ Error generating collection documentation: {e}")
        return 1

    print(f"\nCollection documentation generated in {docs_dir}")
    return 0


if __name__ == "__main__":
    exit(main())
