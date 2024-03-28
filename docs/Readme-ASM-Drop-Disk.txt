# Drop a disk from an ASM diskgroup - Readme
# ==========================================

# Description: This module is used to delete disks from an existing ASM diskgroup(s).

In the following example, we are going to delete /dev/hdisk8 from "CPUDB" diskgroup which is a part of RAC environment.
1. Passwordless SSH must be established between Ansible user & Oracle Database user.
2. Define the required hostname in an inventory file to be used in the playbook.

3. There are two files which needs to be updated:
        a. {{ collection_dir }}/power_aix_oracle_dba/playbooks/asm-drop-disk-dg.yml: This is the playbook.
        b. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/asm-drop-disk-dg-vars.yml: This is the file which contains all the required variables.

4. Update the hosts and remote_user in {{ collection_dir }}/power_aix_oracle_dba/playbooks/asm-drop-disk-dg.yml

$ cat asm-drop-disk-dg.yml

- name: Drop ASM Diskgroup/Disk
  gather_facts: no
  hosts: rac21                 # AIX Lpar Hostname where the Disk has to be dropped. Proceed with caution.
  remote_user: oracle               # Grid Home Owner
  vars_files:
   - vars/asm-drop-disk-dg-vars.yml
  roles:
     - {role: podba_asm_drop_disk_dg }

5. Update the following variables in {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/asm-drop-disk-dg-vars.yml

$ cat vars/asm-drop-disk-dg-vars.yml
grid_install_user: oracle             # Grid software owner.
oracle_home_gi: /ora/grid     # Grid Home Location
oracle_sid: +ASM1                      # SID of the running ASM instance
asm_diskgroups:
   - diskgroup: CPUDB                 # Name of the diskgroup to perform modifications or deletion.
     disk: CPUDB_0002                 # Desired Diskname to drop from the diskgroup. The disk name can be found from v$asm_disk.

is_rac: True                         # If this is RAC environment set to True & update racnodes below, if NOT, mention False.
racnodes: rac22,rac23,rac24             # Rac node names except the primary node. Applicable to RAC only.

# Note: When setting the below parameters, only one must be True at the same time. Please proceed with caution.

drop_diskgroup: False                 # If a diskgroup needs to be dropped, set it to True otherwise set it False.
drop_disk: True                       # If a disk from diskgroup needs to be dropped, set it to True otherwise set it False.

6. Execute the following command to run the playbook

$ ansible-playbook asm-drop-disk-dg.yml -i inventory.yml

PLAY [Drop ASM Diskgroup/Disk] ********************************************************************************************************

TASK [podba_asm_drop_disk_dg : Diskgroup check] ***************************************************************************************
changed: [rac21] => (item={'diskgroup': 'CPUDB', 'disk': 'CPUDB_0002'})

TASK [podba_asm_drop_disk_dg : Dismount ASM diskgroup] ********************************************************************************
skipping: [rac21] => (item={'diskgroup': 'CPUDB', 'disk': 'CPUDB_0002'})
skipping: [rac21]

TASK [podba_asm_drop_disk_dg : Drop ASM diskgroup] ************************************************************************************
skipping: [rac21] => (item={'diskgroup': 'CPUDB', 'disk': 'CPUDB_0002'})
skipping: [rac21]

TASK [podba_asm_drop_disk_dg : Drop ASM Disk] *****************************************************************************************
changed: [rac21] => (item={'diskgroup': 'CPUDB', 'disk': 'CPUDB_0002'})

TASK [podba_asm_drop_disk_dg : Drop disk status] **************************************************************************************
changed: [rac21] => (item={'diskgroup': 'CPUDB', 'disk': 'CPUDB_0002'})

TASK [podba_asm_drop_disk_dg : Print Results] *****************************************************************************************
ok: [rac21] => (item={'diskgroup': 'CPUDB', 'disk': 'CPUDB_0002'}) => {
    "msg": [
        "",
        "no rows selected"
    ]
}

PLAY RECAP ****************************************************************************************************************************
rac21                      : ok=4    changed=3    unreachable=0    failed=0    skipped=2    rescued=0    ignored=0

To execute this playbook from GUI, an example is provided in the document, please refer this link: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
