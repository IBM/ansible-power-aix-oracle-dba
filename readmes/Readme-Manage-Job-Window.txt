# Manage DBMS_SCHEDULER job classes in Oracle database - Readme
# =============================================================

# Description: # This module is used to manage DBMS job Classes. It uses a python library located here: ansible-power-aix-oracle-dba/library/oracle_jobwindow.
# Reference: https://docs.oracle.com/database/121/ADMIN/scheduse.htm#ADMIN12674
# Playbook: ansible-power-aix-oracle-dba/job-window-task.yml

# Prerequisites:
# ==============
# Set the Variables for Oracle to execute this task: Open the file ansible-power-aix-oracle-dba/job-window-task.yml and modify the variables under "vars" section. Do NOT change other sections of the file.

  vars:

     name: Global Variables
     hostname: ansible_db						# AIX hostname.
     service_name: db122cpdb						# DB service name.
     db_user: sys
     db_password_cdb: oracle						# Sys user password.
     listener_port: 1521						# DB port number.
     db_mode: sysdba
     state: disabled     						# enabled, disabled, absent
     resource_plan: DEFAULT_MAINTENANCE_PLAN				
     window_name: ANSI_WINDOW						# Job Window Name
     interval: freq=daily;byday=SUN;byhour=6;byminute=0; bysecond=0	# Window interval
     comments: This is a window for Ansible testing
     duration_hour: 12							# Duration in hours
     oracle_env:
       ORACLE_HOME: /home/ansible/oracle_client				# Oracle client s/w path on Ansible controller.
       LD_LIBRARY_PATH: /home/ansible/oracle_client/lib			# Oracle client library path on Ansible controller.

# Executing the playbook: This playbook runs using a single file where it contain both Oracle related variables as well as ansible task. The connection mode will be "local". The cx_Oracle & Oracle client must be installed on ansible controller before executing this playbook.
# Playbook name: ansible-power-aix-oracle-dba/job-window-task.yml
# Change directory to ansible-power-aix-oracle-dba
# ansible-playbook job-window-task.yml
# The following task will get executed.

   - name: Oracle Job Window
     oracle_jobwindow:
       hostname: "{{ hostname }}"
       service_name: "{{ service_name }}"
       port: "{{ listener_port }}"
       user: "{{ db_user }}"
       password: "{{ db_password_cdb }}"
       mode: "{{ db_mode }}"
       state: "{{ state }}"
       resource_plan: "{{ resource_plan }}"
       name: "{{ window_name }}"
       interval: "{{ interval }}"
       comments: "{{ comments }}"
       duration_hour: "{{ duration_hour }}"
     environment: "{{ oracle_env }}"
     register: jobclass
   - debug:
       var: jobclass
