# Gather global statistics - Readme
# =================================
# Description: This module is used to gather global statistics of the database. It uses a python library located here: ansible-power-aix-oracle-dba/library/oracle_awr
# More information on what Global Statistics is can be found here: https://docs.oracle.com/database/121/ARPLS/d_stats.htm?msclkid=316b7042ab3411eca76cd2c34e98f515#ARPLS059

# Prerequisites:
# ==============
# Passwordless ssh needs to be setup between the Target lpar oracle owner and ansible controller user.

# Set the Variables for Oracle to execute this task: Open the file ansible-power-aix-oracle-dba/globalstats-task.yml and modify the variables under "vars" section. Do NOT change other sections of the file.

name: Global Variables
hostname: ansible_db		# AIX lpar hostname
service_name: db122c		# Database service name in which we're setting AWR retention policy.
db_user: sys
db_password_cdb: oracle		# Sys user password 
listener_port: 1521		# Listener port number
db_mode: sysdba
preference_name: CONCURRENT	# preference name (refer documentation)
preference_value: ALL		# preference type (refer documentation)
state: present			# State: present / absent
oracle_env:
  ORACLE_HOME: /home/ansible/oracle_client		# Oracle client s/w path on Ansible controller.
  LD_LIBRARY_PATH: /home/ansible/oracle_client/lib	# Oracle client library path on Ansible controller.

# Executing the playbook: This playbook runs using a single file where it contain both Oracle related variables as well as ansible task. The connection mode will be "local". The cx_Oracle & Oracle client must be installed on ansible controller before executing this playbook.
# Name of the Playbook: ansible-power-aix-oracle-dba/globalstats-task.yml
# Change directory to ansible-power-aix-oracle-dba
# ansible-playbook globalstats-task.yml
# The following task will get executed.

   - name: Manage Global preferences
     oracle_stats_prefs:
       hostname: "{{ hostname }}"
       service_name: "{{ service_name }}"
       port: "{{ listener_port }}"
       user: "{{ db_user }}"
       password: "{{ db_password_cdb }}"
       mode: "{{ db_mode }}"
       preference_name: "{{ preference_name }}"
       preference_value: "{{ preference_value }}"
       state: "{{ state }}"
     environment: "{{ oracle_env }}"
     register: stats
   - debug:
       var: stats

# Sample output:
================

[ansible@x134vm232 ansible-power-aix-oracle-dba]$ ansible-playbook globalstats-task.yml
[WARNING]: Found variable using reserved name: name

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

