# Manage Database directories  - Readme 
# =====================================

# Description: # This module is used to create/drop database directories. It uses python library located here: ansible-power-aix-oracle-dba/library/oracle_directory
# More information on Create directory can be found here: https://docs.oracle.com/cd/B19306_01/server.102/b14200/statements_5007.htm
# More information on Drop directory can be found here: https://docs.oracle.com/cd/B19306_01/server.102/b14200/statements_8012.htm

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

# Set the Variables for Oracle to execute this task: Open the file ansible-power-aix-oracle-dba/roles/oradb_manage_directories/defaults/main.yml and modify the variables

     hostname: ansible_db                       # AIX Lpar hostname.
     service_name: db122c                       # Service name for the database where the directory needs to be created.
     db_user: sys
     listener_port: 1521                        # Database listener port number.
     db_mode: sysdba
     directory_name: TESTDIR                    # Desired directory name to be created.
     path: /u01/testdir                         # Path to which the database directory is to be created. This must be created manually.
     state: present                             # To create a directory - present. To drop a directory - absent.
     mode: enforce
     oracle_env:
      ORACLE_HOME: /home/ansible/oracle_client          # Oracle Client Home on Ansible Controller.
      LD_RUN_PATH: /home/ansible/oracle_client/lib      # Oracle Client Home Library on Ansible Controller.

# Executing the playbook: This playbook executes a role. Before running the playbook, open the playbook and update the hostname & remote user details as shown below. Do NOT change other parts of the script.
# Change directory to ansible-power-aix-oracle-dba/playbooks
# Name of the Playbook: manage-db-directories.yml
# Content of the playbook

[ansible@DESKTOP-DS5BJC2 playbooks]$ cat manage-db-directories.yml
- hosts: localhost
  connection: local
  pre_tasks:
     - name: include variables
       include_vars: vars.yml
  roles:
     - { role: ibm.power_aix_oracle_dba.oradb_manage_directories }

# ansible-playbook manage-db-directories.yml --ask-vault-pass


# Sample output:
================

[ansible@localhost playbooks]$ ansible-playbook manage-db-directories.yml --ask-vault-pass
Vault password:
[WARNING]: Found both group and host with same name: ansible_db
[WARNING]: running playbook inside collection ibm.power_aix_oracle_dba

PLAY [localhost] ********************************************************************************************************************

TASK [Gathering Facts] **************************************************************************************************************
ok: [localhost]

TASK [include variables] ************************************************************************************************************
ok: [localhost]

TASK [ibm.power_aix_oracle_dba.oradb_manage_directories : Create Directory] *********************************************************
changed: [localhost]

TASK [ibm.power_aix_oracle_dba.oradb_manage_directories : debug] ********************************************************************
ok: [localhost] => {
    "crdir": {
        "changed": true,
        "failed": false,
        "msg": "Directory: TESTDIR, created with path: /u01/testdir"
    }
}

TASK [ibm.power_aix_oracle_dba.oradb_manage_directories : Drop Directory] ***********************************************************
skipping: [localhost]

TASK [ibm.power_aix_oracle_dba.oradb_manage_directories : debug] ********************************************************************
ok: [localhost] => {
    "deldir": {
        "changed": false,
        "skip_reason": "Conditional result was False",
        "skipped": true
    }
}

PLAY RECAP **************************************************************************************************************************
localhost                  : ok=5    changed=1    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0
