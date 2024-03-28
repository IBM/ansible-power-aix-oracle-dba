# Drop database - Readme
# ======================
# Description: This module is used to drop an Oracle database.
# Reference: https://docs.oracle.com/database/121/RACAD/GUID-17439B6B-6D3C-46AA-A585-94B636C708AC.htm

In the following example we're going to drop a Container Database (CDB) called DEVDB.
1. Passwordless SSH must be established between Ansible user & Oracle Database user.
2. Define the required hostname in an inventory file to be used to execute the playbook.
3. There are three files which needs to be updated:
        a. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/vault.yml: This file contains the SYS user password of ASM and SYS password which needs to set to
the new database.
        b. {{ collection_dir }}/power_aix_oracle_dba/playbooks/delete-db.yml: This file contains the playbook which executes the oradb_create role.
        c. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/delete-db-vars.yml: This file contains all the required variables required to delete a database. 

4. Update the {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/vault.yml file with the passwords.
        a. Go to the playbooks directory and update the file with system password for asm and dba
$ cat vault.yml
default_gipass: Oracle4u
default_dbpass: Oracle4u
        b. Encrypt the file using the command:
$ ansible-vault encrypt vault.yml

5. Update the hosts and remote_user in the directory: {{ collection_dir }}/power_aix_oracle_dba/playbooks/delete-db.yml file.

$ cat delete-db.yml
- name: Drop a Database
  hosts: ansible_db                     # Target Lpar hostname.
  remote_user: oracle                   # Remote username.
  gather_facts: false
  vars_files:
   - vars/delete-db-vars.yml
   - vars/vault.yml
  roles:
     - { role: oradb_delete }

6. Update the following variables in {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/delete-db-vars.yml

$ cat vars/delete-db-vars.yml
oracle_databases:                                         # Dictionary describing the databases to be deleted
    - home: db19c                                      # 'Last' directory in ORACLE_HOME path (e.g /u01/app/oracle/12.1.0.2/racdb)
      oracle_home: /u02/db19c
      oracle_db_name: devdb                                 # Database name
      state: absent

7. Execute the following command to run the playbook

$ ansible-playbook delete-db.yml --ask-vault-pass -i inventory.yml
Vault password:

PLAY [Drop a Database] ****************************************************************************************************************

TASK [oradb_delete : Delete database(s)] *********************************************************************
changed: [dev] => (item={'home': 'db19c', 'oracle_home': '/u02/db19c', 'oracle_db_name': 'devdb', 'state': 'absent'})

TASK [oradb_delete : debug] **********************************************************************************
ok: [dev] => (item={'changed': True, 'end': '2023-12-18 05:43:05.654870', 'stdout': '[WARNING] [DBT-19202] The Database Configuration Assistant will delete the Oracle instances and datafiles for your database. All information in the database will be destroyed.\nPrepare for db operation\n32% complete\nConnecting to database\n35% complete\n39% complete\n42% complete\n45% complete\n48% complete\n52% complete\n65% complete\nUpdating network configuration files\n68% complete\nDeleting instance and datafiles\n84% complete\n100% complete\nDatabase deletion completed.\nLook at the log file "/u02/base/cfgtoollogs/dbca/devdb/devdb10.log" for further details.', 'cmd': '/u02/db19c/bin/dbca -deleteDatabase -sourceDB devdb -sysDBAUserName sys -sysDBAPassword Oracle321 -silent', 'rc': 0, 'start': '2023-12-18 05:41:29.155266', 'stderr': '', 'delta': '0:01:36.499604', 'invocation': {'module_args': {'executable': None, '_uses_shell': True, 'strip_empty_ends': True, '_raw_params': '/u02/db19c/bin/dbca -deleteDatabase -sourceDB devdb -sysDBAUserName sys -sysDBAPassword Oracle321 -silent', 'removes': None, 'argv': None, 'creates': None, 'chdir': None, 'stdin_add_newline': True, 'stdin': None}}, 'msg': '', 'stdout_lines': ['[WARNING] [DBT-19202] The Database Configuration Assistant will delete the Oracle instances and datafiles for your database. All information in the database will be destroyed.', 'Prepare for db operation', '32% complete', 'Connecting to database', '35% complete', '39% complete', '42% complete', '45% complete', '48% complete', '52% complete', '65% complete', 'Updating network configuration files', '68% complete', 'Deleting instance and datafiles', '84% complete', '100% complete', 'Database deletion completed.', 'Look at the log file "/u02/base/cfgtoollogs/dbca/devdb/devdb10.log" for further details.'], 'stderr_lines': [], 'ansible_facts': {'discovered_interpreter_python': '/usr/bin/python2.7'}, 'failed': False, 'item': {'home': 'db19c', 'oracle_home': '/u02/db19c', 'oracle_db_name': 'devdb', 'state': 'absent'}, 'ansible_loop_var': 'item'}) => {
    "msg": [
        "[WARNING] [DBT-19202] The Database Configuration Assistant will delete the Oracle instances and datafiles for your database. All information in the database will be destroyed.",
        "Prepare for db operation",
        "32% complete",
        "Connecting to database",
        "35% complete",
        "39% complete",
        "42% complete",
        "45% complete",
        "48% complete",
        "52% complete",
        "65% complete",
        "Updating network configuration files",
        "68% complete",
        "Deleting instance and datafiles",
        "84% complete",
        "100% complete",
        "Database deletion completed.",
        "Look at the log file \"/u02/base/cfgtoollogs/dbca/devdb/devdb10.log\" for further details."
    ]
}

PLAY RECAP ****************************************************************************************************************************
dev               : ok=1    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=1

To execute this playbook from GUI, an example is provided in the document, please refer this link: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
