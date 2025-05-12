# Ansible Role: dataguard_standby_config 
 This role performs pre configuration at standby site for dataguard setup
## Requirements
None.

## Role Variables
Variables are defined at playbooks/vars/dataguard_vars.yml  
## Dependencies
dataguard_precheck
dataguard_primary_config

## Example Playbook

    - hosts: aix
      include_role:
        name: dataguard_standby_config

## Copyright
© Copyright IBM Corporation 2025
