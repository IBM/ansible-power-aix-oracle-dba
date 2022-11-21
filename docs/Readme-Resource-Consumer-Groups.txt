# Manage Database directories  - Readme 
# =====================================

# Description: # This module is used to manage resources at the pluggable database level. It uses python library located here: ansible-power-aix-oracle-dba/library/oracle_rsrc_consgroup
# More information on Create directory can be found here: https://docs.oracle.com/cd/E11882_01/server.112/e25494/dbrm.htm#ADMIN11842

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

# Open the file ansible-power-aix-oracle-dba/roles/oradb_manage_rsrc/defaults/main.yml and modify the variables

db_user: sys
service_name: ansipdb.pbm.ihost.com     # Pluggable DB Service Name.
db_password_cdb: "{% if dbpasswords is defined and dbpasswords[item[1].cdb] is defined and dbpasswords[item[1].cdb][db_user] is defined%}{{dbpasswords[item[1].cdb][db_user]}}{% else %}{{ default_dbpass}}{% endif%}"
db_password_pdb: "{% if dbpasswords is defined and dbpasswords[item[1].cdb] is defined and dbpasswords[item[1].cdb][db_user] is defined%}{{dbpasswords[item[1].cdb][db_user]}}{% else %}{{ default_dbpass}}{% endif%}"
db_mode: sysdba
state: present                  # State: Present/Absent
consumer_group: ansigroup1      # Desired consumer group name
comments:  This is a test consumer resource group       # Optional
grant:
   - ANSIUSER1                  # Name of the user to provide grants to resource group.
map_oracle_user:
   - ANSIUSER1                  # Map user
map_service_name:
   - db122cpdb                  # Map service
map_client_machine:
   - x134vm236                  # Map client

# Executing the playbook: This playbook executes a role.
# Name of the Playbook: manage-resource-consumer-group.yml
# Change directory to ansible-power-aix-oracle-dba/playbooks
# ansible-playbook manage-resource-consumer-group.yml --ask-vault-pass
# The following task will be executed which will call out a role.

- hosts: localhost
  connection: local
  pre_tasks:
     - name: include variables
       include_vars:
         dir: vars
         extensions:
           - 'yml'
  roles:
     - { role: ibm.power_aix_oracle_dba.oradb_manage_rsrc }

# Sample output:
# =============

[ansible@localhost playbooks]$ ansible-playbook manage-resource-consumer-group.yml --ask-vault-pass
Vault password:
[WARNING]: Found both group and host with same name: ansible_db
[WARNING]: running playbook inside collection ibm.power_aix_oracle_dba

PLAY [localhost] ********************************************************************************************************************

TASK [Gathering Facts] **************************************************************************************************************
ok: [localhost]

TASK [include variables] ************************************************************************************************************
ok: [localhost]

TASK [ibm.power_aix_oracle_dba.oradb_manage_rsrc : Resource Consumer Groups] ********************************************************
[WARNING]: Module did not set no_log for password
changed: [localhost]

TASK [ibm.power_aix_oracle_dba.oradb_manage_rsrc : debug] ***************************************************************************
ok: [localhost] => {
    "rsc": {
        "changed": true,
        "failed": false,
        "msg": "Added grants: set(), Added mappings: {'ORACLE_USER': {'ANSIUSER1'}, 'SERVICE_NAME': {'DB122CPDB'}, 'CLIENT_MACHINE': {'X134VM236'}}",
        "warnings": [
            "Module did not set no_log for password"
        ]
    }
}

PLAY RECAP **************************************************************************************************************************
localhost                  : ok=4    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
