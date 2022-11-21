# Run Arbitrary SQL Queries - Readme
# ==================================
# Description: This module is used run arbitrary SQL Queries. Single & multiple queries can be run. It uses a python library located here: ansible-power-aix-oracle-dba/library/oracle_sql.

# Prerequisites:
# ==============

# Go to the playbooks directory 
# Decrypt the file (if it's already encrypted)
# ansible-vault decrypt vars/vault.yml
Vault password:
Decryption successful
# Set SYS password for "default_dbpass" variable in ansible-power-aix-oracle-dba/playbooks/vars/vault.yml.
# Encrypt the file
# ansible-vault encrypt vars/vault.yml
New Vault password:
Confirm New Vault password:
Encryption successful

# Set the Variables for Oracle to execute this task: 

# Open the file vars/vars.yml and set the following variables:

hostname: ansible_db                    # AIX lpar hostname
listener_port: 1521                     # Database port number
oracle_db_home: /tmp/oracle_client      # Oracle Client location on the ansible controller.
oracle_env:
     ORACLE_HOME: "{{ oracle_db_home }}"
     LD_LIBRARY_PATH: "{{ oracle_db_home}}/lib"
     PATH: "{{ oracle_db_home}}/bin:$PATH:/usr/local/bin:/bin:/sbin:/usr/bin:/usr/sbin"

# Open the file ansible-power-aix-oracle-dba/arbitrarysqlquery-task.yml and modify the variables under "vars" section. Do NOT change other sections of the file.

service_name: db122c             # Service name of the database
user: sys
db_password_cdb: "{% if dbpasswords is defined and dbpasswords[item[1].cdb] is defined and dbpasswords[item[1].cdb][db_user] is defined%}{{dbpasswords[item[1].cdb][db_user]}}{% else %}{{ default_dbpass}}{% endif%}"
db_password_pdb: "{% if dbpasswords is defined and dbpasswords[item[1].cdb] is defined and dbpasswords[item[1].cdb][db_user] is defined%}{{dbpasswords[item[1].cdb][db_user]}}{% else %}{{ default_dbpass}}{% endif%}"
db_mode: sysdba
sql_query:
   - { query: 'select name from v$database' }   # SQL Query 1.
   - { query: 'select instance_name from v$instance' }    # SQL Query 2.

# Executing the playbook: This playbook executes a role.
# Change directory to ansible-power-aix-oracle-dba/playbooks
# Name of the Playbook: manage-arbitrarysqlquery.yml
# ansible-playbook manage-arbitrarysqlquery.yml --ask-vault-pass
# The following task will get executed.

- hosts: localhost
  connection: local
  pre_tasks:
     - name: include variables
       include_vars:
         dir: vars
         extensions:
           - 'yml'

  roles:
     - { role: ibm.power_aix_oracle_dba.oradb_manage_sqlqueries }
# Sample output:
================

[ansible@x134vm232 ansible-power-aix-oracle-dba]$ ansible-playbook manage-arbitrarysqlquery.yml --ask-vault-pass
Vault password:

PLAY [localhost] **********************************************************************************************************************

TASK [Gathering Facts] ****************************************************************************************************************
ok: [localhost]

TASK [oracle_sql] *********************************************************************************************************************
ok: [localhost] => (item={'query': 'select name from v$database'})
ok: [localhost] => (item={'query': 'select instance_name from v$instance'})
[WARNING]: The value 1521 (type int) in a string field was converted to '1521' (type string). If this does not look like what you
expect, quote the entire value to ensure it does not change.

TASK [debug] **************************************************************************************************************************
ok: [localhost] => {
    "output": {
        "changed": false,
        "msg": "All items completed",
        "results": [
            {
                "ansible_loop_var": "item",
                "changed": false,
                "failed": false,
                "invocation": {
                    "module_args": {
                        "hostname": "ansible_db",
                        "mode": "sysdba",
                        "password": "VALUE_SPECIFIED_IN_NO_LOG_PARAMETER",
                        "port": "1521",
                        "script": null,
                        "service_name": "db122c",
                        "sql": "select name from v$database",
                        "user": "sys",
                        "username": "sys"
                    }
                },
                "item": {
                    "query": "select name from v$database"
                },
                "msg": [
                    [
                        "DB122C"
                    ]
                ]
            },
            {
                "ansible_loop_var": "item",
                "changed": false,
                "failed": false,
                "invocation": {
                    "module_args": {
                        "hostname": "ansible_db",
                        "mode": "sysdba",
                        "password": "VALUE_SPECIFIED_IN_NO_LOG_PARAMETER",
                        "port": "1521",
                        "script": null,
                        "service_name": "db122c",
                        "sql": "select instance_name from v$instance",
                        "user": "sys",
                        "username": "sys"
                    }
                },
                "item": {
                    "query": "select instance_name from v$instance"
                },
                "msg": [
                    [
                        "db122c"
                    ]
                ]
            }
        ],
        "warnings": [
            "The value 1521 (type int) in a string field was converted to '1521' (type string). If this does not look like what you expect, quote the entire value to ensure it does not change.",
            "The value 1521 (type int) in a string field was converted to '1521' (type string). If this does not look like what you expect, quote the entire value to ensure it does not change."
        ]
    }
}

PLAY RECAP ****************************************************************************************************************************
localhost                  : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
