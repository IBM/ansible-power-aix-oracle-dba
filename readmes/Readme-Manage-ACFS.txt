# Manage ACFS Volume - Readme
# ===========================

# Description: This module is used to Create/Drop ACFS volume in a stanadlone Grid environment.

# Prerequisites:
# ==============
# Passwordless ssh needs to be setup between the Target lpar oracle owner and ansible controller user.
# An ASM diskgroup needs to be created prior creating an acfs volume. Refer the "Readme - Create ASM Diskgroup"

# Set the Variables for Oracle to execute this task: Open the file ansible_oracle_aix/roles/create-acfs/defaults/main.yml and modify the variables. Modify only the ones which are marked with comments.

[ansible@x134vm232 ansible_oracle_aix]$ cat roles/create-acfs/defaults/main.yml
grid_owner: oracle
oracle_home_gi: /u01/grid19c    # Grid Home location.
oracle_sid: +ASM                # Grid SID.
path: /acfs                     # OS Path onto which ACFS to be mounted.
diskgroup: DATA1                # Diskgroup name where ACFS should me created.
volname: ACFSDATA1              # Desired ACFS volume name to be created.
size: 80G                       # ACFS mount point size to be created.
oracle_env:
    ORACLE_HOME: "{{oracle_home_gi}}"
    PATH: "{{oracle_home_gi}}/bin:$PATH:/bin:/usr/bin:/sbin:/usr/sbin:/opt/freeware/bin"
    ORACLE_SID: "{{ oracle_sid }}"
create_acfs: False               # True: Creates ACFS mount point | False: Deletes ACFS mount point.

# Executing the playbook: This playbook executes a role. Before running the playbook, open the playbook and update the hostname & remote user details as shown below. Do NOT change other parts of the script.
# Change directory to ansible_oracle_aix
# Name of the Playbook: manage-acfs.yml
# Content of the playbook

- name: Create ACFS SI
  gather_facts: no
  hosts: ansible_db		# AIX Lpar hostname defined in Ansible inventory.
  remote_user: oracle		# Grid Home Owner
  roles:
     - {role: create-acfs }

# ansible-playbook manage-acfs.yml