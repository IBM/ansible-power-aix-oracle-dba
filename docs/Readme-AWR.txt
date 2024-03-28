# Manage AWR retention policy  - Readme 
# =====================================

# Description: # This module is used to set/alter AWR retention policy. It uses python library "oracle_awr"
# More information of what AWR policy is can be found here: https://docs.oracle.com/cd/E11882_01/server.112/e41573/autostat.htm#PFGRF94188

In the following example we're going to set the Snapshot Interval for every 60 mins & Retention Interval for 15 days.

1. There are two files which need to be updated:
        a. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/manage-awr-vars.yml: This file contains database hostname, database port number and the path to the Oracle client and also AWR retention related parameters.
        b. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/vault.yml: This contains sys password which will be used by cx_oracle to connect to the database with sysdba privilege.

2. Update the common variables file: {{collection_dir}}/power_aix_oracle_dba/playbooks/vars/manage-awr-vars.yml as shown below

hostname: ansible_db                           # AIX hostname where the Database is running.
service_name: devdb                            # Database service name.
listener_port: 1521                            # Database port number.
interval: 60                                   # Snapshot interval (in minutes). '0' disables.
retention: 15                                  # Snapshot Retention period (in days)
oracle_db_home: /home/ansible/oracle_client    # Oracle Instant Client path on the ansible controller.

3. Update the passwords file: {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/vault.yml with sys user password. This file needs to be encrypted using ansible-vault. While running the playbook, please provide the vault password.
default_dbpass: Oracle4u # SYS password
default_gipass: Oracle4u # ASMSNMP password

4. Encrypt the passwords file using ansible-vault as shown below
$ ansible-vault encrypt vars/vault.yml
New Vault password:
Confirm New Vault password:
Encryption successful

5. Create the playbook from {{ collection_dir }}/power_aix_oracle_dba/playbooks directory as shown below
$ cat manage-awr.yml

- hosts: localhost
  connection: local
  vars_files:
   - vars/vault.yml
   - vars/manage-awr-vars.yml
  roles:
     - { role: oradb_manage_awr }

6. Now execute the playbook as shown below
[ansible@p208n149 playbooks]$ ansible-playbook manage-awr.yml --ask-vault-pass -i inventory.yml
Vault password:

PLAY [localhost] **********************************************************************************************************************

TASK [Gathering Facts] ****************************************************************************************************************
ok: [localhost]

TASK [oradb_manage_awr : Modify AWR settings] ****************************************************************
[WARNING]: Module did not set no_log for password
ok: [localhost]

TASK [oradb_manage_awr : AWR Retention] **********************************************************************
ok: [localhost]

TASK [oradb_manage_awr : AWR Retention] **********************************************************************
ok: [localhost] => {
    "msg": "The Snapshot and Retention Intervals is set to - [[45, 25]]"
}

PLAY RECAP ****************************************************************************************************************************
localhost                  : ok=4    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

To execute this playbook from GUI, please refer this link: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
