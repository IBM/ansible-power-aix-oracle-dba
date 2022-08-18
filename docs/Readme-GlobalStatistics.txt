# Gather global statistics - Readme
# =================================
# Description: This module is used to gather global statistics of the database. It uses a python library located here: ansible-power-aix-oracle-dba/library/oracle_awr
# More information on what Global Statistics is can be found here: https://docs.oracle.com/database/121/ARPLS/d_stats.htm?msclkid=316b7042ab3411eca76cd2c34e98f515#ARPLS059

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

# Set the Variables for Oracle : Open the file ansible-power-aix-oracle-dba/roles/oradb_manage_stats/defaults/main.yml and modify the variables.

name: Global Variables
hostname: ansible_db		# AIX lpar hostname
service_name: db122c		# Database service name in which we're setting AWR retention policy.
db_user: sys
db_password_cdb: "{% if dbpasswords is defined and dbpasswords[item[1].cdb] is defined and dbpasswords[item[1].cdb][db_user] is defined%}{{dbpasswords[item[1].cdb][db_user]}}{% else %}{{ default_dbpass}}{% endif%}"
db_password_pdb: "{% if dbpasswords is defined and dbpasswords[item[1].cdb] is defined and dbpasswords[item[1].cdb][db_user] is defined%}{{dbpasswords[item[1].cdb][db_user]}}{% else %}{{ default_dbpass}}{% endif%}"
listener_port: 1521		# Listener port number
db_mode: sysdba
preference_name: CONCURRENT	# preference name (refer documentation)
preference_value: ALL		# preference type (refer documentation)
state: present			# State: present / absent
oracle_env:
  ORACLE_HOME: /home/ansible/oracle_client		# Oracle client s/w path on Ansible controller.
  LD_LIBRARY_PATH: /home/ansible/oracle_client/lib	# Oracle client library path on Ansible controller.

# Executing the playbook: This playbook executes a role.
# Name of the Playbook: manage-globalstats.yml
# Change directory to ansible-power-aix-oracle-dba/playbooks
# ansible-playbook manage-globalstats.yml --ask-vault-pass
# The following task will get executed.

- hosts: localhost
  connection: local
  pre_tasks:
     - name: include variables
       include_vars: vars.yml
  roles:
     - { role: ibm.power_aix_oracle_dba.oradb_manage_stats }

# Sample output:
================

[ansible@x134vm232 ansible-power-aix-oracle-dba]$ ansible-playbook globalstats-task.yml --ask-vault-pass
Vault password:

PLAY [localhost] **********************************************************************************************************************

TASK [Gathering Facts] ****************************************************************************************************************
ok: [localhost]

TASK [Manage Global preferences] ******************************************************************************************************
changed: [localhost]

TASK [debug] **************************************************************************************************************************
ok: [localhost] => {
    "stats": {
        "changed": true,
        "failed": false,
        "msg": "Old value OFF changed to ALL"
    }
}

PLAY RECAP ****************************************************************************************************************************
localhost                  : ok=3    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

