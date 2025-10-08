Variables Reference
===================

Complete variable interface documentation for the ``wolskies.infrastructure`` collection.

.. note::
   This section will contain auto-generated variable tables from role ``argument_specs``.

Collection-Wide Variables
-------------------------

These variables are defined in ``defaults/main.yml`` and apply across multiple roles.

Package Management
~~~~~~~~~~~~~~~~~~

See :doc:`../roles/manage_packages` for detailed documentation and examples.

.. code-block:: yaml

   manage_packages_all: {}
   # Example:
   # manage_packages_all:
   #   Ubuntu:
   #     - name: git
   #     - name: curl
   #   MacOSX:
   #     - name: git

   manage_packages_group: {}
   manage_packages_host: {}

   manage_casks: {}
   # Example:
   # manage_casks:
   #   - name: google-chrome

User Management
~~~~~~~~~~~~~~~

See :doc:`../roles/configure_users` for detailed documentation.

.. code-block:: yaml

   configure_users_list: []
   # Example:
   # configure_users_list:
   #   - username: developer
   #     shell: /bin/bash
   #     groups: [sudo, docker]

Security Services
~~~~~~~~~~~~~~~~~

See collection documentation for detailed security service configuration.

.. code-block:: yaml

   manage_security_services_all: {}
   manage_security_services_group: {}
   manage_security_services_host: {}

Role-Specific Variables
-----------------------

Coming Soon
~~~~~~~~~~~

Auto-generated variable tables will be added here for each role's specific variables.

For now, see individual role documentation:

* :doc:`../roles/manage_packages`
* :doc:`../roles/configure_users`
* See :doc:`../roles/index` for complete role list
