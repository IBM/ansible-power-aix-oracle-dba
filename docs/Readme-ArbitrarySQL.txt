# Run Arbitrary SQL scripts - Readme
# ==================================
# Description: This module is used run arbitrary SQL Scripts. Single & multiple sql scripts can be run. It uses a python library located here: ansible-power-aix-oracle-dba/library/oracle_sql.

# Prerequisites:
# ==============
# Passwordless ssh needs to be setup between the Target lpar oracle owner and ansible controller user.

# Set the Variables for Oracle to execute this task: Open the file ansible-power-aix-oracle-dba/arbitrarysql-task.yml and modify the variables under "vars" section. Do NOT change other sections of the file.

 hostname: ansible_db             # AIX hostname
 service_name: db122c             # Service name of the database
 user: sys
 password: oracle                 # sys user password
 db_mode: sysdba
 listener_port: 1521              # Listen port
 sqlfile:
    - { script: '/home/ansible/ansible_test/stage/create.sql' }   # SQL Script 1 location & name of the file.
    - { script: '/home/ansible/ansible_test/stage/insert.sql' }   # SQL Script 2 location & name of the file.
    - { script: '/home/ansible/ansible_test/stage/insert1.sql' }  # SQL Script 3 location & name of the file.
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
    script: "{{ item.script }}"
  with_items:
    - "{{ sqlfile }}"
  environment: "{{ oracle_env }}"
  register: output
- debug:
    var: output
    
# Sample output:
================

[ansible@x134vm232 ansible-power-aix-oracle-dba]$ ansible-playbook arbitrarysql-task.yml

PLAY [localhost] **********************************************************************************************************************

TASK [Gathering Facts] ****************************************************************************************************************
ok: [localhost]

TASK [oracle_sql] *********************************************************************************************************************
changed: [localhost] => (item={'script': '/home/ansible/ansible_test/stage/create.sql'})
changed: [localhost] => (item={'script': '/home/ansible/ansible_test/stage/insert.sql'})
changed: [localhost] => (item={'script': '/home/ansible/ansible_test/stage/insert1.sql'})
[WARNING]: The value 1521 (type int) in a string field was converted to '1521' (type string). If this does not look like what you
expect, quote the entire value to ensure it does not change.

TASK [debug] **************************************************************************************************************************
ok: [localhost] => {
    "output": {
        "changed": true,
        "msg": "All items completed",
        "results": [
            {
                "ansible_loop_var": "item",
                "changed": true,
                "failed": false,
                "invocation": {
                    "module_args": {
                        "hostname": "ansible_db",
                        "mode": "sysdba",
                        "password": "VALUE_SPECIFIED_IN_NO_LOG_PARAMETER",
                        "port": "1521",
                        "script": "/home/ansible/ansible_test/stage/create.sql",
                        "service_name": "db122c",
                        "sql": null,
                        "user": "sys",
                        "username": "sys"
                    }
                },
                "item": {
                    "script": "/home/ansible/ansible_test/stage/create.sql"
                },
                "msg": "Finished running script /home/ansible/ansible_test/stage/create.sql \nContents: \nCREATE TABLE ansible1(person_id NUMBER GENERATED BY DEFAULT AS IDENTITY, first_name VARCHAR2(50) NOT NULL,last_name VARCHAR2(50) NOT NULL);\ninsert into ansible1 (person_id,first_name,last_name) values (10,'ansiuser','2')"
            },
            {
                "ansible_loop_var": "item",
                "changed": true,
                "failed": false,
                "invocation": {
                    "module_args": {
                        "hostname": "ansible_db",
                        "mode": "sysdba",
                        "password": "VALUE_SPECIFIED_IN_NO_LOG_PARAMETER",
                        "port": "1521",
                        "script": "/home/ansible/ansible_test/stage/insert.sql",
                        "service_name": "db122c",
                        "sql": null,
                        "user": "sys",
                        "username": "sys"
                    }
                },
                "item": {
                    "script": "/home/ansible/ansible_test/stage/insert.sql"
                },
                "msg": "Finished running script /home/ansible/ansible_test/stage/insert.sql \nContents: \ninsert into ansible1 (person_id,first_name,last_name) values (11,'Ansi','User');\ninsert into ansible1 (person_id,first_name,last_name) values (12,'Ansi1','User1')"
            },
            {
                "ansible_loop_var": "item",
                "changed": true,
                "failed": false,
                "invocation": {
                    "module_args": {
                        "hostname": "ansible_db",
                        "mode": "sysdba",
                        "password": "VALUE_SPECIFIED_IN_NO_LOG_PARAMETER",
                        "port": "1521",
                        "script": "/home/ansible/ansible_test/stage/insert1.sql",
                        "service_name": "db122c",
                        "sql": null,
                        "user": "sys",
                        "username": "sys"
                    }
                },
                "item": {
                    "script": "/home/ansible/ansible_test/stage/insert1.sql"
                },
                "msg": "Finished running script /home/ansible/ansible_test/stage/insert1.sql \nContents: \ninsert into ansible1 (person_id,first_name,last_name) values (13,'Ansi2','User2');\ninsert into ansible1 (person_id,first_name,last_name) values (14,'Ansi3','User3')"
            }
        ],
        "warnings": [
            "The value 1521 (type int) in a string field was converted to '1521' (type string). If this does not look like what you expect, quote the entire value to ensure it does not change.",
            "The value 1521 (type int) in a string field was converted to '1521' (type string). If this does not look like what you expect, quote the entire value to ensure it does not change.",
            "The value 1521 (type int) in a string field was converted to '1521' (type string). If this does not look like what you expect, quote the entire value to ensure it does not change."
        ]
    }
}

PLAY RECAP ****************************************************************************************************************************
localhost                  : ok=3    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0