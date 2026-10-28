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
- RAC Grid Infrastructure and Database Upgrade from 12c to 19c
- Introduced Dataguard feature for single instance database using RMAN Backup and RMAN DUPLICATE method
- Oracle 19c cross-endian database migration from x86 Linux to AIX using Oracle's M5 method [RMAN incremental backups & Full Transportable Data Pump]

Version Change:

PODBA v3.0.0

- Migrated underlying Python Oracle driver from cx_Oracle (thick mode) to python-oracledb (thin mode) — pure Python over TCP with no Oracle Instant Client or oracle_db_home required on the Ansible control node.
- Architectural separation between database operations (executing locally from control node over TCP) and Grid Infrastructure / ASM / OS operations (executing on target host via SSH as grid/oracle).
- Enhanced database and grid facts gathering modules (oracle_facts with 9 comprehensive categories including OPatch inventory, tablespaces, redo, and jobs; oracle_gi_facts with OPatch patches, crsctl resource status, and asmcmd lsdg diskgroup metrics).
- Standardized variable structures, zero-indent YAML, per-user privilege definitions, and dynamic initialization parameter management (setting, clearing, and resetting parameters).
- Modernized documentation across the collection with structured Markdown guides, verified execution logs, and SQL/CLI verification commands.
- Introduced Oracle 19c cross-endian migration from x86 Linux to AIX using Oracle's M5 method and the DBMIG 5.1 scripts (MOS Doc 2999157.1). Supports Non-CDB to Non-CDB, PDB to PDB and Non-CDB to PDB.
- New playbook m5_migration.yml with roles mig_prechecks, mig_rman_l0_l1 and mig_rman_l1f, run as tagged stages: prechecks, L0 baseline, repeatable L1 incrementals, L1F cutover and go-live.
- Migration hosts are defined in their own [mig] inventory group (mig_source, mig_destination), so migration runs never touch other hosts.
- Added ansible.posix as a collection dependency.

PODBA v2.0.9

- Tested role separation during upgrade.
- Fixed the bug in oracle_opatch module, ansible interpreter is using the shemang python. Removed shebang from oracle_opatch module. 
- Upgrade module will import oracle install and gi install roles from Oracle Single Instance collection

PODBA v2.0.8

- Refactored oradb_create role for integration with Oracle SI ansible collection.

PODBA v2.0.7

- Introduced Dataguard feature for single instance database using RMAN Backup and RMAN DUPLICATE method.

PODBA v2.0.6

- Introduced RAC Grid Infrastructure and Database Upgrade from 12c to 19c.

PODBA v2.0.5

- Latest RU patches can be applied during the upgrade to 19c. Previously it was restricted till RU 19.17.
- Introduced patch staging options – NFS, local (target node) and remote (ansible controller) for Single Instance Upgrade.

PODBA v2.0.4
- Enhanced the role "oraswdb_manage_patches" patching module to restart DB and listener services. While using "opatch" utility, the DB and listener servies of the Oracle home will be stopped before patching and started post patching.
- Introduced patch staging options – NFS, local (target node) and remote (ansible controller) for patching module.
- The role "orasw_download_patches" has been tested to download EBS patches as well.

PODBA v2.0.3
- Introduced a common path to place the variable files for all the playbooks. 
- Refined existing documentation.
- New documentation to execute playbooks from AAP2 GUI.

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
