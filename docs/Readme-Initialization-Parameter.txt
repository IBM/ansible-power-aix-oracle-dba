# Manage Initialization Parameters - Readme
# =========================================

# Description: # This module is used to set/alter & unset database initialization parameters. 
# More information of what AWR policy is can be found here: https://docs.oracle.com/en/database/oracle/oracle-database/19/refrn/initialization-parameters-2.html#GUID-FD266F6F-D047-4EBB-8D96-B51B1DCA2D61
https://docs.oracle.com/en/database/oracle/oracle-database/19/admin/creating-and-configuring-an-oracle-database.html#GUID-2004E26A-3C24-4D0C-9EF4-F2854BCD6664

In the following example, we're going to alter the initialization parameter "log_archive_dest_state_2" from enable to defer in a CDB called DEVDB.

1. There are two files which needs to be updated:
        a. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/manage-init-parameters-vars.yml: This file contains database hostname, database port number and the path to the Oracle client and other related parameters.
        b. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/vault.yml: This contains sys password which will be used by cx_oracle to connect to the database with sysdba privilege.

2. Update the common variables file: {{collection_dir}}/power_aix_oracle_dba/playbooks

$ cat vars/manage-init-parameters-vars.yml

hostname: ansible_db                           # AIX hostname where the Database is running.
service_name: devdb                            # Database service name.
listener_port: 1521                            # Database port number.
oracle_db_home: /home/ansible/oracle_client    # Oracle Instant Client path on the ansible controller.
param_name: log_archive_dest_state_2  # Initialization Parameter Name
param_value: defer                    # Initialization Parameter Value
state: present                        # Initialization Parameter state: present - sets the value, absent/reset - disables the parameter

3. Update the passwords file: {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/vault.yml with sys user password. This file needs to be encrypted using ansible-vault. While running the playbook, please provide the vault password.
default_dbpass: Oracle4u # SYS password
default_gipass: Oracle4u # ASMSNMP password

4. Encrypt the passwords file using ansible-vault as shown below
$ ansible-vault encrypt vars/vault.yml
New Vault password:
Confirm New Vault password:
Encryption successful

5. Create the playbook in {{ collection_dir }}/power_aix_oracle_dba/playbooks directory as shown below
$ cat manage-init-parameters.yml

- hosts: localhost
  connection: local
  vars_files:
   - vars/vault.yml
   - vars/manage-init-parameters-vars.yml
  roles:
     - { role: oradb_manage_initparams }

6. Execute the playbook as shown below

$ ansible-playbook manage-init-parameters.yml --ask-vault-pass -i inventory.yml
Vault password:

PLAY [localhost] **************************************************************************************************

TASK [Gathering Facts] ********************************************************************************************
ok: [localhost]

TASK [oradb_manage_initparams : oracle_parameter] ****************************************
changed: [localhost]

TASK [oradb_manage_initparams : debug] ***************************************************
ok: [localhost] => {
    "parameter": {
        "changed": true,
        "failed": false,
        "msg": "The parameter (log_archive_dest_state_2) has been changed successfully, new: defer, old: enable"
    }
}

PLAY RECAP ********************************************************************************************************
localhost                  : ok=3    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

To execute this playbook from GUI, please refer this link: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
