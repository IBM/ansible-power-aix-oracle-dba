# Manage AWR retention policy  - Readme 
# =====================================

# Description: # This module is used to set/alter AWR retention policy. It uses python library located here: ansible_oracle_aix/library/oracle_awr
# More information of what AWR policy is can be found here: https://docs.oracle.com/cd/E11882_01/server.112/e41573/autostat.htm#PFGRF94188

# Prerequisites:
# ==============
# Passwordless ssh needs to be setup between the Target lpar oracle owner and ansible controller user.

# Set the Variables for Oracle to execute this task: Open the file ansible_oracle_aix/awr-task.yml and modify the variables under "vars" section. Do NOT change other sections of the file.

name: Global Variables
hostname: ansible_db               # AIX hostname.
service_name: ansible.pbm.ihost.com        # DB service name.
db_user: sys
db_password_cdb: oracle            # Sys user password.
listener_port: 1521                # DB port number.
db_mode: sysdba
interval: 0               # Snapshot interval (in minutes). '0' disables.
retention: 15              # Snapshot Retention period (in days)
oracle_env:
  ORACLE_HOME: /home/ansible/oracle_client		# Oracle client s/w path on Ansible controller.
  LD_LIBRARY_PATH: /home/ansible/oracle_client/lib	# Oracle client library path on Ansible controller.

# Executing the playbook: This playbook runs using a single file where it contain both Oracle related variables as well as ansible task. The connection mode will be "local". Hence, the cx_Oracle & Oracle client must be installed on ansible controller which 
# Change directory to ansible_oracle_aix
# Playbook name: awr-task.yml
# ansible-playbook awr-task.yml
# The following task will get executed.

   - name: Modify AWR settings
     oracle_awr:
       hostname: "{{ hostname }}"
       service_name: "{{ service_name }}"
       port: "{{ listener_port }}"
       user: "{{ db_user }}"
       password: "{{ db_password_cdb }}"
       mode: "{{ db_mode }}"
       snapshot_interval_min: "{{ interval }}"
       snapshot_retention_days: "{{ retention }}"
     environment: "{{ oracle_env }}"
     register: awr
   - debug:
       var: awr

# Sample output:
================

[ansible@x134vm232 ansible_oracle_aix]$ ansible-playbook awr-task.yml
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