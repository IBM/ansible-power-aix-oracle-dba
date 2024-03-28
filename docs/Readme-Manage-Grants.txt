# Manage Grants - Readme
# =====================

# Description: This module is used to grant/Revoke privileges to/from Users/Roles. 

In the following example we're going to grant connect, resource and drop any table privileges to testuser1.

1. There are two files which need to be updated:
        a. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/manage-grants-vars.yml: This file contains database hostname, database port number and the path to the Oracle client and other related parameters.
        b. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/vault.yml: This contains sys password which will be used by cx_oracle to connect to the database with sysdba privilege.

2. Update the common variables file: {{collection_dir}}/power_aix_oracle_dba/playbooks/vars/manage-grants-vars.yml as shown below

hostname: ansible_db                        # AIX Lpar hostname where the database is running.
listener_port: 1521                         # Database port number.
oracle_db_home: /home/ansible/oracle_client      # Oracle Instant Client path on the ansible controller.

oracle_databases:                           # Database users list to be created
      - users:
         - schema: testuser1              # Username to be created.
        service_name: devdb                 # Database service name.
        grants_mode: enforce                # enforce|append.
        grants:
         - connect                          # Provide name of the privilege as a list to grant to the user.
         - resource
         - drop any table
        state: present                       # present|absent.

3. Update the passwords file: {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/vault.yml with sys user password. This file needs to be encrypted using ansible-vault. While running the playbook, please provide the vault password.
default_dbpass: Oracle4u # SYS password
default_gipass: Oracle4u # ASMSNMP password

4. Encrypt the passwords file using ansible-vault as shown below
$ ansible-vault encrypt vars/vault.yml
New Vault password:
Confirm New Vault password:
Encryption successful

5. Create the playbook from {{ collection_dir }}/power_aix_oracle_dba/playbooks directory as shown below
$ cat manage-grants.yml

- name: Manage DB User Permissions/Grants
  hosts: localhost
  gather_facts: false
  vars_files:
   - vars/vault.yml
   - vars/manage-grants-vars.yml
  roles:
     - { role: oradb_manage_grants }

6. Execute the playbook as shown below

ansible-playbook manage-grants.yml -i inventory.yml --ask-vault-pass
Vault password:

PLAY [Manage DB User Permissions/Grants] **********************************************************************************************

TASK [ibm.power_aix_oracle_dba.oradb_manage_grants : Manage role grants] **************************************************************
skipping: [localhost]

TASK [ibm.power_aix_oracle_dba.oradb_manage_grants : Manage schema grants] ************************************************************
changed: [localhost] => (item=port: 1522, service: atsdb, schema: testuser1, grants: ['connect', 'resource', 'drop any table'], state: present)

PLAY RECAP ****************************************************************************************************************************
localhost                  : ok=1    changed=1    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0

To execute this playbook from GUI, please refer this link: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
