# PowerODBA Ansible Collection

Overview: The Power Oracle Database Automation (PowerODBA) Collection modules are based on the Oravirt collection https://github.com/oravirt/ansible-oracle which automate Oracle DBA activities running on AIX. These have been modified and tested exclusively to work on AIX. 
=======

Following functionalities can be achieved with this repository.
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

# Additional features distinguished from Oravirt collection

1. Patching
- Added support for patching Oracle Home on ACFS.
- Backup existing OPatch and creates a latest one.
- Added support to stop database before patch rollback when using opatch option.

2. Automatic storage management (ASM)
- Add and drop disks to/from diskgroups.
- Drop disks/diskgroups.

3. ASM Cluster Filesystem (ACFS)
- Create/Drop ACFS volumes

4. Underscores have been used instead of hyphens for role names.

Getting started with the collection:
=======
# Getting started with the collection:

- Install Ansible >= 2.9 on any x86 platform.
- Works on AIX >= 7.2
- Install Python 3.6. Make sure to have a single python version installed on the system to avoid failures with cx_Oracle execution.
- cx_Oracle must be installed on Ansible controller. Reference: https://cx-oracle.readthedocs.io/en/latest/user_guide/installation.html
- Install Oracle 19c client on the Ansible controller.

- Readmes for each module are placed here: ansible-power-aix-oracle-dba/docs
=======
- Clone this repository:
   `git clone --recursive https://github.com/IBM/ansible-power-aix-oracle-dba`

- Readmes for each module are placed here: ansible-power-aix-oracle-dba/readmes

# Assumptions

This playbook assumes the following:

 - The user is familiar with Ansible and has basic knowledge on YAML, for the purpose of running this playbook.
 - The user is familiar with Oracle Database Administration.
 - The user is familiar with the AIX Operating system.
 - The version of AIX is 7.2 TL4 SP1 or later. (It should work on other versions of AIX supported by the oracle database AIX OS requirements, but has not been tested).
 - The version of Oracle Standalone Database is 19.3.0.0.
 - Uses ibm.power_aix collection modules.

To get started with Ansible refer

https://docs.ansible.com/ansible/latest/user_guide/intro_getting_started.html

To get started with Oracle Database on AIX refer

https://docs.oracle.com/en/database/oracle/oracle-database/19/axdbi/index.html
https://www.ibm.com/support/pages/oracle-db-rac-19c-ibm-aix-tips-and-considerations

To get started with AIX refer

https://www.ibm.com/support/knowledgecenter/ssw_aix_72/navigation/welcome.html
