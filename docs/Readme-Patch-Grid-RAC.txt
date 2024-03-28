# Apply Patch on Oracle Grid Infrastructure RAC - Readme
# ======================================================
# Description: This module is used to apply release update patches on Oracle GI RAC.
# It does "prereq CheckConflictAgainstOHWithDetail" before applying the patch and exits if there are any conflicts.

In the following example we're going to apply 19.21 Release Update patch on a 4 node cluster.

1. Passwordless SSH must be established between Ansible user & Grid user.
2. SUDO must be installed on all the target lpars and the grid user must have sudo privilege. This is required for the "opatchauto" utility.
3. In ansible.cfg file, set "remote_tmp" to a path where there is minimum 16GB of free space. It is for the remote staging option for patches.
4. There are two files which needs to be updated.
	a. {{ collection_dir }}/power_aix_oracle_dba/playbooks/gi-rac-opatchauto.yml: This is the playbook. 
        b. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/gi-rac-opatchauto-vars.yml: This file contains all the required variables.

5. Update the hosts and remote_user in the file: {{ collection_dir }}/power_aix_oracle_dba/playbooks/gi-rac-opatchauto.yml

- name: Apply patches to GI
  hosts: rachosts        # Provide AIX Lapr hostgroup name defined in Ansible inventory. All the RAC nodes must be defined as a group in the Ansible inventory/
  remote_user: oracle    # Remote AIX Lpar username.
  vars_files:
   - vars/gi-rac-opatchauto-vars.yml
  serial: 1
  roles:
     - {role: oraswgi_manage_patches }

6. Update the following variables in {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/gi-rac-opatchauto-vars.yml

 grid_install_user: oracle                      # Grid installation home Owner.
 oracle_group: oinstall                         # Primary group for oracle/grid user.
 oracle_home_gi_cl: "/ora/grid"                 # ORACLE_HOME for Grid Infrastructure (Stand Alone)
 configure_cluster: True                        # True: For RAC GI, False: For SI GI
 oracle_install_version_gi: 19.3.0

################################
# Patch files staging variables#
################################

 ora_binary_location: local                        # local|nfs|remote.

 ora_nfs_host: 129.40.76.1                       # NFS server name if "ora_binary_location is nfs".
 ora_nfs_device: /repos                          # NFS filesystem if "ora_binary_location is nfs".
 ora_nfs_filesystem: /repos                      # Path on the target lpar to mount the NFS filesystem if "ora_binary_location is nfs".

 oracle_patch_stage: /tmp/RU          # Provide the path on the target lpar with sufficient space to extract patch zipfiles if "ora_binary_locationis local". This path will be created by this Ansible playbook.
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
          state: absent                    # present - applies this patch, absent - rollbacks the patch.
          subpatches: []
    opatch: []

7. Execute the following command to run the playbook below. This command requires sudo password of the Grid software owner.

$ ansible-playbook gi-rac-opatchauto.yml -i inventory.yml --ask-become-pass

SSH password: 
BECOME password[defaults to SSH password]: 

PLAY [Apply patches to GI] *****************************************************

TASK [Gathering Facts] *********************************************************
[WARNING]: Platform aix on host rac21 is using the discovered Python
interpreter at /usr/bin/python3, but future installation of another Python
interpreter could change the meaning of that path. See
https://docs.ansible.com/ansible-
core/2.15/reference_appendices/interpreter_discovery.html for more information.
ok: [rac21]

TASK [oraswgi_manage_patches : gi-opatch | check if GI has been configured] ****
ok: [rac21]

TASK [oraswgi_manage_patches : gi-opatch | set fact for patch_before_rootsh] ***
ok: [rac21]

TASK [oraswgi_manage_patches : Creating NFS filesystem from nfshost.] **********
skipping: [rac21]

TASK [oraswgi_manage_patches : gi-opatch | Create patch-base directory (version specific)] ***
ok: [rac21]

TASK [oraswgi_manage_patches : gi-opatch | Extract GI patch files to patch base (from local|nfs)] ***
ok: [rac21] => (item=[{'description': 'GI-RU-Oct-2023', 'filename': '/repos/images/oracle/19c/RU19.21/p35642822_190000_AIX64-5L_RU19.21.zip', 'patchid': 35642822, 'patchversion': '19.21.0.0', 'version': '19.3.0'}, {'patchid': 35642822, 'patchversion': '19.21.0', 'state': 'present', 'subpatches': []}])

TASK [oraswgi_manage_patches : gi-opatch | Extract GI patch files to patch base (from remote)] ***
skipping: [rac21] => (item=[{'description': 'GI-RU-Oct-2023', 'filename': '/repos/images/oracle/19c/RU19.21/p35642822_190000_AIX64-5L_RU19.21.zip', 'patchid': 35642822, 'patchversion': '19.21.0.0', 'version': '19.3.0'}, {'patchid': 35642822, 'patchversion': '19.21.0', 'state': 'present', 'subpatches': []}]) 
skipping: [rac21]

TASK [oraswgi_manage_patches : gi-opatch | Check opatch dir] *******************
ok: [rac21]

TASK [oraswgi_manage_patches : gi-opatch | Check current opatch version] *******
ok: [rac21]

TASK [oraswgi_manage_patches : gi-opatch | Backup existing OPatch directory] ***
skipping: [rac21] => (item={'filename': '/repos/images/oracle/opatch/12.2.0.1.41/opatch-12.2.0.1.41_p6880880_210000_AIX64-5L.zip', 'version': '19.3.0'}) 
skipping: [rac21]

TASK [oraswgi_manage_patches : gi-opatch | Extract OPatch to GI Home (from local/nfs)] ***
skipping: [rac21] => (item={'filename': '/repos/images/oracle/opatch/12.2.0.1.41/opatch-12.2.0.1.41_p6880880_210000_AIX64-5L.zip', 'version': '19.3.0'}) 
skipping: [rac21]

TASK [oraswgi_manage_patches : gi-opatch | Extract OPatch to GI Home (from remote location)] ***
skipping: [rac21] => (item={'filename': '/repos/images/oracle/opatch/12.2.0.1.41/opatch-12.2.0.1.41_p6880880_210000_AIX64-5L.zip', 'version': '19.3.0'}) 
skipping: [rac21]

TASK [oraswgi_manage_patches : gi-opatch | Manage opatchauto patches for GI (after software only install)] ***
skipping: [rac21]

TASK [oraswgi_manage_patches : gi-opatch | Manage opatchauto patches for GI] ***
changed: [rac21] => (item={'patchid': 35642822, 'patchversion': '19.21.0', 'state': 'present', 'subpatches': []})
[WARNING]: Both option rolling and its alias rolling are set.

TASK [oraswgi_manage_patches : gi-opatch | Manage non opatchauto patches for GI] ***
skipping: [rac21]

TASK [oraswgi_manage_patches : gi-opatch | RU version] *************************
ok: [rac21]

TASK [oraswgi_manage_patches : debug] ******************************************
ok: [rac21] => {
    "msg": [
        "35655527;OCW RELEASE UPDATE 19.21.0.0.0 (35655527)",
        "35652062;ACFS RELEASE UPDATE 19.21.0.0.0 (35652062)",
        "35643107;Database Release Update : 19.21.0.0.231017 (35643107)",
        "35553096;TOMCAT RELEASE UPDATE 19.0.0.0.0 (35553096)",
        "33575402;DBWLM RELEASE UPDATE 19.0.0.0.0 (33575402)",
        "",
        "OPatch succeeded.",
        ""
    ]
}

PLAY [Apply patches to GI] *****************************************************

TASK [Gathering Facts] *********************************************************
[WARNING]: Platform aix on host rac22 is using the discovered Python
interpreter at /usr/bin/python3, but future installation of another Python
interpreter could change the meaning of that path. See
https://docs.ansible.com/ansible-
core/2.15/reference_appendices/interpreter_discovery.html for more information.
ok: [rac22]

TASK [oraswgi_manage_patches : gi-opatch | check if GI has been configured] ****
ok: [rac22]

TASK [oraswgi_manage_patches : gi-opatch | set fact for patch_before_rootsh] ***
ok: [rac22]

TASK [oraswgi_manage_patches : Creating NFS filesystem from nfshost.] **********
skipping: [rac22]

TASK [oraswgi_manage_patches : gi-opatch | Create patch-base directory (version specific)] ***
ok: [rac22]

TASK [oraswgi_manage_patches : gi-opatch | Extract GI patch files to patch base (from local|nfs)] ***
ok: [rac22] => (item=[{'description': 'GI-RU-Oct-2023', 'filename': '/repos/images/oracle/19c/RU19.21/p35642822_190000_AIX64-5L_RU19.21.zip', 'patchid': 35642822, 'patchversion': '19.21.0.0', 'version': '19.3.0'}, {'patchid': 35642822, 'patchversion': '19.21.0', 'state': 'present', 'subpatches': []}])

TASK [oraswgi_manage_patches : gi-opatch | Extract GI patch files to patch base (from remote)] ***
skipping: [rac22] => (item=[{'description': 'GI-RU-Oct-2023', 'filename': '/repos/images/oracle/19c/RU19.21/p35642822_190000_AIX64-5L_RU19.21.zip', 'patchid': 35642822, 'patchversion': '19.21.0.0', 'version': '19.3.0'}, {'patchid': 35642822, 'patchversion': '19.21.0', 'state': 'present', 'subpatches': []}]) 
skipping: [rac22]

TASK [oraswgi_manage_patches : gi-opatch | Check opatch dir] *******************
ok: [rac22]

TASK [oraswgi_manage_patches : gi-opatch | Check current opatch version] *******
ok: [rac22]

TASK [oraswgi_manage_patches : gi-opatch | Backup existing OPatch directory] ***
skipping: [rac22] => (item={'filename': '/repos/images/oracle/opatch/12.2.0.1.41/opatch-12.2.0.1.41_p6880880_210000_AIX64-5L.zip', 'version': '19.3.0'}) 
skipping: [rac22]

TASK [oraswgi_manage_patches : gi-opatch | Extract OPatch to GI Home (from local/nfs)] ***
skipping: [rac22] => (item={'filename': '/repos/images/oracle/opatch/12.2.0.1.41/opatch-12.2.0.1.41_p6880880_210000_AIX64-5L.zip', 'version': '19.3.0'}) 
skipping: [rac22]

TASK [oraswgi_manage_patches : gi-opatch | Extract OPatch to GI Home (from remote location)] ***
skipping: [rac22] => (item={'filename': '/repos/images/oracle/opatch/12.2.0.1.41/opatch-12.2.0.1.41_p6880880_210000_AIX64-5L.zip', 'version': '19.3.0'}) 
skipping: [rac22]

TASK [oraswgi_manage_patches : gi-opatch | Manage opatchauto patches for GI (after software only install)] ***
skipping: [rac22]

TASK [oraswgi_manage_patches : gi-opatch | Manage opatchauto patches for GI] ***
changed: [rac22] => (item={'patchid': 35642822, 'patchversion': '19.21.0', 'state': 'present', 'subpatches': []})

TASK [oraswgi_manage_patches : gi-opatch | Manage non opatchauto patches for GI] ***
skipping: [rac22]

TASK [oraswgi_manage_patches : gi-opatch | RU version] *************************
ok: [rac22]

TASK [oraswgi_manage_patches : debug] ******************************************
ok: [rac22] => {
    "msg": [
        "35655527;OCW RELEASE UPDATE 19.21.0.0.0 (35655527)",
        "35652062;ACFS RELEASE UPDATE 19.21.0.0.0 (35652062)",
        "35643107;Database Release Update : 19.21.0.0.231017 (35643107)",
        "35553096;TOMCAT RELEASE UPDATE 19.0.0.0.0 (35553096)",
        "33575402;DBWLM RELEASE UPDATE 19.0.0.0.0 (33575402)",
        "",
        "OPatch succeeded.",
        ""
    ]
}

PLAY [Apply patches to GI] *****************************************************

TASK [Gathering Facts] *********************************************************
[WARNING]: Platform aix on host rac23 is using the discovered Python
interpreter at /usr/bin/python3, but future installation of another Python
interpreter could change the meaning of that path. See
https://docs.ansible.com/ansible-
core/2.15/reference_appendices/interpreter_discovery.html for more information.
ok: [rac23]

TASK [oraswgi_manage_patches : gi-opatch | check if GI has been configured] ****
ok: [rac23]

TASK [oraswgi_manage_patches : gi-opatch | set fact for patch_before_rootsh] ***
ok: [rac23]

TASK [oraswgi_manage_patches : Creating NFS filesystem from nfshost.] **********
skipping: [rac23]

TASK [oraswgi_manage_patches : gi-opatch | Create patch-base directory (version specific)] ***
ok: [rac23]

TASK [oraswgi_manage_patches : gi-opatch | Extract GI patch files to patch base (from local|nfs)] ***
ok: [rac23] => (item=[{'description': 'GI-RU-Oct-2023', 'filename': '/repos/images/oracle/19c/RU19.21/p35642822_190000_AIX64-5L_RU19.21.zip', 'patchid': 35642822, 'patchversion': '19.21.0.0', 'version': '19.3.0'}, {'patchid': 35642822, 'patchversion': '19.21.0', 'state': 'present', 'subpatches': []}])

TASK [oraswgi_manage_patches : gi-opatch | Extract GI patch files to patch base (from remote)] ***
skipping: [rac23] => (item=[{'description': 'GI-RU-Oct-2023', 'filename': '/repos/images/oracle/19c/RU19.21/p35642822_190000_AIX64-5L_RU19.21.zip', 'patchid': 35642822, 'patchversion': '19.21.0.0', 'version': '19.3.0'}, {'patchid': 35642822, 'patchversion': '19.21.0', 'state': 'present', 'subpatches': []}]) 
skipping: [rac23]

TASK [oraswgi_manage_patches : gi-opatch | Check opatch dir] *******************
ok: [rac23]

TASK [oraswgi_manage_patches : gi-opatch | Check current opatch version] *******
ok: [rac23]

TASK [oraswgi_manage_patches : gi-opatch | Backup existing OPatch directory] ***
skipping: [rac23] => (item={'filename': '/repos/images/oracle/opatch/12.2.0.1.41/opatch-12.2.0.1.41_p6880880_210000_AIX64-5L.zip', 'version': '19.3.0'}) 
skipping: [rac23]

TASK [oraswgi_manage_patches : gi-opatch | Extract OPatch to GI Home (from local/nfs)] ***
skipping: [rac23] => (item={'filename': '/repos/images/oracle/opatch/12.2.0.1.41/opatch-12.2.0.1.41_p6880880_210000_AIX64-5L.zip', 'version': '19.3.0'}) 
skipping: [rac23]

TASK [oraswgi_manage_patches : gi-opatch | Extract OPatch to GI Home (from remote location)] ***
skipping: [rac23] => (item={'filename': '/repos/images/oracle/opatch/12.2.0.1.41/opatch-12.2.0.1.41_p6880880_210000_AIX64-5L.zip', 'version': '19.3.0'}) 
skipping: [rac23]

TASK [oraswgi_manage_patches : gi-opatch | Manage opatchauto patches for GI (after software only install)] ***
skipping: [rac23]

TASK [oraswgi_manage_patches : gi-opatch | Manage opatchauto patches for GI] ***
changed: [rac23] => (item={'patchid': 35642822, 'patchversion': '19.21.0', 'state': 'present', 'subpatches': []})

TASK [oraswgi_manage_patches : gi-opatch | Manage non opatchauto patches for GI] ***
skipping: [rac23]

TASK [oraswgi_manage_patches : gi-opatch | RU version] *************************
ok: [rac23]

TASK [oraswgi_manage_patches : debug] ******************************************
ok: [rac23] => {
    "msg": [
        "35655527;OCW RELEASE UPDATE 19.21.0.0.0 (35655527)",
        "35652062;ACFS RELEASE UPDATE 19.21.0.0.0 (35652062)",
        "35643107;Database Release Update : 19.21.0.0.231017 (35643107)",
        "35553096;TOMCAT RELEASE UPDATE 19.0.0.0.0 (35553096)",
        "33575402;DBWLM RELEASE UPDATE 19.0.0.0.0 (33575402)",
        "",
        "OPatch succeeded.",
        ""
    ]
}

PLAY [Apply patches to GI] *****************************************************

TASK [Gathering Facts] *********************************************************
[WARNING]: Platform aix on host rac24 is using the discovered Python
interpreter at /usr/bin/python3, but future installation of another Python
interpreter could change the meaning of that path. See
https://docs.ansible.com/ansible-
core/2.15/reference_appendices/interpreter_discovery.html for more information.
ok: [rac24]

TASK [oraswgi_manage_patches : gi-opatch | check if GI has been configured] ****
ok: [rac24]

TASK [oraswgi_manage_patches : gi-opatch | set fact for patch_before_rootsh] ***
ok: [rac24]

TASK [oraswgi_manage_patches : Creating NFS filesystem from nfshost.] **********
skipping: [rac24]

TASK [oraswgi_manage_patches : gi-opatch | Create patch-base directory (version specific)] ***
ok: [rac24]

TASK [oraswgi_manage_patches : gi-opatch | Extract GI patch files to patch base (from local|nfs)] ***
ok: [rac24] => (item=[{'description': 'GI-RU-Oct-2023', 'filename': '/repos/images/oracle/19c/RU19.21/p35642822_190000_AIX64-5L_RU19.21.zip', 'patchid': 35642822, 'patchversion': '19.21.0.0', 'version': '19.3.0'}, {'patchid': 35642822, 'patchversion': '19.21.0', 'state': 'present', 'subpatches': []}])

TASK [oraswgi_manage_patches : gi-opatch | Extract GI patch files to patch base (from remote)] ***
skipping: [rac24] => (item=[{'description': 'GI-RU-Oct-2023', 'filename': '/repos/images/oracle/19c/RU19.21/p35642822_190000_AIX64-5L_RU19.21.zip', 'patchid': 35642822, 'patchversion': '19.21.0.0', 'version': '19.3.0'}, {'patchid': 35642822, 'patchversion': '19.21.0', 'state': 'present', 'subpatches': []}]) 
skipping: [rac24]

TASK [oraswgi_manage_patches : gi-opatch | Check opatch dir] *******************
ok: [rac24]

TASK [oraswgi_manage_patches : gi-opatch | Check current opatch version] *******
ok: [rac24]

TASK [oraswgi_manage_patches : gi-opatch | Backup existing OPatch directory] ***
skipping: [rac24] => (item={'filename': '/repos/images/oracle/opatch/12.2.0.1.41/opatch-12.2.0.1.41_p6880880_210000_AIX64-5L.zip', 'version': '19.3.0'}) 
skipping: [rac24]

TASK [oraswgi_manage_patches : gi-opatch | Extract OPatch to GI Home (from local/nfs)] ***
skipping: [rac24] => (item={'filename': '/repos/images/oracle/opatch/12.2.0.1.41/opatch-12.2.0.1.41_p6880880_210000_AIX64-5L.zip', 'version': '19.3.0'}) 
skipping: [rac24]

TASK [oraswgi_manage_patches : gi-opatch | Extract OPatch to GI Home (from remote location)] ***
skipping: [rac24] => (item={'filename': '/repos/images/oracle/opatch/12.2.0.1.41/opatch-12.2.0.1.41_p6880880_210000_AIX64-5L.zip', 'version': '19.3.0'}) 
skipping: [rac24]

TASK [oraswgi_manage_patches : gi-opatch | Manage opatchauto patches for GI (after software only install)] ***
skipping: [rac24]

TASK [oraswgi_manage_patches : gi-opatch | Manage opatchauto patches for GI] ***
changed: [rac24] => (item={'patchid': 35642822, 'patchversion': '19.21.0', 'state': 'present', 'subpatches': []})

TASK [oraswgi_manage_patches : gi-opatch | Manage non opatchauto patches for GI] ***
skipping: [rac24]

TASK [oraswgi_manage_patches : gi-opatch | RU version] *************************
ok: [rac24]

TASK [oraswgi_manage_patches : debug] ******************************************
ok: [rac24] => {
    "msg": [
        "35655527;OCW RELEASE UPDATE 19.21.0.0.0 (35655527)",
        "35652062;ACFS RELEASE UPDATE 19.21.0.0.0 (35652062)",
        "35643107;Database Release Update : 19.21.0.0.231017 (35643107)",
        "35553096;TOMCAT RELEASE UPDATE 19.0.0.0.0 (35553096)",
        "33575402;DBWLM RELEASE UPDATE 19.0.0.0.0 (33575402)",
        "",
        "OPatch succeeded.",
        ""
    ]
}

PLAY RECAP *********************************************************************
rac21                      : ok=10   changed=1    unreachable=0    failed=0    skipped=7    rescued=0    ignored=0   
rac22                      : ok=10   changed=1    unreachable=0    failed=0    skipped=7    rescued=0    ignored=0   
rac23                      : ok=10   changed=1    unreachable=0    failed=0    skipped=7    rescued=0    ignored=0   
rac24                      : ok=10   changed=1    unreachable=0    failed=0    skipped=7    rescued=0    ignored=0   

To execute this playbook from GUI, an example is provided in the document, please refer this link: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
