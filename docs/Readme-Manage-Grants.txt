# Manage Grants - Readme
# =====================

# Description: This module is used to grant/Revoke privileges to Users/Roles.
# It uses a python library: ansible-power-aix-oracle-dba/library/oracle_grants

# Prerequisites:
# ==============
# Passwordless ssh needs to be setup between the Target lpar oracle owner and ansible controller user.

# Go to the playbooks directory 
# Decrypt the file (if it's already encrypted)
# ansible-vault decrypt vars/vault.yml
Vault password:
Decryption successful
# Set SYS password for "default_dbpass" variable in ansible-power-aix-oracle-dba/playbooks/vars/vault.yml.
# Encrypt the file
# ansible-vault encrypt vars/vault.yml
New Vault password:
Confirm New Vault password:
Encryption successful

# Set the Variables for Oracle to execute this task: 
# Open the file vars/vars.yml and set the following variables:

hostname: ansible_db                    # AIX lpar hostname
listener_port: 1521                     # Database port number
oracle_db_home: /tmp/oracle_client      # Oracle Client location on the ansible controller.
oracle_env:
     ORACLE_HOME: "{{ oracle_db_home }}"
     LD_LIBRARY_PATH: "{{ oracle_db_home}}/lib"
     PATH: "{{ oracle_db_home}}/bin:$PATH:/usr/local/bin:/bin:/sbin:/usr/bin:/usr/sbin"

# Open the file ansible-power-aix-oracle-dba/roles/oradb_manage_grants/defaults/main.yml and modify the variables. Modify only the ones which are marked with comments.

db_user: sys
db_mode: sysdba
db_service_name: "{% if item.0 is defined %}
                    {%- if item.0.oracle_db_unique_name is defined %}{{ item.0.oracle_db_unique_name }}
                    {%- elif item.0.oracle_db_instance_name is defined %}{{ item.0.oracle_db_instance_name }}
                    {%- else %}{{ item.0.oracle_db_name }}
                    {%- endif %}
                  {%- endif %}"


listener_port_template: "{% if item.0.listener_port is defined %}{{ item.0.listener_port }}{% else %}{{ listener_port }}{% endif %}"

# Note: The following has both Role & User variables defined. Make use of either one stack & comment the other. In this example, "Users" stack is commented to grant privileges to a role named "ansirole".

oracle_databases:
#      - users:
#         - schema: dbuser1          # CDB Schema user to be granter privileges.
#        default_tablespace: users       # Schema's default tablespace.
#        db_password_cdb: oracle         # Sys user password.
#        service_name: ansible.pbm.ihost.com          # Service name of the CDB.
#        grants_mode: enforce            # enforce|append
#        grants:
#         - connect                      # Role/Grants to be assigned to the schema.
#         - resource
#        container: all
#        state: absent                   # present - added to the user|absent - removed from the user| REMOVEALL will remove ALL role/sys privileges.
      - roles:
         - role: ansirole                 # role name
        grants_mode: enforce            # enforce|append
        grants:
         - connect                      # Role/Grants to be assigned to the schema.
         - resource
        oracle_db_name: ansipdb4.pbm.ihost.com         # Service name of the PDB.
        db_password_cdb: oracle         # Sys user password.
        state: present                   # present - adds privileges to the role|absent - removes grants from the role| REMOVEALL will remove ALL role/sys privileges.

oracle_pdbs:
      - users:
         - schema: DBuser1            # PDB Schema user to be granter privileges.
        service_name: ansipdb4.pbm.ihost.com         # Service name of the PDB.
        db_password_pdb: oracle         # Sys user password.
        grants_mode: enforce
        grants:
         - dba                          # Role/Grants to be assigned to the schema.
        state: present                  # present|absent.
      - role: ansirole2                # role name

# Executing the playbook: This playbook executes a role.
# Change directory to ansible-power-aix-oracle-dba
# Name of the Playbook: manage-grants.yml
# Contents of playbook:

- hosts: localhost
  connection: local
  pre_tasks:
   - name: include variables
     include_vars:
       dir: vars
       extensions:
         - 'yml'
  roles:
     - { role: ibm.power_aix_oracle_dba.oradb_manage_grants }

# Sample Output:
# =============

[ansible@x134vm232 ansible-power-aix-oracle-dba]$ ansible-playbook manage-grants.yml

PLAY [localhost] **********************************************************************************************************************

TASK [Gathering Facts] ****************************************************************************************************************
ok: [localhost]

TASK [oradb_manage_grants : Manage role grants (cdb)] *********************************************************************************
changed: [localhost] => (item=port: 1521, service: ansipdb4.pbm.ihost.com, role: none, grants: ['connect', 'resource'], state: present)

TASK [oradb_manage_grants : Manage role grants (pdb)] *********************************************************************************

TASK [oradb_manage_grants : Manage schema grants (cdb)] *******************************************************************************

TASK [oradb_manage_grants : Manage schema grants (pdb)] *******************************************************************************
changed: [localhost] => (item=port: 1521, service: ansipdb4.pbm.ihost.com, schema: DBuser1, grants: ['dba'], state: present)

PLAY RECAP ****************************************************************************************************************************
localhost                  : ok=2    changed=2    unreachable=0    failed=0    skipped=2    rescued=0    ignored=0
