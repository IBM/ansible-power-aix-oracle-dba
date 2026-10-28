# Ansible Role: mig_rman_l0_l1
 This role runs the RMAN level 0 baseline and level 1 incremental backup and restore cycles for the Oracle 19c cross-endian (M5) migration.
## Requirements
DBMIG 5.1 (MOS Doc 2999157.1) staged in roles/mig_prechecks/files/; ansible.posix collection.

## Role Variables
Variables are defined at playbooks/vars/m5_migration/mig_vars.yml
## Dependencies
None.

## Example Playbook

Run from playbooks/ (see playbooks/m5_migration.yml):

    ansible-playbook m5_migration.yml -i inventory.yml --tags rman_l0 --ask-vault-pass

## Copyright
© Copyright IBM Corporation 2026
