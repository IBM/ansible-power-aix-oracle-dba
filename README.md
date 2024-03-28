# PowerODBA Ansible Collection

Overview: The Power Oracle Database Automation (PowerODBA) Collection modules are based on the Oravirt collection https://github.com/oravirt/ansible-oracle which automates Oracle Database Administration activities on AIX. These have been modified and tested exclusively to work on AIX.

Following functionalities can be achieved with this collection.

- Database creation [Single Instance/RAC & Multitenant]
- Apply RU Patches [Standalone DB/Database on ASM & RAC]
- Manage Users [Create/drop users, grant/revoke privileges]
- Manage Pluggable databases
- Manage Tablespaces
- Manage Redo logs
- Manage Database directories.
- Manage ASM
- Manage ACFS
- Manage DBMS jobs
- Single Instance Grid Infrastructure and Database Upgrade from 12c to 19c

Version Change:

PODBA v2.0.4
- Enhanced the role "oraswdb_manage_patches" patching module which uses “opatch” utility with restart of database and listener services while patching.
- Added support for patch staging options – NFS, local (target node) & remote (ansible controller).
- The role "orasw_download_patches" has been tested to download EBS patches as well.

PODBA v2.0.3
- Introduced standalone variables file path.
- Refinement of documentation.
- Documentation provided to execute playbooks from AAP2 GUI.

PODBA v2.0.2
- Upgrade Oracle 12c Single Instance Grid Infrastructure & Multiple Databases to Oracle 19c.

PODBA v2.0.1
- Download Patches from My Oracle Support.

PODBA v2.0.0
- Upgrade Oracle 12c Single Instance Grid Infrastructure & Databases to Oracle 19c.

PODBA v1.0.0
- Base release

# Documentation:

- Instructions to get started with this collection can be found here: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_Ansible_Collection.pdf
- Readmes for each capability can be found here: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs

# Executing PowerODBA collection using Ansible Automation Platform 2 (AAP2)

- Readme: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
