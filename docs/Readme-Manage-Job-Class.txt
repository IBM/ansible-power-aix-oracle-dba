# Manage DBMS_SCHEDULER job classes in Oracle database - Readme
# =============================================================

# Description: # This module is used to manage DBMS job Classes. It uses a python library located here: power-aix-oracle-dba/library/oracle_jobclass.
# Reference: https://docs.oracle.com/database/121/ADMIN/scheduse.htm#ADMIN12674
# Playbook: power-aix-oracle-dba/job-class-task.yml

# Prerequisites:
# ==============
# Set the Variables for Oracle to execute this task: Open the file power-aix-oracle-dba/job-class-task.yml and modify the variables under "vars" section. Do NOT change other sections of the file.

---
- hosts: localhost
  connection: local
  vars:

     name: Global Variables		
     hostname: ansible_db			# AIX hostname.
     service_name: db122cpdb			# DB service name.
     db_user: sys
     db_password_cdb: oracle			# Sys user password.
     listener_port: 1521			# DB port number.
     db_mode: sysdba
     state: present
     resource_group: ansigroup1			# Resource group name
     class_name: ansiclass			# Class name
     logging: failed runs			# logging
     history: 14				# History
     oracle_env:
       ORACLE_HOME: /home/ansible/oracle_client			# Oracle client s/w path on Ansible controller.
       LD_LIBRARY_PATH: /home/ansible/oracle_client/lib		# Oracle client library path on Ansible controller.

# Executing the playbook: This playbook runs using a single file where it contain both Oracle related variables as well as ansible task. The connection mode will be "local". The cx_Oracle & Oracle client must be installed on ansible controller before executing this playbook.
# Playbook name: power-aix-oracle-dba/job-class-task.yml
# Change directory to power-aix-oracle-dba
# ansible-playbook job-class-task.yml
# The following task will get executed.

   - name: Oracle Job Class
     oracle_jobclass:
       hostname: "{{ hostname }}"
       service_name: "{{ service_name }}"
       port: "{{ listener_port }}"
       user: "{{ db_user }}"
       password: "{{ db_password_cdb }}"
       mode: "{{ db_mode }}"
       state: "{{ state }}"
       resource_group: "{{ resource_group }}"
       name: "{{ class_name }}"
       logging: "{{ logging }}"
       history: "{{ history }}"
     environment: "{{ oracle_env }}"
     register: jobclass
   - debug:
       var: jobclass