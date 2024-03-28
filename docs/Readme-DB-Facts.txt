# Gather Facts of a Database - Readme
# ===================================
# Description: This module is used to gather Facts about a Container/Pluggable or Non Multitenant database. It will provide the facts like initialization parameters, size of tablespaces, Archive log Sequence number, Is a CDB or no etc.

In the following example we're going to get facts about a single instance database called devdb.

1. There are two files which need to be updated:
        a. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/gather-dbfacts-vars.yml: This file contains database hostname, database port number and the path to the Oracle client and other related parameters.
        b. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/vault.yml: This contains sys password which will be used by cx_oracle to connect to the database with sysdba privilege.

2. Update the common variables file: {{collection_dir}}/power_aix_oracle_dba/playbooks/vars/gather-dbfacts-vars.yml as shown below
hostname: ansible_db                    # AIX lpar hostname where the database is running.
listener_port: 1521                     # Database port number
oracle_db_home: /home/ansible/oracle_client      # Oracle Client location on the ansible controller.
service_name: devdb                     # Service name of a PDB or CDB.

3. Update the passwords file: {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/vault.yml with sys user password. This file needs to be encrypted using ansible-vault. While running the playbook, please provide the vault password.
default_dbpass: Oracle4u # SYS password
default_gipass: Oracle4u # ASMSNMP password

4. Encrypt the passwords file using ansible-vault as shown below
$ ansible-vault encrypt vars/vault.yml
New Vault password:
Confirm New Vault password:
Encryption successful

5. Create the playbook from {{ collection_dir }}/power_aix_oracle_dba/playbooks directory as shown below

$ cat gather-db-facts.yml
- hosts: localhost
  connection: local
  vars_files:
   - vars/vault.yml
   - vars/gather-dbfacts-vars.yml
  roles:
     - { role: oradb_gather_dbfacts }

6. Now execute the playbook as shown below
ansible-playbook gather-db-facts.yml -i inventory.yml --ask-vault-pass
Vault password:

PLAY [localhost] **********************************************************************************************************************

TASK [Gathering Facts] ****************************************************************************************************************
ok: [localhost]

TASK [ibm.power_aix_oracle_dba.oradb_gather_dbfacts : gather database facts] **********************************************************
[WARNING]: Module did not set no_log for password
ok: [localhost]

TASK [ibm.power_aix_oracle_dba.oradb_gather_dbfacts : debug] **************************************************************************
ok: [localhost] => {
    "dbfacts": {
        "ansible_facts": {
            "database": {
                "ACTIVATION#": 1057980752,
                "ARCHIVELOG_CHANGE#": 0,
                "ARCHIVELOG_COMPRESSION": "DISABLED",
                "ARCHIVE_CHANGE#": 2353520,
                "CDB": "YES",
.
.
.## Some Output is Truncated ##
.
                "DATABASE_ROLE": "PRIMARY",
                "ISDBA": "TRUE",
                "ORACLE_HOME": "/u02/db19c"
            },
            "version": "19.17.0.0.0"
        },
        "changed": false,
        "failed": false,
        "msg": "",
        "warnings": [
            "Module did not set no_log for password"
        ]
    }
}

PLAY RECAP ****************************************************************************************************************************
localhost                  : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
To execute this playbook from GUI, please refer this link: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
