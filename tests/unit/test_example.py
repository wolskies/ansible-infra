"""
Example unit test for wolskies.infrastructure collection.

This is a placeholder - add actual unit tests for custom modules/plugins.
"""


def test_example():
    """Example test that always passes."""
    assert True


def test_collection_structure():
    """Verify basic collection structure exists."""
    import pathlib

    collection_root = pathlib.Path(__file__).parent.parent.parent
    assert (collection_root / "galaxy.yml").exists()
    assert (collection_root / "roles").exists()
    assert (collection_root / "playbooks").exists()
