# Apply Patch on a Standalone Oracle Grid Infrastructure - Readme
# ===============================================================
# Description: This module is used to apply Release Update and other patches on Oracle Standalone GI.
# It does "prereq CheckConflictAgainstOHWithDetail" before applying the patch and exits if there are any conflicts.

In the following example, we will apply RU 19.21 on a Standalone Grid Infrastructure.

1. Passwordless SSH must be established between Ansible user & Grid user.
2. SUDO utility must be installed on all the target lpars and the grid user must have sudo privilege to execute root actions. It is required by the "opatchauto" utility.
3. In ansible.cfg file:
        a. set "remote_tmp" to a path where there is minimum 16GB of free space. It is for the remote staging option for patches. 
        b. Make sure "python3" utility is available in /usr/bin directory on the target lpars.
4. There are two files which needs to be updated.
        a. {{ collection_dir }}/power_aix_oracle_dba/playbooks/gi-si-opatchauto.yml: This is the playbook.
        b. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/gi-si-opatchauto-vars.yml: This file contains all the required variables.

5. Update the hosts and remote_user in the file: {{ collection_dir }}/power_aix_oracle_dba/playbooks/gi-si-opatchauto.yml

- name: Apply patches to GI
  hosts: ansible_db                     # AIX Lapr hostgroup name defined in Ansible inventory.
  remote_user: oracle                   # Grid Home Owner.
  gather_facts: False
  vars_files:
   - vars/gi-si-opatchauto-vars.yml
  roles:
     - {role: oraswgi_manage_patches }

6. Update the following variables in {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/gi-si-opatchauto-vars.yml

grid_install_user: oracle                       # Grid installation home Owner.
oracle_group: oinstall                          # Primary group for oracle/grid user.
apply_patches_gi: True
oracle_home_gi_so: "/u02/base/grid19c"          # ORACLE_HOME for Grid Infrastructure (Stand Alone)
configure_cluster: False                        # True: For RAC GI, False: For SI GI
oracle_install_version_gi: 19.3.0

################################
# Patch files staging variables#
################################

ora_binary_location: local                        # local|nfs|remote.
ora_nfs_host: 129.40.76.1                       # NFS server name if "ora_binary_location is nfs".
ora_nfs_device: /repos                          # NFS filesystem if "ora_binary_location is nfs".
ora_nfs_filesystem: /repos                      # Path on the target lpar to mount the NFS filesystem if "ora_binary_location is nfs".

oracle_patch_stage: /backup/patches/RU          # Provide the path on the target lpar with sufficient space to extract patch zipfiles if "ora_binary_locationis local". This path will be created by this Ansible playbook.

oracle_sw_patches:
 - filename: /repos/images/oracle/19c/RU19.21/p35642822_190000_AIX64-5L_RU19.21.zip # Provide full path( based on nfs|local|remote) and the zipfile name.
   patchid: 35642822                            # Release update Patch ID to be applied.
   version: 19.3.0                              # Grid Version must be the same defined for the variable "oracle_install_version_gi"
   patchversion: 19.21.0.0                      # Release update patch version
   description: GI-RU-Oct-2023                  # This is an optional parameter shows the description of the patch.

oracle_opatch_patch:
 - filename: /repos/images/oracle/opatch/12.2.0.1.41/opatch-12.2.0.1.41_p6880880_210000_AIX64-5L.zip # Provide full path(based on nfs|local|remote) and the zipfile name.
   version: 19.3.0                              # Grid Version must be the same defined for the variable "oracle_install_version_gi"

#####################################
# Grid Home environment Variables   #
#####################################

gi_patches:
   opatch_minversion: 12.2.0.1.41         # Minimum opatch version required to apply the patch as per Oracle readme.txt file
   opatchauto:
       - patchid: 35642822                # Release update Patch ID to be applied.
         patchversion: 19.21.0            # Release update patch version obtained from Oracle readme.txt file
         state: present                   # present - applies the patch, absent - rollsback the patch.
         subpatches: []
   opatch: []

7. Execute the playbook

$ ansible-playbook gi-si-opatchauto.yml -i inventory.yml --ask-become-pass
BECOME password:

PLAY [Apply patches to GI] ************************************************************************************************************************************************************************

TASK [Gathering Facts] ************************************************************************************************************************************************************************
[WARNING]: Platform aix on host ansible_db is using the discovered Python interpreter at /usr/bin/python2.7, but future installation of another Python interpreter could change the meaning of that
path. See https://docs.ansible.com/ansible-core/2.15/reference_appendices/interpreter_discovery.html for more information.
ok: [ansible_db]

TASK [oraswgi_manage_patches : gi-opatch | check if GI has been configured] ***************************************************************************************************
ok: [ansible_db]

TASK [oraswgi_manage_patches : gi-opatch | set fact for patch_before_rootsh] **************************************************************************************************
ok: [ansible_db]

TASK [oraswgi_manage_patches : Creating NFS filesystem from nfshost.] *********************************************************************************************************
ok: [ansible_db]

TASK [oraswgi_manage_patches : gi-opatch | Create patch-base directory (version specific)] ************************************************************************************
ok: [ansible_db]

TASK [oraswgi_manage_patches : gi-opatch | Extract GI psu files to patch base (from local|nfs)] *******************************************************************************
ok: [ansible_db] => (item=[{'filename': '/repos/images/oracle/19c/RU19.21/p35642822_190000_AIX64-5L_RU19.21.zip', 'patchid': 35642822, 'version': '19.3.0', 'patchversion': '19.21.0.0', 'description': 'GI-RU-Oct-2023'}, {'patchid': 35642822, 'patchversion': '19.21.0', 'state': 'present', 'subpatches': []}])

TASK [oraswgi_manage_patches : gi-opatch | Extract GI psu files to patch base (from remote)] **********************************************************************************
skipping: [ansible_db] => (item=[{'filename': '/repos/images/oracle/19c/RU19.21/p35642822_190000_AIX64-5L_RU19.21.zip', 'patchid': 35642822, 'version': '19.3.0', 'patchversion': '19.21.0.0', 'description': 'GI-RU-Oct-2023'}, {'patchid': 35642822, 'patchversion': '19.21.0', 'state': 'present', 'subpatches': []}])
skipping: [ansible_db]

TASK [oraswgi_manage_patches : gi-opatch | Check opatch] **********************************************************************************************************************
ok: [ansible_db]

TASK [oraswgi_manage_patches : gi-opatch | Check current opatch version] ******************************************************************************************************
ok: [ansible_db]

TASK [oraswgi_manage_patches : gi-opatch | Backup existing OPatch directory] **************************************************************************************************
skipping: [ansible_db] => (item={'filename': '/repos/images/oracle/opatch/opatch-12.2.0.1.41_p6880880_210000_AIX64-5L.zip', 'version': '19.3.0'})
skipping: [ansible_db]

TASK [oraswgi_manage_patches : gi-opatch | Extract OPatch to GI Home (from local/nfs)] ****************************************************************************************
skipping: [ansible_db] => (item={'filename': '/repos/images/oracle/opatch/opatch-12.2.0.1.41_p6880880_210000_AIX64-5L.zip', 'version': '19.3.0'})
skipping: [ansible_db]

TASK [oraswgi_manage_patches : gi-opatch | Extract OPatch to GI Home (from remote location)] **********************************************************************************
skipping: [ansible_db] => (item={'filename': '/repos/images/oracle/opatch/opatch-12.2.0.1.41_p6880880_210000_AIX64-5L.zip', 'version': '19.3.0'})
skipping: [ansible_db]

TASK [oraswgi_manage_patches : gi-opatch | Manage opatchauto patches for GI (after software only install)] ********************************************************************
skipping: [ansible_db]

TASK [oraswgi_manage_patches : gi-opatch | Manage opatchauto patches for GI] **************************************************************************************************
 changed: [ansible_db] => (item={'patchid': 35642822, 'patchversion': '19.21.0', 'state': 'present', 'subpatches': []})
[WARNING]: Both option rolling and its alias rolling are set.

TASK [oraswgi_manage_patches : gi-opatch | Manage non opatchauto patches for GI] **********************************************************************************************
skipping: [ansible_db]

PLAY RECAP ************************************************************************************************************************************************************************
ansible_db                 : ok=9    changed=1    unreachable=0    failed=0    skipped=6    rescued=0    ignored=0

To execute this playbook from GUI, an example is provided in the document, please refer this link: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
