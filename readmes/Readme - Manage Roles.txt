# Manage Roles - Readme
# =====================

# Description: This module is used to create or drop roles. 
# It uses a python library: ansible_oracle_aix/library/oracle_users

# Prerequisites:
# ==============
# Passwordless ssh needs to be setup between the Target lpar oracle owner and ansible controller user.

# Set the Variables for Oracle to execute this task: Open the file ansible_oracle_aix/roles/oradb-manage-roles/defaults/main.yml and modify the variables. Modify only the ones which are marked with comments.

db_user: sys
db_mode: sysdba

db_service_name: "{% if item.0 is defined %}
                    {%- if item.0.oracle_db_unique_name is defined %}{{ item.0.oracle_db_unique_name }}
                    {%- elif item.0.oracle_db_instance_name is defined %}{{ item.0.oracle_db_instance_name }}
                    {%- else %}{{ item.0.oracle_db_name }}
                    {%- endif %}
                  {%- endif %}"

listener_port_template: "{% if item.0.listener_port is defined %}{{ item.0.listener_port }}{% else %}{{ listener_port }}{% endif %}"
listener_port: 1521             # Database listener port number.
hostname: ansible_db            # AIX hostname/SCAN Name in case of RAC.

oracle_home_db: /home/ansible/oracle_client     # Oracle 19c Client Home location on Ansible controller.

oracle_env:
       ORACLE_HOME: "{{ oracle_home_db }}"
       LD_LIBRARY_PATH: "{{ oracle_home_db }}/lib"
oracle_databases:
      - roles:
          - name: ansirole                              # Name of the role to be created in CDB.
        oracle_db_name: ANSIPDB4.pbm.ihost.com          # CDB service name.
        db_password_cdb: oracle                         # Sys user password.
        grants:
          - create session                              # Privileges assigned to the role.
          - create public synonym                       # Privileges assigned to the role.
        container: all
        state: absent                                   # present|absent

oracle_pdbs:
      - roles:
          - name: ansirole                              # Name of the role to be created in PDB
        service_name: ansipdb4.pbm.ihost.com            # PDB service name.
        db_password_pdb: oracle                         # Sys user password.
        grants:
          - create session                              # Privilege 1 assigned to the role.
          - create any table                            # Privilege 2 assigned to the role.
          - create any view
        state: absent                                   # present|absent

# Executing the playbook: This playbook executes a role.
# Change directory to ansible_oracle_aix
# Name of the Playbook: manage-roles.yml
# Contents of playbook:

- hosts: localhost
  connection: local
  roles:
     - { role: oradb-manage-roles }

# ansible-playbook manage-roles.yml

# Sample output:
# =============

[ansible@x134vm232 ansible_oracle_aix]$ ansible-playbook manage-roles.yml

PLAY [localhost] **********************************************************************************************************************

TASK [Gathering Facts] ****************************************************************************************************************
ok: [localhost]

TASK [oradb-manage-roles : Manage roles (cdb)] ****************************************************************************************
ok: [localhost] => (item=port: 1521, service: ANSIPDB4.pbm.ihost.com, role: ansirole, state: present)

TASK [oradb-manage-roles : Manage roles (pdb)] ****************************************************************************************
ok: [localhost] => (item=port: 1521, service: ansipdb4.pbm.ihost.com, role: ansirole, state: present)

TASK [oradb-manage-roles : Manage roles (cdb)] ****************************************************************************************
skipping: [localhost] => (item=port: 1521, service: ANSIPDB4.pbm.ihost.com, role: ansirole, state: present)

TASK [oradb-manage-roles : Manage roles (pdb)] ****************************************************************************************
skipping: [localhost] => (item=port: 1521, service: ansipdb4.pbm.ihost.com, role: ansirole, state: present)

PLAY RECAP ****************************************************************************************************************************
localhost                  : ok=3    changed=0    unreachable=0    failed=0    skipped=2    rescued=0    ignored=0
