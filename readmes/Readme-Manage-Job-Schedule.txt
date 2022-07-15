# Manage DBMS_SCHEDULER job schedules in Oracle database - Readme
# ===============================================================

# Description: # This module is used to manage DBMS job schedules. It uses a python library located here: ansible-power-aix-oracle-dba/library/oracle_jobschedule.
# Reference: https://docs.oracle.com/database/121/ADMIN/scheduse.htm#ADMIN12674
# Playbook: ansible-power-aix-oracle-dba/job-schedule-task.yml

# Prerequisites:
# ==============
# Set the Variables for Oracle to execute this task: Open the file ansible-power-aix-oracle-dba/job-schedule-task.yml and modify the variables under "vars" section. Do NOT change other sections of the file.


  vars:

     name: Global Variables
     hostname: ansible_db			# AIX hostname.
     service_name: db122cpdb			# DB service name.
     db_user: sys
     db_password_cdb: oracle			# Sys user password.
     listener_port: 1521			# DB port number.
     db_mode: sysdba
     state: present
     enabled: True				# True|False
     repeat_interval: FREQ=MINUTELY;INTERVAL=30	# Schedule interval
     convert_to_upper: True			
     comments: This is test
     schedule_name: ansiuser1.ansi_schedule	# Job Schedule Name
     oracle_env:
       ORACLE_HOME: /home/ansible/oracle_client		# Oracle client s/w path on Ansible controller.
       LD_LIBRARY_PATH: /home/ansible/oracle_client/lib	# Oracle client library path on Ansible controller.

# Executing the playbook: This playbook runs using a single file where it contain both Oracle related variables as well as ansible task. The connection mode will be "local". The cx_Oracle & Oracle client must be installed on ansible controller before executing this playbook.
# Playbook name: ansible-power-aix-oracle-dba/job-schedule-task.yml
# Change directory to ansible-power-aix-oracle-dba
# ansible-playbook job-schedule-task.yml
# The following task will get executed.

   - name: Create Job
     oracle_jobschedule:
       hostname: "{{ hostname }}"
       service_name: "{{ service_name }}"
       port: "{{ listener_port }}"
       user: "{{ db_user }}"
       password: "{{ db_password_cdb }}"
       mode: "{{ db_mode }}"
       state: "{{ state }}"
       repeat_interval: "{{ repeat_interval }}"
       convert_to_upper: "{{ convert_to_upper }}"
       comments: "{{ comments }}"
       name: "{{ schedule_name }}"
     environment: "{{ oracle_env }}"
     register: job
   - debug:
       var: job
