### Variable structure

Vars can be placed in several locations, for purposes of this role, they should be placed in inventory/ with the following guidelines:

all.yml: global variables go here that affect all machines and should be prefixed with "global".  Examples:
- configure an admin user for all machines
- site/network defaults
- minimum required packages/features
- banned packages/features

workstations.yml: these settings and features will be applied to all workstations.  Examples:
- desktop environment
- graphics configurations
- minimum required packages above/beyond the global list
- banned packages/features above/beyond the global list

servers.yml:  these settings and features will be applied to all servers.  Examples
- docker configuration
- proxy configuration
- minimum required packages above/beyond the global list
- banned packages/features above/beyond the global list


##### all.yaml
global_ansible_user: 'ed'

global_config_system_locale: 'en_US.UTF-8'
global_config_system_language: 'en_US.UTF-8'
global_config_system_timezone: 'America/New_York'

