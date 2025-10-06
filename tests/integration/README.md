# Integration Tests

Integration tests for the wolskies.infrastructure collection.

## Structure

- Collection-level integration tests go here
- Role-level tests should use molecule in `roles/<role-name>/molecule/`

## Running Tests

```bash
# Run all integration tests
just test

# Run specific integration tests
pytest tests/integration/test_specific.py
```

## Guidelines

- Use molecule for role-level integration testing
- Use this directory for cross-role integration scenarios
- Keep tests focused and independent
