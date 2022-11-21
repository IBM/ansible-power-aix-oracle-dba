# Gather Grid Facts - Readme
# ==========================

# Description: # This module is used to gather facts about Grid infrastructure [Standalone or RAC].
# It gives information about local listener, scan, scan listener, clustername, databases registered in the cluster etc.

# Prerequisites:
# ==============
# Passwordless ssh needs to be setup between the Target lpar oracle owner and ansible controller user.

# Set the Variables for Oracle to execute this task: 

# Open the file ansible-power-aix-oracle-dba/oradb_gather_gifacts/defaults/main.yml and modify the variables.
oracle_env:
   ORACLE_HOME: /u01/grid19c                # Grid Home path on the remote lpar.
   LD_LIBRARY_PATH: /u01/grid19c/lib         # Grid Home Library path on the remote lpar.

# Executing the playbook: This playbook runs a role. 
# Name of the Playbook: gather-gi-facts.yml 
# ansible-playbook gather-gi-facts.yml
# The following task will get executed.

- hosts: ansihost               # Grid Host
  remote_user: oracle
  roles:
     - { role: oradb_gather_gifacts }
