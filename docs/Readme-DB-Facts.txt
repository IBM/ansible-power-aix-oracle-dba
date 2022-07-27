# Gather Facts of a Database - Readme
# ===================================
# Description: This module is used to gather Facts about a Container/Pluggable or Non Multitenant database. It uses a python library located here: power-aix-oracle-dba/library/oracle_facts
# Lists out the parameters set, size of tablespaces, Archive log Sequence number, Is a CDB or no etc.

# Prerequisites:
# ==============
# Passwordless ssh needs to be setup between the Target lpar oracle owner and ansible controller user.

# Set the Variables for Oracle to execute this task: Open the file power-aix-oracle-dba/db-facts-task.yml and modify the variables under "vars" section. Do NOT change other sections of the file.

vars:
   hostname: ansible_db                               # AIX Hostname.
   service_name: db122c                               # Service name of a PDB or CDB, based on the requirement.
   db_user: sys
   db_password_cdb: oracle                            # SYS user password.
   listener_port: 1521                                # DB listener port.
   db_mode: sysdba
   oracle_env:
     ORACLE_HOME: /home/ansible/oracle_client         # Oracle client s/w path on Ansible controller.
     LD_LIBRARY_PATH: /home/ansible/oracle_client/lib # Oracle client library path on Ansible controller.

# Executing the playbook: This playbook runs using a single file where it contain both Oracle related variables as well as ansible task. The connection mode will be "local". The cx_Oracle & Oracle client must be installed on ansible controller before executing this playbook.
# Name of the Playbook: power-aix-oracle-dba/db-facts-task.yml
# Change directory to power-aix-oracle-dba
# ansible-playbook db-facts-task.yml
# The following task will get executed.
     
tasks:
 - name: gather database facts
   oracle_facts:
     hostname: "{{ hostname }}"
     port: "{{ listener_port }}"
     service_name: "{{ service_name }}"
     user: "{{ db_user }}"
     password: "{{ db_password_cdb }}"
     mode: "{{ db_mode }}"
   environment: "{{ oracle_env }}"
   register: dbfacts
 - debug:
     var: dbfacts
    
