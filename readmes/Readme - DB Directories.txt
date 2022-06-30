# Manage Database directories  - Readme 
# =====================================

# Description: # This module is used to create/drop database directories. It uses python library located here: ansible_oracle_aix/library/oracle_directory
# More information on Create directory can be found here: https://docs.oracle.com/cd/B19306_01/server.102/b14200/statements_5007.htm
# More information on Drop directory can be found here: https://docs.oracle.com/cd/B19306_01/server.102/b14200/statements_8012.htm

# Prerequisites:
# ==============
# Passwordless ssh needs to be setup between the Target lpar oracle owner and ansible controller user.

# Set the Variables for Oracle to execute this task: Open the file ansible_oracle_aix/db-directory-task.yml and modify the variables under "vars" section. Do NOT change other sections of the file.

   - name: Global Variables
     hostname: ansible_db                       # AIX Lpar hostname.
     service_name: db122c                       # Service name for the database where the directory needs to be created.
     db_user: sys
     db_password_cdb: oracle                    # Sys user password.
     listener_port: 1521                        # Database listener port number.
     db_mode: sysdba
     directory_name: TESTDIR                    # Desired directory name to be created.
     path: /u01/testdir                         # Path to which the database directory is to be created. This must be created manually.
     state: present                             # To create a directory - present. To drop a directory - absent.
     mode: enforce
     oracle_env:
      ORACLE_HOME: /home/ansible/oracle_client          # Oracle Client Home on Ansible Controller.
      LD_RUN_PATH: /home/ansible/oracle_client/lib      # Oracle Client Home Library on Ansible Controller.

# Executing the playbook: This playbook runs using a single file where it contain both Oracle related variables and ansible task. The connection mode will be "local". The cx_Oracle & Oracle client must be installed on ansible controller before executing this playbook.
# Playbook name: ansible_oracle_aix/db-directory-task.yml
# Change directory to ansible_oracle_aix
# ansible-playbook db-directory-task.yml

# The following task will get executed.

   - name: Create Directory
     oracle_directory:
           hostname: "{{ hostname }}"
           service_name: "{{ service_name }}"
           port: "{{ listener_port }}"
           user: "{{ db_user }}"
           password: "{{ db_password_cdb }}"
           mode: "{{ db_mode }}"
           directory_name: "{{ directory_name }}"
           directory_path: "{{ path }}"
           state: "{{ state }}"
           directory_mode: "{{ mode }}"
     register: crdir
     when: state == 'present'
     environment: "{{ oracle_env }}"
   - debug:
       var: crdir

   - name: Drop Directory
     oracle_directory:
           hostname: "{{ hostname }}"
           service_name: "{{ service_name }}"
           port: "{{ listener_port }}"
           user: "{{ db_user }}"
           password: "{{ db_password_cdb }}"
           mode: "{{ db_mode }}"
           directory_name: "{{ directory_name }}"
           directory_path: "{{ path }}"
           state: "{{ state }}"
           directory_mode: "{{ mode }}"
     register: deldir
     when: state == 'absent'
     environment: "{{ oracle_env }}"
   - debug:
       var: deldir

# Sample output to create a directory
=====================================

[ansible@x134vm232 ansible_oracle_aix]$ ansible-playbook db-directory-task.yml
[WARNING]: Found variable using reserved name: name

PLAY [localhost] **********************************************************************************************************************

TASK [Gathering Facts] ****************************************************************************************************************
ok: [localhost]

TASK [Create Directory] ***************************************************************************************************************
[WARNING]: The value 1521 (type int) in a string field was converted to '1521' (type string). If this does not look like what you
expect, quote the entire value to ensure it does not change.
changed: [localhost]

TASK [debug] **************************************************************************************************************************
ok: [localhost] => {
    "crdir": {
        "changed": true,
        "failed": false,
        "msg": "Directory: TESTDIR, created with path: /u01/testdir",
        "warnings": [
            "The value 1521 (type int) in a string field was converted to '1521' (type string). If this does not look like what you expect, quote the entire value to ensure it does not change."
        ]
    }
}

TASK [Drop Directory] *****************************************************************************************************************
skipping: [localhost]

TASK [debug] **************************************************************************************************************************
ok: [localhost] => {
    "deldir": {
        "changed": false,
        "skip_reason": "Conditional result was False",
        "skipped": true
    }
}

PLAY RECAP ****************************************************************************************************************************
localhost                  : ok=4    changed=1    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0
