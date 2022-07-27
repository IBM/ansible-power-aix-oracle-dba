# Manage ACFS Volume on RAC - Readme
# ==================================

# Description: This module is used to Create/Drop ACFS volume in a RAC environment.

# Prerequisites:
# ==============
# Passwordless ssh needs to be setup between the Target lpar oracle owner and ansible controller user.
# An ASM diskgroup needs to be created prior creating an acfs volume. Refer the "Readme - Create ASM Diskgroup"

# Set the Variables for Oracle to execute this task: Open the file power-aix-oracle-dba/roles/create_acfs/defaults/main.yml and modify the variables. Modify only the ones which are marked with comments.

grid_owner: grid
oracle_home_gi: /u01/app/19c/grid    	# Grid Home location.
oracle_sid: +APX1                	# Grid SID.
path: /acfs                     	# OS Path onto which ACFS to be mounted.
diskgroup: ACFSDATA1                	# Diskgroup name where ACFS should me created.
volname: ACFS1              		# Desired ACFS volume name to be created.
size: 80G                       	# ACFS mount point size to be created.
oracle_env:
    ORACLE_HOME: "{{oracle_home_gi}}"
    PATH: "{{oracle_home_gi}}/bin:$PATH:/bin:/usr/bin:/sbin:/usr/sbin:/opt/freeware/bin"
    ORACLE_SID: "{{ oracle_sid }}"
create_acfs: False               # True: Creates ACFS mount point | False: Deletes ACFS mount point.

# Executing the playbook: This playbook executes a role. Before running the playbook, open the playbook and update the hostname & remote user details as shown below. Do NOT change other parts of the script.
# Change directory to power-aix-oracle-dba
# Name of the Playbook: manage-acfs-rac.yml
# Content of the playbook

- name: Create ACFS in RAC
  gather_facts: no
  hosts: rac91                  # AIX Lpar hostgroup defined in ansible inventory.
  remote_user: grid             # Grid Home owner.
  roles:
     - {role: create_acfs-rac }
    
# ansible-playbook manage-acfs-rac.yml
