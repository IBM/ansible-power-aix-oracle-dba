# Create a database - Readme
# ==========================

# Description: This module is used to create database on File system/ASM.
# The role "oradb_create" is used to create databases. It can be used for a Non Container Database (CDB) instance or a CDB in a Single Instance or RAC. 
# Reference: https://docs.oracle.com/en/database/oracle/oracle-database/19/cwlin/running-dbca-using-response-files.html#GUID-E84CE996-B30C-4DCA-AE4C-1E90201317C2

In the following example we're going to create a RAC Container Database (CDB) called devdb with one PDB called devpdb.
1. Passwordless SSH must be established between Ansible user & Oracle Database user.
2. Define the required hostname in an inventory file to be used to execute the playbook.
3. There are three files which needs to be updated:
	a. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/vault.yml: This file contains the SYS user password of ASM and SYS password which needs to set to the new database.
	b. {{ collection_dir }}/power_aix_oracle_dba/playbooks/create-db.yml: This file contains the playbook which executes the oradb_create role.
	c. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/create-db-vars.yml: This file contains all the required variables to create a database. Multiple databases can be created by providing the variables as a list.

4. Update the {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/vault.yml file with the passwords.
	a. Go to the playbooks directory and update the file with system password for asm and dba
$ cat vault.yml
default_gipass: Oracle4u
default_dbpass: Oracle4u
	b. Encrypt the file using the command:
$ ansible-vault encrypt vault.yml

5. Update the hosts and remote_user in the directory: {{ collection_dir }}/power_aix_oracle_dba/playbooks/create-db.yml file.
- name: Create a Database
  hosts: rac91 # Target LPAR hostname defined in the inventory file.
  remote_user: oracle # Oracle Database Username
  vars_file:
   - vars/create-db-vars.yml
   - vars/vault.yml
  roles:
   - { role: oradb_create }
 
 6. Update the following variables in {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/create-db-vars.yml 
 oracle_stage: /tmp # Location on the target AIX LPAR to stage response files.
 oracle_inventory_loc: /u01/app/oraInventory
 oracle_base: /u01/base
 oracle_dbf_dir_asm: '+DATA1' # If storage_type=ASM this is where the database is placed.
 oracle_reco_dir_asm: '+DATA1' # If storage_type=ASM this is where the fast recovery area is 
 oracle_databases: # Dictionary describing the databases to be created.
  - home: db1 
    oracle_version_db: 19.3.0.0 # For a 19c database, the version should be 19.3.0.0
    oracle_home: /u01/app/19c_ansible # Oracle Home location.
    oracle_edition: EE # The edition of database-server (EE,SE,SEONE)
    oracle_db_name: devdb # Database name
    oracle_db_type: RAC # Type of database (RAC,RACONENODE,SI)
    is_container: True # (true/false) Is the database a container database.
    pdb_prefix: devpdb # Pluggable database name.
    num_pdbs: 1 # Number of pluggable databases.
    storage_type: ASM # Database storage to be used. ASM or FS.
    service_name: db19c # Inital service to be created.
    oracle_init_params: "" # initialization parameters, comma separated
    oracle_db_mem_totalmb: 10000 # Amount of RAM to be used for SGA + PGA
    oracle_database_type: MULTIPURPOSE # MULTIPURPOSE|DATA_WAREHOUSING|OLTP
    redolog_size_in_mb: 512 # Redolog size in MB
    state: present 	# present | absent 

7. Verify the DB does not currently exist as shown below
bash-5.1$ srvctl status database -d devdb
PRCD-1120 : The resource for database devdb could not be found.
PRCR-1001 : Resource ora.devdb.db does not exist

8. Execute the following command to run the playbook below
[ansible@x134vm236 playbooks]$ ansible-playbook create-db.yml -i inventory.yml 
--ask-vault-pass
Vault password:
[DEPRECATION WARNING]: "include" is deprecated, use include_tasks/import_tasks instead. 
This feature will be removed in version 2.16.
Deprecation warnings can be disabled by setting deprecation_warnings=False in ansible.cfg.
PLAY [Create a Database] 
*******************************************************************************************
TASK [Gathering Facts] 
*******************************************************************************************
[WARNING]: Platform aix on host rac93 is using the discovered Python interpreter at /usr/bin/python3, but future installation of another Python interpreter could change the meaning of that path. See https://docs.ansible.com/ansiblecore/2.12/reference_appendices/interpreter_discovery.html for more information.
ok: [rac93]
TASK [oradb_create : set fact] 
*******************************************************************************************
ok: [rac93] => (item={'home': 'db1', 'oracle_version_db': '19.3.0.0', 'oracle_home': '/u01/app/oracle/db', 'oracle_edition': 'EE', 'oracle_db_name': 'devdb', 'oracle_db_type': 'RAC', 'is_container': True, 'pdb_prefix': 'devpdb', 'num_pdbs': 1, 'storage_type': 'ASM', 'service_name': 'devdb', 'oracle_init_params': '', 'oracle_db_mem_totalmb': 10000, 'oracle_database_type': 'MULTIPURPOSE', 'redolog_size_in_mb': 50, 'state': 'present'})
TASK [oradb_create : Create Stage directory for response file.] 
***********************************************************************
ok: [rac93]
TASK [oradb_create : listener | Create responsefile for listener configuration] 
*******************************************************
skipping: [rac93] => (item={'home': 'db1', 'oracle_version_db': '19.3.0.0', 'oracle_home': 
'/u01/app/oracle/db', 'oracle_edition': 'EE', 'oracle_db_name': 'devdb', 'oracle_db_type':
.
.
.
Name:devdb', 'System Identifier(SID) Prefix:devdb', 'Look at the log file 
"/u01/app/oracle/cfgtoollogs/dbca/devdb/devdb.log" for further details.']) => {
 "ansible_loop_var": "item",
 "item": [
 "[WARNING] [DBT-09102] Target environment does not meet some optional 
requirements.",
 " CAUSE: Some of the optional prerequisites are not met. See logs for details.",
 " ACTION: Find the appropriate configuration from the log file or from the 
installation guide to meet the prerequisites and fix this manually.",
 "Prepare for db operation",
 "7% complete",
 "Copying database files",
 "27% complete",
 "Creating and starting Oracle instance",
 "28% complete",
 "31% complete",
 "35% complete",
 "37% complete",
 "40% complete",
 "Creating cluster database views",
 "41% complete",
 "53% complete",
 "Completing Database Creation",
 "57% complete",
 "59% complete",
 "60% complete",
 "Creating Pluggable Databases",
 "64% complete",
 "80% complete",
 "Executing Post Configuration Actions",
 "100% complete",
 "Database creation complete. For details check the logfiles at:",
 " /u01/app/oracle/cfgtoollogs/dbca/devdb.",
 "Database Information:",
 "Global Database Name:devdb",
 "System Identifier(SID) Prefix:devdb",

"Look at the log file \"/u01/app/oracle/cfgtoollogs/dbca/devdb/devdb.log\" for 
further details."
 ]
}

TASK [oradb_create : Check if database is running] 
************************************************************************************
changed: [rac93]
TASK [oradb_create : debug] 
*******************************************************************************************
ok: [rac93] => {
 "psout.stdout_lines": [
 " grid 14483936 1 0 00:54:37 - 0:00 asm_pmon_+ASM1",
 " grid 14745992 1 0 00:54:56 - 0:00 apx_pmon_+APX1",
 " oracle 21365224 1 0 02:08:59 - 0:00 ora_pmon_devdb1"
 ]
}
PLAY RECAP 
*******************************************************************************************
rac93 : ok=11 changed=4 unreachable=0 failed=0 skipped=3 
rescued=0 ignored=0

NOTE: Some output has been truncated

9. Verify the DB is created by running the commands shown below
bash-5.1$ srvctl status database -d devdb
Instance devdb1 is running on node rac93
Instance devdb2 is running on node rac94

To execute this playbook from GUI, an example is provided in the document, please refer this link: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
