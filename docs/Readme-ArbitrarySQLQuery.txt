# Run Arbitrary SQL Queries - Readme
# ==================================
# Description: This module is used run arbitrary SQL Queries. Single & multiple queries can be run. It uses a python library located here: ansible-power-aix-oracle-dba/library/oracle_sql.

# Prerequisites:
# ==============
# Passwordless ssh needs to be setup between the Target lpar oracle owner and ansible controller user.

# Go to the collection directory 
# Decrypt the file (if it's already encrypted)
# ansible-vault decrypt playbooks/vars/vars.yml
Vault password:
Decryption successful
# Set SYS password for "default_dbpass" variable in ansible-power-aix-oracle-dba/playbooks/vars/vars.yml.
# Encrypt the file
# ansible-vault encrypt playbooks/vars/vars.yml
New Vault password:
Confirm New Vault password:
Encryption successful

# Set the Variables for Oracle to execute this task: Open the file ansible-power-aix-oracle-dba/arbitrarysqlquery-task.yml and modify the variables under "vars" section. Do NOT change other sections of the file.

hostname: ansible_db             # AIX hostname
service_name: db122c             # Service name of the database
user: sys
db_password_cdb: "{% if dbpasswords is defined and dbpasswords[item[1].cdb] is defined and dbpasswords[item[1].cdb][db_user] is defined%}{{dbpasswords[item[1].cdb][db_user]}}{% else %}{{ default_dbpass}}{% endif%}"
db_password_pdb: "{% if dbpasswords is defined and dbpasswords[item[1].cdb] is defined and dbpasswords[item[1].cdb][db_user] is defined%}{{dbpasswords[item[1].cdb][db_user]}}{% else %}{{ default_dbpass}}{% endif%}"
db_mode: sysdba
listener_port: 1521              # Listen port
sql_query:
   - { query: 'select name from v$database' }   # SQL Query 1.
   - { query: 'select instance_name from v$instance' }    # SQL Query 2.
oracle_env:
   ORACLE_HOME: /home/ansible/oracle_client              # Oracle client home location on Ansible controller.
   LD_LIBRARY_PATH: /home/ansible/oracle_client/lib      # Oracle client library location on Ansible controller.


# Executing the playbook: This playbook executes a role.
# Change directory to ansible-power-aix-oracle-dba/playbooks
# Name of the Playbook: manage-arbitrarysqlquery.yml
# ansible-playbook manage-arbitrarysqlquery.yml --ask-vault-pass
# The following task will get executed.

- hosts: localhost
  connection: local
  pre_tasks:
     - name: include variables
       include_vars: vars.yml

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
