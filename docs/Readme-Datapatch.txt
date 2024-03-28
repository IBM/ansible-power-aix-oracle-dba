/ Datapatch - Readme
# ==================
# Description: This module is used to run datapatch on a given database list.

In the following example we're going to run datapatch on a Single Instance Database called ansible_dbdb.
1. Passwordless SSH must be established between Ansible user & Oracle Database user.
2. Define the required hostname in an inventory file to be used to execute the playbook.
3. There are two files which needs to be updated:
      a. {{ collection_dir }}/power_aix_oracle_dba/playbooks/manage-datapatch.yml: This file calls oradb_datapatch role to run datapatch on a given database.
      b. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/manage-datapatch-vars.yml: This file contains variables.
4. Update hostname and remote_user details in the file as shown below: {{ collection_dir }}/power_aix_oracle_dba/playbooks/manage-datapatch.yml file.

- name: Datapatch
  gather_facts: yes
  hosts: all            # AIX lpar hostname, make sure it's set in the inventory.
  remote_user: oracle   # AIX lpar Oracle home user.
  vars_files:
   - vars/manage-datapatch-vars.yml
  roles:
     - {role: oradb_datapatch }

5. Update the following variables in {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/manage-datapatch-vars.yml

oracle_db_name: ansible_db                         # Name of the database to run Datapatch.
listener_port: 1521                           # Database Listener port.
oracle_db_home: /u02/db19c                    # Oracle Home location of the above database.

6. Execute the following command to run the playbook as shown below

$ ansible-playbook manage-datapatch.yml -i inventory.yml

PLAY [Datapatch] **********************************************************************************************************************

TASK [Gathering Facts] ****************************************************************************************************************
ok: [ansible_db]

TASK [oradb_datapatch : oradb-datapatch | Start database] ****************************************************
changed: [ansible_db]

TASK [oradb_datapatch : oradb-datapatch | Run datapatch] *****************************************************
changed: [ansible_db]

TASK [oradb_datapatch : debug] *******************************************************************************
ok: [ansible_db] => {
    "datapatch.stdout_lines": [
        "SQL Patching tool version 19.17.0.0.0 Production on Sun Nov 19 01:22:17 2023",
        "Copyright (c) 2012, 2022, Oracle.  All rights reserved.",
        "",
        "Log file for this invocation: /u02/base/cfgtoollogs/sqlpatch/sqlpatch_22741270_2023_11_19_01_22_17/sqlpatch_invocation.log",
        "",
        "Connecting to database...OK",
        "Gathering database info...done",
        "",
        "Note:  Datapatch will only apply or rollback SQL fixes for PDBs",
        "       that are in an open state, no patches will be applied to closed PDBs.",
        "       Please refer to Note: Datapatch: Database 12c Post Patch SQL Automation",
        "       (Doc ID 1585822.1)",
        "",
        "Bootstrapping registry and package to current versions...done",
        "Determining current state...done",
        "",
        "Current state of interim SQL patches:",
        "  No interim patches found",
        "",
        "Current state of release update SQL patches:",
        "  Binary registry:",
        "    19.17.0.0.0 Release_Update 220928055956: Installed",
        "  PDB CDB$ROOT:",
        "    Applied 19.17.0.0.0 Release_Update 220928055956 successfully on 19-NOV-23 12.34.27.352034 AM",
        "  PDB DEVPDB:",
        "    Applied 19.17.0.0.0 Release_Update 220928055956 successfully on 19-NOV-23 12.46.39.411874 AM",
        "  PDB PDB$SEED:",
        "    Applied 19.17.0.0.0 Release_Update 220928055956 successfully on 19-NOV-23 12.46.39.411874 AM",
        "",
        "Adding patches to installation queue and performing prereq checks...done",
        "Installation queue:",
        "  For the following PDBs: CDB$ROOT PDB$SEED DEVPDB",
        "    No interim patches need to be rolled back",
        "    No release update patches need to be installed",
        "    No interim patches need to be applied",
        "",
        "SQL Patching tool complete on Sun Nov 19 01:22:55 2023"
    ]
}

PLAY RECAP ****************************************************************************************************************************
ansible_db               : ok=4    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

To execute this playbook from GUI, an example is provided in the document, please refer this link: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
