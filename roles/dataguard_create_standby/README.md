# Ansible Role: dataguard_backup_primary_db 
 This role performs RMAN backup at primary site for dataguard setup
## Requirements
None.

## Role Variables
Variables are defined at playbooks/vars/dataguard_vars.yml  
## Dependencies
dataguard_precheck

## Example Playbook

    - hosts: aix
      include_role:
        name: dataguard_backup_primary_db

## Copyright
© Copyright IBM Corporation 2025
