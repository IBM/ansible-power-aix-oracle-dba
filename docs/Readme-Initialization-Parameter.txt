# Manage Initialization Parameters - Readme
# =========================================

# Description: # This module is used to set/alter & unset database initialization parameters. It uses a python library located here: ansible-power-aix-oracle-dba/library/oracle_parameter.
# Playbook: ansible-power-aix-oracle-dba/parameter-task.yml
# More information of what AWR policy is can be found here: https://docs.oracle.com/en/database/oracle/oracle-database/19/refrn/initialization-parameters-2.html#GUID-FD266F6F-D047-4EBB-8D96-B51B1DCA2D61
https://docs.oracle.com/en/database/oracle/oracle-database/19/admin/creating-and-configuring-an-oracle-database.html#GUID-2004E26A-3C24-4D0C-9EF4-F2854BCD6664

# Prerequisites:
# ==============
# Passwordless ssh needs to be setup between the Target lpar oracle owner and ansible controller user.

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

# Set the Variables for Oracle: Open the file ansible-power-aix-oracle-dba/oradb_manage_directories/defaults/main.yml and modify the variables.

hostname: ansible_db               # AIX hostname.
service_name: ansible.pbm.ihost.com              # DB service name.
db_user: sys
db_password_cdb: "{% if dbpasswords is defined and dbpasswords[item[1].cdb] is defined and dbpasswords[item[1].cdb][db_user] is defined%}{{dbpasswords[item[1].cdb][db_user]}}{% else %}{{ default_dbpass}}{% endif%}"
db_password_pdb: "{% if dbpasswords is defined and dbpasswords[item[1].cdb] is defined and dbpasswords[item[1].cdb][db_user] is defined%}{{dbpasswords[item[1].cdb][db_user]}}{% else %}{{ default_dbpass}}{% endif%}"
listener_port: 1521                # DB port number.
db_mode: sysdba
param_name: log_archive_dest_state_2       # Initialization Parameter Name
param_value: defer                         # Initialization Parameter Value
state: present                              # Initialization Parameter state: present - sets the value, absent/reset - disables the parameter
oracle_env:
  ORACLE_HOME: /home/ansible/oracle_client         # Oracle client s/w path on Ansible controller.
  LD_LIBRARY_PATH: /home/ansible/oracle_client/lib # Oracle client library path on Ansible controller.

# Executing the playbook: This playbook executes a role.
# Name of the Playbook: manage-init-parameters.yml
# Change directory to ansible-power-aix-oracle-dba/playbooks
# ansible-playbook manage-init-parameters.yml --ask-vault-pass
# The following task will be executed which will call out a role.

- hosts: localhost
  connection: local
  pre_tasks:
     - name: include variables
       include_vars: vars.yml
  roles:
     - { role: ibm.power_aix_oracle_dba.oradb_manage_initparams }

# Sample Output:
================

[ansible@localhost playbooks]$ ansible-playbook manage-init-parameters.yml --ask-vault-pass
Vault password:
[WARNING]: Found both group and host with same name: ansible_db
[WARNING]: running playbook inside collection ibm.power_aix_oracle_dba

PLAY [localhost] ********************************************************************************************************************

TASK [Gathering Facts] **************************************************************************************************************
ok: [localhost]

TASK [include variables] ************************************************************************************************************
ok: [localhost]

TASK [ibm.power_aix_oracle_dba.oradb_manage_initparams : oracle_parameter] **********************************************************
changed: [localhost]

TASK [ibm.power_aix_oracle_dba.oradb_manage_initparams : debug] *********************************************************************
ok: [localhost] => {
    "parameter": {
        "changed": true,
        "failed": false,
        "msg": "The parameter (log_archive_dest_state_2) has been changed successfully, new: defer, old: enable"
    }
}

PLAY RECAP **************************************************************************************************************************
localhost                  : ok=4    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
