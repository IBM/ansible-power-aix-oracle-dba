# Ansible Role: dataguard_primary_config 
 This role performs pre configuration at primary site for dataguard setup
## Requirements
None.

## Role Variables
Variables are defined at playbooks/vars/dataguard_vars.yml  
## Dependencies
dataguard_precheck

## Example Playbook

    - hosts: aix
      include_role:
        name: dataguard_primary_config

## Copyright
© Copyright IBM Corporation 2025
