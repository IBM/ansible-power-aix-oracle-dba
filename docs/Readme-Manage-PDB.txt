# Manage Pluggable databases - Readme
# ===================================
# Description: This module is used to manage pluggable databases. 
# It can create, drop, plug & unplug pluggable databases in both Standalone & RAC databases.
# Pluggable databases are a part of Multitenant database. More information on Multitenancy: https://docs.oracle.com/en/database/oracle/oracle-database/19/multi/introduction-to-the-multitenant-architecture.html#GUID-FC2EB562-ED31-49EF-8707-C766B6FE66B8

In this readme, there are two examples A & B.

A. In the following example we're going to create a new PDB called devpdb1 in a Standalone CDB called devdb on ASM.

1. There are two files which need to be updated:
        a. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/manage-pdb-vars.yml: This file contains database hostname, database port number and the path to the Oracle client and other related parameters.
        b. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/vault.yml: This contains sys password which will be used by cx_oracle to connect to the database with sysdba privilege.

2. Update the common variables file: {{collection_dir}}/power_aix_oracle_dba/playbooks/vars/manage-awr-vars.yml as shown below

hostname: ansible_db                  # AIX hostname where the Database is running.
listener_port: 1521                   # Database listener port.
oracle_db_name: devdb                 # Database Service Name.
oracle_db_home: /home/ansible/oracle_client    # Oracle Instant Client path on the ansible controller.

create_pdb: True        # Set it to True to Create a fresh PDB. Otherwise, set False.
drop_pdb: False         # Set it to True to Drop an existing PDB. Otherwise, set False.
plug_pdb: False         # Set it to True to Create a PDB from an XML file. Otherwise, set False.
unplug_pdb: False       # Set it to True to Unplug a PDB into an XML file. Otherwise, set False.

pdb_oradata_dest: +DATA # Path to store PDB datafiles.
pdb_seed_dest: +DATA    # PDB Seed datafiles path.
xml_file_dest:          # Path to where to create/use the XML files.

#PDB Creation Variables  [When the above "create_pdb" or "plug_pdb" are set to True]

create_oracle_pdbs:               # Set these parameters to create a new PDB from SEED PDB. Make sure to set plug_pdb variable "False"
   - pdb_name: devpdb1            # Name of the PDB to be created or plugged from XML file.
     cdb: "{{ oracle_db_name }}"
     state: present               # present - creates PDB.
     file_name_convert: "{{ pdb_seed_dest }},{{ pdb_oradata_dest }}"
     xml_dest: "{{ xml_file_dest }}"
     xml_file: ansipdb4.xml       # XML File name.
     datafile_dest: "{{ pdb_oradata_dest }}"

3. Update the passwords file: {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/vault.yml with sys user password. This file needs to be encrypted using ansible-vault. While running the playbook, please provide the vault password.
default_dbpass: Oracle4u # SYS password
default_gipass: Oracle4u # ASMSNMP password

4. Encrypt the passwords file using ansible-vault as shown below
$ ansible-vault encrypt vars/vault.yml
New Vault password:
Confirm New Vault password:
Encryption successful

5. Create the playbook in {{ collection_dir }}/power_aix_oracle_dba/playbooks directory as shown below

$ cat manage-pdb.yml
- hosts: localhost
  connection: local
  vars_files:
   - vars/vault.yml
   - vars/manage-pdb-vars.yml
  roles:
     - { role: oradb_manage_pdb }

6. Execute the playbook as shown below

$ ansible-playbook manage-pdb.yml -i inventory.yml --ask-vault-pass
Vault password:
[DEPRECATION WARNING]: "include" is deprecated, use include_tasks/import_tasks instead. See https://docs.ansible.com/ansible-
core/2.15/user_guide/playbooks_reuse_includes.html for details. This feature will be removed in version 2.16. Deprecation warnings can
 be disabled by setting deprecation_warnings=False in ansible.cfg.

PLAY [localhost] **********************************************************************************************************************

TASK [Gathering Facts] ****************************************************************************************************************
ok: [localhost]

TASK [oradb_manage_pdb : Create PDB] *************************************************************************
changed: [localhost] => (item={'pdb_name': 'devpdb1', 'cdb': 'devdb', 'state': 'present', 'file_name_convert': '+DATA,+DATA', 'xml_dest': None, 'xml_file': 'ansipdb4.xml', 'datafile_dest': '+DATA'})

TASK [oradb_manage_pdb : Plug PDB] ***************************************************************************
skipping: [localhost] => (item={'pdb_name': 'devpdb1', 'cdb': 'devdb', 'state': 'present', 'file_name_convert': '+DATA,+DATA', 'xml_dest': None, 'xml_file': 'ansipdb4.xml', 'datafile_dest': '+DATA'})
skipping: [localhost]

TASK [oradb_manage_pdb : Drop PDB] ***************************************************************************
skipping: [localhost] => (item={'pdb_name': 'devpdb', 'cdb': 'devdb', 'state': 'absent', 'file_name_convert': '+DATA,+DATA', 'xml_dest': None, 'xml_file': 'ansipdb4.xml'})
skipping: [localhost]

TASK [oradb_manage_pdb : Unplug PDB] *************************************************************************
skipping: [localhost] => (item={'pdb_name': 'devpdb', 'cdb': 'devdb', 'state': 'absent', 'file_name_convert': '+DATA,+DATA', 'xml_dest': None, 'xml_file': 'ansipdb4.xml'})
skipping: [localhost]

PLAY RECAP ****************************************************************************************************************************
localhost                  : ok=2    changed=1    unreachable=0    failed=0    skipped=3    rescued=0    ignored=0

B. In the following example, we're going to drop a PDB called devpdb1 in a Standalone CDB called devdb on ASM.

Note: Please refer the steps in example A if you are starting with Step B first.

1. Update the common variables file: {{collection_dir}}/power_aix_oracle_dba/playbooks/vars/manage-awr-vars.yml as shown below

hostname: ansible_db                  # AIX hostname where the Database is running.
listener_port: 1521                   # Database listener port.
oracle_db_name: devdb                 # Database Service Name.
oracle_db_home: /home/ansible/oracle_client    # Oracle Instant Client path on the ansible controller.

create_pdb: False        # Set it to True to Create a fresh PDB. Otherwise, set False.
drop_pdb: True         # Set it to True to Drop an existing PDB. Otherwise, set False.
plug_pdb: False         # Set it to True to Create a PDB from an XML file. Otherwise, set False.
unplug_pdb: False       # Set it to True to Unplug a PDB into an XML file. Otherwise, set False.

pdb_oradata_dest: +DATA # Path to store PDB datafiles.
pdb_seed_dest: +DATA    # PDB Seed datafiles path.
xml_file_dest:          # Path to where to create/use the XML files.

#PDB Drop & Unplug Variables  [When the above "unplug_pdb" or "drop_pdb" are set to True]

drop_oracle_pdbs:                 # Set these parameters to create a new PDB using an XML File.
   - pdb_name: devpdb1             # Name of the PDB to be dropped/unplugged.
     cdb: "{{ oracle_db_name }}"
     state: absent                # absent - drops a pdb, unplugged - unplugs a pdb
     file_name_convert: "{{ pdb_seed_dest }},{{ pdb_oradata_dest }}"
     xml_dest: "{{ xml_file_dest }}"
     xml_file: ansipdb4.xml       # XML File name.

2. Execute the playbook to drop the PDB.

$ ansible-playbook manage-pdb.yml -i inventory.yml --ask-vault-pass
Vault password:
[DEPRECATION WARNING]: "include" is deprecated, use include_tasks/import_tasks instead. See https://docs.ansible.com/ansible-
core/2.15/user_guide/playbooks_reuse_includes.html for details. This feature will be removed in version 2.16. Deprecation warnings can
 be disabled by setting deprecation_warnings=False in ansible.cfg.

PLAY [localhost] **********************************************************************************************************************

TASK [Gathering Facts] ****************************************************************************************************************
ok: [localhost]

TASK [oradb_manage_pdb : Create PDB] *************************************************************************
skipping: [localhost] => (item={'pdb_name': 'devpdb1', 'cdb': 'devdb', 'state': 'present', 'file_name_convert': '+DATA,+DATA', 'xml_dest': None, 'xml_file': 'ansipdb4.xml', 'datafile_dest': '+DATA'})
skipping: [localhost]

TASK [oradb_manage_pdb : Plug PDB] ***************************************************************************
skipping: [localhost] => (item={'pdb_name': 'devpdb1', 'cdb': 'devdb', 'state': 'present', 'file_name_convert': '+DATA,+DATA', 'xml_dest': None, 'xml_file': 'ansipdb4.xml', 'datafile_dest': '+DATA'})
skipping: [localhost]

TASK [oradb_manage_pdb : Drop PDB] ***************************************************************************
changed: [localhost] => (item={'pdb_name': 'devpdb1', 'cdb': 'devdb', 'state': 'absent', 'file_name_convert': '+DATA,+DATA', 'xml_dest': None, 'xml_file': 'ansipdb4.xml'})

TASK [oradb_manage_pdb : Unplug PDB] *************************************************************************
skipping: [localhost] => (item={'pdb_name': 'devpdb1', 'cdb': 'devdb', 'state': 'absent', 'file_name_convert': '+DATA,+DATA', 'xml_dest': None, 'xml_file': 'ansipdb4.xml'})
skipping: [localhost]

PLAY RECAP ****************************************************************************************************************************
localhost                  : ok=2    changed=1    unreachable=0    failed=0    skipped=3    rescued=0    ignored=0

To execute this playbook from GUI, please refer this link: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
