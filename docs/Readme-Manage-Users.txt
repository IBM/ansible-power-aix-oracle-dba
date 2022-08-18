# Manage Users - Readme
# =====================

# Description: This module is used to create, drop, lock, unlock & expire user accounts. For privileges refer "grants" readme of our ansible collection.
# It uses a python library: ansible-power-aix-oracle-dba/library/oracle_users

# Prerequisites:
# ==============
# Passwordless ssh needs to be setup between the Target lpar oracle owner and ansible controller user.

# Go to the collection directory 
# Decrypt the file (if it's already encrypted)
# ansible-vault decrypt playbooks/vars/vars.yml
Vault password:
Decryption successful
# Set SYS password for "default_dbpass" variable in ansible-power-aix-oracle-dba/playbooks/vars/vars.yml.
# Encrypt the file
# ansible-vault encrypt playbooks/vars/vars.yml
New Vault password:
Confirm New Vault password:
Encryption successful

# Set the Variables for Oracle to execute this task: Open the file ansible-power-aix-oracle-dba/roles/oradb_manage_users/defaults/main.yml and modify the variables. Modify only the ones which are marked with comments.

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
listener_port: 1521             # Database listener port.
hostname: ansible_db		# Database hostname/SCAN name in case of RAC.

oracle_env:
  ORACLE_HOME: /home/ansible/oracle_client              # Oracle client path installed on Ansible controller.
  LD_LIBRARY_PATH: /home/ansible/oracle_client/lib      # Oracle client library path installed on Ansible controller.

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
       include_vars: vars.yml
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

