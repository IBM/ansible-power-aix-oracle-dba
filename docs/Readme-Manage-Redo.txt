# Manage Redo Logs - Readme
# =========================

# Description: This module is used to Create/Drop Redo logs which are on ASM.
# Support for this module on filesystem is not ready.
# It uses a python library: power-aix-oracle-dba/library/oracle_redo

# Prerequisites:
# ==============
# Passwordless ssh needs to be setup between the Target lpar oracle owner and ansible controller user.

# Set the Variables for Oracle to execute this task: Open the file power-aix-oracle-dba/roles/oradb_manage_redo/defaults/main.yml and modify the variables. Modify only the ones which are marked with comments.

db_user: sys
db_mode: sysdba

db_service_name: orcl           # DB service name
listener_port: 1521     # Database Listen port
default_dbpass: oracle  # Sys user password

hostname: rac91                  # AIX Hostname or SCAN address in case of RAC.
oracle_databases:
       redolog_groups: 2        # Number of additional redo log groups to add (If there are already 2 groups and need to create  2 more groups, set this value to 4. )
       redolog_size: 200M       # Redo log file size.
       state: present           # "present" - creates redo groups, "absent" - drops redo groups.

# Executing the playbook: This playbook executes a role. 
# Change directory to power-aix-oracle-dba
# Name of the Playbook: manage-redo.yml
# Contents of playbook:

- hosts: localhost
  connection: local
  roles:
     - { role: oradb_manage_redo }
     
# ansible-playbook manage-redo.yml
