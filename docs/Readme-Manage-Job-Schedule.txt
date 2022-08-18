# Manage DBMS_SCHEDULER job schedules in Oracle database - Readme
# ===============================================================

# Description: # This module is used to manage DBMS job schedules. It uses a python library located here: ansible-power-aix-oracle-dba/library/oracle_jobschedule.
# Reference: https://docs.oracle.com/database/121/ADMIN/scheduse.htm#ADMIN12674
# Playbook: ansible-power-aix-oracle-dba/job-schedule-task.yml

# Prerequisites:
# ==============

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

# Set the Variables for Oracle to execute this task: Open the file ansible-power-aix-oracle-dba/job-schedule-task.yml and modify the variables under "vars" section. Do NOT change other sections of the file.

     hostname: ansible_db			# AIX hostname.
     service_name: db122cpdb			# DB service name.
     db_user: sys
     db_password_cdb: "{% if dbpasswords is defined and dbpasswords[item[1].cdb] is defined and dbpasswords[item[1].cdb][db_user] is defined%}{{dbpasswords[item[1].cdb][db_user]}}{% else %}{{ default_dbpass}}{% endif%}"
     db_password_pdb: "{% if dbpasswords is defined and dbpasswords[item[1].cdb] is defined and dbpasswords[item[1].cdb][db_user] is defined%}{{dbpasswords[item[1].cdb][db_user]}}{% else %}{{ default_dbpass}}{% endif%}"
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

# Executing the playbook: This playbook executes a role
# Playbook name: manage-job-schedule.yml
# Change directory to ansible-power-aix-oracle-dba/playbooks
# ansible-playbook job-schedule.yml --ask-vault-pass
# The following task will get executed.

- hosts: localhost
  connection: local
  pre_tasks:
     - name: include variables
       include_vars: vars.yml
  roles:
     - { role: ibm.power_aix_oracle_dba.oradb_manage_jobschedule }
