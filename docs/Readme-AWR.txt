# Manage AWR retention policy  - Readme 
# =====================================

# Description: # This module is used to set/alter AWR retention policy. It uses python library located here: ansible-power-aix-oracle-dba/library/oracle_awr
# More information of what AWR policy is can be found here: https://docs.oracle.com/cd/E11882_01/server.112/e41573/autostat.htm#PFGRF94188

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

# Set the Variables for Oracle to execute this task: Open the file ansible-power-aix-oracle-dba/awr-task.yml and modify the variables under "vars" section. Do NOT change other sections of the file.

hostname: ansible_db               # AIX hostname.
service_name: ansible.pbm.ihost.com        # DB service name.
db_user: sys
db_password_cdb: "{% if dbpasswords is defined and dbpasswords[item[1].cdb] is defined and dbpasswords[item[1].cdb][db_user] is defined%}{{dbpasswords[item[1].cdb][db_user]}}{% else %}{{ default_dbpass}}{% endif%}"
db_password_pdb: "{% if dbpasswords is defined and dbpasswords[item[1].cdb] is defined and dbpasswords[item[1].cdb][db_user] is defined%}{{dbpasswords[item[1].cdb][db_user]}}{% else %}{{ default_dbpass}}{% endif%}"
listener_port: 1521                # DB port number.
db_mode: sysdba
interval: 0               # Snapshot interval (in minutes). '0' disables.
retention: 15              # Snapshot Retention period (in days)
oracle_env:
  ORACLE_HOME: /home/ansible/oracle_client		# Oracle client s/w path on Ansible controller.
  LD_LIBRARY_PATH: /home/ansible/oracle_client/lib	# Oracle client library path on Ansible controller.

# Executing the playbook: This playbook executes a role.
# Change directory to ansible-power-aix-oracle-dba/playbooks
# Playbook name: manage-awr.yml
# ansible-playbook manage-awr.yml --ask-vault-pass
# The following task will get executed.

- hosts: localhost
  connection: local
  pre_tasks:
     - name: include variables
       include_vars: vars.yml
  roles:
     - { role: ibm.power_aix_oracle_dba.oradb_manage_awr }

# Sample output:
================

[ansible@x134vm232 ansible-power-aix-oracle-dba]$ ansible-playbook awr-task.yml --ask-vault-pass
Vault password:
[WARNING]: Found variable using reserved name: name

PLAY [localhost] **********************************************************************************************************************

TASK [Gathering Facts] ****************************************************************************************************************
ok: [localhost]

TASK [Modify AWR settings] ************************************************************************************************************
[WARNING]: Module did not set no_log for password
changed: [localhost]

TASK [debug] **************************************************************************************************************************
ok: [localhost] => {
    "awr": {
        "changed": true,
        "failed": false,
        "msg": "",
        "warnings": [
            "Module did not set no_log for password"
        ]
    }
}

PLAY RECAP ****************************************************************************************************************************
localhost                  : ok=3    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
