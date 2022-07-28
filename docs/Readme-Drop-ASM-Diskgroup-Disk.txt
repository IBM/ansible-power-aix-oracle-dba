# Drop ASM diskgroup/Disk - Readme
# ================================
# Description: This module is used to perform any one of the two tasks: 1) Drop ASM diskgroups, 2) Drop ASM disks.
# Reference: https://docs.oracle.com/database/121/SQLRF/statements_8014.htm#SQLRF01517

# Prerequisites:
# ==============
# Passwordless ssh needs to be setup between the Target lpar oracle owner and ansible controller user.

# 1) Drop ASM diskgroups
# ======================

# Set the Variables for Oracle to execute the task to Drop Diskgroup: Open the file ansible-power-aix-oracle-dba/roles/drop_asmdg_disk_aix/defaults/main.yml and modify the variables. Modify only the ones which are marked with comments.

grid_install_user: "{{ ansible_user_id }}"
oracle_group: oinstall                        # Grid owner's primary user group.
oracle_home_gi: /u01/grid19c                  # Grid Home Location.
oracle_rsp_stage: /u01/app/stage              # Location on aix lpar to copy response file.
asm_diskgroups:
   - diskgroup: PQSTDB                        # Name of the diskgroup to perform modifications or deletion.
     disk: PQSTDB_0001                        # Required Diskname to drop. Value obtained from v$asm_disk.
oracle_sid: +ASM                              # SID of the running ASM instance.

is_rac: False                                 # If this is RAC environment set to True & update racnodes below, if NOT, mention False.
racnodes: rac93,rac94                         # Rac node names except one node where asm diskgroup is running. Applicable to RAC only.
oracle_env:
       ORACLE_HOME: "{{ oracle_home_gi }}"
       ORACLE_SID: "{{ oracle_sid }}"
       PATH: "{{ oracle_home_gi }}/bin:$PATH"

# Note: When setting the following parameter, only one must be True at the same time.

drop_diskgroup: True                          # If diskgroup needs to be dropped, set it to True otherwise set it False.
drop_disk: False                              # If a disk from diskgroup needs to be dropped, set it to True otherwise set it False.

# Executing the playbook: This playbook executes a role. Before running the playbook, open the playbook and update the hostname & remote user details which as shown with the comments below. Do NOT change other parts of the script.
# Change directory to ansible-power-aix-oracle-dba
# Name of the Playbook: asm-dg-manage.yml
# Content of the playbook

 - name: Manage ASM Diskgroup/Disk
   gather_facts: yes
   hosts: ansible_db                 # AIX Lpar Hostname where the Diskgroup/Disk has to be dropped.
   remote_user: oracle               # Grid Home Owner
   roles:
      - {role: drop_asmdg_disk_aix }

# ansible-playbook asm-dg-disk-drop.yml

# Sample Output to drop diskgroup
# ===============================

[ansible@x134vm232 ansible-power-aix-oracle-dba]$ ansible-playbook asm-dg-disk-drop.yml

PLAY [Manage ASM Diskgroup/Disk] ******************************************************************************************************

TASK [Gathering Facts] ****************************************************************************************************************
[WARNING]: Platform aix on host 129.40.76.82 is using the discovered Python interpreter at /usr/bin/python, but future installation of
another Python interpreter could change this. See https://docs.ansible.com/ansible/2.9/reference_appendices/interpreter_discovery.html
for more information.
ok: [129.40.76.82]

TASK [drop_asmdg_disk_aix : Diskgroup check] ******************************************************************************************
changed: [129.40.76.82] => (item={'diskgroup': 'PQSTDB', 'disk': 'PQSTDB_0001'})

TASK [drop_asmdg_disk_aix : Dismount ASM diskgroup] ***********************************************************************************
skipping: [129.40.76.82] => (item={'diskgroup': 'PQSTDB', 'disk': 'PQSTDB_0001'})

TASK [drop_asmdg_disk_aix : Drop ASM diskgroup] ***************************************************************************************
changed: [129.40.76.82] => (item={'diskgroup': 'PQSTDB', 'disk': 'PQSTDB_0001'})

TASK [drop_asmdg_disk_aix : Drop ASM Disk] ********************************************************************************************
skipping: [129.40.76.82] => (item={'diskgroup': 'PQSTDB', 'disk': 'PQSTDB_0001'})

TASK [drop_asmdg_disk_aix : debug] ****************************************************************************************************
ok: [129.40.76.82] => {
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
129.40.76.82               : ok=4    changed=2    unreachable=0    failed=0    skipped=2    rescued=0    ignored=0

# 2) Drop ASM disks
# =================

# Reference: https://docs.oracle.com/database/121/OSTMG/GUID-44160C76-20B6-40C8-82F8-FF332A28899E.htm#OSTMG10222
# Set the Variables for Oracle to execute the task to Drop Disk: Open the file ansible-power-aix-oracle-dba/roles/drop_asmdg_disk_aix/defaults/main.yml and modify the variables. Modify only the ones which are marked with comments.

grid_install_user: "{{ ansible_user_id }}"
oracle_group: oinstall                        # Grid owner's primary user group
oracle_home_gi: /u01/grid19c                  # Grid Home Location
oracle_rsp_stage: /u01/app/stage                  # Location on aix lpar to copy response file
asm_diskgroups:
   - diskgroup: PQSTDB                        # Name of the diskgroup to perform modifications or deletion.
     disk: PQSTDB_0001                        # Desired Diskname to drop. Value obtained from v$asm_disk.
oracle_sid: +ASM                              # SID of the running ASM instance

is_rac: False                                 # If this is RAC environment set to True & update racnodes below, if NOT, mention False.
racnodes: rac93,rac94                         # Rac node names except one node where asm diskgroup is running. Applicable to RAC only.
oracle_env:
       ORACLE_HOME: "{{ oracle_home_gi }}"
       ORACLE_SID: "{{ oracle_sid }}"
       PATH: "{{ oracle_home_gi }}/bin:$PATH"

# Note: When setting the following parameter, only one must be True at the same time.

drop_diskgroup: False                          # If diskgroup needs to be dropped, set it to True otherwise set it False.
drop_disk: True                              # If a disk from diskgroup needs to be dropped, set it to True otherwise set it False.

# Sample Output to drop disk
# ==========================

[ansible@x134vm232 ansible-power-aix-oracle-dba]$ ansible-playbook asm-dg-disk-drop.yml

PLAY [Manage ASM Diskgroup/Disk] ******************************************************************************************************

TASK [Gathering Facts] ****************************************************************************************************************
[WARNING]: Platform aix on host 129.40.76.82 is using the discovered Python interpreter at /usr/bin/python, but future installation of
another Python interpreter could change this. See https://docs.ansible.com/ansible/2.9/reference_appendices/interpreter_discovery.html
for more information.
ok: [129.40.76.82]

TASK [drop_asmdg_disk_aix : Diskgroup check] ******************************************************************************************
changed: [129.40.76.82] => (item={'diskgroup': 'PQSTDB', 'disk': 'PQSTDB_0001'})

TASK [drop_asmdg_disk_aix : Dismount ASM diskgroup] ***********************************************************************************
skipping: [129.40.76.82] => (item={'diskgroup': 'PQSTDB', 'disk': 'PQSTDB_0001'})

TASK [drop_asmdg_disk_aix : Drop ASM diskgroup] ***************************************************************************************
skipping: [129.40.76.82] => (item={'diskgroup': 'PQSTDB', 'disk': 'PQSTDB_0001'})

TASK [drop_asmdg_disk_aix : Drop ASM Disk] ********************************************************************************************
changed: [129.40.76.82] => (item={'diskgroup': 'PQSTDB', 'disk': 'PQSTDB_0001'})

PLAY RECAP ****************************************************************************************************************************
129.40.76.82               : ok=3    changed=2    unreachable=0    failed=0    skipped=2    rescued=0    ignored=0
