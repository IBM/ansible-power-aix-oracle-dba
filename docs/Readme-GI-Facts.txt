# Gather Grid Facts - Readme
# ==========================

# Description: # This module is used to gather facts about Grid infrastructure [Standalone or RAC].
# It gives information about local listener, scan, scan listener, clustername, databases registered in the cluster etc.

# Prerequisites:
# ==============
# Passwordless ssh needs to be setup between the Target lpar oracle owner and ansible controller user.

# Set the Variables for Oracle to execute this task: Open the file ansible-power-aix-oracle-dba/gi-facts-task.yml and modify the variables under "vars" section. Do NOT change other sections of the file.

- hosts: rachosts                               # AIX LAPR hostname/groupname. The connection mode will be remote. Oracle environment variables on the remote lpar must be defined.
  remote_user: grid                             # Name of the Grid owner on the remote server.
  vars:
      oracle_env:
         ORACLE_HOME: /u01/app/19c/grid/                # Grid Home path on the remote lpar.
         LD_LIBRARY_PATH: /u01/app/19c/grid/lib         # Grid Home Library path on the remote lpar.

# Executing the playbook: This playbook runs using a single file where it contain both Oracle related variables as well as ansible task. The connection mode will be remote. Oracle environment variables on the remote lpar must be defined.
# Change directory to ansible-power-aix-oracle-dba
# Name of the Playbook: gi-facts-task.yml 
# ansible-playbook gi-facts-task.yml
# The following task will get executed.

  tasks:
    - name: Return GI facts
      oracle_gi_facts:
      environment: "{{ oracle_env }}"
      register: gifacts
    - debug:
       var: gifacts