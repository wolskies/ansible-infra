Priority 3: Remove Excessive Safety Checks

- OS version validation in discovery (lines 4-20) - Ansible facts are reliable
- Package existence checks before installation - package modules handle this
- Directory existence checks before creation - file module handles this
- Lines saved: ~50

Simplify variable validation:

- Remove | length > 0 checks - empty lists are falsy
- Remove is defined where defaults exist
- Lines saved: ~30

Priority 4: Consolidate Similar Functionality

Merge system configuration roles:

- os_configuration + configure_system → Single system role
- Similar tasks, different naming conventions
- Lines saved: ~60

Simplify user configuration:

- configure_user + manage_users → Single user role
- Lines saved: ~40

Total Impact

- Estimated lines reduced: ~600+ (70% reduction)
- Roles consolidated: 12 → 6
- Improved maintainability through community modules
- Better idempotence and cross-platform support

collection-level defaults for vars??

consolidate user validation logic

Remove redundant validation:
