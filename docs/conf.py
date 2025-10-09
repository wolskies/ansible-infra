# Configuration file for Sphinx documentation builder.
# For the full list of built-in configuration values, see:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
project = "wolskies.infrastructure"
copyright = "2025, wolskies infrastructure team"
author = "wolskies infrastructure team"

release = "1.2.0"
version = "1.2.0"

# -- General configuration ---------------------------------------------------
extensions = [
    "sphinx.ext.autodoc",
    "sphinx.ext.viewcode",
    "sphinx.ext.napoleon",
    "sphinx.ext.intersphinx",
    "sphinx.ext.todo",
]

templates_path = ["_templates"]
exclude_patterns = ["_build", "Thumbs.db", ".DS_Store"]

# -- Options for HTML output -------------------------------------------------
html_theme = "sphinx_rtd_theme"
html_static_path = ["_static"]

# Theme options
html_theme_options = {
    "navigation_depth": 4,
    "collapse_navigation": False,
    "sticky_navigation": True,
    "includehidden": True,
    "titles_only": False,
    "prev_next_buttons_location": "bottom",
    "style_external_links": True,
}

# -- Extension configuration -------------------------------------------------

# intersphinx: Refer to other Sphinx documentation
intersphinx_mapping = {
    "ansible": ("https://docs.ansible.com/ansible/latest/", None),
}

# todo: Show TODO items
todo_include_todos = True
