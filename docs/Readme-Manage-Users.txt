# Manage Users - Readme
# =====================

# Description: This module is used to create, drop, lock, unlock & expire user accounts. For privileges refer "grants" readme of our ansible collection.
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

# Open the file ansible-power-aix-oracle-dba/roles/oradb_manage_users/defaults/main.yml and modify the variables. Modify only the ones which are marked with comments.

db_user: sys
db_password_cdb: oracle         # CDB Password (SYS)
db_password_pdb: oracle         # PDB Admin Password.
db_mode: sysdba
db_service_name: "{% if item.0 is defined %}
                    {%- if item.0.oracle_db_unique_name is defined %}{{ item.0.oracle_db_unique_name }}
                    {%- elif item.0.oracle_db_instance_name is defined %}{{ item.0.oracle_db_instance_name }}
                    {%- else %}{{ item.0.oracle_db_name }}
                    {%- endif %}
                  {%- endif %}"

listener_port_template: "{% if item.0.listener_port is defined %}{{ item.0.listener_port }}{% else %}{{ listener_port }}{% endif %}"

oracle_databases:
      - users:
          - schema: DBUser1                           	# Username to be created in the database.
        default_tablespace: users                       # Default tablespace to be assigned to the created user.
        service_name: ansipdb4.pbm.ihost.com            # Database service name
        user_pdb_password: oracle1
        state: present                                  # present|absent.
      - users:                                         	# Multiple users can be created with different attributes as shown below.
         - schema: DBUser2
        default_tablespace: users
        service_name: db19cpdb.pbm.ihost.com
        user_pdb_password: oracle2
        state: present

# Executing the playbook: This playbook executes a role.
# Change directory to ansible-power-aix-oracle-dba/playbooks
# Name of the Playbook: manage-users.yml
# Contents of playbook:

- hosts: localhost
  connection: local
  pre_tasks:
     - name: include variables
       include_vars: vault.yml
  roles:
     - { role: ibm.power_aix_oracle_dba.oradb_manage_users }

# ansible-playbook manage-users.yml --ask-vault-pass

# Sample output:
# =============

[ansible@x134vm232 ansible-power-aix-oracle-dba]$ ansible-playbook manage-users.yml --ask-vault-pass
Vault password:

PLAY [localhost] **********************************************************************************************************************

TASK [Gathering Facts] ****************************************************************************************************************
ok: [localhost]

TASK [oradb_manage_users : Manage users (pdb)] ****************************************************************************************
changed: [localhost] => (item=port: 1521 service: ansipdb4.pbm.ihost.com schema: DBUser1 state:present)
changed: [localhost] => (item=port: 1521 service: db19cpdb.pbm.ihost.com schema: DBUser2 state:present)
[WARNING]: Module did not set no_log for update_password

PLAY RECAP ****************************************************************************************************************************
localhost                  : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

