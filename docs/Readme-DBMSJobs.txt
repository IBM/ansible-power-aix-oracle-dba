# Manage DBMS jobs - Readme 
# =========================
# Description: This module is used to Create & schedule DBMS jobs. It uses a python library located here: ansible-power-aix-oracle-dba/library/oracle_job
# More information on what DBMS jobs is can be found here: https://docs.oracle.com/database/121/ARPLS/d_job.htm#ARPLS019

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
listener_port: 1521			# Database listener port
oracle_db_home: /tmp/oracle_client	# Oracle Client location on the ansible controller.
oracle_env:
     ORACLE_HOME: "{{ oracle_db_home }}"
     LD_LIBRARY_PATH: "{{ oracle_db_home}}/lib"
     PATH: "{{ oracle_db_home}}/bin:$PATH:/usr/local/bin:/bin:/sbin:/usr/bin:/usr/sbin"

# Open the file ansible-power-aix-oracle-dba/roles/oradb_manage_job/defaults/main.yml and modify the variables.

service_name: db122cpdb            # Database service name
db_password_cdb: "{% if dbpasswords is defined and dbpasswords[item[1].cdb] is defined and dbpasswords[item[1].cdb][db_user] is defined%}{{dbpasswords[item[1].cdb][db_user]}}{% else %}{{ default_dbpass}}{% endif%}"
db_password_pdb: "{% if dbpasswords is defined and dbpasswords[item[1].cdb] is defined and dbpasswords[item[1].cdb][db_user] is defined%}{{dbpasswords[item[1].cdb][db_user]}}{% else %}{{ default_dbpass}}{% endif%}"
state: present                     # present - creates a job, absent - drops a job.
enabled: True                      # True - Enables the job, False, Disables the job.
job_name: ansiuser1.ansi_job       # Job name along with schema name prefixed.
job_action: ansiuser1.PKG_TEST_SCHEDULER.JOB_PROC_STEP_1   # Job action
job_type: stored_procedure         # Type of the job
repeat_interval: FREQ=MINUTELY;INTERVAL=35 # Job interval

# Executing the playbook: This playbook executes a role.
# Change directory to ansible-power-aix-oracle-dba/playbooks
# Name of the Playbook: manage-job.yml
# ansible-playbook manage-job.yml
# The following task will get executed which will call out a role.

- hosts: localhost
  connection: local
  pre_tasks:
   - name: include variables
     include_vars:
       dir: vars
       extensions:
         - 'yml'
  roles:
     - { role: ibm.power_aix_oracle_dba.oradb_manage_job }

# Sample output:
================

[ansible@DESKTOP-DS5BJC2 playbooks]$ ansible-playbook manage-job.yml --ask-vault-pass
Vault password:
[WARNING]: Found both group and host with same name: ansible_db
[WARNING]: running playbook inside collection ibm.power_aix_oracle_dba

PLAY [localhost] ********************************************************************************************************************

TASK [Gathering Facts] **************************************************************************************************************
ok: [localhost]

TASK [include variables] ************************************************************************************************************
ok: [localhost]

TASK [Create Job] *********************************************************************************************************************
[WARNING]: Module did not set no_log for password
changed: [localhost]

TASK [debug] **************************************************************************************************************************
ok: [localhost] => {
    "job": {
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
