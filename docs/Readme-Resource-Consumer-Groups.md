# Manage Resource Consumer Groups

## Description

This playbook creates, modifies or drops a Resource Manager consumer group in a database using the `oracle_rsrc_consgroup` module. It can also grant users switch privilege on the group and map sessions to it by Oracle user, service name or client machine. After applying the change, it reads `dba_rsrc_consumer_groups` and `dba_rsrc_group_mappings` with the `oracle_sql` module and displays what is now in effect.

More information on Resource Manager can be found here: https://docs.oracle.com/cd/E11882_01/server.112/e25494/dbrm.htm#ADMIN11842

In the example below, the consumer group `ANSIGROUP1` is created in the PDB `prodpdb`. It is used by the job class playbook ([`Readme-Manage-Job-Class.md`](Readme-Manage-Job-Class.md)).

> **Migration note:** This collection has been migrated from `cx_Oracle` to `python-oracledb` (thin mode).
> Thin mode is pure Python — no Oracle Instant Client is required on the control node.
> All database connections are made over TCP from `localhost` directly to the database listener.
> The `oracle_db_home` variable is no longer needed.

---

## Files to Update

| File | Purpose |
|------|---------|
| `playbooks/vars/manage-resource-group-vars.yml` | DB hostname, service name, consumer group, grants, mappings, state |
| `playbooks/vars/vault.yml` | SYS password (SYSDBA connect) — **encrypt with ansible-vault** |

---

## Step 1 — Update `manage-resource-group-vars.yml`

```yaml
# Manage Resource Consumer Group - Variables section
hostname: ansible-db                        # AIX LPAR hostname where the database is running (TCP endpoint).
listener_port: 1521                         # Database listener port.
service_name: prodpdb                       # Database service name to connect to as SYSDBA.
# oracle_db_home not needed — oracle_rsrc_consgroup module uses Thin mode (pure Python, no Oracle client required)

state: present                              # present = create/modify the consumer group | absent = drop it
consumer_group: ansigroup1                  # Consumer group name (stored uppercase).
comments: This is a test consumer resource group   # Optional comment.
grant:
- pselect                                   # Users/roles granted switch privilege on this group (must exist, others are ignored).
map_oracle_user:
- pselect                                   # Map sessions of this Oracle user to the group.
map_service_name:
- prodpdb                                   # Map sessions connecting through this service name to the group.
map_client_machine:
- x123vm456                                 # Map sessions from this client machine to the group.
```

> The role previously ignored `consumer_group` and `comments` and always created `ansigroup1`. Both variables are now used.

---

## Step 2 — Update `vault.yml`

```yaml
default_dbpass: Oracle4u    # SYS password used to connect as SYSDBA.
```

---

## Step 3 — Encrypt the Vault File

```bash
ansible-vault encrypt vars/vault.yml
```

```
New Vault password:
Confirm New Vault password:
Encryption successful
```

---

## Step 4 — Review the Playbook

```yaml
# playbooks/manage-resource-consumer-group.yml
- name: Manage Resource Consumer Group
  hosts: localhost
  gather_facts: false
  vars_files:
   - vars/vault.yml
   - vars/manage-resource-group-vars.yml
  roles:
     - { role: oradb_manage_rsrc }
```

---

## Step 5 — Execute the Playbook

```bash
ansible-playbook playbooks/manage-resource-consumer-group.yml --ask-vault-pass
```

### Verified Execution Output

```
PLAY [Manage Resource Consumer Group] ******************************************

TASK [oradb_manage_rsrc : Resource Consumer Groups] ****************************
changed: [localhost]

TASK [oradb_manage_rsrc : Show consumer group result] **************************
ok: [localhost] => {
    "msg": "Added grants: {'PSELECT'}, Added mappings: {'ORACLE_USER': {'PSELECT'}, 'SERVICE_NAME': {'PRODPDB'}, 'CLIENT_MACHINE': {'X123VM456'}}"
}

TASK [oradb_manage_rsrc : Verify consumer group in DBA_RSRC_CONSUMER_GROUPS and mappings] ***
ok: [localhost] => (item=select consumer_group, mgmt_method, comments from dba_rsrc_c)
ok: [localhost] => (item=select attribute, value from dba_rsrc_group_mappings where c)

TASK [oradb_manage_rsrc : Show consumer group [consumer_group, mgmt_method, comments]] ***
ok: [localhost] => {
    "msg": [
        [
            "ANSIGROUP1",
            "ROUND-ROBIN",
            "This is a test consumer resource group"
        ]
    ]
}

TASK [oradb_manage_rsrc : Show group mappings [attribute, value]] **************
ok: [localhost] => {
    "msg": [
        [
            "CLIENT_MACHINE",
            "X123VM456"
        ],
        [
            "ORACLE_USER",
            "PSELECT"
        ],
        [
            "SERVICE_NAME",
            "PRODPDB"
        ]
    ]
}

PLAY RECAP *********************************************************************
localhost                  : ok=5    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```


### Drop Consumer Group

To drop the group, set `state: absent` in `manage-resource-group-vars.yml` and re-run. Drop any job classes that reference the group first.

---

## Step 6 — SQL Verification

Connect to the database and verify directly:

```sql
SELECT consumer_group, mgmt_method, comments
FROM dba_rsrc_consumer_groups
WHERE consumer_group = 'ANSIGROUP1';

SELECT attribute, value
FROM dba_rsrc_group_mappings
WHERE consumer_group = 'ANSIGROUP1'
ORDER BY attribute, value;

SELECT grantee, granted_group
FROM dba_rsrc_consumer_group_privs
WHERE granted_group = 'ANSIGROUP1';
```

---

## Variables Reference

| Variable | File | Description |
|----------|------|-------------|
| `hostname` | `manage-resource-group-vars.yml` | AIX LPAR hostname (TCP endpoint for DB connection) |
| `listener_port` | `manage-resource-group-vars.yml` | Database listener port (default: 1521) |
| `service_name` | `manage-resource-group-vars.yml` | Database service name to connect to as SYSDBA |
| `state` | `manage-resource-group-vars.yml` | `present` = create/modify \| `absent` = drop |
| `consumer_group` | `manage-resource-group-vars.yml` | Consumer group name (stored uppercase) |
| `comments` | `manage-resource-group-vars.yml` | Comment about the group |
| `grant` | `manage-resource-group-vars.yml` | List of users/roles granted switch privilege. Names that do not exist are ignored |
| `map_oracle_user` | `manage-resource-group-vars.yml` | List of Oracle users whose sessions map to the group |
| `map_service_name` | `manage-resource-group-vars.yml` | List of service names whose sessions map to the group |
| `map_client_machine` | `manage-resource-group-vars.yml` | List of client machine names whose sessions map to the group |
| `default_dbpass` | `vault.yml` | SYS password used to connect as SYSDBA |
| `db_user` | role defaults | Connecting user (default: `sys`) |
| `db_mode` | role defaults | Connection mode (default: `sysdba`) |

---

To execute this playbook from a GUI, refer to: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
