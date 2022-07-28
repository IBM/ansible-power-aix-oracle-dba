# Create ASM diskgroup - Readme
# =============================

# Description: This module is used to create ASM diskgroup. 

# Prerequisites:
# ==============
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

# Refer Oracle ASM Configuration Assistant Command-Line Interface section in https://docs.oracle.com/cd/E11882_01/server.112/e18951/asmca.htm#OSTMG60000

# Set the Variables for Oracle to execute this task: Open the file ansible-power-aix-oracle-dba/roles/create_asmdg_aix/defaults/main.yml and modify the variables. Modify only the ones which are marked with comments.

oracle_home_gi: /u01/app/19c/grid            	# Grid Home Location
oracle_rsp_stage: /u01/app/stage             	# Any accessible location on remote host to stage scripts. Must be created manually.
grid_install_user: "{{ ansible_user_id }}"
oracle_group: oinstall                       	# Grid owner's primary user group
oracle_asm_disk_string: "/dev/"              	# Entry point of the raw disk
asm_diskgroups:
  - diskgroup: ACFSDATA1                     	# Desired dikgroup name to be created.
    properties:
      - {redundancy: external, ausize: 1 }      # Redundancy: External, Normal, Ausize 1MB is default
    attributes:
      - {name: 'compatible.rdbms', value: 19.0.0.0}
      - {name: 'compatible.asm', value: 19.0.0.0}
    disk:
      - {device: rhdisk8}           		# Raw disk name 1 with which the diskgroup needs to be created. The diskgroup can be created with multiple disks by adding them to the following list. Comment them if not being used to avoid failure.
#      - {device: rhdisk9}           		# Raw disk name 2 
#      - {device: rhdisk10}          		# Raw disk name 3
#      - {device: diskn}			# Raw disk name n, more number of disks can be added to the list.      

# Executing the playbook: This playbook executes a role. Before running the playbook, open the playbook and update the hostname & remote user details as shown below. Do NOT change other parts of the script.
# Change directory to ansible-power-aix-oracle-dba
# Name of the Playbook: asm-dg-create.yml
# Content of the playbook

 - name: Create ASM Diskgroup
   gather_facts: yes
   hosts: ansible_db                                   # AIX Lpar Hostname where the Diskgroup has to be created.
   remote_user: oracle                                 # Grid Home Owner
   roles:
      - {role: create_asmdg_aix }

# ansible-playbook asm-dg-create.yml

# Sample Output:
# =============

[ansible@x134vm232 ansible-power-aix-oracle-dba]$ ansible-playbook asm-dg-create.yml

PLAY [Create ASM Diskgroup] ***********************************************************************************************************

TASK [Gathering Facts] ****************************************************************************************************************
[WARNING]: Platform aix on host 129.40.76.82 is using the discovered Python interpreter at /usr/bin/python, but future installation of
another Python interpreter could change this. See https://docs.ansible.com/ansible/2.9/reference_appendices/interpreter_discovery.html
for more information.
ok: [129.40.76.82]

TASK [create_asmdg_aix : ASMCA | Create script to build asm-diskgroups] ***************************************************************
changed: [129.40.76.82] => (item={'diskgroup': 'PQSTDB', 'properties': [{'redundancy': 'external', 'ausize': 1}], 'attributes': [{'name': 'compatible.rdbms', 'value': '19.0.0.0'}, {'name': 'compatible.asm', 'value': '19.0.0.0'}], 'disk': [{'device': 'rhdiskasm13'}]})

TASK [create_asmdg_aix : ASMCA | Create ASM diskgroups] *******************************************************************************
changed: [129.40.76.82] => (item={'diskgroup': 'PQSTDB', 'properties': [{'redundancy': 'external', 'ausize': 1}], 'attributes': [{'name': 'compatible.rdbms', 'value': '19.0.0.0'}, {'name': 'compatible.asm', 'value': '19.0.0.0'}], 'disk': [{'device': 'rhdiskasm13'}]})

TASK [create_asmdg_aix : Print Results] ***********************************************************************************************
ok: [129.40.76.82] => (item=['', '[DBT-30001] Disk groups created successfully. Check /u01/base/cfgtoollogs/asmca/asmca-220622AM032455.log for details.']) => {
    "ansible_loop_var": "item",
    "item": [
        "",
        "[DBT-30001] Disk groups created successfully. Check /u01/base/cfgtoollogs/asmca/asmca-220622AM032455.log for details."
    ]
}

TASK [create_asmdg_aix : ASMCA | List ASM diskgroups] *********************************************************************************
changed: [129.40.76.82] => (item={'diskgroup': 'PQSTDB', 'properties': [{'redundancy': 'external', 'ausize': 1}], 'attributes': [{'name': 'compatible.rdbms', 'value': '19.0.0.0'}, {'name': 'compatible.asm', 'value': '19.0.0.0'}], 'disk': [{'device': 'rhdiskasm13'}]})

TASK [create_asmdg_aix : list diskgroups] *********************************************************************************************
ok: [129.40.76.82] => (item=['Disk Group PQSTDB is running on p125n82']) => {
    "ansible_loop_var": "item",
    "item": [
        "Disk Group PQSTDB is running on p125n82"
    ]
}

PLAY RECAP ****************************************************************************************************************************
129.40.76.82               : ok=6    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
