# Gather Facts of a Database - Readme
# ===================================
# Description: This module is used to gather Facts about a Container/Pluggable or Non Multitenant database. It uses a python library located here: ansible-power-aix-oracle-dba/library/oracle_facts
# Lists out the parameters set, size of tablespaces, Archive log Sequence number, Is a CDB or no etc.

# Prerequisites:
# ==============

# Go to the playbooks directory
# Decrypt the file (if it's already encrypted)
# ansible-vault decrypt vars/vault.yml
Vault password:
Decryption successful
# Set SYS password for "default_dbpass" variable in ansible-power-aix-oracle-dba/playbooks/vars/vault.yml.
# Encrypt the file
# ansible-vault encrypt vars/vault.yml
New Vault password:
Confirm New Vault password:
Encryption successful

# Setup the variables for Oracle:
# Open the file vars/vars.yml and set the following variables:

hostname: ansible_db			# AIX lpar hostname
listener_port: 1521			# Database port number
oracle_db_home: /tmp/oracle_client      # Oracle Client location on the ansible controller.
oracle_env:
     ORACLE_HOME: "{{ oracle_db_home }}"
     LD_LIBRARY_PATH: "{{ oracle_db_home}}/lib"
     PATH: "{{ oracle_db_home}}/bin:$PATH:/usr/local/bin:/bin:/sbin:/usr/bin:/usr/sbin"

# Open the file ansible-power-aix-oracle-dba/roles/oradb_gather_dbfacts/defaults/main.yml and modify the variables.

service_name: ansidb                               # Service name of a PDB or CDB.
db_user: sys
db_mode: sysdba

# Executing the playbook: This playbook runs using a single file where it contain both Oracle related variables as well as ansible task. The connection mode will be "local". The cx_Oracle & Oracle client must be installed on ansible controller before executing this playbook.
# Name of the Playbook: ansible-power-aix-oracle-dba/gather-db-facts.yml
# Change directory to ansible-power-aix-oracle-dba
# ansible-playbook gather-db-facts.yml --ask-vault-pass
# The following task will get executed.

- hosts: localhost
  connection: local
  pre_tasks:
   - name: include variables
     include_vars:
       dir: vars
       extensions:
         - 'yml'
  roles:
     - { role: oradb_gather_dbfacts } 
