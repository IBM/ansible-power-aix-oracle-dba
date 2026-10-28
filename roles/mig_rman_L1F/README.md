# Ansible Role: mig_rman_L1F
 This role runs the final RMAN level 1 backup and restore, the Data Pump Full Transportable import, postchecks and validation for the Oracle 19c cross-endian (M5) migration.
## Requirements
DBMIG 5.1 (MOS Doc 2999157.1) staged in roles/mig_prechecks/files/; ansible.posix collection.

## Role Variables
Variables are defined at playbooks/vars/m5_migration/mig_vars.yml
## Dependencies
None.

## Example Playbook

Run from playbooks/ (see playbooks/m5_migration.yml):

    ansible-playbook m5_migration.yml -i inventory.yml --tags rman_l1f --ask-vault-pass

## Copyright
© Copyright IBM Corporation 2026
