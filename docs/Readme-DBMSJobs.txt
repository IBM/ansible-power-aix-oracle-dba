# Manage DBMS jobs - Readme 
# =========================
# Description: This module is used to Create & schedule DBMS jobs. It uses a python library located here: ansible-power-aix-oracle-dba/library/oracle_job
# More information on what DBMS jobs is can be found here: https://docs.oracle.com/database/121/ARPLS/d_job.htm#ARPLS019

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

# Set the Variables for Oracle: Open the file ansible-power-aix-oracle-dba/roles/oradb_manage_job/defaults/main.yml and modify the variables.

hostname: ansible_db               # Aix Lpar hostname where the database is running
service_name: db122cpdb            # Database service name
db_password_cdb: "{% if dbpasswords is defined and dbpasswords[item[1].cdb] is defined and dbpasswords[item[1].cdb][db_user] is defined%}{{dbpasswords[item[1].cdb][db_user]}}{% else %}{{ default_dbpass}}{% endif%}"
db_password_pdb: "{% if dbpasswords is defined and dbpasswords[item[1].cdb] is defined and dbpasswords[item[1].cdb][db_user] is defined%}{{dbpasswords[item[1].cdb][db_user]}}{% else %}{{ default_dbpass}}{% endif%}"
listener_port: 1521                # Listener port number
state: present                     # present - creates a job, absent - drops a job.
enabled: True                      # True - Enables the job, False, Disables the job.
job_name: ansiuser1.ansi_job       # Job name along with schema name prefixed.
job_action: ansiuser1.PKG_TEST_SCHEDULER.JOB_PROC_STEP_1   # Job action
job_type: stored_procedure         # Type of the job
repeat_interval: FREQ=MINUTELY;INTERVAL=35 # Job interval
oracle_env:
  ORACLE_HOME: /home/ansible/oracle_client # Oracle client s/w path on Ansible controller.
  LD_LIBRARY_PATH: /home/ansible/oracle_client/lib # Oracle client library path on Ansible controller.

# Executing the playbook: This playbook executes a role.
# Change directory to ansible-power-aix-oracle-dba/playbooks
# Name of the Playbook: manage-jobs.yml
# ansible-playbook manage-jobs.yml
# The following task will get executed which will call out a role.

- hosts: localhost
  connection: local
  pre_tasks:
     - name: include variables
       include_vars: vars.yml
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
