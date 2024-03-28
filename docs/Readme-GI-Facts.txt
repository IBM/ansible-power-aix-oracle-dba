# Gather Grid Facts - Readme
# ==========================

# Description: # This module is used to gather facts about Grid infrastructure [Standalone or RAC].
# It gives information about local listener, scan, scan listener, clustername, databases registered in the cluster etc.

# Prerequisites:
# ==============
# Passwordless ssh needs to be setup between the Target lpar oracle owner and ansible controller user.

In the following example we're going to retrieve facts about GI Cluster.

1. Create the playbook from {{ collection_dir }}/power_aix_oracle_dba/playbooks  directory as shown below

- hosts: all                          # AIX Lpar where Grid Services are running.
  remote_user: oracle
  vars:
   oracle_env:
      ORACLE_HOME: /ora/grid          # Grid Home Path on the above AIX Lpar.
  roles:
     - { role: oradb_gather_gifacts }

2. Execute the playbook as shown below
ansible-playbook gather-gi-facts.yml -i inventory.yml

PLAY [rac21] **************************************************************************************************************************

TASK [Gathering Facts] ****************************************************************************************************************
ok: [rac21]

TASK [oradb_gather_gifacts : Return GI facts] *****************************************************************************************
ok: [rac21]

TASK [oradb_gather_gifacts : debug] ***************************************************************************************************
ok: [rac21] => {
    "gifacts": {
        "ansible_facts": {
            "clustername": "rac21-cluster",
            "database_list": [
                ""
            ],
            "local_listener": [],
            "network": [
                {
                    "ipv4": "192.168.64.0/255.255.252.0/en1, static",
                    "ipv6": "",
                    "network": "1"
                }
            ],
            "scan": [
                {
                    "fqdn": "rac21-scn",
                    "ipv4": [
                        "192.168.64.25",
                        "192.168.64.26",
                        "192.168.64.27"
                    ],
                    "ipv6": [],
                    "name": "rac21-scn",
                    "network": "1"
                }
            ],
            "scan_listener": [
                {
                    "endpoints": "TCP:1521",
                    "ipv4": [
                        "192.168.64.25",
                        "192.168.64.26",
                        "192.168.64.27"
                    ],
                    "ipv6": [],
                    "network": "1",
                    "scan_address": "rac21-scn",
                    "tcp": "1521"
                }
            ],
            "version": "19.0.0.0.0",
            "vip": []
        },
        "changed": false,
        "failed": false,
        "msg": ""
    }
}

PLAY RECAP ****************************************************************************************************************************
rac21                      : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

To execute this playbook from GUI, an example is provided in the document, please refer this link: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
