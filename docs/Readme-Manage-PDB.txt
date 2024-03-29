# Manage Pluggable databases - Readme
# ===================================
# Description: This module is used to manage pluggable databases. It uses a python library located here: ansible-power-aix-oracle-dba/library/oracle_pdb. 
# It can create, drop, plug & unplug pluggable databases in both Standalone & RAC databases.
# Pluggable databases are a part of Multitenant database. More information on Multitenancy: https://docs.oracle.com/en/database/oracle/oracle-database/19/multi/introduction-to-the-multitenant-architecture.html#GUID-FC2EB562-ED31-49EF-8707-C766B6FE66B8

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

# Setup the variables for Oracle:
# Open the file vars/vars.yml and set the following variables:

hostname: ansible_db			# AIX lpar hostname
listener_port: 1521			# Database port number
oracle_db_home: /tmp/oracle_client      # Oracle Client location on the ansible controller.
oracle_env:
    ORACLE_HOME: "{{ oracle_db_home }}"
    LD_LIBRARY_PATH: "{{ oracle_db_home}}/lib"
    PATH: "{{ oracle_db_home}}/bin:$PATH:/usr/local/bin:/bin:/sbin:/usr/bin:/usr/sbin"

# Set the Variables for Oracle to execute this task: Open the file ansible-power-aix-oracle-dba/roles/oradb_manage_pdb/defaults/main.yml and modify the variables. Modify only the ones which are marked with comments.

configure_cluster: false
db_user: sys
db_password_cdb: "{% if dbpasswords is defined and dbpasswords[item[1].cdb] is defined and dbpasswords[item[1].cdb][db_user] is defined%}{{dbpasswords[item[1].cdb][db_user]}}{% else %}{{ default_dbpass}}{% endif%}"
db_mode: sysdba
pdbadmin_user: pdbadmin
pdbadmin_password: "{% if dbpasswords is defined and dbpasswords[item[1].cdb] is defined and dbpasswords[item[1].cdb][item[1].pdb_name] is defined and dbpasswords[item[1].cdb][item[1].pdb_name][pdbadmin_user] is defined%}{{dbpasswords[item[1].cdb][item[1].pdb_name][pdbadmin_user]}}{% else %}{{ default_dbpass}}{% endif%}"
oracle_db_name: db122c                 # Database Service Name.
oracle_home_db: /u01/db12.2c            # Oracle DB Home Location.

create_pdb: True        #Set it to True when creating a fresh PDB. Otherwise, set False.
drop_pdb: False         #Set it to True to Drop a PDB. Otherwise, set False.
plug_pdb: False         #Set it to True to Create a PDB from an XML file. Otherwise, set False.
unplug_pdb: False       #Set it to True to Unplug a PDB to an XML file. Otherwise, set False.

pdb_oradata_dest: /oradata/db122c/db122cpdb #Directory to store PDB datafiles, this needs to be created manually on the target machine.
pdb_seed_dest: /oradata/db122c/pdbseed  # PDB Seed datafiles location to replicate (location can be get from name of v$datafile)
xml_file_dest:

#PDB Creation Variables  [When the above "create_pdb" or "plug_pdb" are set to True]
#
create_oracle_pdbs:                    # Set these parameters to create a new PDB from SEED PDB. Make sure to set plug_pdb variable "False"
   - pdb_name: DB12CPDB              # Name of the PDB to be created from PDB
     cdb: "{{ oracle_db_name }}"
     state: present                      # present - creates PDB.
     file_name_convert: "{{ pdb_seed_dest }},{{ pdb_oradata_dest }}"
     xml_dest: "{{ xml_file_dest }}"         # Location of the XML file to plug in a PDB.
     xml_file: ansipdb4.xml             # XML File name.
     datafile_dest: "{{ pdb_oradata_dest }}"

#PDB Drop & Unplug Variables  [When the above "unplug_pdb" or "drop_pdb" are set to True]

drop_oracle_pdbs:                  # Set these parameters to create a new PDB using an XML File.
   - pdb_name: DB19CPDB              # Name of the PDB to be created from XML File.
     cdb: "{{ oracle_db_name }}"                        # CDB name
     state: absent                      # absent - drops pdb, unplugged - unplug pdb
     file_name_convert: "{{ pdb_seed_dest }},{{ pdb_oradata_dest }}"
     xml_dest: "{{ xml_file_dest }}"
     xml_file: ansipdb4.xml


# Executing the playbook: This playbook executes a role.
# Name of the Playbook: pdb_manage.yml
# Change directory to ansible-power-aix-oracle-dba/playbooks
# ansible-playbook pdb_manage.yml --ask-vault-pass
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
     - { role: ibm.power_aix_oracle_dba.oradb_manage_pdb }

# Sample output:
# =============
# Creating a fresh pluggable database in a 12.2 database.

[ansible@x134vm232 ansible-power-aix-oracle-dba]$ ansible-playbook pdb_manage.yml --ask-vault-pass
Vault password:

PLAY [localhost] **********************************************************************************************************************

TASK [Gathering Facts] ****************************************************************************************************************
ok: [localhost]

TASK [oradb_manage_pdb : Create PDB] **************************************************************************************************
changed: [localhost] => (item={'pdb_name': 'DB12CPDB', 'cdb': 'db122c', 'state': 'present', 'file_name_convert': '/oradata/db122c/pdbseed,/oradata/db122c/db122cpdb', 'xml_dest': None, 'xml_file': 'ansipdb4.xml', 'datafile_dest': '/oradata/db122c/db122cpdb'})
[WARNING]: The value 1521 (type int) in a string field was converted to '1521' (type string). If this does not look like what you
expect, quote the entire value to ensure it does not change.

TASK [oradb_manage_pdb : Plug PDB] ****************************************************************************************************
skipping: [localhost] => (item={'pdb_name': 'DB12CPDB', 'cdb': 'db122c', 'state': 'present', 'file_name_convert': '/oradata/db122c/pdbseed,/oradata/db122c/db122cpdb', 'xml_dest': None, 'xml_file': 'ansipdb4.xml', 'datafile_dest': '/oradata/db122c/db122cpdb'})

TASK [oradb_manage_pdb : Drop PDB] ****************************************************************************************************
skipping: [localhost] => (item={'pdb_name': 'DB19CPDB', 'cdb': 'db122c', 'state': 'absent', 'file_name_convert': '/oradata/db122c/pdbseed,/oradata/db122c/db122cpdb', 'xml_dest': None, 'xml_file': 'ansipdb4.xml'})

TASK [oradb_manage_pdb : Unplug PDB] **************************************************************************************************
skipping: [localhost] => (item={'pdb_name': 'DB19CPDB', 'cdb': 'db122c', 'state': 'absent', 'file_name_convert': '/oradata/db122c/pdbseed,/oradata/db122c/db122cpdb', 'xml_dest': None, 'xml_file': 'ansipdb4.xml'})

PLAY RECAP ****************************************************************************************************************************
localhost                  : ok=2    changed=1    unreachable=0    failed=0    skipped=3    rescued=0    ignored=0
