# Manage AWR retention policy  - Readme 
# =====================================

# Description: # This module is used to set/alter AWR retention policy. It uses python library located here: ansible-power-aix-oracle-dba/library/oracle_awr
# More information of what AWR policy is can be found here: https://docs.oracle.com/cd/E11882_01/server.112/e41573/autostat.htm#PFGRF94188

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

# Set the Variables for Oracle to execute this task:

# Open the file vars/vars.yml and set the following variables:

hostname: ansible_db                    # AIX lpar hostname
listener_port: 1521                     # Database port number
oracle_db_home: /tmp/oracle_client      # Oracle Client location on the ansible controller.
oracle_env:
     ORACLE_HOME: "{{ oracle_db_home }}"
     LD_LIBRARY_PATH: "{{ oracle_db_home}}/lib"
     PATH: "{{ oracle_db_home}}/bin:$PATH:/usr/local/bin:/bin:/sbin:/usr/bin:/usr/sbin"

# Open the file ansible-power-aix-oracle-dba/awr-task.yml and modify the variables under "vars" section. Do NOT change other sections of the file.

service_name: ansible.pbm.ihost.com        # DB service name.
db_user: sys
db_password_cdb: "{% if dbpasswords is defined and dbpasswords[item[1].cdb] is defined and dbpasswords[item[1].cdb][db_user] is defined%}{{dbpasswords[item[1].cdb][db_user]}}{% else %}{{ default_dbpass}}{% endif%}"
db_password_pdb: "{% if dbpasswords is defined and dbpasswords[item[1].cdb] is defined and dbpasswords[item[1].cdb][db_user] is defined%}{{dbpasswords[item[1].cdb][db_user]}}{% else %}{{ default_dbpass}}{% endif%}"
db_mode: sysdba
interval: 0               # Snapshot interval (in minutes). '0' disables.
retention: 15              # Snapshot Retention period (in days)

# Executing the playbook: This playbook executes a role.
# Change directory to ansible-power-aix-oracle-dba/playbooks
# Playbook name: manage-awr.yml
# ansible-playbook manage-awr.yml --ask-vault-pass
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
