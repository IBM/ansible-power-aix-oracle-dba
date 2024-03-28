# Apply Patch on Oracle RDBMS homes - Readme
# ==========================================

# Description: This module is used to apply Release Update and other patches on an Oracle RBDMS on a standalone Non-Grid environment.
# It uses Oracle's "opatch" utility.

In the following example, we will apply 19.21 RU and a one-off patch on an two Oracle RDBMS homes.

1. Passwordless SSH must be established between Ansible user & Grid user.
2. In ansible.cfg file, set "remote_tmp" to a path where there is minimum 16GB of free space. It is for the remote staging option for patches.
3. There are two files which needs to be updated.
      a. {{ collection_dir }}/power_aix_oracle_dba/playbooks/db-si-opatch.yml: This is the playbook.
      b. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/db-si-opatch-vars.yml: This file contains all the required variables.

4. Update the hosts and remote_user in the file: {{ collection_dir }}/power_aix_oracle_dba/playbooks/db-si-opatch.yml

- name: Apply binary patches
  hosts: ansible_db     # AIX lpar hostname defined in Ansible inventory.
  gather_facts: False
  remote_user: oracle   # Oracle RDBMS user on the AIX lpar.
  vars_files:
     - vars/db-si-opatch-vars.yml
  roles:
     - {role: oraswdb_manage_patches }

5. Update the following variables in {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/db-si-opatch-vars.yml

oracle_user: oracle
oracle_group: oinstall                  # Primary group for oracle/grid user.
configure_cluster: False                # Set it to False in case of Standalone DB, Set it to True in case of RAC DB.

################################
# Patch files staging variables#
################################

ora_binary_location: local      # local|nfs|remote. When using "nfs" option, provide sudo password "--ask-become-pass" when running the playbook, this will use the elevated privileges to configure NFS.
ora_nfs_host: 129.40.76.1                       # NFS server name if "ora_binary_location is nfs".
ora_nfs_device: /repos                          # NFS filesystem if "ora_binary_location is nfs".
ora_nfs_filesystem: /repos                      # Path on the target lpar to mount the NFS filesystem if "ora_binary_location is nfs".

oracle_patch_stage: /backup/patches/RU          # Provide the path on the target lpar with sufficient space to extract the patch zipfiles. This path will be created by this Ansible playbook.

oracle_sw_patches:
 - filename: /repos/images/oracle/19c/RU19.21/p35642822_190000_AIX64-5L_RU19.21.zip # Provide full path( based on nfs|local|remote) and the zipfile name.
   patchid: 35642822                            # Patch to be applied.
   version: 19.3.0                              # 19c GI version
   patchversion: 19.21.0.0                      # Release update patch version
   description: GI-RU-Oct-2023                  # This is an optional parameter shows the description of the patch.
 - filename: /backup/patches/p34774667_1921000DBRU_AIX64-5L.zip
   patchid: 34774667
   version: 19.21.0
   patchversion: 19.21.0.0

oracle_opatch_patch:
 - filename: /repos/images/oracle/opatch/12.2.0.1.41/opatch-12.2.0.1.41_p6880880_210000_AIX64-5L.zip # Provide full path(nfs|local|remote) along with the zipfile name.
   version: 19.3.0                              # 19c GI version

#####################################
# Oracle Home environment Variables #
#####################################
 db_homes_config:
  19300-base:                       # Provide any name, this is the value for "home" variable in "db_homes_installed" used below.
    oracle_home: /u01/db19c         # Oracle Home path.
    opatch_minversion: 12.2.0.1.41  # Minimum opatch version required to apply the patches.
    opatchauto: []
    opatch:
      - patchid: 35642822           # Given patch id is the system patch of 19.21 RU, it contains both grid and db patches.
        patchversion: 19.21.0.0     # Minimum opatch version required to apply required patches.
        state: present              # present - applies the patch. absent - rollbacks the patch.
        subpatches:
         - 35655527                 # This is the DB patch inside 35642822 patch directory.
         - 35643107                 # This is OCW patch inside 35642822 patch directory.
      - patchid:                    # Leave this empty and provide the one off patch under subpatches below.
        patchversion: 19.21.0.0
        subpatches:
        - 34774667                  # This is a one off patch to be applied on Oracle home with 19.21 RU.
   stop_services: True              # True - Stops the DB and listener services before patching, False - Won't stop the services.
    databases:
         - testdb                   # Provide the list of the databases running in the above Oracle Home.
    listeners:
         - LISTENER                 # Provide the list of the listeners running in the above Oracle Home.
  19300-base-1:
    oracle_home: /u01/db19c_2
    opatch_minversion: 12.2.0.1.41
    opatchauto: []
    opatch:
      - patchid: 35642822
        patchversion: 19.21.0.0
        state: absent
        subpatches:
         - 35655527
         - 35643107
      - patchid:
        patchversion: 19.21.0.0
        state: absent
        subpatches:
         - 34774667
    stop_services: True
    databases:
         - testdb
    listeners:
         - testlis
 db_homes_installed:
  - home: 19300-base            # This must be the same mentioned under "db_homes_config", see the above parameter.
    db_version: 19.3.0          # Oracle version.
    apply_patches: True         # True - will apply patch, False - will do nothing.
    state: present              # present - Oracle Home exists, absent - Oracle Home doesn't exist.
  - home: 19300-base-1
    db_version: 19.3.0
    apply_patches: True
    state: present

7. Execute the playbook

PLAY [Apply binary patches] ****************************************************

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : db-opatch | check if GI is installed] ***
ok: [ansible_db]

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : Creating NFS filesystem from nfshost.] ***
skipping: [ansible_db]

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : include_tasks] *********
included: /home/ansible/.ansible/collections/ansible_collections/ibm/power_aix_oracle_dba/roles/oraswdb_manage_patches/tasks/db-home-patch.yml for ansible_db => (item={'home': '19300-base', 'db_version': '19.3.0', 'apply_patches': True, 'state': 'present'})
included: /home/ansible/.ansible/collections/ansible_collections/ibm/power_aix_oracle_dba/roles/oraswdb_manage_patches/tasks/db-home-patch.yml for ansible_db => (item={'home': '19300-base-1', 'db_version': '19.3.0', 'apply_patches': True, 'state': 'present'})

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : set_fact] **************
ok: [ansible_db]

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : db-opatch | Create patch-base directory (version specific)] ***
ok: [ansible_db] => (item={'home': '19300-base', 'db_version': '19.3.0', 'apply_patches': True, 'state': 'present'})
ok: [ansible_db] => (item={'home': '19300-base-1', 'db_version': '19.3.0', 'apply_patches': True, 'state': 'present'})

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : db-opatch | Extract DB patch files to patch base (from local|nfs) for opatchauto] ***
skipping: [ansible_db]

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : db-opatch | Extract DB patch files to patch base (from remote) for opatchauto] ***
skipping: [ansible_db]

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : db-opatch | Extract DB patch files to patch base (from local|nfs) for opatch] ***
ok: [ansible_db] => (item=[{'filename': '/repos/images/oracle/19c/RU19.21/p35642822_190000_AIX64-5L_RU19.21.zip', 'patchid': 35642822, 'version': '19.3.0', 'patchversion': '19.21.0.0', 'description': 'GI-RU-Oct-2023'}, {'home': '19300-base', 'db_version': '19.3.0', 'apply_patches': True, 'state': 'present'}, {'patchid': 35642822, 'patchversion': '19.21.0.0', 'state': 'present', 'subpatches': [35655527, 35643107]}])
skipping: [ansible_db] => (item=[{'filename': '/repos/images/oracle/19c/RU19.21/p35642822_190000_AIX64-5L_RU19.21.zip', 'patchid': 35642822, 'version': '19.3.0', 'patchversion': '19.21.0.0', 'description': 'GI-RU-Oct-2023'}, {'home': '19300-base', 'db_version': '19.3.0', 'apply_patches': True, 'state': 'present'}, {'patchid': None, 'patchversion': '19.21.0.0', 'state': 'present', 'subpatches': [34774667]}])
ok: [ansible_db] => (item=[{'filename': '/repos/images/oracle/19c/RU19.21/p35642822_190000_AIX64-5L_RU19.21.zip', 'patchid': 35642822, 'version': '19.3.0', 'patchversion': '19.21.0.0', 'description': 'GI-RU-Oct-2023'}, {'home': '19300-base-1', 'db_version': '19.3.0', 'apply_patches': True, 'state': 'present'}, {'patchid': 35642822, 'patchversion': '19.21.0.0', 'state': 'present', 'subpatches': [35655527, 35643107]}])
skipping: [ansible_db] => (item=[{'filename': '/repos/images/oracle/19c/RU19.21/p35642822_190000_AIX64-5L_RU19.21.zip', 'patchid': 35642822, 'version': '19.3.0', 'patchversion': '19.21.0.0', 'description': 'GI-RU-Oct-2023'}, {'home': '19300-base-1', 'db_version': '19.3.0', 'apply_patches': True, 'state': 'present'}, {'patchid': None, 'patchversion': '19.21.0.0', 'state': 'present', 'subpatches': [34774667]}])
skipping: [ansible_db] => (item=[{'filename': '/backup/patches/p34774667_1921000DBRU_AIX64-5L.zip', 'patchid': 34774667, 'version': '19.21.0', 'patchversion': '19.21.0.0'}, {'home': '19300-base', 'db_version': '19.3.0', 'apply_patches': True, 'state': 'present'}, {'patchid': 35642822, 'patchversion': '19.21.0.0', 'state': 'present', 'subpatches': [35655527, 35643107]}])
skipping: [ansible_db] => (item=[{'filename': '/backup/patches/p34774667_1921000DBRU_AIX64-5L.zip', 'patchid': 34774667, 'version': '19.21.0', 'patchversion': '19.21.0.0'}, {'home': '19300-base', 'db_version': '19.3.0', 'apply_patches': True, 'state': 'present'}, {'patchid': None, 'patchversion': '19.21.0.0', 'state': 'present', 'subpatches': [34774667]}])
skipping: [ansible_db] => (item=[{'filename': '/backup/patches/p34774667_1921000DBRU_AIX64-5L.zip', 'patchid': 34774667, 'version': '19.21.0', 'patchversion': '19.21.0.0'}, {'home': '19300-base-1', 'db_version': '19.3.0', 'apply_patches': True, 'state': 'present'}, {'patchid': 35642822, 'patchversion': '19.21.0.0', 'state': 'present', 'subpatches': [35655527, 35643107]}])
skipping: [ansible_db] => (item=[{'filename': '/backup/patches/p34774667_1921000DBRU_AIX64-5L.zip', 'patchid': 34774667, 'version': '19.21.0', 'patchversion': '19.21.0.0'}, {'home': '19300-base-1', 'db_version': '19.3.0', 'apply_patches': True, 'state': 'present'}, {'patchid': None, 'patchversion': '19.21.0.0', 'state': 'present', 'subpatches': [34774667]}])

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : db-opatch | Extract DB patch files to patch base (from remote) for opatch] ***
skipping: [ansible_db] => (item=[{'filename': '/repos/images/oracle/19c/RU19.21/p35642822_190000_AIX64-5L_RU19.21.zip', 'patchid': 35642822, 'version': '19.3.0', 'patchversion': '19.21.0.0', 'description': 'GI-RU-Oct-2023'}, {'home': '19300-base', 'db_version': '19.3.0', 'apply_patches': True, 'state': 'present'}, {'patchid': 35642822, 'patchversion': '19.21.0.0', 'state': 'present', 'subpatches': [35655527, 35643107]}])
skipping: [ansible_db] => (item=[{'filename': '/repos/images/oracle/19c/RU19.21/p35642822_190000_AIX64-5L_RU19.21.zip', 'patchid': 35642822, 'version': '19.3.0', 'patchversion': '19.21.0.0', 'description': 'GI-RU-Oct-2023'}, {'home': '19300-base', 'db_version': '19.3.0', 'apply_patches': True, 'state': 'present'}, {'patchid': None, 'patchversion': '19.21.0.0', 'state': 'present', 'subpatches': [34774667]}])
skipping: [ansible_db] => (item=[{'filename': '/repos/images/oracle/19c/RU19.21/p35642822_190000_AIX64-5L_RU19.21.zip', 'patchid': 35642822, 'version': '19.3.0', 'patchversion': '19.21.0.0', 'description': 'GI-RU-Oct-2023'}, {'home': '19300-base-1', 'db_version': '19.3.0', 'apply_patches': True, 'state': 'present'}, {'patchid': 35642822, 'patchversion': '19.21.0.0', 'state': 'present', 'subpatches': [35655527, 35643107]}])
skipping: [ansible_db] => (item=[{'filename': '/repos/images/oracle/19c/RU19.21/p35642822_190000_AIX64-5L_RU19.21.zip', 'patchid': 35642822, 'version': '19.3.0', 'patchversion': '19.21.0.0', 'description': 'GI-RU-Oct-2023'}, {'home': '19300-base-1', 'db_version': '19.3.0', 'apply_patches': True, 'state': 'present'}, {'patchid': None, 'patchversion': '19.21.0.0', 'state': 'present', 'subpatches': [34774667]}])
skipping: [ansible_db] => (item=[{'filename': '/backup/patches/p34774667_1921000DBRU_AIX64-5L.zip', 'patchid': 34774667, 'version': '19.21.0', 'patchversion': '19.21.0.0'}, {'home': '19300-base', 'db_version': '19.3.0', 'apply_patches': True, 'state': 'present'}, {'patchid': 35642822, 'patchversion': '19.21.0.0', 'state': 'present', 'subpatches': [35655527, 35643107]}])
skipping: [ansible_db] => (item=[{'filename': '/backup/patches/p34774667_1921000DBRU_AIX64-5L.zip', 'patchid': 34774667, 'version': '19.21.0', 'patchversion': '19.21.0.0'}, {'home': '19300-base', 'db_version': '19.3.0', 'apply_patches': True, 'state': 'present'}, {'patchid': None, 'patchversion': '19.21.0.0', 'state': 'present', 'subpatches': [34774667]}])
skipping: [ansible_db] => (item=[{'filename': '/backup/patches/p34774667_1921000DBRU_AIX64-5L.zip', 'patchid': 34774667, 'version': '19.21.0', 'patchversion': '19.21.0.0'}, {'home': '19300-base-1', 'db_version': '19.3.0', 'apply_patches': True, 'state': 'present'}, {'patchid': 35642822, 'patchversion': '19.21.0.0', 'state': 'present', 'subpatches': [35655527, 35643107]}])
skipping: [ansible_db] => (item=[{'filename': '/backup/patches/p34774667_1921000DBRU_AIX64-5L.zip', 'patchid': 34774667, 'version': '19.21.0', 'patchversion': '19.21.0.0'}, {'home': '19300-base-1', 'db_version': '19.3.0', 'apply_patches': True, 'state': 'present'}, {'patchid': None, 'patchversion': '19.21.0.0', 'state': 'present', 'subpatches': [34774667]}])
skipping: [ansible_db]

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : db-opatch | Check opatch dir] ***
ok: [ansible_db]

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : db-opatch | Check current opatch version] ***
ok: [ansible_db]

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : db-opatch | Backup existing OPatch directory] ***
skipping: [ansible_db] => (item={'filename': '/repos/images/oracle/opatch/12.2.0.1.41/opatch-12.2.0.1.41_p6880880_210000_AIX64-5L.zip', 'version': '19.3.0'})
skipping: [ansible_db]

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : db-opatch | Extract OPatch to DB Home (from local/nfs)] ***
skipping: [ansible_db] => (item={'filename': '/repos/images/oracle/opatch/12.2.0.1.41/opatch-12.2.0.1.41_p6880880_210000_AIX64-5L.zip', 'version': '19.3.0'})
skipping: [ansible_db]

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : db-opatch | Extract OPatch to DB Home (from remote location)] ***
skipping: [ansible_db] => (item={'filename': '/repos/images/oracle/opatch/12.2.0.1.41/opatch-12.2.0.1.41_p6880880_210000_AIX64-5L.zip', 'version': '19.3.0'})
skipping: [ansible_db]

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : Checking the Patch ID] ***
changed: [ansible_db] => (item=[{'patchid': 35642822, 'patchversion': '19.21.0.0', 'state': 'present'}, 35655527])
changed: [ansible_db] => (item=[{'patchid': 35642822, 'patchversion': '19.21.0.0', 'state': 'present'}, 35643107])
changed: [ansible_db] => (item=[{'patchid': None, 'patchversion': '19.21.0.0', 'state': 'present'}, 34774667])

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : Store Patch count list] ***
ok: [ansible_db] => (item=None)
ok: [ansible_db] => (item=None)
ok: [ansible_db] => (item=None)
ok: [ansible_db]

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : Stopping the DB Services for Patching] ***
changed: [ansible_db] => (item=devdb)

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : Stopping the DB Services for Rollback] ***
skipping: [ansible_db] => (item=devdb)
skipping: [ansible_db]

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : Stopping the Listeners for Patching] ***
changed: [ansible_db] => (item=devlis)

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : Stopping the Listeners for Rollback] ***
skipping: [ansible_db] => (item=devlis)
skipping: [ansible_db]

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : debug] *****************
ok: [ansible_db] => {
    "msg": "Managing patches for /u01/db19c"
}

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : db-opatch | Manage opatchauto patches for DB (non-gi)] ***
changed: [ansible_db] => (item=[{'patchid': 35642822, 'patchversion': '19.21.0.0', 'state': 'present'}, 35655527])
changed: [ansible_db] => (item=[{'patchid': 35642822, 'patchversion': '19.21.0.0', 'state': 'present'}, 35643107])
changed: [ansible_db] => (item=[{'patchid': None, 'patchversion': '19.21.0.0', 'state': 'present'}, 34774667])

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : db-opatch | Manage opatchauto patches for DB (gi)] ***
skipping: [ansible_db]

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : Opatch lspatches output] ***
ok: [ansible_db]

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : ansible.builtin.debug] ***
ok: [ansible_db] => {
    "msg": [
        "34774667;TT23.1ASAN  GLOBAL-BUFFER-OVERFLOW IN PGA AT KWQALOCKQTWITHINFO",
        "35643107;Database Release Update : 19.21.0.0.231017 (35643107)",
        "35655527;OCW RELEASE UPDATE 19.21.0.0.0 (35655527)",
        "",
        "OPatch succeeded.",
        ""
    ]
}

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : Starting the DB Services Post Patching] ***
changed: [ansible_db] => (item=devdb)

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : Starting the DB Services Post Patching] ***
skipping: [ansible_db] => (item=devdb)
skipping: [ansible_db]

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : Starting the Listeners Post Rollback] ***
changed: [ansible_db] => (item=devlis)

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : Starting the Listeners Post Rollback] ***
skipping: [ansible_db] => (item=devlis)
skipping: [ansible_db]

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : Start Oracle Home on RAC nodes] ***
skipping: [ansible_db]

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : Remove stat files] *****
skipping: [ansible_db]

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : set_fact] **************
ok: [ansible_db]

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : db-opatch | Create patch-base directory (version specific)] ***
ok: [ansible_db] => (item={'home': '19300-base', 'db_version': '19.3.0', 'apply_patches': True, 'state': 'present'})
ok: [ansible_db] => (item={'home': '19300-base-1', 'db_version': '19.3.0', 'apply_patches': True, 'state': 'present'})

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : db-opatch | Extract DB patch files to patch base (from local|nfs) for opatchauto] ***
skipping: [ansible_db]

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : db-opatch | Extract DB patch files to patch base (from remote) for opatchauto] ***
skipping: [ansible_db]

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : db-opatch | Extract DB patch files to patch base (from local|nfs) for opatch] ***
ok: [ansible_db] => (item=[{'filename': '/repos/images/oracle/19c/RU19.21/p35642822_190000_AIX64-5L_RU19.21.zip', 'patchid': 35642822, 'version': '19.3.0', 'patchversion': '19.21.0.0', 'description': 'GI-RU-Oct-2023'}, {'home': '19300-base', 'db_version': '19.3.0', 'apply_patches': True, 'state': 'present'}, {'patchid': 35642822, 'patchversion': '19.21.0.0', 'state': 'present', 'subpatches': [35655527, 35643107]}])
skipping: [ansible_db] => (item=[{'filename': '/repos/images/oracle/19c/RU19.21/p35642822_190000_AIX64-5L_RU19.21.zip', 'patchid': 35642822, 'version': '19.3.0', 'patchversion': '19.21.0.0', 'description': 'GI-RU-Oct-2023'}, {'home': '19300-base', 'db_version': '19.3.0', 'apply_patches': True, 'state': 'present'}, {'patchid': None, 'patchversion': '19.21.0.0', 'state': 'present', 'subpatches': [34774667]}])
ok: [ansible_db] => (item=[{'filename': '/repos/images/oracle/19c/RU19.21/p35642822_190000_AIX64-5L_RU19.21.zip', 'patchid': 35642822, 'version': '19.3.0', 'patchversion': '19.21.0.0', 'description': 'GI-RU-Oct-2023'}, {'home': '19300-base-1', 'db_version': '19.3.0', 'apply_patches': True, 'state': 'present'}, {'patchid': 35642822, 'patchversion': '19.21.0.0', 'state': 'present', 'subpatches': [35655527, 35643107]}])
skipping: [ansible_db] => (item=[{'filename': '/repos/images/oracle/19c/RU19.21/p35642822_190000_AIX64-5L_RU19.21.zip', 'patchid': 35642822, 'version': '19.3.0', 'patchversion': '19.21.0.0', 'description': 'GI-RU-Oct-2023'}, {'home': '19300-base-1', 'db_version': '19.3.0', 'apply_patches': True, 'state': 'present'}, {'patchid': None, 'patchversion': '19.21.0.0', 'state': 'present', 'subpatches': [34774667]}])
skipping: [ansible_db] => (item=[{'filename': '/backup/patches/p34774667_1921000DBRU_AIX64-5L.zip', 'patchid': 34774667, 'version': '19.21.0', 'patchversion': '19.21.0.0'}, {'home': '19300-base', 'db_version': '19.3.0', 'apply_patches': True, 'state': 'present'}, {'patchid': 35642822, 'patchversion': '19.21.0.0', 'state': 'present', 'subpatches': [35655527, 35643107]}])
skipping: [ansible_db] => (item=[{'filename': '/backup/patches/p34774667_1921000DBRU_AIX64-5L.zip', 'patchid': 34774667, 'version': '19.21.0', 'patchversion': '19.21.0.0'}, {'home': '19300-base', 'db_version': '19.3.0', 'apply_patches': True, 'state': 'present'}, {'patchid': None, 'patchversion': '19.21.0.0', 'state': 'present', 'subpatches': [34774667]}])
skipping: [ansible_db] => (item=[{'filename': '/backup/patches/p34774667_1921000DBRU_AIX64-5L.zip', 'patchid': 34774667, 'version': '19.21.0', 'patchversion': '19.21.0.0'}, {'home': '19300-base-1', 'db_version': '19.3.0', 'apply_patches': True, 'state': 'present'}, {'patchid': 35642822, 'patchversion': '19.21.0.0', 'state': 'present', 'subpatches': [35655527, 35643107]}])
skipping: [ansible_db] => (item=[{'filename': '/backup/patches/p34774667_1921000DBRU_AIX64-5L.zip', 'patchid': 34774667, 'version': '19.21.0', 'patchversion': '19.21.0.0'}, {'home': '19300-base-1', 'db_version': '19.3.0', 'apply_patches': True, 'state': 'present'}, {'patchid': None, 'patchversion': '19.21.0.0', 'state': 'present', 'subpatches': [34774667]}])

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : db-opatch | Extract DB patch files to patch base (from remote) for opatch] ***
skipping: [ansible_db] => (item=[{'filename': '/repos/images/oracle/19c/RU19.21/p35642822_190000_AIX64-5L_RU19.21.zip', 'patchid': 35642822, 'version': '19.3.0', 'patchversion': '19.21.0.0', 'description': 'GI-RU-Oct-2023'}, {'home': '19300-base', 'db_version': '19.3.0', 'apply_patches': True, 'state': 'present'}, {'patchid': 35642822, 'patchversion': '19.21.0.0', 'state': 'present', 'subpatches': [35655527, 35643107]}])
skipping: [ansible_db] => (item=[{'filename': '/repos/images/oracle/19c/RU19.21/p35642822_190000_AIX64-5L_RU19.21.zip', 'patchid': 35642822, 'version': '19.3.0', 'patchversion': '19.21.0.0', 'description': 'GI-RU-Oct-2023'}, {'home': '19300-base', 'db_version': '19.3.0', 'apply_patches': True, 'state': 'present'}, {'patchid': None, 'patchversion': '19.21.0.0', 'state': 'present', 'subpatches': [34774667]}])
skipping: [ansible_db] => (item=[{'filename': '/repos/images/oracle/19c/RU19.21/p35642822_190000_AIX64-5L_RU19.21.zip', 'patchid': 35642822, 'version': '19.3.0', 'patchversion': '19.21.0.0', 'description': 'GI-RU-Oct-2023'}, {'home': '19300-base-1', 'db_version': '19.3.0', 'apply_patches': True, 'state': 'present'}, {'patchid': 35642822, 'patchversion': '19.21.0.0', 'state': 'present', 'subpatches': [35655527, 35643107]}])
skipping: [ansible_db] => (item=[{'filename': '/repos/images/oracle/19c/RU19.21/p35642822_190000_AIX64-5L_RU19.21.zip', 'patchid': 35642822, 'version': '19.3.0', 'patchversion': '19.21.0.0', 'description': 'GI-RU-Oct-2023'}, {'home': '19300-base-1', 'db_version': '19.3.0', 'apply_patches': True, 'state': 'present'}, {'patchid': None, 'patchversion': '19.21.0.0', 'state': 'present', 'subpatches': [34774667]}])
skipping: [ansible_db] => (item=[{'filename': '/backup/patches/p34774667_1921000DBRU_AIX64-5L.zip', 'patchid': 34774667, 'version': '19.21.0', 'patchversion': '19.21.0.0'}, {'home': '19300-base', 'db_version': '19.3.0', 'apply_patches': True, 'state': 'present'}, {'patchid': 35642822, 'patchversion': '19.21.0.0', 'state': 'present', 'subpatches': [35655527, 35643107]}])
skipping: [ansible_db] => (item=[{'filename': '/backup/patches/p34774667_1921000DBRU_AIX64-5L.zip', 'patchid': 34774667, 'version': '19.21.0', 'patchversion': '19.21.0.0'}, {'home': '19300-base', 'db_version': '19.3.0', 'apply_patches': True, 'state': 'present'}, {'patchid': None, 'patchversion': '19.21.0.0', 'state': 'present', 'subpatches': [34774667]}])
skipping: [ansible_db] => (item=[{'filename': '/backup/patches/p34774667_1921000DBRU_AIX64-5L.zip', 'patchid': 34774667, 'version': '19.21.0', 'patchversion': '19.21.0.0'}, {'home': '19300-base-1', 'db_version': '19.3.0', 'apply_patches': True, 'state': 'present'}, {'patchid': 35642822, 'patchversion': '19.21.0.0', 'state': 'present', 'subpatches': [35655527, 35643107]}])
skipping: [ansible_db] => (item=[{'filename': '/backup/patches/p34774667_1921000DBRU_AIX64-5L.zip', 'patchid': 34774667, 'version': '19.21.0', 'patchversion': '19.21.0.0'}, {'home': '19300-base-1', 'db_version': '19.3.0', 'apply_patches': True, 'state': 'present'}, {'patchid': None, 'patchversion': '19.21.0.0', 'state': 'present', 'subpatches': [34774667]}])
skipping: [ansible_db]

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : db-opatch | Check opatch dir] ***
ok: [ansible_db]

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : db-opatch | Check current opatch version] ***
ok: [ansible_db]

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : db-opatch | Backup existing OPatch directory] ***
changed: [ansible_db] => (item={'filename': '/repos/images/oracle/opatch/12.2.0.1.41/opatch-12.2.0.1.41_p6880880_210000_AIX64-5L.zip', 'version': '19.3.0'})

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : db-opatch | Extract OPatch to DB Home (from local/nfs)] ***
changed: [ansible_db] => (item={'filename': '/repos/images/oracle/opatch/12.2.0.1.41/opatch-12.2.0.1.41_p6880880_210000_AIX64-5L.zip', 'version': '19.3.0'})

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : db-opatch | Extract OPatch to DB Home (from remote location)] ***
skipping: [ansible_db] => (item={'filename': '/repos/images/oracle/opatch/12.2.0.1.41/opatch-12.2.0.1.41_p6880880_210000_AIX64-5L.zip', 'version': '19.3.0'})
skipping: [ansible_db]

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : Checking the Patch ID] ***
changed: [ansible_db] => (item=[{'patchid': 35642822, 'patchversion': '19.21.0.0', 'state': 'present'}, 35655527])
changed: [ansible_db] => (item=[{'patchid': 35642822, 'patchversion': '19.21.0.0', 'state': 'present'}, 35643107])
changed: [ansible_db] => (item=[{'patchid': None, 'patchversion': '19.21.0.0', 'state': 'present'}, 34774667])

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : Store Patch count list] ***
ok: [ansible_db] => (item=None)
ok: [ansible_db] => (item=None)
ok: [ansible_db] => (item=None)
ok: [ansible_db]

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : Stopping the DB Services for Patching] ***
changed: [ansible_db] => (item=testlis)

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : Stopping the DB Services for Rollback] ***
skipping: [ansible_db] => (item=testlis)
skipping: [ansible_db]

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : Stopping the Listeners for Patching] ***
changed: [ansible_db] => (item=)

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : Stopping the Listeners for Rollback] ***
skipping: [ansible_db] => (item=)
skipping: [ansible_db]

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : debug] *****************
ok: [ansible_db] => {
    "msg": "Managing patches for /u01/db19c_2"
}

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : db-opatch | Manage opatchauto patches for DB (non-gi)] ***
changed: [ansible_db] => (item=[{'patchid': 35642822, 'patchversion': '19.21.0.0', 'state': 'present'}, 35655527])
changed: [ansible_db] => (item=[{'patchid': 35642822, 'patchversion': '19.21.0.0', 'state': 'present'}, 35643107])
changed: [ansible_db] => (item=[{'patchid': None, 'patchversion': '19.21.0.0', 'state': 'present'}, 34774667])

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : db-opatch | Manage opatchauto patches for DB (gi)] ***
skipping: [ansible_db]

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : Opatch lspatches output] ***
ok: [ansible_db]

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : ansible.builtin.debug] ***
ok: [ansible_db] => {
    "msg": [
        "34774667;TT23.1ASAN  GLOBAL-BUFFER-OVERFLOW IN PGA AT KWQALOCKQTWITHINFO",
        "35643107;Database Release Update : 19.21.0.0.231017 (35643107)",
        "35655527;OCW RELEASE UPDATE 19.21.0.0.0 (35655527)",
        "",
        "OPatch succeeded.",
        ""
    ]
}

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : Starting the DB Services Post Patching] ***
changed: [ansible_db] => (item=testlis)

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : Starting the DB Services Post Patching] ***
skipping: [ansible_db] => (item=testlis)
skipping: [ansible_db]

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : Starting the Listeners Post Rollback] ***
changed: [ansible_db] => (item=)

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : Starting the Listeners Post Rollback] ***
skipping: [ansible_db] => (item=)
skipping: [ansible_db]

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : Start Oracle Home on RAC nodes] ***
skipping: [ansible_db]

TASK [ibm.power_aix_oracle_dba.oraswdb_manage_patches : Remove stat files] *****
skipping: [ansible_db]

PLAY RECAP *********************************************************************
ansible_db                 : ok=35   changed=14   unreachable=0    failed=0    skipped=25   rescued=0    ignored=0

To execute this playbook from GUI, an example is provided in the document, please refer this link: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
