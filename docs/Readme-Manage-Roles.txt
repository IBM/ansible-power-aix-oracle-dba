# Manage Roles - Readme
# =====================

# Description: This module is used to create or drop roles. To add privileges to the roles please refer 
# It uses a python library: ansible-power-aix-oracle-dba/library/oracle_users

# Prerequisites:
# ==============

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

# Open the file ansible-power-aix-oracle-dba/roles/oradb_manage_roles/defaults/main.yml and modify the variables. Modify only the ones which are marked with comments.

db_user: sys
db_mode: sysdba

db_service_name: "{% if item.0 is defined %}
                    {%- if item.0.oracle_db_unique_name is defined %}{{ item.0.oracle_db_unique_name }}
                    {%- elif item.0.oracle_db_instance_name is defined %}{{ item.0.oracle_db_instance_name }}
                    {%- else %}{{ item.0.oracle_db_name }}
                    {%- endif %}
                  {%- endif %}"

listener_port_template: "{% if item.0.listener_port is defined %}{{ item.0.listener_port }}{% else %}{{ listener_port }}{% endif %}"

oracle_databases:
      - roles:
          - name: ansirole                              # Name of the role to be created in CDB.
        oracle_db_name: ANSIPDB4.pbm.ihost.com          # CDB service name.
        db_password_cdb: oracle                         # Sys user password.
        container: all
        state: absent                                   # present|absent

oracle_pdbs:
      - roles:
          - name: ansirole                              # Name of the role to be created in PDB
        service_name: ansipdb4.pbm.ihost.com            # PDB service name.
        db_password_pdb: oracle                         # Sys user password.
        state: absent                                   # present|absent

# Executing the playbook: This playbook executes a role.
# Change directory to ansible-power-aix-oracle-dba/playbooks
# Name of the Playbook: manage-roles.yml
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
     - { role: oradb_manage_roles }

# ansible-playbook manage-roles.yml --ask-vault-pass

# Sample output:
# =============

[ansible@x134vm232 ansible-power-aix-oracle-dba]$ ansible-playbook manage-roles.yml --ask-vault-pass
Vault password:

PLAY [localhost] **********************************************************************************************************************

TASK [Gathering Facts] ****************************************************************************************************************
ok: [localhost]

TASK [oradb_manage_roles : Manage roles (cdb)] ****************************************************************************************
ok: [localhost] => (item=port: 1521, service: ANSIPDB4.pbm.ihost.com, role: ansirole, state: present)

TASK [oradb_manage_roles : Manage roles (pdb)] ****************************************************************************************
ok: [localhost] => (item=port: 1521, service: ansipdb4.pbm.ihost.com, role: ansirole, state: present)

TASK [oradb_manage_roles : Manage roles (cdb)] ****************************************************************************************
skipping: [localhost] => (item=port: 1521, service: ANSIPDB4.pbm.ihost.com, role: ansirole, state: present)

TASK [oradb_manage_roles : Manage roles (pdb)] ****************************************************************************************
skipping: [localhost] => (item=port: 1521, service: ansipdb4.pbm.ihost.com, role: ansirole, state: present)

PLAY RECAP ****************************************************************************************************************************
localhost                  : ok=3    changed=0    unreachable=0    failed=0    skipped=2    rescued=0    ignored=0
