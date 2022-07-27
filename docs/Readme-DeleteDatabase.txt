# Drop database - Readme
# ======================
# Description: This module is used to drop an Oracle database.
# Reference: https://docs.oracle.com/database/121/RACAD/GUID-17439B6B-6D3C-46AA-A585-94B636C708AC.htm

# Prerequisites:
# ==============
# Passwordless ssh needs to be setup between the Target lpar oracle owner and ansible controller user.

# Set the Variables for Oracle to execute this task: Open the file power-aix-oracle-dba/roles/oradb_delete/tasks/main.yml and modify the variables. Modify only the ones which are marked with comments.

oracle_home_db: "{% if item.0 is defined %}{% if item.0.oracle_home is defined %}{{ item.0.oracle_home}}{% else %}{{ oracle_base }}/{{ item.0.oracle_version_db }}/{{ item.0.home }}{% endif %}{% else %}{% if item.oracle_home is defined %}{{ item.oracle_home }}{% else %}{{ oracle_base }}/{{ item.oracle_version_db }}/{{ item.home }}{% endif %}{% endif %}"

oracle_databases:                                         
      - home: db12c2                                      	# 'Last' directory in ORACLE_HOME path (e.g /u01/app/oracle/12.1.0.2/racdb)
        oracle_version_db: 12.2.0.1                          	# Oracle version.
        oracle_home: /u01/db12.2c				# Oracle Home.
        oracle_db_name: db12c2                                 	# Database name to be dropped.
        oracle_db_passwd: Oracle123                          	# Sys user password
        state: absent						
        
# Executing the playbook: This playbook executes a role. Before running the playbook, open the playbook and update the hostname & remote user details as shown below. Do NOT change other parts of the script.
# Change directory to power-aix-oracle-dba
# Name of the Playbook: delete-db.yml
# Content of the playbook
        
- name: Drop a Database
  hosts: ansible_db                     # Target Lpar hostname.
  remote_user: oracle                   # Remote username.
  roles:
     - { role: oradb_delete }

# ansible-playbook delete-db.yml
