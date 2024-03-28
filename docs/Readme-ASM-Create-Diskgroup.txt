# Create ASM diskgroup - Readme
# =============================

# Description: The role "create_asmdg_aix" is used to create ASM diskgroup in a standalone Grid infrastructure (or) RAC.
# Refer Oracle ASM Configuration Assistant Command-Line Interface section in https://docs.oracle.com/cd/E11882_01/server.112/e18951/asmca.htm#OSTMG60000

In the following example we're going to create a diskgroup "ACFSDISK" in a standalone Grid infrastructure environment.
1. Passwordless SSH must be established between Ansible user & Oracle Database user.
2. Define the required hostname in an inventory file to be used to execute the playbook.
3. Prepare raw disk(s): The raw disks must be prepared to for creating ASM diskgroups. If the disks are Former/Candidate, then skip this step.

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
	a. {{ collection_dir }}/power_aix_oracle_dba/playbooks/asm-dg-create.yml: This is the playbook which will execute "create_asmdg_aix".
	b. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/asm-dg-create-vars.yml: This is the file which contains all the required variables to create a diskgroup.

5. Update the hosts and remote_user in {{ collection_dir }}/power_aix_oracle_dba/playbooks/asm-dg-create.yml.
$ cat asm-dg-create.yml
 - name: Create ASM Diskgroup
   gather_facts: no
   hosts: ansible_db                                   # AIX Lpar Hostname where the Diskgroup has to be created.
   remote_user: oracle                                 # Grid Software owner.
   vars_files:
    - vars/asm-dg-create-vars.yml
   roles:
    - {role: ibm.power_aix_oracle_dba.create_asmdg_aix }

6. Update the following variables in {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/asm-dg-create.yml
$ cat vars/asm-dg-create-vars.yml
grid_install_user: oracle                       # Grid software owner.
oracle_home_gi: /u02/base/grid19c               # Grid Home Location.
oracle_rsp_stage: /tmp                          # Any accessible location on remote host to stage scripts.
oracle_group: oinstall                          # Grid owner's primary user group.
oracle_asm_disk_string: "/dev/"                 # Entry point of the raw disk. Example "/dev".
asm_diskgroups:
  - diskgroup: ACFSDISK                         # Desired dikgroup name to be created.
    properties:
      - {redundancy: external, ausize: 1 }      # Redundancy: External, Normal, Ausize 1MB is default.
    attributes:
      - {name: 'compatible.rdbms', value: 19.0.0.0}
      - {name: 'compatible.asm', value: 19.0.0.0}
    disk:
      - {device: rhdisk7}                       # Provide raw disk name 1 on which the diskgroup needs to be created.
#      - {device: rhdisk8}                        # Provide raw disk name 2, more number of disks can be added to the list.

7. Execute the following command to run the playbook

$ ansible-playbook asm-dg-create.yml -i inventory.yml

PLAY [Create ASM Diskgroup] ***********************************************************************************************************

TASK [ibm.power_aix_oracle_dba.create_asmdg_aix : ASMCA | Check diskgroups] ***********************************************************
changed: [ansible_db] => (item={'diskgroup': 'ACFSDISK', 'properties': [{'redundancy': 'external', 'ausize': 1}], 'attributes': [{'name': 'compatible.rdbms', 'value': '19.0.0.0'}, {'name': 'compatible.asm', 'value': '19.0.0.0'}], 'disk': [{'device': 'rhdisk7'}]})
[WARNING]: Platform aix on host ansible_db is using the discovered Python interpreter at /usr/bin/python2.7, but future installation
of another Python interpreter could change the meaning of that path. See https://docs.ansible.com/ansible-
core/2.15/reference_appendices/interpreter_discovery.html for more information.

TASK [ibm.power_aix_oracle_dba.create_asmdg_aix : ASMCA | Create script to build asm-diskgroups] **************************************
changed: [ansible_db] => (item={'diskgroup': 'ACFSDISK', 'properties': [{'redundancy': 'external', 'ausize': 1}], 'attributes': [{'name': 'compatible.rdbms', 'value': '19.0.0.0'}, {'name': 'compatible.asm', 'value': '19.0.0.0'}], 'disk': [{'device': 'rhdisk7'}]})

TASK [ibm.power_aix_oracle_dba.create_asmdg_aix : ASMCA | Create ASM diskgroups] ******************************************************
changed: [ansible_db] => (item={'diskgroup': 'ACFSDISK', 'properties': [{'redundancy': 'external', 'ausize': 1}], 'attributes': [{'name': 'compatible.rdbms', 'value': '19.0.0.0'}, {'name': 'compatible.asm', 'value': '19.0.0.0'}], 'disk': [{'device': 'rhdisk7'}]})

TASK [ibm.power_aix_oracle_dba.create_asmdg_aix : Print Results] **********************************************************************
ok: [ansible_db] => (item=['', '[DBT-30001] Disk groups created successfully. Check /u02/base/cfgtoollogs/asmca/asmca-240102AM040928.log for details.']) => {
    "ansible_loop_var": "item",
    "item": [
        "",
        "[DBT-30001] Disk groups created successfully. Check /u02/base/cfgtoollogs/asmca/asmca-240102AM040928.log for details."
    ]
}

TASK [ibm.power_aix_oracle_dba.create_asmdg_aix : ASMCA | List ASM diskgroups] ********************************************************
changed: [ansible_db] => (item={'diskgroup': 'ACFSDISK', 'properties': [{'redundancy': 'external', 'ausize': 1}], 'attributes': [{'name': 'compatible.rdbms', 'value': '19.0.0.0'}, {'name': 'compatible.asm', 'value': '19.0.0.0'}], 'disk': [{'device': 'rhdisk7'}]})

TASK [ibm.power_aix_oracle_dba.create_asmdg_aix : list diskgroups] ********************************************************************
ok: [ansible_db] => (item=['Disk Group ACFSDISK is running on ansible_db']) => {
    "ansible_loop_var": "item",
    "item": [
        "Disk Group ACFSDISK is running on ansible_db"
    ]
}

PLAY RECAP ****************************************************************************************************************************
ansible_db                 : ok=6    changed=4    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

To execute this playbook from GUI, an example is provided in the document, please refer this link: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
