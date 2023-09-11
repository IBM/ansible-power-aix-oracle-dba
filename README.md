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

PODBA v2.0 and later
- Upgrade Oracle 12c Single Instance Grid Infrastructure & Multiple Databases to Oracle 19c.
- Download Patches from My Oracle Support.

# Documentation:

- Instructions to get started with this collection can be found here: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_Ansible_Collection.pdf
- Readmes for each capability can be found here: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs

# Executing PowerODBA collection using Ansible Automation Platform 2 (AAP2)

- Readme: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
