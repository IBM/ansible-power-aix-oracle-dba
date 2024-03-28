# Manage Roles - Readme
# =====================

# Description: This module is used to create or drop roles. To add privileges to the roles please refer: https://docs.oracle.com/en/database/oracle/oracle-database/19/sqlrf/CREATE-ROLE.html#GUID-B2252DC5-5AE7-49B7-9048-98062993E450. 

In the following example we're going to create a role called devrole in a PDB called DEVPDB.

1. There are two files which need to be updated:
        a. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/manage-roles-vars.yml: This file contains database hostname, database port number and the path to the Oracle client and other related parameters.
        b. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/vault.yml: This contains sys password which will be used by cx_oracle to connect to the database with sysdba privilege.

2. Update the common variables file: {{collection_dir}}/power_aix_oracle_dba/playbooks

$  cat vars/manage-roles-vars.yml
hostname: ansible_db                           # AIX hostname where the Database is running.
service_name: devdb                            # Database service name.
listener_port: 1521                            # Database port number.
oracle_db_home: /home/ansible/oracle_client    # Oracle Instant Client path on the ansible controller.
oracle_databases:
      - roles:
          - name: devrole                              # Name of the role to be created in PDB
        service_name: devpdb            # PDB service name.
        grants:
          - create session                              # Privilege 1 assigned to the role.
          - create any table                            # Privilege 2 assigned to the role.
          - create any view
        state: present                                   # present|absent

3. Update the passwords file: {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/vault.yml with sys user password. This file needs to be encrypted using ansible-vault. While running the playbook, please provide the vault password.
default_dbpass: Oracle4u # SYS password
default_gipass: Oracle4u # ASMSNMP password

4. Encrypt the passwords file using ansible-vault as shown below
$ ansible-vault encrypt vars/vault.yml
New Vault password:
Confirm New Vault password:
Encryption successful

5. Create the playbook in {{ collection_dir }}/power_aix_oracle_dba/playbooks directory as shown below

$ cat manage-roles.yml

- hosts: localhost
  connection: local
  vars_files:
   - vars/vault.yml
   - vars/manage-roles-vars.yml
  roles:
     - { role: oradb_manage_roles }

6. Execute the playbook as shown below

$ ansible-playbook manage-roles.yml -i inventory.yml --ask-vault-pass
Vault password:

PLAY [localhost] *********************************************************************************************************************

TASK [Gathering Facts] ***************************************************************************************************************
ok: [localhost]

TASK [oradb_manage_roles : Manage roles] ********************************************************************
changed: [localhost] => (item=port: 1521, service: devpdb, role: devrole, state: present)

PLAY RECAP ***************************************************************************************************************************
localhost                  : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

To execute this playbook from GUI, please refer this link: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf

