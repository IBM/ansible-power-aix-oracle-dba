# Ansible Role: sync_gap 
 This role performs sync between primary and standby
## Requirements
None.

## Role Variables
Variables are defined at playbooks/vars/dataguard_vars.yml  
## Dependencies
dataguard_precheck

## Example Playbook

    - hosts: aix
      include_role:
        name: sync_gap

## Copyright
© Copyright IBM Corporation 2025
