# Manage Tablespaces - Readme
# ===========================
# Description: This module is used to manage tablespaces in Standalone & RAC environments. It uses python library "oracle_tablespaces"
# Using this the tablespaces can create, drop, put in read only/read write, offline/online.
# More information on managing tablespaces: https://docs.oracle.com/cd/A57673_01/DOC/server/doc/SCN73/ch4.htm

In the following example we are going to create a tablespace called devtbs.

1. There are two files which need to be updated:
        a. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/manage-tablespaces-vars.yml: This file contains database hostname, database port number and the path to the Oracle client and also tablespace related parameters.
        b. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/vault.yml: This contains sys password which will be used by cx_oracle to connect to the database with sysdba privilege.

2. Update the common variables file: {{collection_dir}}/power_aix_oracle_dba/playbooks/vars/manage-tablespaces-vars.yml as shown below

$ cat vars/manage-tablespaces-vars.yml
hostname: ansible_db                           # AIX hostname where the Database is running.
service_name: devdb                            # Database service name.
listener_port: 1521                            # Database port number.
oracle_db_home: /home/ansible/oracle_client    # Oracle Instant Client path on the ansible controller.

oracle_databases:
      - tablespaces:
          - name: devusertbs      # Tablespace name for creation.
            datafile: +DATA     # Diskgroup name in which tablespace needs to be created.
            #datafile: '/u02/db19c/dbs/ +DATA'           # Specify datafile path & name in case of non ASM.
            size: 1g     # Desired size of the datafile.
            maxsize: 2g   # Desired maxsize for the datafile.
            state: absent     # Set "present" to create / "absent" to drop tablespace.
            autoextend: true   # Whether to extend the datafile size automatically or not. True or False.
            next: 100m      # Set this only if autoextend parameter is set to True, otherwise comment this parameter.

3. Update the passwords file: {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/vault.yml with sys user password. This file needs to be encrypted using ansible-vault. While running the playbook, please provide the vault password.
default_dbpass: Oracle4u # SYS password
default_gipass: Oracle4u # ASMSNMP password

4. Encrypt the passwords file using ansible-vault as shown below
$ ansible-vault encrypt vars/vault.yml
New Vault password:
Confirm New Vault password:
Encryption successful

5. Create the playbook in {{ collection_dir }}/power_aix_oracle_dba/playbooks directory as shown below

$ cat manage-tablespaces.yml

- hosts: localhost
  connection: local
  vars_files:
   - vars/vault.yml
   - vars/manage-tablespaces-vars.yml
  roles:
     - { role: oradb_manage_tablespace }

6. Execute the playbook as shown below

$ ansible-playbook manage-tablespaces.yml -i inventory.yml --ask-vault-pass
Vault password:

PLAY [localhost] **********************************************************************************************************************

TASK [Gathering Facts] ****************************************************************************************************************
ok: [localhost]

TASK [oradb_manage_tablespace : Manage tablespaces] **********************************************************
changed: [localhost] => (item=port: 1521 service: devdb tablespace: devtbs content: __omit_place_holder__c20ce1da57ddec80847e4ecfb8dae50c3beb5f8b state: present)
[WARNING]: Both option datafile and its alias datafile are set.

PLAY RECAP ****************************************************************************************************************************
localhost                  : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

To execute this playbook from GUI, please refer this link: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
