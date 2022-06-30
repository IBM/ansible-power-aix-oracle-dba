# Manage Manage DBMS_RESOURCE_MANAGER consumer groups - Readme
# ============================================================

# Description: # This module is used to manage DBMS job Classes. It uses a python library located here: ansible_oracle_aix/library/oracle_rsrc_consgroup.
# Reference: https://docs.oracle.com/cd/E11882_01/server.112/e25494/dbrm.htm#ADMIN027
# Playbook: ansible_oracle_aix/resource-consumer-group-task.yml

     name: Global Variables
     hostname: ansible_db					# AIX hostname.
     service_name: db122cpdb					# DB service name.
     db_user: sys
     db_password_cdb: oracle					# Sys user password.
     listener_port: 1521					# DB port number.
     db_mode: sysdba
     state: present						# present|absent
     consumer_group: ansigroup1					# Desired group name for identification.
     comments:  This is a test consumer resource group
     grant:
        - ANSIUSER1						# List of users and roles that will be granted switch to this consumer group
     map_oracle_user:
        - ANSIUSER1						# This procedure adds, deletes, or modifies entries that map sessions to consumer groups, based on the session's login and runtime attributes.
     map_service_name:
        - db122cpdb
     map_client_machine:
        - x134vm236
     oracle_env:
       ORACLE_HOME: /home/ansible/oracle_client			# Oracle client s/w path on Ansible controller.
       LD_LIBRARY_PATH: /home/ansible/oracle_client/lib		# Oracle client library path on Ansible controller.

# Executing the playbook: This playbook runs using a single file where it contain both Oracle related variables as well as ansible task. The connection mode will be "local". The cx_Oracle & Oracle client must be installed on ansible controller before executing this playbook.
# Playbook name: ansible_oracle_aix/resource-consumer-group-task.yml
# Change directory to ansible_oracle_aix
# ansible-playbook resource-consumer-group-task.yml
# The following task will get executed.

   - name: Resource Consumer Groups
     oracle_rsrc_consgroup:
       hostname: "{{ hostname }}"
       service_name: "{{ service_name }}"
       port: "{{ listener_port }}"
       user: "{{ db_user }}"
       password: "{{ db_password_cdb }}"
       mode: "{{ db_mode }}"
       name: ansigroup1
       state: "{{ state }}"
       comments: This is a test consumer resource group
       grant: "{{ grant }}"
       map_oracle_user: "{{ map_oracle_user }}"
       map_service_name: "{{ map_service_name }}"
       map_client_machine: "{{ map_client_machine }}"
     environment: "{{ oracle_env }}"
     register: rsc
   - debug:
       var: rsc
