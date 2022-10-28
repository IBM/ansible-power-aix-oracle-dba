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

# Additional features distinguished from Oravirt collection

1. Patching
- Added support for patching Oracle Home on ACFS.
- Backup existing OPatch and creates a latest one.
- Added support to stop database before patch rollback when using opatch option.
- Note: Support for Oracle job role separation is under development.

2. Automatic storage management (ASM)
- Add and drop disks to/from diskgroups.
- Drop disks/diskgroups.

3. ASM Cluster Filesystem (ACFS)
- Create/Drop ACFS volumes

4. Underscores have been used instead of hyphens for role names.

# Getting started with the collection:

- Install Ansible >= 2.9 on any x86 platform.
- Works on AIX >= 7.2 
- Install Python 3.6. Make sure to have a single python version installed on the system to avoid failures with cx_Oracle execution.
- cx_Oracle must be installed on Ansible controller. Reference: https://cx-oracle.readthedocs.io/en/latest/user_guide/installation.html
- Install Oracle 19c client on the Ansible controller.

# Installing this collection using tar ball:

- Download the tar ball and place it in /tmp of the Ansible controller.
- ansible-galaxy collection install /tmp/ibm-power_aix_oracle_dba-1.0.1.tar.gz

# Installing this collection from github:

- Use git clone or download the zip file. 
- Extract the zip file and update your ansible.cfg file with role_path in this collection.

# Documentation:

- Readmes on how to execute each DBA tasks are placed in "docs" folder of this collection.
- This new version mitigates the issue of stored Database User passwords in variables file by using "Ansible Vault".
- Place the SYS user passwords in playbooks/vars/vars.yml and encrypt the file using "ansible-vault encrypt" command. To decrypt the file, use "ansible-vault decrypt" command.
- Ansible Vault Reference: https://docs.ansible.com/ansible/2.8/user_guide/vault.html#:~:text=Ansible%20Vault%20is%20a%20feature,or%20placed%20in%20source%20control.
- To execute a playbook which uses the encrypted password file, use "--ask-vault-pass".

# This collection assumes the following:

 - The user is familiar with Ansible and has basic knowledge on YAML, for the purpose of running this playbook.
 - The user is familiar with Oracle Database Administration.
 - The user is familiar with the AIX Operating system.
 - The version of AIX is 7.2 TL4 SP1 or later. (It should work on other versions of AIX supported by the oracle database AIX OS requirements, but has not been tested).
 - The version of Oracle Standalone Database is 12.2c & 19c
 - Uses ibm.power_aix collection modules.

To get started with Ansible refer

https://docs.ansible.com/ansible/latest/user_guide/intro_getting_started.html

To get started with Oracle Database on AIX refer

https://docs.oracle.com/en/database/oracle/oracle-database/19/axdbi/index.html
https://www.ibm.com/support/pages/oracle-db-rac-19c-ibm-aix-tips-and-considerations

To get started with AIX refer

https://www.ibm.com/support/knowledgecenter/ssw_aix_72/navigation/welcome.html

# Executing PowerODBA collection using Ansible Automation Platform 2 (AAP2)

- This is the readme file to create an execution environment to execute the PowerODBA playbooks. 
- Steps to create an execution environment

1. In any present working directory, create a directory named "context".
2. Inside the "context" directory place the extracted oracle client software directory with the name "oracle_client".
3. Create a file with the following content. 

- $ cat create_podba.yml
```
# Execution Environment
---
version: 1

build_arg_defaults:
  EE_BASE_IMAGE: 'quay.io/ansible/ansible-runner:latest'

additional_build_steps:
  prepend:
   - RUN pip3 install cx_Oracle	# Installs cx_Oracle in the container
   - RUN yum install libnsl -y	# Installs libnsl which is required by oracle client.
   - RUN yum install libaio -y	# Installs libaio which is required by oracle client.
  append:
   - COPY oracle_client /oracle_client_sw	# Copies "oracle_client" directory into the container
```
4. Run the following command to build the execution environment image.

```ansible-builder build -t <name of the image> -f <name of the file to build the image>

ansible-builder build -t powerodba -f create_podba.yml
Running command:
  podman build -f context/Containerfile -t powerodba context
Complete! The build context can be found at: /home/ansible/aap2/context
```
5. Listing the images
```
[ansible@x134vm236 aap2]$ podman images
REPOSITORY                       TAG         IMAGE ID      CREATED         SIZE
localhost/powerodba              latest      ea01cbbf4b64  56 minutes ago  1.45 GB
<none>                           <none>      9a6f51f8bff9  57 minutes ago  816 MB
quay.io/ansible/ansible-runner   latest      bec0dc171168  6 months ago    816 MB
quay.io/ansible/ansible-builder  latest      b0348faa7f41  8 months ago    779 MB
```

6. Create a file called ansible-navigator.yml inside the playbooks directory with the following content.
```
$ cat ansible-navigator.yml
---
ansible-navigator:
   execution-environment:
     enabled: True
     image: powerodba:latest	# Name of the REPOSITORY:TAG
```
7. Executing  playbook against execution environment/container image using ansible-navigator
```
ansible-navigator run <playbook name> --pp=missing --m stdout -i <name of the hosts inventory file>

Before executing the playbook, make sure to update the oracle_env variables ORACLE_HOME & LD_RUN_PATH to "/oracle_client_sw" of the readme: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/Readme-DB-Directories.txt
As shown below -

oracle_env:
      ORACLE_HOME: /oracle_client_sw      # Oracle Client Home in the execution environment.
      LD_RUN_PATH: /oracle_client_sw      # Oracle Client Home Library in the execution environment.

Example:
ansible-navigator run manage-db-directories.yml --pp=missing --m stdout -i hosts.yml
```

Note: To use escalated privileges, please use "--playbook-artifact-enable false" at the end of the command.

```ansible-navigator run db-opatch.yml --pp=missing --m stdout -i hosts.yml --ask-become-pass --playbook-artifact-enable false```
