# Manage DBMS_SCHEDULER job classes in Oracle database - Readme
# =============================================================

# Description: # This module is used to manage DBMS Job Window. 
# More information can be found here: https://docs.oracle.com/database/121/ADMIN/scheduse.htm#ADMIN12674

In the following example we're going to create a DBMS Scheduler Job window called ANSI_WINDOW.

1. There are two files which need to be updated:
        a. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/manage-job-window-vars.yml: This file contains database hostname, database port number and the path to the Oracle client and other related parameters.
        b. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/vault.yml: This contains sys password which will be used by cx_oracle to connect to the database with sysdba privilege.

2. Update the common variables file: {{collection_dir}}/power_aix_oracle_dba/playbooks

$ cat vars/manage-job-window-vars.yml
hostname: ansible_db                           # AIX hostname where the Database is running.
service_name: devpdb                           # Database service name.
listener_port: 1521                            # Database port number.
oracle_db_home: /home/ansible/oracle_client    # Oracle Instant Client path on the ansible controller.
resource_plan: DEFAULT_MAINTENANCE_PLAN        # Resource plan name.
window_name: ANSI_WINDOW                       # Scheduler Window Name.
interval: freq=daily;byday=SUN;byhour=6;byminute=0; bysecond=0  # Interval.
comments: This is a window for Ansible testing  # Comments
state: enabled                                 # enabled, disabled, absent
duration_hour: 12                              # Duration 12/24

3. Update the passwords file: {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/vault.yml with sys user password. This file needs to be encrypted using ansible-vault. While running the playbook, please provide the vault password.
default_dbpass: Oracle4u # SYS password
default_gipass: Oracle4u # ASMSNMP password

4. Encrypt the passwords file using ansible-vault as shown below
$ ansible-vault encrypt vars/vault.yml
New Vault password:
Confirm New Vault password:
Encryption successful

5. Create the playbook in {{ collection_dir }}/power_aix_oracle_dba/playbooks directory as shown below
$ cat manage-job-window.yml

- hosts: localhost
  gather_facts: false
  connection: local
  vars_files:
   - vars/vault.yml
   - vars/manage-job-window-vars.yml
  roles:
     - { role: oradb_manage_job_window }

6. Execute the playbook as shown below
ansible-playbook manage-job-window.yml --ask-vault-pass -i inventory.yml
Vault password:

PLAY [localhost] **********************************************************************************************************************

TASK [oradb_manage_job_window : Oracle Job Window] ***********************************************************
[WARNING]: Module did not set no_log for password
changed: [localhost]

TASK [oradb_manage_job_window : debug] ***********************************************************************
ok: [localhost] => {
    "jobclass": {
        "changed": true,
        "failed": false,
        "msg": "",
        "warnings": [
            "Module did not set no_log for password"
        ]
    }
}

PLAY RECAP ****************************************************************************************************************************
localhost                  : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

To execute this playbook from GUI, please refer this link: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
