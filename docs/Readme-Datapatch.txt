# Datapatch - Readme
# ==================

# Description: # This module is used to run datapatch on a given database.

# Prerequisites:
# ==============
# Passwordless ssh needs to be setup between the Target lpar oracle owner and ansible controller user.
# Set the Variables for Oracle to execute this task: Open the file power-aix-oracle-dba/roles/oradb_datapatch/defaults/main.yml and modify the variables which are provided with comments on the right.

hostgroup: "{{ group_names[0] }}"
oracle_user: "{{ remote_user_id }}"

db_user: sys
db_service_name: ansible                        # Service name of the database

listener_port_template: "{% if item.listener_port is defined %}{{ item.listener_port }}{% else %}{{ listener_port }}{% endif %}"
listener_port: 1521                             # Database Listener port.

listener_home: "{%- if lsnrinst is defined -%}
                  {%- if db_homes_config[lsnrinst.home]['oracle_home'] is defined -%}{{db_homes_config[lsnrinst.home]['oracle_home']}}
                  {%- else -%}{{oracle_base}}/{{db_homes_config[lsnrinst.home]['version']}}/{{db_homes_config[lsnrinst.home]['home']}}
                  {%- endif -%}
                {%- endif -%}"
oracle_db_name: ansible                         # Name of the database to run Datapatch.
oracle_db_home: /u01/19.3.0.0/19c_ansible       # Oracle Home location of the above database.
oracle_env:
      ORACLE_SID: "{{ oracle_db_name }}"
      ORACLE_HOME: "{{ oracle_db_home}}"
      PATH: "{{ oracle_db_home}}/bin:$PATH:/usr/local/bin:/bin:/sbin:/usr/bin:/usr/sbin"

oracle_env_lsnrctl:
      ORACLE_BASE: "{{ oracle_base }}"
      ORACLE_HOME: "{{ listener_home }}"
      LD_LIBRARY_PATH: "{{ listener_home }}/lib"
      PATH: "{{ listener_home}}/bin:$PATH:/usr/local/bin:/bin:/sbin:/usr/bin:/usr/sbin"

autostartup_service: false
fail_on_db_not_exist: False

# Executing the playbook: This playbook executes a role. Before running the playbook, open the playbook and update the hostname & remote user details as shown below. Do NOT change other parts of the script.
# Change directory to power-aix-oracle-dba
# Name of the Playbook: datapatch.yml
# Content of the playbook

- name: Datapatch
  gather_facts: yes
  hosts: ansible_db     # AIX lpar hostname, make sure it's set in the inventory.
  remote_user: oracle   # AIX lpar Oracle home user.
  roles:
     - {role: oradb_datapatch }
