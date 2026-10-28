# Manage Users

## Description

This module is used to **create, drop, lock, unlock & expire** Oracle database user accounts.
For privileges, refer to the [Grants readme](Readme-Manage-Grants.md) of this collection.

- **`oradb_manage_users`** — creates, drops, locks, unlocks and sets expiration on schemas using the `oracle_user` module.
- **`oradb_manage_grants`** — assigns privileges to those schemas using the `oracle_grants` module.

> **Migration note:** This collection has been migrated from `cx_Oracle` to `python-oracledb` (thin mode).
> Thin mode is pure Python — no Oracle Instant Client is required on the control node.
> All database connections are made over TCP from `localhost` directly to the database host.
> The `oracle_db_home` variable is no longer needed.

---

## Files to Update

| File | Purpose |
|------|---------|
| `playbooks/vars/manage-users-vars.yml` | DB hostname, port, service name, user list, per-user grants |
| `playbooks/vars/vault.yml` | SYS password (SYSDBA connect) and per-schema passwords — **encrypt with ansible-vault** |

---

## Step 1 — Update `manage-users-vars.yml`

> **Loop mechanics** (`with_subelements` over `users`):
> - `item.0` → outer dict: `service_name`, `state`, `grants_mode`
> - `item.1` → user entry: `schema`, `schema_password`, `default_tablespace`, `grants`

```yaml
# Create/Drop Database Users - Variables section
hostname: host242                           # AIX Lpar hostname where the database is running.
listener_port: 1521                         # Database port number.
# oracle_db_home not needed - oracle_user module uses Thin mode (pure Python, no Oracle client required)

oracle_databases:

  - service_name: prodpdb
    state: present                          # present | absent | locked | unlocked
    grants_mode: enforce                    # enforce | append
    users:
      - schema: pbatch
        schema_password: "{{ schema_passwords['pbatch'] }}"
        default_tablespace: users
        grants:
          - connect
          - resource

      - schema: pwrite
        schema_password: "{{ schema_passwords['pwrite'] }}"
        default_tablespace: users
        grants:
          - connect
          - resource

      - schema: pselect
        schema_password: "{{ schema_passwords['pselect'] }}"
        default_tablespace: users
        grants:
          - connect
```

**Notes:**
- Each user carries its own `grants` list — different privileges can be assigned per schema.
- To add more users, append entries under `users:` with no other changes required.
- To target a different PDB or host, update `service_name` and `hostname` accordingly.

---

## Step 2 — Update `vault.yml`

Keep the SYS connection password (`default_dbpass`) separate from the per-schema passwords (`schema_passwords`).

```yaml
default_dbpass: Oracle4u             # SYS password — used to CONNECT to the DB as SYSDBA.
default_gipass: Oracle4u             # ASM sys user password.

# Per-schema passwords — keep this vault encrypted in production.
schema_passwords:
  pbatch:  "Pbatch#Pass1"
  pwrite:  "Pwrite#Pass1"
  pselect: "Pselect#Pass1"
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

When running the playbook against an encrypted vault, add `--ask-vault-pass`:

```bash
ansible-playbook manage-users.yml --ask-vault-pass
```

---

## Step 4 — Verify Schemas Do Not Already Exist

```sql
SHOW PDBS;
```

```
    CON_ID CON_NAME                       OPEN MODE  RESTRICTED
---------- ------------------------------ ---------- ----------
         3 PRODPDB                        READ WRITE NO
```

```sql
SELECT username FROM dba_users WHERE username IN ('PBATCH','PWRITE','PSELECT');
```

```
no rows selected
```

---

## Step 5 — Review the Playbook

```yaml
# playbooks/manage-users.yml
- name: Create DB User
  hosts: localhost                  # Runs on the Ansible control node (thin mode — no SSH to AIX)
  remote_user: oracle
  gather_facts: false
  vars_files:
   - vars/vault.yml
   - vars/manage-users-vars.yml
  roles:
     - { role: oradb_manage_users }
     - { role: oradb_manage_grants }
```

> `hosts: localhost` — the `oracle_user` and `oracle_grants` modules run on the control node and
> connect to the database over TCP using `python-oracledb` thin mode. No SSH connection to the AIX host is made.

---

## Step 6 — Execute the Playbook

```bash
ansible-playbook manage-users.yml
```

```text
PLAY [Create DB User] *****************************************************************************************************************

TASK [oradb_manage_users : Manage users (cdb/pdb)] ************************************************************************************
changed: [localhost] => (item=port: 1521 service: prodpdb schema: pbatch state:present)
changed: [localhost] => (item=port: 1521 service: prodpdb schema: pwrite state:present)
changed: [localhost] => (item=port: 1521 service: prodpdb schema: pselect state:present)
[WARNING]: Module did not set no_log for update_password

TASK [oradb_manage_grants : Manage role grants] ***************************************************************************************
skipping: [localhost]

TASK [oradb_manage_grants : Manage schema grants] *************************************************************************************
changed: [localhost] => (item=port: 1521, service: prodpdb, schema: pbatch, grants: ['connect', 'resource'], state: present)
changed: [localhost] => (item=port: 1521, service: prodpdb, schema: pwrite, grants: ['connect', 'resource'], state: present)
changed: [localhost] => (item=port: 1521, service: prodpdb, schema: pselect, grants: ['connect'], state: present)

PLAY RECAP ****************************************************************************************************************************
localhost                  : ok=2    changed=2    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0
```

**Output notes:**
- `Manage role grants` is **skipped** — no role-based grants are defined in the vars file.
- `Manage schema grants` runs **once per user**, applying each user's individual grants list.
- `ok=2 changed=2` — both tasks (create users + apply grants) completed successfully with changes.
- The `[WARNING]` about `update_password` is informational only and does not affect execution.

---

## Step 7 — Verify Schemas Were Created

```sql
SHOW PDBS;
```

```
    CON_ID CON_NAME                       OPEN MODE  RESTRICTED
---------- ------------------------------ ---------- ----------
         3 PRODPDB                        READ WRITE NO
```

```sql
SELECT username FROM dba_users WHERE username IN ('PBATCH','PWRITE','PSELECT');
```

```
USERNAME
--------------------
PBATCH
PWRITE
PSELECT
```

---

## Variables Reference

| Variable | File | Description |
|----------|------|-------------|
| `hostname` | `manage-users-vars.yml` | AIX hostname of the database server (TCP endpoint) |
| `listener_port` | `manage-users-vars.yml` | Database listener port (default: 1521) |
| `service_name` | `manage-users-vars.yml` | PDB service name to connect to |
| `state` | `manage-users-vars.yml` | `present` \| `absent` \| `locked` \| `unlocked` |
| `grants_mode` | `manage-users-vars.yml` | `enforce` (exact match) \| `append` (additive) |
| `schema` | `manage-users-vars.yml` | Schema/username to create |
| `schema_password` | `manage-users-vars.yml` | References `schema_passwords[schema]` from vault |
| `default_tablespace` | `manage-users-vars.yml` | Default tablespace assigned to the schema |
| `grants` | `manage-users-vars.yml` | Per-user list of privileges to grant |
| `default_dbpass` | `vault.yml` | SYS password used to connect as SYSDBA |
| `schema_passwords` | `vault.yml` | Dict of per-schema passwords keyed by schema name |

---

To execute this playbook from a GUI, refer to: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
