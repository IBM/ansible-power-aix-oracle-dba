# Manage Tablespaces - Readme
# ===========================
# Description: This module is used to manage tablespaces in Standalone & RAC environments. It uses a python library located here: ansible-power-aix-oracle-dba/library/oracle_tablespaces. 
# It can create, drop, put in read only/read write, offline/online.
# More information on managing tablespaces: https://docs.oracle.com/cd/A57673_01/DOC/server/doc/SCN73/ch4.htm

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

# Set the Variables for Oracle to execute this task: Open the file ansible-power-aix-oracle-dba/roles/oradb_manage_tablespace/defaults/main.yml and modify the variables. Modify only the ones which are marked with comments.

oracle_base: /u01/app/oracle	# Oracle base location
hostname: ansible_db            # AIX hostname
db_user: sys
db_mode: sysdba
db_password_cdb: "{% if dbpasswords is defined and dbpasswords[item.0.oracle_db_name] is defined and dbpasswords[item.0.oracle_db_name][db_user] is defined%}{{dbpasswords[item.0.oracle_db_name][db_user]}}{% else %}{{ default_dbpass}}{% endif%}"
db_password_pdb: "{% if dbpasswords is defined and dbpasswords[item.0.cdb] is defined and dbpasswords[item.0.cdb][db_user] is defined%}{{dbpasswords[item.0.cdb][db_user]}}{% else %}{{ default_dbpass}}{% endif%}"

db_service_name: "{% if item.0 is defined %}
                    {%- if item.0.oracle_db_unique_name is defined %}{{ item.0.oracle_db_unique_name }}
                    {%- elif item.0.oracle_db_instance_name is defined %}{{ item.0.oracle_db_instance_name }}
                    {%- else %}{{ item.0.oracle_db_name }}
                    {%- endif %}
                  {%- endif %}"
default_dbpass: oracle  	# Sys user password.
oracle_env:
     ORACLE_HOME: /home/ansible/oracle_client           # Oracle Client Home on Ansible Controller.
     LD_LIBRARY_PATH: /home/ansible/oracle_client/lib   # Oracle Client Home Library on Ansible Controller.

oracle_databases:			
      - tablespaces:
          - name: testtbs2       	# Tablespace name for creation.
            datafile: +DATA      	# Diskgroup name in which tablespace needs to be created.
            # datafile: /u01/app/oracle/oradata/testtbs2.dbf		# Specify datafile path & name in case of non ASM.
            size: 1g            	# Desired size of the datafile.
            maxsize: 2g         	# Desired maxsize for the datafile.
            state: present      	# Set "present" to create / "absent" to drop tablespace.
            autoextend: true    	# Whether to extend the datafile size automatically or not. True or False.
            next: 100m          	# Set this only if autoextend parameter is set to True, otherwise comment this parameter.
        oracle_db_name: ansidb		# Container database Service Name

listener_port_template: "{% if item.0.listener_port is defined %}{{ item.0.listener_port }}{% else %}{{ listener_port }}{% endif %}"
listener_port: 1521			# Database listener port number.

# Executing the playbook: This playbook executes a role.
# Name of the Playbook: manage-tablespaces.yml
# Change directory to ansible-power-aix-oracle-dba/playbooks
# ansible-playbook manage-tablespaces.yml --ask-vault-pass
# The following task will be executed which will call out a role.

- hosts: localhost
  connection: local
  roles:
     - { role: ibm.power_aix_oracle_dba.oradb_manage_tablespace }

# Sample Output
# =============

[ansible@x134vm232 ansible-power-aix-oracle-dba]$ ansible-playbook tablespace.yml --ask-vault-pass
Vault password:

PLAY [localhost] **********************************************************************************************************************

TASK [Gathering Facts] ****************************************************************************************************************
ok: [localhost]

TASK [oradb_manage_tablespace : Manage tablespaces] ***********************************************************************************
changed: [localhost] => (item=port: 1521 service: ansible.pbm.ihost.com tablespace: testtbs2 content: __omit_place_holder__b8805138655ad69cd93d525b85dbbab4986eb7b7 state: present)
[WARNING]: Both option datafile and its alias datafile are set.

PLAY RECAP ****************************************************************************************************************************
localhost                  : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
