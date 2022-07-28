# Add disk to an ASM diskgroup - Readme
# =====================================

# Description: This module is used to Add disks to ASM diskgroup(s).
# Reference: https://docs.oracle.com/database/121/OSTMG/GUID-AEA16D80-2EEA-49C7-BB04-48BBF078F30F.htm#OSTMG94057
# Reference: https://docs.oracle.com/database/121/OSTMG/GUID-85391590-DAD5-46BB-A70C-ED94DA94D18D.htm#OSTMG10071

# Prerequisites:
# =============
# Passwordless ssh needs to be setup between the Target lpar oracle owner and ansible controller user.

# Prepare the disks: We need to prepare raw disks which will be used for creating ASM diskgroup.
# List the disks currently attached to the LPAR. Command: lspv
# Scan for any new disks. Command: cfgmgr
# List the disks again. Command: lspv
# Find an empty disk. Command: lquerypv -h /dev/hdisk8 [The output should look something like shown below]

00000000   00000000 00000000 00000000 00000000  |................|
00000010   00000000 00000000 00000000 00000000  |................|
00000020   00000000 00000000 00000000 00000000  |................|
00000030   00000000 00000000 00000000 00000000  |................|
00000040   00000000 00000000 00000000 00000000  |................|
00000050   00000000 00000000 00000000 00000000  |................|
00000060   00000000 00000000 00000000 00000000  |................|
00000070   00000000 00000000 00000000 00000000  |................|
00000080   00000000 00000000 00000000 00000000  |................|
00000090   00000000 00000000 00000000 00000000  |................|
000000A0   00000000 00000000 00000000 00000000  |................|
000000B0   00000000 00000000 00000000 00000000  |................|
000000C0   00000000 00000000 00000000 00000000  |................|
000000D0   00000000 00000000 00000000 00000000  |................|
000000E0   00000000 00000000 00000000 00000000  |................|
000000F0   00000000 00000000 00000000 00000000  |................|

# Change the attributes of the disk: Command: chdev -l hdisk8 -a reserve_policy=no_reserve algorithm=round_robin
# Set ownership. Command: chown grid:oinstall /dev/rhdisk8
# Change permissions. Command: chmod 660 /dev/rhdisk8

# Set the variables for Oracle to execute this task: Open the file ansible-power-aix-oracle-dba/roles/asm_add_disk_aix/defaults/main.yml and modify the variables. Modify only the ones which are marked with comments.

[ansible@x134vm232 ansible-power-aix-oracle-dba]$ cat roles/asm_add_disk_aix/defaults/main.yml
oracle_home_gi: /u01/grid19c                    # Grid Home Location
oracle_rsp_stage: /u01/app/stage                # Any accessible location on remote host to stage scripts. Must be created manually.
grid_install_user: "{{ ansible_user_id }}"
oracle_group: dba                               # Grid owner's primary user group
oracle_asm_disk_string: "/dev/"                 # Entry point of the raw disk
asm_diskgroups:
  - diskgroup: PQSTDB                             # Name of the diskgroup to which the disk needs to be added to.
    disk:
      - {device: rhdiskasm10}                   # Name of the disk that should be added to the diskgroup.
#      - {device: rhdiskasm17}                  # If there are additional disks, it can be added to the list.

# Executing the playbook: This playbook executes a role. Before running the playbook, open the playbook and update the hostname & remote user details as below. Do NOT change other parts of the script.
# Change directory to ansible-power-aix-oracle-dba
# Name of the Playbook: asm-add-disk.yml
# Content of the playbook

 - name: Add disk to ASM Diskgroup
   gather_facts: yes
   hosts: ansible_db
   remote_user: oracle
   roles:
      - {role: asm_add_disk_aix }

# ansible-playbook asm-disk-add.yml

# Sample Output
# =============

[ansible@x134vm232 ansible-power-aix-oracle-dba]$ ansible-playbook asm-disk-add.yml

PLAY [Add disk to ASM Diskgroup] ******************************************************************************************************

TASK [Gathering Facts] ****************************************************************************************************************
[WARNING]: Platform aix on host 129.40.76.82 is using the discovered Python interpreter at /usr/bin/python, but future installation of
another Python interpreter could change this. See https://docs.ansible.com/ansible/2.9/reference_appendices/interpreter_discovery.html
for more information.
ok: [129.40.76.82]

TASK [manage-asmdg-aix : ASMCA | Create script to build asm-diskgroups] ***************************************************************
changed: [129.40.76.82] => (item={'diskgroup': 'PQSTDB', 'disk': [{'device': 'rhdiskasm10'}]})

TASK [manage-asmdg-aix : ASMCA | Add ASM disks] ***************************************************************************************
changed: [129.40.76.82] => (item={'diskgroup': 'PQSTDB', 'disk': [{'device': 'rhdiskasm10'}]})

TASK [manage-asmdg-aix : Print Results] ***********************************************************************************************
ok: [129.40.76.82] => (item=[]) => {
    "ansible_loop_var": "item",
    "item": []
}

PLAY RECAP ****************************************************************************************************************************
129.40.76.82               : ok=4    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
