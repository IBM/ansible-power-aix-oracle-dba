# Manage Users - Readme
# =====================

# Description: This module is used to create, drop, lock, unlock & expire user accounts. For privileges refer "grants" readme of our ansible collection.
# The role oradb_manage_users is used to create, drop, lock, unlock & set expiration to database users. It uses the oracle_users module. The users require privileges to access the database which can be achieved by the role oradb_manage_grants. It uses the oracle_grants module.

In the following example we're going to create two database users (testuser1 & testuser2) in a pluggable database DEVPDB running in a container database and grant privileges to the users.
1. There are two files which need to be updated:
	a. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/manage-users-vars.yml: This file contains database hostname, database port number and the path to the Oracle client. 
	b. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/vault.yml: This contains sys password which will be used by cx_oracle to connect to the database with sysdba privilege.
2. Update the common variables file: {{collection_dir}}/power_aix_oracle_dba/playbooks/vars/manage-users-vars.yml as shown below

# Create/Drop Database Users - Variables section
hostname: rac93 # AIX Lpar hostname where the database is running.
listener_port: 1522 # Database port number.
oracle_db_home: /home/ansible/oracle_client # Oracle Instant Client path on controller.
oracle_databases: # Database users list to be created
 - users:
 - schema: testuser1 # Username to be created.
 default_tablespace: users # Default tablespace to be assigned to the user.
 service_name: devpdb # Database service name.
 schema_password: oracle3 # Password for the user.
 grants_mode: enforce # enforce|append.
 grants:
 - connect # Provide name of the privilege as a list to 
grant to the user.
 - resource
 state: present # present|absent|locked|unlocked [present: Creates user, # absent: Drops user]

# Multiple users can be created with different attributes as shown below.
 - users:
 - schema: testuser2
 default_tablespace: users
 service_name: devpdb
 schema_password: oracle4
 grants_mode: enforce
 grants:
 - connect
 state: present # present|absent|locked|unlocked [present: Creates user, # absent: drops user}

3. Update the passwords file: {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/vault.yml with sys user password. This file needs to be encrypted using ansible-vault. While running the playbook, please provide the vault password. 
default_dbpass: Oracle4u # SYS password
default_gipass: Oracle4u # ASMSNMP password

4. Encrypt the passwords file using ansible-vault as shown below
$ ansible-vault encrypt vars/vault.yml
New Vault password:
Confirm New Vault password:
Encryption successful

5. Check the user names in the database before creating them as shown below
SQL> sho pdbs
 
    CON_ID CON_NAME                       OPEN MODE  RESTRICTED
---------- ------------------------------ ---------- ----------
        3  DEVPDB                         READ WRITE NO
        
SQL> select username from dba_users where username in ('TESTUSER1','TESTUSER2');
no rows selected

We can see the users do not exist.

6. Create the playbook from {{ collection_dir }}/power_aix_oracle_dba/playbooks directory as shown below
$ cat manage-users.yml
- hosts: localhost
 connection: local
 gather_facts: false
 vars_files:
- vars/manage-user-vars.yml
 - vars/vault.yml
 roles:
 - { role: oradb_manage_users }
 
 
7. Execute the playbook as shown below
$ ansible-playbook manage-users.yml --ask-vault-pass
Vault password:
PLAY [Create DB User] 
*******************************************************************************************
TASK [oradb_manage_users : Manage users (cdb/pdb)] 
************************************************************************************
changed: [localhost] => (item=port: 1522 service: devpdb schema: testuser1 state:present)
changed: [localhost] => (item=port: 1522 service: devpdb schema: testuser2 state:present)
[WARNING]: Module did not set no_log for update_password
PLAY RECAP 
*******************************************************************************************

localhost : ok=1 changed=1 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0

8. Check the user names in the database after creating them as shown below where we can see the testuser1 & testuser2 are created in the PDB database.
SQL> sho pdbs
 
    CON_ID CON_NAME                       OPEN MODE  RESTRICTED
---------- ------------------------------ ---------- ----------
        3  DEVPDB                         READ WRITE NO

SQL> select username from dba_users where username in ('TESTUSER1','TESTUSER2');
USERNAME
---------------
TESTUSER2
TESTUSER1

To execute this playbook from GUI, please refer this link: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
