# Manage Grants

## Description

This module is used to **grant or revoke privileges** to/from database schemas.
It supports system/role privileges, object-level privileges, and directory privileges.

- **`oradb_manage_grants`** — applies or revokes grants using the `oracle_grants` module.

> **Migration note:** This collection has been migrated from `cx_Oracle` to `python-oracledb` (thin mode).
> Thin mode is pure Python — no Oracle Instant Client is required on the control node.
> All database connections are made over TCP from `localhost` directly to the database host.
> The `oracle_db_home` variable is no longer needed.

---

## Files to Update

| File | Purpose |
|------|---------|
| `playbooks/vars/manage-grants-vars.yml` | DB hostname, port, service name, user list, per-user grants |
| `playbooks/vars/vault.yml` | SYS password (SYSDBA connect) — **encrypt with ansible-vault** |

---

## Step 1 — Update `manage-grants-vars.yml`

> **Loop mechanics** (`with_subelements` over `users`):
> - `item.0` → outer dict: `service_name`, `state`, `grants_mode`
> - `item.1` → user entry: `schema`, `grants`, `object_privs`, `directory_privs`

```yaml
# Grant/Revoke Database User Privileges - Variables section
hostname: ansible-db                        # AIX Lpar hostname where the database is running.
listener_port: 1521                         # Database port number.
# oracle_db_home not needed - oracle_grants module uses Thin mode (pure Python, no Oracle client required)

oracle_databases:
- service_name: prodpdb
  state: present                          # present | absent (revoke all listed grants)
  grants_mode: enforce                    # enforce | append
  users:
  - schema: pbatch
    grants:
    - connect
    - resource
    - create database link
    - create procedure

  - schema: pwrite
    grants:
    - connect
    - resource
    - create table
    - create sequence

  - schema: pselect
    grants:
    - connect
    - select any table
    - select any dictionary
```

**Notes:**
- `grants_mode: enforce` — exactly matches the listed privileges; any unlisted grants are **revoked**.
- `grants_mode: append` — only adds the listed grants; existing privileges are not touched.
- `state: absent` — revokes all listed grants from the schema.
- Each user carries its own `grants` list for full per-schema control.
- `object_privs` and `directory_privs` are also supported (see examples below).

### Additional grant types (uncomment as needed)

```yaml
  # Object-level privileges:
  - schema: pselect
    grants:
    - connect
    object_privs:
    - "select on hr.employees"
    - "select on hr.departments"

  # Directory privileges:
  - schema: pbatch
    grants:
    - connect
    - resource
    directory_privs:
    - "read on directory DATA_PUMP_DIR"
    - "write on directory DATA_PUMP_DIR"
```

---

## Step 2 — Update `vault.yml`

```yaml
default_dbpass: Oracle4u             # SYS password — used to CONNECT to the DB as SYSDBA.
default_gipass: Oracle4u             # ASM sys user password.
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

When running against an encrypted vault, add `--ask-vault-pass`:

```bash
ansible-playbook manage-grants.yml --ask-vault-pass
```

---

## Step 4 — Review the Playbook

```yaml
# playbooks/manage-grants.yml
- name: Manage DB user/role grants
  hosts: localhost                  # Runs on the Ansible control node (thin mode — no SSH to AIX)
  gather_facts: false
  vars_files:
   - vars/vault.yml
   - vars/manage-grants-vars.yml
  roles:
     - { role: oradb_manage_grants }
```

---

## Step 5 — Execute the Playbook

```bash
ansible-playbook manage-grants.yml
```

```text
PLAY [Manage DB user/role grants] *****************************************************************************************************

TASK [oradb_manage_grants : Manage role grants] ***************************************************************************************
skipping: [localhost]

TASK [oradb_manage_grants : Manage schema grants] *************************************************************************************
changed: [localhost] => (item=port: 1521, service: prodpdb, schema: pbatch, grants: ['connect', 'resource', 'create database link', 'create procedure'], state: present)
changed: [localhost] => (item=port: 1521, service: prodpdb, schema: pwrite, grants: ['connect', 'resource', 'create table', 'create sequence'], state: present)
changed: [localhost] => (item=port: 1521, service: prodpdb, schema: pselect, grants: ['connect', 'select any table', 'select any dictionary'], state: present)

PLAY RECAP ****************************************************************************************************************************
localhost                  : ok=1    changed=1    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0
```

**Output notes:**
- `Manage role grants` is **skipped** — no role-based grants are defined in the vars file.
- `Manage schema grants` runs **once per user**, applying each user's individual grants list.
- `ok=1 changed=1` — the grants task completed successfully with changes applied.

---

## Step 6 — Verify Grants in the Database

```sql
SELECT grantee, privilege, admin_option
FROM dba_sys_privs
WHERE grantee IN ('PBATCH','PWRITE','PSELECT')
ORDER BY grantee, privilege;
```

---

## Variables Reference

| Variable | File | Description |
|----------|------|-------------|
| `hostname` | `manage-grants-vars.yml` | AIX hostname of the database server (TCP endpoint) |
| `listener_port` | `manage-grants-vars.yml` | Database listener port (default: 1521) |
| `service_name` | `manage-grants-vars.yml` | PDB service name to connect to |
| `state` | `manage-grants-vars.yml` | `present` (grant) \| `absent` (revoke) |
| `grants_mode` | `manage-grants-vars.yml` | `enforce` (exact match) \| `append` (additive) |
| `schema` | `manage-grants-vars.yml` | Target schema to grant/revoke privileges on |
| `grants` | `manage-grants-vars.yml` | Per-user list of system/role privileges |
| `object_privs` | `manage-grants-vars.yml` | Per-user list of object-level privileges |
| `directory_privs` | `manage-grants-vars.yml` | Per-user list of directory privileges |
| `default_dbpass` | `vault.yml` | SYS password used to connect as SYSDBA |

---

To execute this playbook from a GUI, refer to: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
