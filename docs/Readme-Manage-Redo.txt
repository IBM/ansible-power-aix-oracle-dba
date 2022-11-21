# Manage Redo Logs - Readme
# =========================

# Description: This module is used to Create/Drop Redo logs which are on ASM.
# Support for this module on filesystem is not ready.
# It uses a python library: ansible-power-aix-oracle-dba/library/oracle_redo

# Prerequisites:
# ==============

# Go to the playbooks directory 
# Decrypt the file (if it's already encrypted)
# ansible-vault decrypt vars/vault.yml
Vault password:
Decryption successful
# Set SYS password for "default_dbpass" variable in ansible-power-aix-oracle-dba/playbooks/vars/vault.yml.
# Encrypt the file
# ansible-vault encrypt playbooks/vars/vault.yml
New Vault password:
Confirm New Vault password:
Encryption successful

# Set the Variables for Oracle to execute this task: 

hostname: ansible_db                    # AIX lpar hostname
listener_port: 1521                     # Database port number
oracle_db_home: /tmp/oracle_client      # Oracle Client location on the ansible controller.
oracle_env:
     ORACLE_HOME: "{{ oracle_db_home }}"
     LD_LIBRARY_PATH: "{{ oracle_db_home}}/lib"
     PATH: "{{ oracle_db_home}}/bin:$PATH:/usr/local/bin:/bin:/sbin:/usr/bin:/usr/sbin"

# Open the file ansible-power-aix-oracle-dba/roles/oradb_manage_redo/defaults/main.yml and modify the variables. Modify only the ones which are marked with comments.

db_user: sys
db_mode: sysdba
db_service_name: orcl           # DB service name
oracle_databases:
       redolog_groups: 2        # Number of additional redo log groups to add (If there are already 2 groups and need to create  2 more groups, set this value to 4. )
       redolog_size: 200M       # Redo log file size.
       state: present           # "present" - creates redo groups, "absent" - drops redo groups.

# Executing the playbook: This playbook executes a role. 
# Change directory to ansible-power-aix-oracle-dba/playbooks
# Name of the Playbook: manage-redo.yml
# Contents of playbook:

- hosts: localhost
  connection: local
  pre_tasks:
   - name: include variables
     include_vars:
       dir: vars
       extensions:
         - 'yml'
  roles:
     - { role: ibm.power_aix_oracle_dba.oradb_manage_redo }
     
# ansible-playbook manage-redo.yml --ask-vault-pass
