# Manage ACFS Volume - Readme
# ===========================

# Description: This module is used to Create/Drop ACFS volume in a standalone Grid environment.
# Reference: https://docs.oracle.com/cd/E18283_01/server.112/e16102/asmfs_util004.htm

In the following example we're going to create an ACFS volume called "ACFSDATA1" in a standalone Grid environment.
1. Passwordless SSH must be established between Ansible user & Oracle Database user.
2. An ASM diskgroup must to be created prior creating an acfs volume. Refer the "Readme - Create ASM Diskgroup"
3. This file must be updated: {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/manage-acfs-vars.yml: This file contains all the required variables to create ACFS mount point.

4. Update the hosts and remote_user in the directory: {{ collection_dir }}/power_aix_oracle_dba/playbooks/manage-acfs.yml
- name: Create ACFS SI
  gather_facts: no
  hosts: ansible_db                     # AIX Lpar Hostname defined in ansible inventory.
  remote_user: oracle                   # Grid home owner.
  vars_files:
   - vars/manage-acfs-vars.yml
  roles:
     - {role: manage_acfs }

5. Update the following variables in {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/manage-acfs-vars.yml

$ cat vars/manage-acfs-vars.yml
grid_owner: oracle                   # Grid Software Owner.
oracle_home_gi: /u02/base/grid19c    # Grid Home location.
oracle_sid: +ASM                     # Grid SID.
path: /acfs                          # Path onto which ACFS to be mounted.
diskgroup: ACFSDISK                  # Diskgroup name where ACFS should me created.
volname: ACFSDATA1                   # Desired ACFS volume name to be created.
size: 10G                            # ACFS mount point size.
create_acfs: True                    # True: Creates ACFS mount point | False: Deletes ACFS mount point. Proceed with caution.

6. Execute the following command to run the playbook below. This command requires sudo password of the Grid software owner.

$ ansible-playbook manage-acfs.yml -i inventory.yml --ask-become-pass
BECOME password:

PLAY [Create ACFS SI] *****************************************************************************************************************

TASK [ibm.power_aix_oracle_dba.create_acfs : include_tasks] ***************************************************************************
included: /home/ansible/.ansible/collections/ansible_collections/ibm/power_aix_oracle_dba/roles/create_acfs/tasks/create_acfs.yml for ansible_db

TASK [ibm.power_aix_oracle_dba.create_acfs : Check directory] *************************************************************************
[WARNING]: Platform aix on host ansible_db is using the discovered Python interpreter at /usr/bin/python2.7, but future installation
of another Python interpreter could change the meaning of that path. See https://docs.ansible.com/ansible-
core/2.15/reference_appendices/interpreter_discovery.html for more information.
ok: [ansible_db]

TASK [ibm.power_aix_oracle_dba.create_acfs : Check volume] ****************************************************************************
fatal: [ansible_db]: FAILED! => {"changed": true, "cmd": "asmcmd volinfo --all|grep -w ACFSDATA1", "delta": "0:00:02.430644", "end": "2024-01-12 20:49:01.681447", "msg": "non-zero return code", "rc": 1, "start": "2024-01-12 20:48:59.250803", "stderr": "", "stderr_lines": [], "stdout": "", "stdout_lines": []}
...ignoring

TASK [ibm.power_aix_oracle_dba.create_acfs : fail] ************************************************************************************
skipping: [ansible_db]

TASK [ibm.power_aix_oracle_dba.create_acfs : Create directory] ************************************************************************
changed: [ansible_db]

TASK [ibm.power_aix_oracle_dba.create_acfs : Start acfsload] **************************************************************************
changed: [ansible_db]

TASK [ibm.power_aix_oracle_dba.create_acfs : Create ACFS Volume] **********************************************************************
changed: [ansible_db]

TASK [ibm.power_aix_oracle_dba.create_acfs : Get Volume Device] ***********************************************************************
changed: [ansible_db]

TASK [ibm.power_aix_oracle_dba.create_acfs : Make Filesystem] *************************************************************************
changed: [ansible_db]

TASK [ibm.power_aix_oracle_dba.create_acfs : Mount] ***********************************************************************************
changed: [ansible_db]

TASK [ibm.power_aix_oracle_dba.create_acfs : include_tasks] ***************************************************************************
skipping: [ansible_db]

PLAY RECAP ****************************************************************************************************************************
ansible_db                 : ok=9    changed=7    unreachable=0    failed=0    skipped=2    rescued=0    ignored=1

Note: The ignored error above is a pre-check, this is intended. It can be safely ignored.

To execute this playbook from GUI, an example is provided in the document, please refer this link: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
