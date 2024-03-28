# Manage Database directories  - Readme 
# =====================================

# Description: # The role oradb_manage_directories is used to create/drop database directories. It uses python library "oracle_directory".
# More information on Create directory can be found here: https://docs.oracle.com/cd/B19306_01/server.102/b14200/statements_5007.htm
# More information on Drop directory can be found here: https://docs.oracle.com/cd/B19306_01/server.102/b14200/statements_8012.htm

In the following example we're going to create a directory called TESTDIR on /u01/dbdir.
1. There are two files which need to be updated:
        a. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/manage-directories-vars.yml: This file contains database hostname, database port number and the path to the Oracle client.
        b. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/vault.yml: This contains sys password which will be used by cx_oracle to connect to the database with sysdba privilege.
2. Update the common variables file: {{collection_dir}}/power_aix_oracle_dba/playbooks/vars/manage-directories-vars.yml as shown below:
hostname: ansible_db                       # AIX Lpar hostname where the Database is running.
service_name: devdb                        # Database service name.
listener_port: 1521                        # Database port number.
directory_name: TESTDIR                    # Desired directory name to be created.
path: /u01/dbdir                           # OS Path on AIX Lpar. This path must exist.
state: present                             # To create a directory - present. To drop a directory - absent.
mode: enforce
oracle_db_home: /home/ansible/oracle_client    # Oracle Instant Client path on the ansible controller.

3. Update the passwords file: {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/vault.yml with sys user password. This file needs to be encrypted using ansible-vault. While running the playbook, please provide the vault password.
default_dbpass: Oracle4u # SYS password
default_gipass: Oracle4u # ASMSNMP password

4. Encrypt the passwords file using ansible-vault as shown below
$ ansible-vault encrypt vars/vault.yml
New Vault password:
Confirm New Vault password:
Encryption successful

5. Create the playbook in {{ collection_dir }}/power_aix_oracle_dba/playbooks directory as shown below
$ cat manage-db-directories.yml

- hosts: localhost
  connection: local
  vars_files:
   - vars/vault.yml
   - vars/manage-directories-vars.yml
  roles:
     - { role: oradb_manage_directories }

6. Execute the playbook as shown below
$ ansible-playbook manage-db-directories.yml --ask-vault-pass -i inventory.yml
Vault password:

PLAY [localhost] **********************************************************************************************************************

TASK [Gathering Facts] ****************************************************************************************************************
ok: [localhost]

TASK [oradb_manage_directories : Create Directory] ***********************************************************
changed: [localhost]

TASK [oradb_manage_directories : debug] **********************************************************************
ok: [localhost] => {
    "crdir": {
        "changed": true,
        "failed": false,
        "msg": "Directory: TESTDIR, created with path: /u01/dbdir"
    }
}

TASK [oradb_manage_directories : Drop Directory] *************************************************************
skipping: [localhost]

TASK [oradb_manage_directories : debug] **********************************************************************
ok: [localhost] => {
    "deldir": {
        "changed": false,
        "false_condition": "state == 'absent'",
        "skip_reason": "Conditional result was False",
        "skipped": true
    }
}

PLAY RECAP ****************************************************************************************************************************
localhost                  : ok=4    changed=1    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0

To execute this playbook from GUI, please refer this link: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf 
