# Manage Database directories  - Readme 
# =====================================

# Description: # This module is used to manage resources at the pluggable database level. 
# More information on Create directory can be found here: https://docs.oracle.com/cd/E11882_01/server.112/e25494/dbrm.htm#ADMIN11842

In the following example we're going to create a Resource Consumer Group in a PDB DEVPDB.

1. There are two files which need to be updated:
         a. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/manage-resource-group-vars.yml: This file contains database hostname, database port number and the path to the Oracle client and other related parameters.
        b. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/vault.yml: This contains sys password which will be used by cx_oracle to connect to the database with sysdba privilege.

2. Update the common variables file: {{collection_dir}}/power_aix_oracle_dba/playbooks/vars/manage-resource-group-vars.yml as shown below

$ cat vars/manage-resource-group-vars.yml

hostname: ansible_db                           # AIX hostname where the Database is running.
service_name: devpdb                           # Database service name.
listener_port: 1521                            # Database port number.
oracle_db_home: /home/ansible/oracle_client    # Oracle Instant Client path on the ansible controller.
state: present                  # State: Present/Absent
consumer_group: ansigroup1      # Desired consumer group name
comments:  This is a test consumer resource group       # Optional
grant:
   - testuser1                  # Name of the user to provide grants to resource group.
map_oracle_user:
   - testuser1                  # Map user
map_service_name:
   - devpdb                     # Map service name
map_client_machine:
   - x123vm456                  # Map client machine name

3. Update the passwords file: {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/vault.yml with sys user password. This file needs to be encrypted using ansible-vault. While running the playbook, please provide the vault password.
default_dbpass: Oracle4u # SYS password
default_gipass: Oracle4u # ASMSNMP password

4. Encrypt the passwords file using ansible-vault as shown below
$ ansible-vault encrypt vars/vault.yml
New Vault password:
Confirm New Vault password:
Encryption successful

5. Create the playbook in {{ collection_dir }}/power_aix_oracle_dba/playbooks directory as shown below
$ cat manage-awr.yml

- hosts: localhost
  connection: local
  vars_files:
   - vars/vault.yml
   - vars/manage-resource-group-vars.yml
  roles:
     - { role: oradb_manage_rsrc }

6. Execute the playbook as shown below

$ ansible-playbook manage-resource-consumer-group.yml -i inventory.yml --ask-vault-pass
Vault password:

PLAY [localhost] **********************************************************************************************************************

TASK [oradb_manage_rsrc : Resource Consumer Groups] **********************************************************
[WARNING]: Module did not set no_log for password
changed: [localhost]

TASK [oradb_manage_rsrc : debug] *****************************************************************************
ok: [localhost] => {
    "rsc": {
        "changed": true,
        "failed": false,
        "msg": "Added grants: {'TESTUSER1'}, Added mappings: {'ORACLE_USER': {'TESTUSER1'}, 'SERVICE_NAME': {'DEVPDB'}, 'CLIENT_MACHINE': {'X123VM456'}}",
        "warnings": [
            "Module did not set no_log for password"
        ]
    }
}

PLAY RECAP ****************************************************************************************************************************
localhost                  : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

To execute this playbook from GUI, please refer this link: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
