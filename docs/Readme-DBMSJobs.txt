# Manage DBMS jobs - Readme 
# =========================
# Description: This module is used to Create & schedule DBMS jobs. It uses a python library located here: power-aix-oracle-dba/library/oracle_job
# More information on what DBMS jobs is can be found here: https://docs.oracle.com/database/121/ARPLS/d_job.htm#ARPLS019

# Prerequisites:
# ==============
# Passwordless ssh needs to be setup between the Target lpar oracle owner and ansible controller user.

# Set the Variables for Oracle to execute this task: Open the file power-aix-oracle-dba/job-task.yml and modify the variables under "vars" section. Do NOT change other sections of the file.

name: Global Variables
hostname: ansible_db               # Aix Lpar hostname where the database is running
service_name: db122cpdb            # Database service name
db_password_cdb: oracle            # sys user password
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

# Executing the playbook: This playbook runs using a single file where it contain both Oracle related variables as well as ansible task. The connection mode will be "local". The cx_Oracle & Oracle client must be installed on ansible controller before executing this playbook.
# Change directory to power-aix-oracle-dba
# Name of the Playbook: job-task.yml
# ansible-playbook job-task.yml
# The following task will get executed.

   - name: Create Job
     oracle_job:
       hostname: "{{ hostname }}"
       service_name: "{{ service_name }}"
       port: "{{ listener_port }}"
       user: "{{ db_user }}"
       password: "{{ db_password_cdb }}"
       mode: "{{ db_mode }}"
       state: "{{ state }}"
       enabled: "{{ enabled }}"
       job_name: "{{ job_name }}"
       job_action: "{{ job_action }}"
       job_type: "{{ job_type }}"
       repeat_interval: "{{ repeat_interval }}"
     environment: "{{ oracle_env }}"
     register: job
   - debug:
       var: job

# Sample output:
================

[ansible@x134vm232 power-aix-oracle-dba]$ ansible-playbook job-task.yml
[WARNING]: Found variable using reserved name: name

PLAY [localhost] **********************************************************************************************************************

TASK [Gathering Facts] ****************************************************************************************************************
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