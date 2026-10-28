# Manage DB Directories

## Description

This module is used to manage Oracle database directory objects (`CREATE DIRECTORY` / `DROP DIRECTORY`) in Oracle databases using the `oracle_directory` module.

It supports:
- **Creating** an Oracle directory object and the underlying OS path on the target LPAR in a single operation.
- **Dropping** an Oracle directory object.

> **Migration note:** This collection has been migrated from `cx_Oracle` to `python-oracledb` (thin mode).
> Thin mode is pure Python — no Oracle Instant Client is required on the control node.
> All database connections are made over TCP from `localhost` directly to the database listener.
> The `oracle_db_home` variable is no longer needed.

---

## Files to Update

| File | Purpose |
|------|---------|
| `playbooks/vars/manage-directories-vars.yml` | DB hostname, service name, directory name, OS path, state |
| `playbooks/vars/vault.yml` | SYS password (SYSDBA connect) — **encrypt with ansible-vault** |

---

## Step 1 — Update `manage-directories-vars.yml`

```yaml
# Manage DB Directories - Variables section
hostname: ansible-db                        # AIX LPAR hostname where the database is running (TCP endpoint).
listener_port: 1521                         # Database listener port.
service_name: prodpdb                       # Database service name to connect to as SYSDBA.
# oracle_db_home not needed — oracle_directory module uses Thin mode (pure Python, no Oracle client required)

os_user: oracle                             # OS user used to create the path on the target LPAR via SSH.

directory_name: expdp                       # Oracle directory object name (case-insensitive, stored uppercase).
path: /d01/expdir                           # OS path on the AIX LPAR. Created automatically if state: present.
state: present                              # present = CREATE DIRECTORY | absent = DROP DIRECTORY
mode: enforce                               # enforce = error if path does not exist | skip = silently skip
```

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
# playbooks/manage-db-directories.yml
- name: Manage DB Directories
  hosts: localhost
  gather_facts: false
  vars_files:
   - vars/vault.yml
   - vars/manage-directories-vars.yml
  roles:
     - { role: oradb_manage_directories }
```

---

## Step 5 — Execute the Playbook

```bash
ansible-playbook -i playbooks/inventory.yml playbooks/manage-db-directories.yml --ask-vault-pass
```

### Verified Execution Output — Create Directory

```
PLAY [Manage DB Directories] **********************************************************************************************************

TASK [oradb_manage_directories : Create OS path on target LPAR (if state is present and path does not exist)] *************************
changed: [localhost -> ansible-db]

TASK [oradb_manage_directories : Manage directory (create or drop)] *******************************************************************
changed: [localhost]

TASK [oradb_manage_directories : Show directory result] *******************************************************************************
ok: [localhost] => {
    "msg": "Directory: expdp, created with path: /d01/expdir"
}

TASK [oradb_manage_directories : Verify directory in DBA_DIRECTORIES] *****************************************************************
ok: [localhost]

TASK [oradb_manage_directories : Show directory verification] *************************************************************************
ok: [localhost] => {
    "msg": [
        [
            "EXPDP",
            "/d01/expdir"
        ]
    ]
}

PLAY RECAP ****************************************************************************************************************************
localhost                  : ok=5    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### Drop Directory

To drop the directory, set `state: absent` in `manage-directories-vars.yml` and re-run. The OS path on the LPAR is **not** removed — only the Oracle directory object is dropped.

---

## Step 6 — SQL Verification

Connect to the database and verify directly:

```sql
-- Confirm directory was created
SELECT directory_name, directory_path
FROM dba_directories
WHERE directory_name = 'EXPDP';

-- After drop: should return no rows
SELECT COUNT(*) FROM dba_directories WHERE directory_name = 'EXPDP';
```

---

## Variables Reference

| Variable | File | Description |
|----------|------|-------------|
| `hostname` | `manage-directories-vars.yml` | AIX LPAR hostname (TCP endpoint for DB connection and SSH target for OS path) |
| `listener_port` | `manage-directories-vars.yml` | Database listener port (default: 1521) |
| `service_name` | `manage-directories-vars.yml` | Database service name to connect to as SYSDBA |
| `os_user` | `manage-directories-vars.yml` | OS user for SSH when creating the path on the LPAR (default: `oracle`) |
| `directory_name` | `manage-directories-vars.yml` | Oracle directory object name (stored uppercase in `dba_directories`) |
| `path` | `manage-directories-vars.yml` | OS filesystem path on the AIX LPAR the directory points to |
| `state` | `manage-directories-vars.yml` | `present` = CREATE DIRECTORY \| `absent` = DROP DIRECTORY |
| `mode` | `manage-directories-vars.yml` | `enforce` = fail if OS path missing \| `skip` = silently skip |
| `default_dbpass` | `vault.yml` | SYS password used to connect as SYSDBA |

---

To execute this playbook from a GUI, refer to: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
