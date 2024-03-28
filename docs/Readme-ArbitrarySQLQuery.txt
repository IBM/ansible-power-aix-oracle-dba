# Run Arbitrary SQL Queries - Readme
# ==================================
# Description: This module is used run arbitrary SQL Queries. Single & multiple queries can be run. 

In the following example we're going to execute two simple queries against a PDB.

1. There are two files which need to be updated:
        a. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/manage-arbitrarysqlquery-vars.yml: This file contains database hostname, database port number and the path to the Oracle client and other related parameters.
        b. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/vault.yml: This contains sys password which will be used by cx_oracle to connect to the database with sysdba privilege.

2. Update the common variables file: {{collection_dir}}/power_aix_oracle_dba/playbooks/vars/manage-arbitrarysqlquery-vars.yml as shown below

hostname: ansible_db                  # AIX Lpar hostname where the Database is running.
service_name: devpdb   # Database service name.
listener_port: 1521                   # Database port number.
oracle_db_home: /home/ansible/oracle_client    # Oracle Instant Client path on the ansible controller.

sql_query:
   - { query: 'select name from v$database' }   # SQL Query 1.
   - { query: 'select instance_name from v$instance' }    # SQL Query 2.

3. Update the passwords file: {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/vault.yml with sys user password. This file needs to be encrypted using ansible-vault. While running the playbook, please provide the vault password.
default_dbpass: Oracle4u # SYS password
default_gipass: Oracle4u # ASMSNMP password

4. Encrypt the passwords file using ansible-vault as shown below
$ ansible-vault encrypt vars/vault.yml
New Vault password:
Confirm New Vault password:
Encryption successful

5. Create the playbook in {{ collection_dir }}/power_aix_oracle_dba/playbooks directory as shown below

$ cat manage-arbitrarysqlquery.yml

- hosts: localhost
  connection: local
  vars_files:
   - vars/vault.yml
   - vars/manage-arbitrarysqlquery-vars.yml
  roles:
     - { role: oradb_manage_sqlqueries }

6. Execute the playbook as shown below

$ ansible-playbook manage-arbitrarysqlquery.yml -i inventory.yml --ask-vault-pass
Vault password:

PLAY [localhost] **********************************************************************************************************************

TASK [Gathering Facts] ****************************************************************************************************************
ok: [localhost]

TASK [oradb_manage_sqlqueries : oracle_sql] ******************************************************************
ok: [localhost] => (item={'query': 'select name,open_mode from v$database'})
ok: [localhost] => (item={'query': 'select instance_name from v$instance'})

TASK [oradb_manage_sqlqueries : set_fact] ********************************************************************
ok: [localhost]

TASK [oradb_manage_sqlqueries : SQL Output] ******************************************************************
ok: [localhost] => {
    "query_ouput": [
        "{'query': 'select name,open_mode from v$database'}: [['DEVDB', 'READ WRITE']]",
        "{'query': 'select instance_name from v$instance'}: [['devdb']]"
    ]
}

PLAY RECAP ****************************************************************************************************************************
localhost                  : ok=4    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

To execute this playbook from GUI, please refer this link: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
