# ansible-power-aix-oracle-dba
Automate Administration Tasks of Oracle DB on AIX

Overview: These ansible modules are an orignal work of Oravirt https://github.com/oravirt/ansible-oracle. These have been tested on AIX. Following functionalities can be achieved with this repository.
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

Getting started with the collection:

- Install Ansible >= 2.9 on any x86 platform.
- Works on AIX >= 7.2 
- Install Python 3.6. Make sure to have a single python version installed on the system to avoid failures with cx_Oracle execution.
- cx_oracle must be installed on Ansible controller. Reference: https://cx-oracle.readthedocs.io/en/latest/user_guide/installation.html
- Install Oracle 19c on the Ansible controller.

- Clone this repository:
   `git clone --recursive https://github.com/IBM/ansible-power-aix-oracle-dba`
   
- Readmes for each module is placed here: ansible-power-aix-oracle-dba/readmes
