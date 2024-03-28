# Manage ACFS Volume on RAC - Readme
# ==================================
# Description: This module is used to Create/Drop ACFS volume in a RAC environment.

In the following example we're going to create an ACFS volume called "ACFSVOLUME" in a RAC environment.
1. Passwordless SSH must be established between Ansible user & Oracle Database user.
2. An ASM diskgroup must exist prior creating an acfs volume. Refer the "Readme - Create ASM Diskgroup"
3. This file must be updated: {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/manage-acfs-rac-vars.yml: This file contains all the required variables to create ACFS mount point.

4. Update the hosts and remote_user in the file: {{ collection_dir }}/power_aix_oracle_dba/playbooks/manage-acfs-rac.yml

- name: Create ACFS in RAC
  gather_facts: no
  hosts: all                  # AIX Lpar hostgroup defined in ansible inventory.
  remote_user: oracle             # Grid Home owner.
  vars_files:
   - vars/manage-acfs-rac-vars.yml
  roles:
     - {role: manage_acfs_rac }

5. Update the following variables in {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/manage-acfs-rac-vars.yml

$ cat vars/manage-acfs-rac-vars.yml
grid_owner: oracle                       # Grid Home Owner.
grid_group: oinstall                     # Grid Home Owner's primary group
oracle_home_gi: /ora/grid        # Grid Home path.
oracle_sid: +APX1                        # ASM/APX SID running on the connected node.
path: /acfs                              # Path onto which ACFS to be mounted.
diskgroup: ACFSDISK                      # Diskgroup name where ACFS should me created.
volname: ACFSVOLUME                      # Desired ACFS volume name to be created.
size: 95G                                # ACFS mount point size that needs to be allocated.
create_acfs: True                        # True: Creates ACFS mount point. False: Does ntohing.
delete_acfs: False                       # True: Deletes ACFS mount point. False: Does nothing.

6. Execute the following command to run the playbook below. This command requires sudo password of the Grid software owner.

$ ansible-playbook manage-acfs-rac.yml -i inventory.yml --ask-become-pass

BECOME password:
PLAY [Create ACFS in RAC] ******************************************************

TASK [create_acfs_rac : ansible.builtin.include_tasks] *************************
included: /home/ansible/.ansible/collections/ansible_collections/ibm/power_aix_oracle_dba/roles/create_acfs_rac/tasks/create_acfs.yml for rac21

TASK [create_acfs_rac : Check volume] ******************************************
[WARNING]: Platform aix on host rac21 is using the discovered Python
interpreter at /usr/bin/python3, but future installation of another Python
interpreter could change the meaning of that path. See
https://docs.ansible.com/ansible-
core/2.15/reference_appendices/interpreter_discovery.html for more information.
fatal: [rac21]: FAILED! => {"ansible_facts": {"discovered_interpreter_python": "/usr/bin/python3"}, "changed": true, "cmd": "asmcmd volinfo --all|grep -w ACFSVOLUME", "delta": "0:00:05.012710", "end": "2024-03-06 21:09:39.668126", "msg": "non-zero return code", "rc": 1, "start": "2024-03-06 21:09:34.655416", "stderr": "", "stderr_lines": [], "stdout": "", "stdout_lines": []}
...ignoring

TASK [create_acfs_rac : Check directory] ***************************************
ok: [rac21]

TASK [create_acfs_rac : Create directory] **************************************
changed: [rac21]

TASK [create_acfs_rac : ansible.builtin.fail] **********************************
skipping: [rac21]

TASK [create_acfs_rac : Create ACFS Volume] ************************************
changed: [rac21]

TASK [create_acfs_rac : Get Volume Device] *************************************
changed: [rac21]

TASK [create_acfs_rac : Make Filesystem] ***************************************
changed: [rac21]

TASK [create_acfs_rac : Add filesystem] ****************************************
changed: [rac21]

TASK [create_acfs_rac : start filesystem] **************************************
changed: [rac21]

TASK [create_acfs_rac : Add permissions to oracle user] ************************
changed: [rac21]

TASK [create_acfs_rac : Verify New ACFS] ***************************************
changed: [rac21]

TASK [create_acfs_rac : Verify New ACFS] ***************************************
ok: [rac21] => {
    "msg": [
        "Filesystem    GB blocks      Free %Used    Iused %Iused Mounted on",
        "/dev/asm/acfsvolume-5     95.00     93.74    2%   329234     2% /acfs"
    ]
}

TASK [create_acfs_rac : ansible.builtin.include_tasks] *************************
skipping: [rac21]

PLAY RECAP *********************************************************************
rac21                      : ok=12   changed=9    unreachable=0    failed=0    skipped=2    rescued=0    ignored=1   

Note: The ignored error above is a pre-check, this is intended. It can be safely ignored.

To execute this playbook from GUI, an example is provided in the document, please refer this link: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
