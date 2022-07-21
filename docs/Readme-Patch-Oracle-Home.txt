# Patch Oracle database 19c
# =========================
# Description: This module can be used for the following patching scenarios. Each section is described in this readme file. This contains four sections.
# It uses a python library located here: ansible-power-aix-oracle-dba/library/oracle_opatch.

# 1. Standalone Oracle Home: This will patch one oracle home hosting one database, it uses "opatch" utility for patching. In case, there are more than one databases running under the Oracle home, they should be stopped manually before the patching activity. Datapatch to be run separately using datapatch module provided with this collection, please refer ansible-power-aix-oracle-dba/readmes/Readme-Datapatch.txt

# 2. Standalone Oracle Home on Grid (Oracle restart): This will patch one oracle home hosting multiple database, uses "opatchauto" utility for patching. Multiple Oracle homes & databases can be patched. Requires sudo access for Orcle home user to run opatchauto.

# 3. RAC with ACFS: This will patch RAC oracle home residing in ACFS, uses "opatchauto" utility.

# 4. RAC without ACFS: This will patch RAC oracle home, uses "opatchauto" utility.

######################################
# 1. Standalone Oracle Home Patching #
######################################

# Description: This playbook executes "oraswdb_manage_patches" role. Opatch option must be set in the variables file & opatchauto must be disabled in order to avoid conflict. The opatchauto option is already disabled in the following example.
# Make sure to set the variables appropriately to avoid failure(s) or patching of unintended instances.
# This module can patch one oracle home at a time. In case, there are more than one databases running under the Oracle home, they should be stopped manually before the patching activity. Datapatch to be run separately using datapatch module provided with this collection, please refer ansible-power-aix-oracle-dba/readmes/Readme-Datapatch.txt

# Prerequisites:
# ==============
# Passwordless ssh needs to be setup between the Target lpar oracle owner and ansible controller user.

# Set the Variables for Oracle to execute this task: Open the file ansible-power-aix-oracle-dba/roles/oraswdb_manage_patches/defaults/main.yml and modify the variables. Modify only the ones which are marked with comments.

role_separation: false                          # If Oracle Home & Grid home owners are not same, set it to True. Not applicable for standalone DB.
hostgroup: "{{ group_names[0] }}"
cluster_master: "{{play_hosts[0]}}"
configure_cluster: False                        # Set it to False as this is a standalone DB.
oracle_user: "{{ ansible_user_id }}"
oracle_group: oinstall                          # Primary group for oracle_user.
apply_patches_db: True                          # This should be set to True

oracle_sw_source_local: /home/ansible/ansible_test/patches              # This is the location on Ansible controller, place OPatch & Release update patch zip files.
is_sw_source_local: True                        # Set this to True to utilize the patches mentioned in the above parameter oracle_sw_source_local.
install_from_nfs: False                         # Use this parameter when using NFS mount point.
oracle_sw_copy: "{% if install_from_nfs %}False{% else %}True{% endif %}"
oracle_sw_unpack: "{% if install_from_nfs %}True{% else %}False{% endif %}"
nfs_server_sw_path: /home/ansible/ansible_test/patches/   # Location of the NFS path mounted on AIX lpar where the patches and OPatch must be placed. No need to extract the zip files, ansible will do it. Make sure this directory has proper read permissions.
oracle_stage: /backup/patches                   # This can be any location on AIX Lpar, used by ansible to stage the patches. Make sure this directory has proper read-write permissions.
oracle_stage_remote: "{{ nfs_server_sw_path }}"
oracle_stage_install: "{% if not oracle_sw_copy and not oracle_sw_unpack%}{{ oracle_stage_remote }}{% else %}{{ oracle_stage }}{% endif %}"
oracle_rsp_stage: "{{ oracle_stage }}/rsp"
oracle_patch_stage: "{{ oracle_stage }}/patches"
oracle_patch_stage_remote: "{{ oracle_stage_remote }}/patches"
oracle_patch_install: "{% if not oracle_sw_copy and not oracle_sw_unpack%}{{ oracle_patch_stage_remote }}{% else %}{{ oracle_patch_stage }}{% endif %}"

oracle_sw_patches:
  - filename: RU19.14-p33509923_190000_AIX64-5L.zip     # Patch filename placed on the Ansible controller (defined for oracle_sw_source_local).
    patchid: 33509923                                   # Patch ID.
    version: 19.3.0.0                                   # Oracle version.
    patchversion: 19.14.0.0.220118                      # Release update patch version (or) Patch ID
    description: DB-RU-Jan-2022                         # This is optional.
  - filename: p33515361_1914RU.zip                      # 2nd Patch filename placed on the Ansible controller (defined for oracle_sw_source_local)
    patchid: 33515361                                   # Release update Patch ID.
    version: 19.3.0.0                                   # Oracle version.
    patchversion: 19.14.0.0.220118                      # Release update patch version.
    description: DB-RU-Jan-2022                         # This is optional.

oracle_opatch_patch:
  - filename: p6880880_12201029_AIX64.zip               # OPatch zip filename.
    version: 19.3.0.0                                   # Database Version

db_version: 19.3.0.0                                    # Database Version
oracle_db_name: ansible                                 # Database Name
oracle_env:
      ORACLE_SID: "{{ oracle_db_name }}"
      ORACLE_HOME: "{{ oracle_home_db}}"
      PATH: "{{ oracle_home_db}}/bin:$PATH:/usr/local/bin:/bin:/sbin:/usr/bin:/usr/sbin"

oracle_inventory_loc: /u01/app/oraInventory		# Oracle Home Inventory location

db_homes_config:
  19300-base:
    oracle_home: /u01/19.3.0.0/19c_ansible      	# Oracle Home Location
    version: 19.3.0.0           			# Oracle version.
    edition: EE                 			# Oracle edition.
    opatch_minversion: 12.2.0.1.29      		# Minimum opatch version required to apply required patches.
    opatch:
      - patchid: 33515361       			# Patch ID. Example: given patch id is 19.14 Release update patch for Database.
        patchversion: 19.14.0.0.220118  		# Release update patch version
        state: absent           			# Set to present (applies the patch). Set to absent (rolls back the patch).
        stop_processes: True    			# This should be set to True, stops the DB before patch apply/rollback.
    opatchauto: []                               	# Here, "opatchauto: []" means opatchauto option is NOT defined. Also the 6 parameters must be commented as shown below.
    #      - patchid: 33509923
    #    patchversion: 19.14.0.0.220118
    #    state: absent
    #    subpatches:
    #        - 33515361
    #        - 33529556

db_homes_installed:
  - home: 19300-base            # This must be the name mentioned under "db_homes_config", see the above parameter.
    apply_patches: True         # Don't change this.
    state: present              # Set to "present" to patch this home. Set to "absent" to skip.

oracle_home_gi: "{% if configure_cluster %}{{ oracle_home_gi_cl }}{% else %}{{ oracle_home_gi_so }}{% endif %}"
oracle_home_gi_cl: "/u01/app/{{ oracle_install_version_gi }}/grid" # ORACLE_HOME for Grid Infrastructure (Clustered)
oracle_home_gi_so: "{{ oracle_base }}/{{ oracle_install_version_gi }}/grid" # ORACLE_HOME for Grid Infrastructure (Stand Alone)

acfs_used: False        # Set to True only if Oracle Home is on ACFS mount point. This should be False for Standalone DB patching.
node_list:              # If the above parameter is True, mention all the nodes names except the one from where Ansible does the patching.
   - { node: rac92 }
   - { node: rac93 }
   - { node: rac94 }

# Executing the playbook: This playbook executes a role. Before running the playbook, open the playbook and update the hostname & remote user details as shown below. Do NOT change other parts of the script.
# Change directory to ansible-power-aix-oracle-dba
# Name of the Playbook: db-opatch.yml
# Content of the playbook

- name: Apply binary patches
  gather_facts: yes
  hosts: ansible_db     # AIX lpar hostname, make sure it's set in the inventory.
  remote_user: oracle   # AIX lpar Oracle home user.
  roles:
     - {role: oraswdb_manage_patches }

# ansible-playbook db-opatch.yml

#####################################   
# 2. Standalone Oracle Home on Grid #
#####################################

# Description: This playbook executes "oraswdb_manage_patches" role. Opatchauto option must be set in the variables file & opatch option must be disabled in order to avoid conflict. The opatch option is already disabled in the following example.
# Make sure to set the variables appropriately to avoid failure(s) or patching of unintended instances.
# This module can patch multiple Oracle homes & databases.  

# Prerequisites:
# ==============
# Passwordless ssh needs to be setup between the Target lpar oracle owner and ansible controller user.

# Set the Variables for Oracle to execute this task: Open the file ansible-power-aix-oracle-dba/roles/oraswdb_manage_patches/defaults/main.yml and modify the variables. Modify only the ones which are marked with comments.

role_separation: false                          # If Oracle Home & Grid home owners are not same, set it to True. Not applicable for standalone DB.
hostgroup: "{{ group_names[0] }}"
cluster_master: "{{play_hosts[0]}}"
configure_cluster: False                        # Set it to False in case of Standalone DB, Set it to True in calse of RAC DB.
oracle_user: "{{ ansible_user_id }}"
oracle_group: oinstall                          # Primary group for oracle/grid user.
apply_patches_db: True                          # Don't change this.

oracle_sw_source_local: /home/ansible/ansible_test/patches              # This is the location on Ansible controller, place the appropriate OPatch & patch zip files.
is_sw_source_local: True                        # Set this to True to utilize the patches mentioned in the above parameter oracle_sw_source_local. "install_from_nfs" must be set to False when this parameter is set to True.
install_from_nfs: False                         # Set this parameter to True if you want to use NFS mount point to stage the patches. Associated parameter is "nfs_server_sw_path".
oracle_sw_copy: "{% if install_from_nfs %}False{% else %}True{% endif %}"
oracle_sw_unpack: "{% if install_from_nfs %}True{% else %}False{% endif %}"
nfs_server_sw_path: /home/ansible/ansible_test/patches/   # Location of the NFS path mounted on AIX lpar where the patches and OPatch must be placed. No need to extract the zip files, ansible will do it. Make sure this directory has proper read permissions.
oracle_stage: /backup/patches                   # This can be any location on AIX Lpar, used by ansible to stage the patches. Make sure this directory has proper read-write permissions.
oracle_stage_remote: "{{ nfs_server_sw_path }}"
oracle_stage_install: "{% if not oracle_sw_copy and not oracle_sw_unpack%}{{ oracle_stage_remote }}{% else %}{{ oracle_stage }}{% endif %}"
oracle_rsp_stage: "{{ oracle_stage }}/rsp"
oracle_patch_stage: "{{ oracle_stage }}/patches"
oracle_patch_stage_remote: "{{ oracle_stage_remote }}/patches"
oracle_patch_install: "{% if not oracle_sw_copy and not oracle_sw_unpack%}{{ oracle_patch_stage_remote }}{% else %}{{ oracle_patch_stage }}{% endif %}"

oracle_sw_patches:
  - filename: RU19.14-p33509923_190000_AIX64-5L.zip     # Patch filename placed on the Ansible controller (defined in oracle_sw_source_local (or) nfs_server_sw_path).
    patchid: 33509923                                   # Patch ID.
    version: 19.3.0.0                                   # Oracle version.
    patchversion: 19.14.0.0.220118                      # Release update patch version (or) Patch ID
    description: DB-RU-Jan-2022                         # This is optional.
  - filename: p33515361_1914RU.zip                      # 2nd Patch filename placed on the Ansible controller (defined for oracle_sw_source_local (or) nfs_server_sw_path)
    patchid: 33515361                                   # Release update Patch ID.
    version: 19.3.0.0                                   # Oracle version.
    patchversion: 19.14.0.0.220118                      # Release update patch version.
    description: DB-RU-Jan-2022                         # This is optional.

oracle_opatch_patch:
  - filename: p6880880_12201029_AIX64.zip               # OPatch zip filename.
    version: 19.3.0.0                                   # Database Version

db_version: 19.3.0.0                                    # Database Version
oracle_db_name: ansible                                 # Database Name
oracle_env:
      ORACLE_SID: "{{ oracle_db_name }}"
      ORACLE_HOME: "{{ oracle_home_db}}"
      PATH: "{{ oracle_home_db}}/bin:$PATH:/usr/local/bin:/bin:/sbin:/usr/bin:/usr/sbin"

oracle_inventory_loc: /u01/app/oraInventory             # Oracle Home Inventory location

db_homes_config:
  19300-base:                                           # Any name for identification.
    oracle_home: /u01/19.3.0.0/19c_ansible              # 1st Oracle Home Location.
    version: 19.3.0.0                                   # Oracle version.
    edition: EE                                         # Oracle edition.
    opatch_minversion: 12.2.0.1.29                      # Minimum opatch version required to apply required patches.
    opatchauto:
      - patchid: 33509923                               # Patch ID. Example: given patch id is 19.14 Release update patch for Database.
        patchversion: 19.14.0.0.220118                  # Minimum opatch version required to apply required patches.
        state: present                                  # Set to present (applies the patch). Set to absent (rolls back the patch).
        subpatches:
          - 33515361
          - 33529556
    opatch: []                                          # Here, "opatch: []" means opatch option is NOT defined. Also the 4 parameters must be commented as shown here.
    #  - patchid: 33515361                              # Patch ID. Example: given patch id is 19.14 Release update patch for Database.
    #    patchversion: 19.14.0.0.220118                 # Release update patch version
    #    state: absent                                  # Set to present (applies the patch). Set to absent (rolls back the patch).
    #    stop_processes: True                           # This should be set to True, stops the DB before patch apply/rollback.
  #19300-base2:                                          # Any name for identification.
  #  oracle_home: /u01/homedb19c                         # 2nd Oracle Home Location
  #  version: 19.3.0.0                                   # Oracle version.
  #  edition: EE                                         # Oracle edition.
  #  opatch_minversion: 12.2.0.1.29                      # Minimum opatch version required to apply required patches.
  #  opatchauto:
  #    - patchid: 33509923                               # Patch ID. Example: given patch id is 19.14 Release update patch for Database.
  #      patchversion: 19.14.0.0.220118                  # Release update patch version.
  #      state: present                                  # Set to present (applies the patch). Set to absent (rolls back the patch).
  #      subpatches:
  #        - 33515361
  #        - 33529556
    opatch: []                                          # Here, "opatch: []" means opatch option is NOT defined. Also the 4 parameters must be commented as shown here.
    #  - patchid: 33515361                              # Patch ID. Example: given patch id is 19.14 Release update patch for Database.
    #    patchversion: 19.14.0.0.220118                 # Release update patch version
    #    state: absent                                  # Set to present (applies the patch). Set to absent (rolls back the patch).
    #    stop_processes: True                           # This should be set to True, stops the DB before patch apply/rollback.

db_homes_installed:
  - home: 19300-base            # This must be the name mentioned under "db_homes_config", see the above parameter.
    apply_patches: True         # Don't change this.
    state: present              # Set to "present" to patch this home. Set to "absent" to skip.
  #- home: 19300-base2           # This must be the name mentioned under "db_homes_config", see the above parameter.
  #  apply_patches: True         # Don't change this.
  #  state: present              # Set to "present" to patch this home. Set to "absent" to skip.


oracle_home_gi: "{% if configure_cluster %}{{ oracle_home_gi_cl }}{% else %}{{ oracle_home_gi_so }}{% endif %}"
oracle_home_gi_cl: "/u01/app/{{ oracle_install_version_gi }}/grid" # ORACLE_HOME for Grid Infrastructure (Clustered)
oracle_home_gi_so: "{{ oracle_base }}/{{ oracle_install_version_gi }}/grid" # ORACLE_HOME for Grid Infrastructure (Stand Alone)

acfs_used: False        # Set to True only if Oracle Home is on ACFS mount point. This should be False for Standalone DB patching.
node_list:              # If the above parameter is True, mention all the nodes names except the one from where Ansible does the patching.
   - { node: rac92 }
   - { node: rac93 }
   - { node: rac94 }

# Executing the playbook: This playbook executes a role. Before running the playbook, open the playbook and update the hostname & remote user details as shown below. Do NOT change other parts of the script.
# Change directory to ansible-power-aix-oracle-dba
# Name of the Playbook: db-opatch.yml
# Content of the playbook

- name: Apply binary patches
  gather_facts: yes
  hosts: ansible_db     # AIX lpar hostname, make sure it's set in the inventory.
  remote_user: oracle   # AIX lpar Oracle home user.
  roles:
     - {role: oraswdb_manage_patches }

# ansible-playbook db-opatch.yml --ask-become-pass

####################
# 3. RAC with ACFS #
####################

# Description: This playbook executes "oraswdb_manage_patches" role. Opatchauto option must be set in the variables file & opatch option must be disabled in order to avoid conflict. 
# Make sure to set the variables appropriately to avoid failure(s) or patching of unintended instances.

# Prerequisites:
# ==============
# Passwordless ssh needs to be setup between the Target lpar oracle owner and ansible controller user.

# Set the Variables for Oracle to execute this task: Open the file ansible-power-aix-oracle-dba/roles/oraswdb_manage_patches/defaults/main.yml and modify the variables. Modify only the ones which are marked with comments.

# Note: This change should be done when using Oracle Home configured on ACFS. 
# Note: All the parameters are similar to Case 2 shown above, except "ACFS related variables" must be changed as shown below.

acfs_used: True        # Set to True only if Oracle Home is on ACFS mount point. This should be False for Standalone DB patching.
node_list:             # When the above parameter is set to True, mention all the RAC node names except the first node. Example: In case of a 4 node RAC (rac91, rac92, rac93, rac94), rac91 should be left off and the remaining node names must be mentioned in the node list below.
   - { node: rac92 }
   - { node: rac93 }
   - { node: rac94 }

# Executing the playbook: This playbook executes a role. Before running the playbook, open the playbook and update the hostname & remote user details as shown below. Do NOT change other parts of the script.
# Change directory to ansible-power-aix-oracle-dba
# Name of the Playbook: db-opatchauto.yml
# Content of the playbook

- name: Apply binary patches
  gather_facts: yes
  hosts: ansible_db     # AIX lpar hostname, make sure it's set in the inventory.
  remote_user: oracle   # AIX lpar Oracle home user.
  roles:
     - {role: oraswdb_manage_patches }

# ansible-playbook db-opatch.yml --ask-become-pass

######################
# 4. RAC without ACFS#
######################

# Description: This playbook executes "oraswdb_manage_patches" role. Opatchauto option must be set in the variables file & opatch option must be disabled in order to avoid conflict. For convenience, opatch option is already disabled in the following example.
# Make sure to set the variables appropriately to avoid failure(s) or patching of unintended instances.

# Prerequisites:
# ==============
# Passwordless ssh needs to be setup between the Target lpar oracle owner and ansible controller user.

# Set the Variables for Oracle to execute this task: Open the file ansible-power-aix-oracle-dba/roles/oraswdb_manage_patches/defaults/main.yml and modify the variables. Modify only the ones which are marked with comments.
# Note: Please refer case 2 to set the parameters.

# Executing the playbook: This playbook executes a role. Before running the playbook, open the playbook and update the hostname & remote user details as shown below. Do NOT change other parts of the script.
# Change directory to ansible-power-aix-oracle-dba
# Playbook Name: db-rac-opatchauto.yml
# Content of the playbook

- name: Apply binary patches
  gather_facts: yes
  hosts: rachosts     # AIX lpar RAC hostnames, make sure it's set in the inventory.
  remote_user: oracle   # AIX lpar Oracle home user.
  serial: 1
  roles:
     - {role: oraswdb_manage_patches }

# ansible-playbook db-rac-opatchauto.yml --ask-become-pass
