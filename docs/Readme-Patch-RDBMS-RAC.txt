# Apply Patch on Oracle RDBMS homes - Readme
# ==========================================

# Description: This module is used to apply Release Update and other patches on an Oracle RBDMS running on RAC environment.
# It uses Oracle's "opatchauto" utility.

In the following example, we will apply 19.21 RU on an Oracle RDBMS home on ACFS on 4 node RAC.

1. Passwordless SSH must be established between Ansible user & Grid user.
2. SUDO must be installed on all the target lpars and the grid user must have sudo privilege. This is required for the "opatchauto" utility.
3. In ansible.cfg file, set "remote_tmp" to a path where there is minimum 16GB of free space. It is for the remote staging option for patches.
4. There are two files which needs to be updated.
        a. {{ collection_dir }}/power_aix_oracle_dba/playbooks/db-rac-opatchauto.yml: This is the playbook.
        b. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/db-rac-opatchauto-vars.yml: This file contains all the required variables.

5. Update the hosts and remote_user in the file: {{ collection_dir }}/power_aix_oracle_dba/playbooks/db-rac-opatchauto.yml

- name: Apply binary patches
  hosts: rachosts        # Provide AIX Lapr hostgroup name defined in Ansible inventory. All the RAC nodes must be defined as a group in the Ansible inventory. When using ACFS for shared Oracle DB Home, provide only the 1st node hostname.
  remote_user: root    # Remote AIX Lpar username.
  vars_files:
   - vars/db-rac-opatchauto-vars.yml
  roles:
     - {role: oraswdb_manage_patches }

6. Update the following variables in {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/db-si-opatchauto-vars.yml

oracle_user: oracle
oracle_group: oinstall                  # Primary group for oracle/grid user.
configure_cluster: False                # Set it to False in case of Standalone DB, Set it to True in case of RAC DB.

ora_binary_location: local                        # local|nfs|remote. When using "nfs" option, provide sudo password "--ask-become-pass" when running the playbook.

ora_nfs_host: 129.40.76.1                       # NFS server name if "ora_binary_location is nfs".
ora_nfs_device: /repos                          # NFS filesystem if "ora_binary_location is nfs".
ora_nfs_filesystem: /repos                      # Path on the target lpar to mount the NFS filesystem if "ora_binary_location is nfs".

oracle_patch_stage: /ora/RU          # Provide the path on the target lpar with sufficient space to extract patch zipfiles if "ora_binary_location is local". This path will be created by this Ansible playbook.

oracle_sw_patches:
 - filename: /repos/images/oracle/19c/RU19.21/p35642822_190000_AIX64-5L_RU19.21.zip # Provide full path( based on nfs|local|remote) and the zipfile name.
   patchid: 35642822                            # Release update Patch ID to be applied.
   version: 19.3.0                              # Grid Version must be the same defined for the variable "oracle_install_version_gi"
   patchversion: 19.21.0.0                      # Release update patch version
   description: GI-RU-Oct-2023                  # This is an optional parameter shows the description of the patch.

oracle_opatch_patch:
 - filename: /repos/images/oracle/opatch/12.2.0.1.41/opatch-12.2.0.1.41_p6880880_210000_AIX64-5L.zip # Provide full path(based on nfs|local|remote) and the zipfile name.
   version: 19.3.0                              # Grid Version must be the same defined for the variable "oracle_install_version_gi"

db_homes_config:
  19300-base:                       #Provide a name for the Oracle home identification, this name must be used in "db_homes_installed"
    oracle_home: /u02/db19c         # Oracle Home path.
    opatch_minversion: 12.2.0.1.41  # Minimum opatch version required to apply the patches.
    opatchauto:
      - patchid: 35642822           # Patch ID. Example: given patch id is 19.14 Release update patch for Database.
        patchversion: 19.21.0.0     # Minimum opatch version required to apply required patches.
        state: present              # Set to present (applies the patch). Set to absent (rolls back the patch).
    opatch: []

db_homes_installed:
    home: 19300-base            # This must be the same mentioned under "db_homes_config", see the above parameter.
    db_version: 19.3.0          # Oracle version.
    apply_patches: True         # True - will apply patch, False - will do nothing.
    state: present              # present - Oracle Home exists, absent - Oracle Home doesn't exist.

acfs_used: True        # Set this to True only if Oracle Home is shared on ACFS mount point. This should be False when ACFS is not used.
node_list:           # When "acfs_used" variable is set to True, mention all the RAC node names except the node to which Ansible connects. Example: In case of a 4 node RAC (rac21, rac22, rac23, rac24), lets say Ansible connects to rac21 to patch, so rac21 should be left off and the remaining node names must be mentioned in the node list below.
   - { node: rac22 }
   - { node: rac23 }
   - { node: rac24 }

7. Execute the playbook

SSH password: 

PLAY [Apply binary patches] ****************************************************

TASK [Gathering Facts] *********************************************************
[WARNING]: Platform aix on host rac21 is using the discovered Python
interpreter at /usr/bin/python3, but future installation of another Python
interpreter could change the meaning of that path. See
https://docs.ansible.com/ansible-
core/2.15/reference_appendices/interpreter_discovery.html for more information.
ok: [rac21]

TASK [oraswdb_manage_patches : db-opatch | check if GI is installed] ***********
ok: [rac21]

TASK [oraswdb_manage_patches : Creating NFS filesystem from nfshost.] **********
skipping: [rac21]

TASK [oraswdb_manage_patches : include_tasks] **********************************
included: /runner/project/roles/oraswdb_manage_patches/tasks/db-home-patch.yml for rac21 => (item={'home': '19300-base', 'db_version': '19.3.0', 'apply_patches': True, 'state': 'present'})

TASK [oraswdb_manage_patches : set_fact] ***************************************
ok: [rac21]

TASK [oraswdb_manage_patches : db-opatch | Create patch-base directory (version specific)] ***
ok: [rac21] => (item=home)
ok: [rac21] => (item=db_version)
ok: [rac21] => (item=apply_patches)
ok: [rac21] => (item=state)

TASK [oraswdb_manage_patches : db-opatch | Extract DB patch files to patch base (from local|nfs) for opatchauto] ***
ok: [rac21] => (item=[{'filename': '/repos/images/oracle/19c/RU19.21/p35642822_190000_AIX64-5L_RU19.21.zip', 'patchid': 35642822, 'version': '19.3.0', 'patchversion': '19.21.0.0', 'description': 'GI-RU-Oct-2023'}, 'home', {'patchid': 35642822, 'patchversion': '19.21.0.0', 'state': 'present'}])
ok: [rac21] => (item=[{'filename': '/repos/images/oracle/19c/RU19.21/p35642822_190000_AIX64-5L_RU19.21.zip', 'patchid': 35642822, 'version': '19.3.0', 'patchversion': '19.21.0.0', 'description': 'GI-RU-Oct-2023'}, 'db_version', {'patchid': 35642822, 'patchversion': '19.21.0.0', 'state': 'present'}])
ok: [rac21] => (item=[{'filename': '/repos/images/oracle/19c/RU19.21/p35642822_190000_AIX64-5L_RU19.21.zip', 'patchid': 35642822, 'version': '19.3.0', 'patchversion': '19.21.0.0', 'description': 'GI-RU-Oct-2023'}, 'apply_patches', {'patchid': 35642822, 'patchversion': '19.21.0.0', 'state': 'present'}])
ok: [rac21] => (item=[{'filename': '/repos/images/oracle/19c/RU19.21/p35642822_190000_AIX64-5L_RU19.21.zip', 'patchid': 35642822, 'version': '19.3.0', 'patchversion': '19.21.0.0', 'description': 'GI-RU-Oct-2023'}, 'state', {'patchid': 35642822, 'patchversion': '19.21.0.0', 'state': 'present'}])

TASK [oraswdb_manage_patches : db-opatch | Extract DB patch files to patch base (from remote) for opatchauto] ***
skipping: [rac21] => (item=[{'filename': '/repos/images/oracle/19c/RU19.21/p35642822_190000_AIX64-5L_RU19.21.zip', 'patchid': 35642822, 'version': '19.3.0', 'patchversion': '19.21.0.0', 'description': 'GI-RU-Oct-2023'}, 'home', {'patchid': 35642822, 'patchversion': '19.21.0.0', 'state': 'present'}]) 
skipping: [rac21] => (item=[{'filename': '/repos/images/oracle/19c/RU19.21/p35642822_190000_AIX64-5L_RU19.21.zip', 'patchid': 35642822, 'version': '19.3.0', 'patchversion': '19.21.0.0', 'description': 'GI-RU-Oct-2023'}, 'db_version', {'patchid': 35642822, 'patchversion': '19.21.0.0', 'state': 'present'}]) 
skipping: [rac21] => (item=[{'filename': '/repos/images/oracle/19c/RU19.21/p35642822_190000_AIX64-5L_RU19.21.zip', 'patchid': 35642822, 'version': '19.3.0', 'patchversion': '19.21.0.0', 'description': 'GI-RU-Oct-2023'}, 'apply_patches', {'patchid': 35642822, 'patchversion': '19.21.0.0', 'state': 'present'}]) 
skipping: [rac21] => (item=[{'filename': '/repos/images/oracle/19c/RU19.21/p35642822_190000_AIX64-5L_RU19.21.zip', 'patchid': 35642822, 'version': '19.3.0', 'patchversion': '19.21.0.0', 'description': 'GI-RU-Oct-2023'}, 'state', {'patchid': 35642822, 'patchversion': '19.21.0.0', 'state': 'present'}]) 
skipping: [rac21]

TASK [oraswdb_manage_patches : db-opatch | Extract DB patch files to patch base (from local|nfs) for opatch] ***
skipping: [rac21]

TASK [oraswdb_manage_patches : db-opatch | Extract DB patch files to patch base (from remote) for opatch] ***
skipping: [rac21]

TASK [oraswdb_manage_patches : db-opatch | Check opatch dir] *******************
ok: [rac21]

TASK [oraswdb_manage_patches : db-opatch | Check current opatch version] *******
ok: [rac21]

TASK [oraswdb_manage_patches : db-opatch | Backup existing OPatch directory] ***
skipping: [rac21] => (item={'filename': '/repos/images/oracle/opatch/12.2.0.1.41/opatch-12.2.0.1.41_p6880880_210000_AIX64-5L.zip', 'version': '19.3.0'}) 
skipping: [rac21]

TASK [oraswdb_manage_patches : db-opatch | Extract OPatch to DB Home (from local/nfs)] ***
skipping: [rac21] => (item={'filename': '/repos/images/oracle/opatch/12.2.0.1.41/opatch-12.2.0.1.41_p6880880_210000_AIX64-5L.zip', 'version': '19.3.0'}) 
skipping: [rac21]

TASK [oraswdb_manage_patches : db-opatch | Extract OPatch to DB Home (from remote location)] ***
skipping: [rac21] => (item={'filename': '/repos/images/oracle/opatch/12.2.0.1.41/opatch-12.2.0.1.41_p6880880_210000_AIX64-5L.zip', 'version': '19.3.0'}) 
skipping: [rac21]

TASK [oraswdb_manage_patches : Checking the Patch ID] **************************
skipping: [rac21]

TASK [oraswdb_manage_patches : Store Patch count list] *************************
skipping: [rac21]

TASK [oraswdb_manage_patches : Stopping the DB Services for Patching] **********
skipping: [rac21]

TASK [oraswdb_manage_patches : Stopping the DB Services for Rollback] **********
skipping: [rac21]

TASK [oraswdb_manage_patches : Stopping the Listeners for Patching] ************
skipping: [rac21]

TASK [oraswdb_manage_patches : Stopping the Listeners for Rollback] ************
skipping: [rac21]

TASK [oraswdb_manage_patches : Stop Home | Stop Oracle Home on RAC nodes for patching when ACFS is used] ***
changed: [rac21] => (item={'node': 'rac22'})
changed: [rac21] => (item={'node': 'rac23'})
changed: [rac21] => (item={'node': 'rac24'})

TASK [oraswdb_manage_patches : debug] ******************************************
ok: [rac21] => {
    "msg": "Managing patches for /acfs/db"
}

TASK [oraswdb_manage_patches : db-opatch | Manage opatchauto patches for DB (non-gi)] ***
skipping: [rac21]

TASK [oraswdb_manage_patches : db-opatch | Manage opatchauto patches for DB (gi)] ***
changed: [rac21] => (item={'patchid': 35642822, 'patchversion': '19.21.0.0', 'state': 'present'})

TASK [oraswdb_manage_patches : Opatch lspatches output] ************************
ok: [rac21]

TASK [oraswdb_manage_patches : ansible.builtin.debug] **************************
ok: [rac21] => {
    "msg": [
        "35655527;OCW RELEASE UPDATE 19.21.0.0.0 (35655527)",
        "35643107;Database Release Update : 19.21.0.0.231017 (35643107)",
        "",
        "OPatch succeeded.",
        ""
    ]
}

TASK [oraswdb_manage_patches : Starting the DB Services Post Patching] *********
skipping: [rac21]

TASK [oraswdb_manage_patches : Starting the DB Services Post Patching] *********
skipping: [rac21]

TASK [oraswdb_manage_patches : Starting the Listeners Post Rollback] ***********
skipping: [rac21]

TASK [oraswdb_manage_patches : Starting the Listeners Post Rollback] ***********
skipping: [rac21]

TASK [oraswdb_manage_patches : Start Oracle Home on RAC nodes post patching when ACFS is used] ***
changed: [rac21] => (item={'node': 'rac22'})
changed: [rac21] => (item={'node': 'rac23'})
changed: [rac21] => (item={'node': 'rac24'})

TASK [oraswdb_manage_patches : Remove stat files] ******************************
changed: [rac21] => (item={'node': 'rac22'})
changed: [rac21] => (item={'node': 'rac23'})
changed: [rac21] => (item={'node': 'rac24'})

PLAY RECAP *********************************************************************
rac21                      : ok=15   changed=4    unreachable=0    failed=0    skipped=18   rescued=0    ignored=0   

To execute this playbook from GUI, an example is provided in the document, please refer this link: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
