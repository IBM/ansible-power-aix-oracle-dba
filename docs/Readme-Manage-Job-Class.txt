# Manage DBMS_SCHEDULER job classes in Oracle database - Readme
# =============================================================

# Description: # This module is used to manage DBMS job Classes. It uses a python library located here: ansible-power-aix-oracle-dba/library/oracle_jobclass.
# Reference: https://docs.oracle.com/database/121/ADMIN/scheduse.htm#ADMIN12674

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

# Set the Variables for Oracle: 

# Open the file vars/vars.yml and set the following variables:

hostname: ansible_db                    # AIX lpar hostname
listener_port: 1521                     # Database port number
oracle_db_home: /tmp/oracle_client      # Oracle Client location on the ansible controller.
oracle_env:
     ORACLE_HOME: "{{ oracle_db_home }}"
     LD_LIBRARY_PATH: "{{ oracle_db_home}}/lib"
     PATH: "{{ oracle_db_home}}/bin:$PATH:/usr/local/bin:/bin:/sbin:/usr/bin:/usr/sbin"

# Open the file ansible-power-aix-oracle-dba/roles/oradb_manage_jobclass/defaults/main.yml and modify the variables.

service_name: db122cpdb			# DB service name.
db_user: sys
db_password_cdb: "{% if dbpasswords is defined and dbpasswords[item[1].cdb] is defined and dbpasswords[item[1].cdb][db_user] is defined%}{{dbpasswords[item[1].cdb][db_user]}}{% else %}{{ default_dbpass}}{% endif%}"
db_password_pdb: "{% if dbpasswords is defined and dbpasswords[item[1].cdb] is defined and dbpasswords[item[1].cdb][db_user] is defined%}{{dbpasswords[item[1].cdb][db_user]}}{% else %}{{ default_dbpass}}{% endif%}"
db_mode: sysdba
state: present
resource_group: ansigroup1			# Resource group name
class_name: ansiclass			# Class name
logging: failed runs			# logging
history: 14				# History

# Executing the playbook: This playbook executes a role.
# Playbook name: manage-jobclass.yml
# Change directory to ansible-power-aix-oracle-dba/playbooks
# ansible-playbook manage-jobclass.yml --ask-vault-pass
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
     - { role: ibm.power_aix_oracle_dba.oradb_manage_jobclass }
