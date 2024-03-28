# Add disk to an ASM diskgroup - Readme
# =====================================

# Description: This module is used to Add disks to an existing ASM diskgroup(s).
# Reference: https://docs.oracle.com/database/121/OSTMG/GUID-AEA16D80-2EEA-49C7-BB04-48BBF078F30F.htm#OSTMG94057
# Reference: https://docs.oracle.com/database/121/OSTMG/GUID-85391590-DAD5-46BB-A70C-ED94DA94D18D.htm#OSTMG10071

In the following example, we are going to add /dev/hdisk8 to "CPUDB" diskgroup which is a part of RAC environment.
1. Passwordless SSH must be established between Ansible user & Oracle Database user.
2. Define the required hostname in an inventory file to be used to execute the playbook.
3. Prepare raw disk(s): The raw disks must be prepared to add to the existing Diskgroups. If the disks are Former/Candidate, then skip this step.
   List the disks currently attached to the LPAR. Command: lspv  
   Scan for any new disks. Command: cfgmgr.
   List the disks again. Command: lspv.
   Find an empty disk. Command: lquerypv -h /dev/hdisk8 [The output should look something like shown below].

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

   Change the attributes of the disk: Command: chdev -l hdisk8 -a reserve_policy=no_reserve algorithm=round_robin
   Set ownership. Command: chown grid:oinstall /dev/rhdisk8
   Change permissions. Command: chmod 660 /dev/rhdisk8

4. There are two files which needs to be updated:
        a. {{ collection_dir }}/power_aix_oracle_dba/playbooks/asm-add-disk.yml: This is the playbook.
        b. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/asm-add-disk-vars.yml: This is the file which contains all the required variables. 

5. Update the hosts and remote_user in {{ collection_dir }}/power_aix_oracle_dba/playbooks/asm-add-disk.yml

- name: Add disk to ASM Diskgroup
  gather_facts: no
  hosts: rac21
  remote_user: oracle
  vars_files:
   - vars/asm-add-disk-vars.yml
  roles:
   - {role: podba_asm_add_disk }

6. Update the following variables in {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/asm-add-disk-vars.yml

$ cat vars/asm-add-disk-vars.yml
grid_install_user: oracle             # Grid software owner.
oracle_group: oinstall                     # Grid software owner's primary group.
oracle_home_gi: /ora/grid     # Grid installation software path.
oracle_sid: +ASM1                      # SID of the running ASM instance
asm_diskgroups:                       # Multiple diskgroups can be managed by providing the details as a list.
  - diskgroup: CPUDB                  # ASM diskgroup name to which the disk needs to be added.
    disk:
      - { device: rhdisk8 }           # Raw disk name 1. Multiple raw disks can be added to the list.
#     - { device: rhdisk8 }           # Raw disk name 2.
#  - diskgroup: DATA2                 # ASM diskgroup name to be created.
#    disk:
#     - { device: rhdiskasm1 }        # Raw disk name 1. Multiple raw disks can be added to the list.
#     - { device: rhdiskasm2 }        # Raw disk name 2.

7. Execute the following command to run the playbook

$ ansible-playbook asm-add-disk.yml -i inventory.yml

PLAY [Add disk to ASM Diskgroup] ******************************************************************************************************

TASK [podba_asm_add_disk : ASMCA | Creating script to add asm disk(s)] ****************************************************************
changed: [rac21] => (item={'diskgroup': 'CPUDB', 'disk': [{'device': 'rhdisk8'}]})

TASK [podba_asm_add_disk : ASMCA | Add ASM disks] *************************************************************************************
 changed: [rac21] => (item={'diskgroup': 'CPUDB', 'disk': [{'device': 'rhdisk8'}]})

TASK [podba_asm_add_disk : Add disk status] *******************************************************************************************
changed: [rac21] => (item=[{'diskgroup': 'CPUDB', 'disk': [{'device': 'rhdisk8'}]}, {'device': 'rhdisk8'}])

TASK [podba_asm_add_disk : Print Results] *********************************************************************************************
ok: [rac21] => (item=[{'diskgroup': 'CPUDB', 'disk': [{'device': 'rhdisk8'}]}, {'device': 'rhdisk8'}]) => {
    "msg": [
        "",
        "NAME",
        "------------------------------",
        "PATH",
        "--------------------------------------------------------------------------------",
        "STATE\t HEADER_STATU",
        "-------- ------------",
        "CPUDB_0002",
        "/dev/rhdisk8",
        "NORMAL\t MEMBER"
    ]
}

PLAY RECAP ****************************************************************************************************************************
rac21                      : ok=4    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

To execute this playbook from GUI, an example is provided in the document, please refer this link: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
