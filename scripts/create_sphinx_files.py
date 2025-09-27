#!/usr/bin/env python3
"""
Create Sphinx configuration files for GitLab Pages documentation.
"""

import json
import os
from datetime import datetime
from pathlib import Path


def create_index_rst(output_dir: Path):
    """Create index.rst for Sphinx documentation."""
    index_content = """wolskies.infrastructure Collection Documentation
===============================================

.. toctree::
   :maxdepth: 2
   :caption: Contents:

   collection_overview
   role_configure_user
   role_go
   role_manage_flatpak
   role_manage_packages
   role_manage_security_services
   role_manage_snap_packages
   role_neovim
   role_nodejs
   role_os_configuration
   role_rust
   role_terminal_config

Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
"""

    with open(output_dir / "index.rst", "w") as f:
        f.write(index_content)


def create_conf_py(output_dir: Path):
    """Create conf.py for Sphinx documentation."""
    conf_content = """project = 'wolskies.infrastructure'
copyright = '2025, wolskies infrastructure team'
author = 'wolskies infrastructure team'

release = '1.2.0'
version = '1.2.0'

extensions = [
    'sphinx.ext.autodoc',
    'sphinx.ext.viewcode',
    'sphinx.ext.napoleon',
]

templates_path = ['_templates']
exclude_patterns = []

html_theme = 'sphinx_rtd_theme'
html_static_path = ['_static']

# Theme options
html_theme_options = {
    'navigation_depth': 3,
    'collapse_navigation': False,
    'sticky_navigation': True,
    'includehidden': True,
    'titles_only': False
}
"""

    with open(output_dir / "conf.py", "w") as f:
        f.write(conf_content)


def create_manifest_json(output_dir: Path):
    """Create manifest.json with build metadata."""
    manifest = {
        "collection": "wolskies.infrastructure",
        "version": "1.2.0",
        "generated_at": datetime.now(datetime.UTC).isoformat(),
        "commit": os.environ.get("CI_COMMIT_SHA", "unknown"),
        "pipeline": os.environ.get("CI_PIPELINE_ID", "unknown"),
        "roles": [
            "configure_user",
            "go",
            "manage_flatpak",
            "manage_packages",
            "manage_security_services",
            "manage_snap_packages",
            "neovim",
            "nodejs",
            "os_configuration",
            "rust",
            "terminal_config",
        ],
    }

    with open(output_dir / "manifest.json", "w") as f:
        json.dump(manifest, f, indent=2)


def main():
    """Create all Sphinx files in the public directory."""
    if len(os.sys.argv) > 1:
        output_dir = Path(os.sys.argv[1])
    else:
        output_dir = Path("public")

    output_dir.mkdir(exist_ok=True)

    create_index_rst(output_dir)
    create_conf_py(output_dir)
    create_manifest_json(output_dir)

    print(f"✅ Sphinx files created in {output_dir}")


if __name__ == "__main__":
    main()
