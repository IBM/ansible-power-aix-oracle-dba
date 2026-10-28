# Ansible Role: mig_prechecks
 This role performs the prechecks and preparation for the Oracle 19c cross-endian (M5) migration: OS and database checks, patch checks, SSH equivalence, source and destination database preparation, and DBMIG deployment.
## Requirements
DBMIG 5.1 (MOS Doc 2999157.1) staged in roles/mig_prechecks/files/; ansible.posix collection.

## Role Variables
Variables are defined at playbooks/vars/m5_migration/mig_vars.yml
## Dependencies
None.

## Example Playbook

Run from playbooks/ (see playbooks/m5_migration.yml):

    ansible-playbook m5_migration.yml -i inventory.yml --tags prechecks --ask-vault-pass

## Copyright
© Copyright IBM Corporation 2026
