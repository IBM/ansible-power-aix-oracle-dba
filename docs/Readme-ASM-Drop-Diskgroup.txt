# Drop ASM diskgroup - Readme
# ===========================
# Description: This module is used to Drop ASM diskgroups.
# Reference: https://docs.oracle.com/database/121/SQLRF/statements_8014.htm#SQLRF01517

In the following example, we are going to drop a diskgroup "PQSTDB" from a Standalone GI environment.
1. Passwordless SSH must be established between Ansible user and the Grid user.
2. Define the required hostname in an inventory file to be used in the playbook.
3. There are two files which needs to be updated:
        a. {{ collection_dir }}/power_aix_oracle_dba/playbooks/asm-drop-disk-dg.yml: This is the playbook.
        b. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/asm-drop-disk-dg-vars.yml: This is the file which contains all the required variables.

4. Update the hosts and remote_user in {{ collection_dir }}/power_aix_oracle_dba/playbooks/asm-drop-disk-dg.yml

$ cat asm-drop-disk-dg.yml

- name: Drop ASM Diskgroup/Disk
  gather_facts: no
  hosts: ansible_db                 # AIX Lpar Hostname where the Diskgroup has to be dropped. Proceed with caution.
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
   - diskgroup: PQSTDB                 # Name of the diskgroup to perform modifications or deletion.
     disk: PQSTDB_0001                 # Desired Diskname to drop from the diskgroup. The disk name can be found from v$asm_disk.

is_rac: False                         # If this is RAC environment set to True & update racnodes below, if NOT, mention False.
racnodes: rac22,rac23,rac24             # Rac node names except the primary node. Applicable to RAC only.

# Note: When setting the below parameters, only one must be True at the same time. Please proceed with caution.

drop_diskgroup: True                 # If a diskgroup needs to be dropped, set it to True otherwise set it False.
drop_disk: False                       # If a disk from diskgroup needs to be dropped, set it to True otherwise set it False.

6. Execute the following command to run the playbook

$ ansible-playbook asm-drop-disk-dg.yml -i inventory.yml

PLAY [Drop ASM Diskgroup/Disk] ********************************************************************************************************

TASK [podba_asm_drop_disk_dg : Diskgroup check] ******************************************************************************************
changed: [ansible_db] => (item={'diskgroup': 'PQSTDB', 'disk': 'PQSTDB_0001'})

TASK [podba_asm_drop_disk_dg : Dismount ASM diskgroup] ***********************************************************************************
skipping: [ansible_db] => (item={'diskgroup': 'PQSTDB', 'disk': 'PQSTDB_0001'})

TASK [podba_asm_drop_disk_dg : Drop ASM diskgroup] ***************************************************************************************
changed: [ansible_db] => (item={'diskgroup': 'PQSTDB', 'disk': 'PQSTDB_0001'})

TASK [podba_asm_drop_disk_dg : Drop ASM Disk] ********************************************************************************************
skipping: [ansible_db] => (item={'diskgroup': 'PQSTDB', 'disk': 'PQSTDB_0001'})

TASK [podba_asm_drop_disk_dg : debug] ****************************************************************************************************
ok: [ansible_db] => {
    "dropdisk": {
        "changed": false,
        "msg": "All items completed",
        "results": [
            {
                "ansible_loop_var": "item",
                "changed": false,
                "item": {
                    "disk": "PQSTDB_0001",
                    "diskgroup": "PQSTDB"
                },
                "skip_reason": "Conditional result was False",
                "skipped": true
            }
        ]
    }
}

PLAY RECAP ****************************************************************************************************************************
ansible_db               : ok=4    changed=2    unreachable=0    failed=0    skipped=2    rescued=0    ignored=0

To execute this playbook from GUI, an example is provided in the document, please refer this link: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
