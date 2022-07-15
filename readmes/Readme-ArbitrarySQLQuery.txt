# Run Arbitrary SQL Queries - Readme
# ==================================
# Description: This module is used run arbitrary SQL Queries. Single & multiple queries can be run. It uses a python library located here: ansible-power-aix-oracle-dba/library/oracle_sql.

# Prerequisites:
# ==============
# Passwordless ssh needs to be setup between the Target lpar oracle owner and ansible controller user.

# Set the Variables for Oracle to execute this task: Open the file ansible-power-aix-oracle-dba/arbitrarysqlquery-task.yml and modify the variables under "vars" section. Do NOT change other sections of the file.

hostname: ansible_db             # AIX hostname
service_name: db122c             # Service name of the database
user: sys
password: oracle                 # sys user password
db_mode: sysdba
listener_port: 1521              # Listen port
sql_query:
   - { query: 'select name from v$database' }   # SQL Query 1.
   - { query: 'select instance_name from v$instance' }    # SQL Query 2.
oracle_env:
   ORACLE_HOME: /home/ansible/oracle_client              # Oracle client home location on Ansible controller.
   LD_LIBRARY_PATH: /home/ansible/oracle_client/lib      # Oracle client library location on Ansible controller.


# Executing the playbook: This playbook runs using a single file where it contain both Oracle related variables as well as ansible task. The connection mode will be "local". The cx_Oracle & Oracle client must be installed on ansible controller before executing this playbook.
# Change directory to ansible-power-aix-oracle-dba
# Name of the Playbook: arbitrarysql-task.yml
# ansible-playbook arbitrarysql-task.yml
# The following task will get executed.

 - oracle_sql:
     username: "{{ user }}"
     password: "{{ password }}"
     service_name: "{{ service_name }}"
     hostname: "{{ hostname }}"
     port: "{{ listener_port }}"
     mode: "{{ db_mode }}"
     sql: "{{ item.query }}"
   with_items:
     - "{{ sql_query }}"
   environment: "{{ oracle_env }}"
   register: output
 - debug:
     var: output

# Sample output:
================

[ansible@x134vm232 ansible-power-aix-oracle-dba]$ ansible-playbook arbitrarysqlquery-task.yml

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
