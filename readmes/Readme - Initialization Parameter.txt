# Manage Initialization Parameters - Readme
# =========================================

# Description: # This module is used to set/alter & unset database initialization parameters. It uses a python library located here: ansible_oracle_aix/library/oracle_parameter.
# Playbook: ansible_oracle_aix/parameter-task.yml
# More information of what AWR policy is can be found here: https://docs.oracle.com/en/database/oracle/oracle-database/19/refrn/initialization-parameters-2.html#GUID-FD266F6F-D047-4EBB-8D96-B51B1DCA2D61
https://docs.oracle.com/en/database/oracle/oracle-database/19/admin/creating-and-configuring-an-oracle-database.html#GUID-2004E26A-3C24-4D0C-9EF4-F2854BCD6664

# Prerequisites:
# ==============
# Set the Variables for Oracle to execute this task: Open the file ansible_oracle_aix/parameter-task.yml and modify the variables under "vars" section. Do NOT change other sections of the file.

     name: Global Variables
     hostname: ansible_db               # AIX hostname.
     service_name: db122c               # DB service name.
     db_user: sys
     db_password_cdb: oracle            # Sys user password.
     listener_port: 1521                # DB port number.
     db_mode: sysdba
     param_name: log_archive_dest_state_2       # Initialization Parameter Name
     param_value: enable                         # Initialization Parameter Value
     state: present                              # Initialization Parameter state: present - sets the value, absent/reset - disables the parameter
     oracle_env:
       ORACLE_HOME: /home/ansible/oracle_client         # Oracle client s/w path on Ansible controller.
       LD_LIBRARY_PATH: /home/ansible/oracle_client/lib # Oracle client library path on Ansible controller.

# Executing the playbook: This playbook runs using a single file where it contain both Oracle related variables as well as ansible task. The connection mode will be "local". The cx_Oracle & Oracle client must be installed on ansible controller before executing this playbook.
# Playbook name: ansible_oracle_aix/parameter-task.yml
# Change directory to ansible_oracle_aix
# ansible-playbook parameter-task.yml
# The following task will get executed.

  tasks:
    - oracle_parameter:
            hostname: "{{ hostname }}"
            service_name: "{{ service_name }}"
            port: "{{ listener_port }}"
            user: "{{ db_user }}"
            password: "{{ db_password_cdb }}"
            mode: "{{ db_mode }}"
            name: "{{ param_name }}"
            value: "{{ param_value }}"
            state: "{{ state }}"
      environment: "{{ oracle_env }}"
      register: parameter

    - debug:
        var: parameter

# Sample output:
================

[ansible@x134vm232 ansible_oracle_aix]$ ansible-playbook parameter-task.yml
[WARNING]: Found variable using reserved name: name

PLAY [localhost] **********************************************************************************************************************

TASK [Gathering Facts] ****************************************************************************************************************
ok: [localhost]

TASK [oracle_parameter] ***************************************************************************************************************
[WARNING]: The value 1521 (type int) in a string field was converted to '1521' (type string). If this does not look like what you
expect, quote the entire value to ensure it does not change.
changed: [localhost]

TASK [debug] **************************************************************************************************************************
ok: [localhost] => {
    "parameter": {
        "changed": true,
        "failed": false,
        "msg": "The parameter (log_archive_dest_state_2) has been changed successfully, new: defer, old: enable",
        "warnings": [
            "The value 1521 (type int) in a string field was converted to '1521' (type string). If this does not look like what you expect, quote the entire value to ensure it does not change."
        ]
    }
}

PLAY RECAP ****************************************************************************************************************************
localhost                  : ok=3    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
