# Manage Database directories  - Readme 
# =====================================

# Description: # This module is used to create/drop database directories. It uses python library located here: ansible-power-aix-oracle-dba/library/oracle_directory
# More information on Create directory can be found here: https://docs.oracle.com/cd/B19306_01/server.102/b14200/statements_5007.htm
# More information on Drop directory can be found here: https://docs.oracle.com/cd/B19306_01/server.102/b14200/statements_8012.htm

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

# Setup the variables for Oracle:
# Open the file vars/vars.yml and set the following variables:

hostname: ansible_db                    # AIX lpar hostname
listener_port: 1521                     # Database port number
oracle_db_home: /tmp/oracle_client      # Oracle Client location on the ansible controller.
oracle_env:
     ORACLE_HOME: "{{ oracle_db_home }}"
     LD_LIBRARY_PATH: "{{ oracle_db_home}}/lib"
     PATH: "{{ oracle_db_home}}/bin:$PATH:/usr/local/bin:/bin:/sbin:/usr/bin:/usr/sbin"

# Open the file ansible-power-aix-oracle-dba/roles/oradb_manage_directories/defaults/main.yml and modify the variables.

     service_name: db122c                       # Service name for the database where the directory needs to be created.
     db_user: sys
     db_mode: sysdba
     directory_name: TESTDIR                    # Desired directory name to be created.
     path: /u01/testdir                         # Path to which the database directory is to be created. This must be created manually.
     state: present                             # To create a directory - present. To drop a directory - absent.
     mode: enforce

# Executing the playbook: This playbook executes a role. Before running the playbook, open the playbook and update the hostname & remote user details as shown below. Do NOT change other parts of the script.
# Change directory to ansible-power-aix-oracle-dba/playbooks
# Name of the Playbook: manage-db-directories.yml
# Content of the playbook

[ansible@DESKTOP-DS5BJC2 playbooks]$ cat manage-db-directories.yml
- hosts: localhost
  connection: local
  pre_tasks:
     - name: include variables
       include_vars:
         dir: vars
         extensions:
           - 'yml'
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
