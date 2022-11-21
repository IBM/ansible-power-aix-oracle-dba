# Manage DBMS_SCHEDULER job classes in Oracle database - Readme
# =============================================================

# Description: # This module is used to manage DBMS job Classes. It uses a python library located here: ansible-power-aix-oracle-dba/library/oracle_jobwindow.
# Reference: https://docs.oracle.com/database/121/ADMIN/scheduse.htm#ADMIN12674
# Playbook: ansible-power-aix-oracle-dba/job-window-task.yml

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

# Set the Variables for Oracle: 

# Open the file vars/vars.yml and set the following variables:

hostname: ansible_db                    # AIX lpar hostname
listener_port: 1521                     # Database port number
oracle_db_home: /tmp/oracle_client      # Oracle Client location on the ansible controller.
oracle_env:
     ORACLE_HOME: "{{ oracle_db_home }}"
     LD_LIBRARY_PATH: "{{ oracle_db_home}}/lib"
     PATH: "{{ oracle_db_home}}/bin:$PATH:/usr/local/bin:/bin:/sbin:/usr/bin:/usr/sbin"

# Open the file ansible-power-aix-oracle-dba/roles/oradb_manage_job_window/main.yml and modify the variables.

db_password_cdb: "{% if dbpasswords is defined and dbpasswords[item[1].cdb] is defined and dbpasswords[item[1].cdb][db_user] is defined%}{{dbpasswords[item[1].cdb][db_user]}}{% else %}{{ default_dbpass}}{% endif%}"
db_password_pdb: "{% if dbpasswords is defined and dbpasswords[item[1].cdb] is defined and dbpasswords[item[1].cdb][db_user] is defined%}{{dbpasswords[item[1].cdb][db_user]}}{% else %}{{ default_dbpass}}{% endif%}"
db_user: sys
db_mode: sysdba
state: disabled     						# enabled, disabled, absent
resource_plan: DEFAULT_MAINTENANCE_PLAN				
window_name: ANSI_WINDOW						# Job Window Name
interval: freq=daily;byday=SUN;byhour=6;byminute=0; bysecond=0	# Window interval
comments: This is a window for Ansible testing
duration_hour: 12							# Duration in hours

# Executing the playbook: This playbook runs using a single file where it contain both Oracle related variables as well as ansible task. The connection mode will be "local". The cx_Oracle & Oracle client must be installed on ansible controller before executing this playbook.
# Playbook name: ansible-power-aix-oracle-dba/playbooks/manage-job-window.yml
# Change directory to ansible-power-aix-oracle-dba/playbooks
# ansible-playbook manage-job-window.yml

# Contents of playbook:

- hosts: localhost
  connection: local
  pre_tasks:
   - name: include variables
     include_vars:
       dir: vars
       extensions:
         - 'yml'
  roles:
     - { role: ibm.power_aix_oracle_dba.oradb_manage_job_window }

#Sample Output:
==============

PLAY [localhost] ********************************************************************************************************************

TASK [Gathering Facts] **************************************************************************************************************
ok: [localhost]

TASK [include variables] ************************************************************************************************************
ok: [localhost]

TASK [ibm.power_aix_oracle_dba.oradb_manage_job_window : Oracle Job Window] *********************************************************
[WARNING]: Module did not set no_log for password
changed: [localhost]

TASK [ibm.power_aix_oracle_dba.oradb_manage_job_window : debug] *********************************************************************
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

PLAY RECAP **************************************************************************************************************************
localhost                  : ok=4    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
