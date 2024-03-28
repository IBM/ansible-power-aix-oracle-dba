# Gather global statistics - Readme
# =================================
# Description: This module is used to alter global statistics settings of the database. 
# More information on what Global Statistics is can be found here: https://docs.oracle.com/database/121/ARPLS/d_stats.htm?msclkid=316b7042ab3411eca76cd2c34e98f515#ARPLS059

In the following example we're going to enable gloabl statistics to ALL in a CDB called DEVDB.

1. There are two files which need to be updated:
        a. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/manage-globalstats-vars.yml: This file contains database hostname, database port number and the path to the Oracle client and also AWR retention related parameters.
        b. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/vault.yml: This contains sys password which will be used by cx_oracle to connect to the database with sysdba privilege.

2. Update the common variables file: {{collection_dir}}/power_aix_oracle_dba/playbooks as shown below:

$ cat vars/manage-globalstats-vars.yml
hostname: ansible_db                           # AIX hostname where the Database is running.
service_name: devdb                            # Database service name.
listener_port: 1521                            # Database port number.
oracle_db_home: /home/ansible/oracle_client    # Oracle Instant Client path on the ansible controller.
preference_name: CONCURRENT                    # Statistics preference.
preference_value: ALL                          # Value
state: present

3. Update the passwords file: {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/vault.yml with sys user password. This file needs to be encrypted using ansible-vault. While running the playbook, please provide the vault password.
default_dbpass: Oracle4u # SYS password
default_gipass: Oracle4u # ASMSNMP password

4. Encrypt the passwords file using ansible-vault as shown below
$ ansible-vault encrypt vars/vault.yml
New Vault password:
Confirm New Vault password:
Encryption successful

5. Create the playbook from {{ collection_dir }}/power_aix_oracle_dba/playbooks directory as shown below

$ cat manage-globalstats.yml

- hosts: localhost
  connection: local
  vars_files:
   - vars/vault.yml
   - vars/manage-globalstats-vars.yml
  roles:
     - { role: oradb_manage_stats }

6. Execute the playbook as shown below:

$ ansible-playbook manage-globalstats.yml --ask-vault-pass -i inventory.yml
Vault password:

PLAY [localhost] **********************************************************************************************************************

TASK [Gathering Facts] ****************************************************************************************************************
ok: [localhost]

TASK [oradb_manage_stats : Manage Global preferences] ********************************************************
changed: [localhost]

TASK [oradb_manage_stats : debug] ****************************************************************************
ok: [localhost] => {
    "stats": {
        "changed": true,
        "failed": false,
        "msg": "Old value OFF changed to ALL"
    }
}

PLAY RECAP ****************************************************************************************************************************
localhost                  : ok=3    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

To execute this playbook from GUI, please refer this link: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
