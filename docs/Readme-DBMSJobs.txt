# Manage DBMS jobs - Readme 
# =========================
# Description: This module is used to Create & schedule DBMS jobs. 
# More information on what DBMS jobs is can be found here: https://docs.oracle.com/database/121/ARPLS/d_job.htm#ARPLS019

In the following example we're going to create a DBMS Scheduler Job called ANSI_JOB under TESTUSER1.

1. There are two files which need to be updated:
        a. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/manage-job-vars.yml: This file contains database hostname, database port number and the path to the Oracle client and other related parameters.
        b. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/vault.yml: This contains sys password which will be used by cx_oracle to connect to the database with sysdba privilege.

2. Update the common variables file: {{collection_dir}}/power_aix_oracle_dba/playbooks/vars/manage-job-vars.yml as shown below

hostname: ansible_db                           # AIX hostname where the Database is running.
service_name: devdb                            # Database service name.
listener_port: 1521                            # Database port number.
oracle_db_home: /home/ansible/oracle_client    # Oracle Instant Client path on the ansible controller.
job_name: testuser1.ansi_job                   # Job name along with schema name prefixed.
job_action: testuser1.PKG_TEST_SCHEDULER.JOB_PROC_STEP_1   # Job action
job_type: stored_procedure                     # Type of the job
repeat_interval: FREQ=MINUTELY;INTERVAL=35     # Job interval
state: present                                 # present - creates a job, absent - drops a job.
enabled: True                                  # True - Enables the job, False, Disables the job.

3. Update the passwords file: {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/vault.yml with sys user password. This file needs to be encrypted using ansible-vault. While running the playbook, please provide the vault password.
default_dbpass: Oracle4u # SYS password
default_gipass: Oracle4u # ASMSNMP password

4. Encrypt the passwords file using ansible-vault as shown below
$ ansible-vault encrypt vars/vault.yml
New Vault password:
Confirm New Vault password:
Encryption successful

5. Create the playbook in {{ collection_dir }}/power_aix_oracle_dba/playbooks directory as shown below
cat manage-awr.yml

- hosts: localhost
  connection: local
  vars_files:
   - vars/vault.yml
   - vars/manage-job-vars.yml
  roles:
     - { role: oradb_manage_job }

6. Execute the playbook as shown below
$ ansible-playbook manage-job.yml -i inventory.yml --ask-vault-pass
Vault password:

PLAY [localhost] **********************************************************************************************************************

TASK [oradb_manage_job : Create Job] *************************************************************************
[WARNING]: Module did not set no_log for password
changed: [localhost]

PLAY RECAP ****************************************************************************************************************************
localhost                  : ok=1    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

To execute this playbook from GUI, please refer this link: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
