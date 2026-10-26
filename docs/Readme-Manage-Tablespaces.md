# Manage Tablespaces

## Description

This module is used to manage tablespaces in Oracle databases (Standalone and RAC environments) using the `oracle_tablespace` module.

It supports:
- **Creating** permanent, temporary, or undo tablespaces (smallfile or bigfile)
- **Dropping** tablespaces (including contents and datafiles)
- **Managing tablespace state** (`read_only`, `read_write`, `offline`, `online`)
- **Autoextend configuration** (`next`, `maxsize`)
- **Storage targets** on Oracle ASM (e.g., `+DATA`) or filesystem paths

> **Migration note:** This collection has been migrated from `cx_Oracle` to `python-oracledb` (thin mode).
> Thin mode is pure Python — no Oracle Instant Client is required on the control node.
> All database connections are made over TCP from `localhost` directly to the database listener.
> The `oracle_db_home` variable is no longer needed.

---

## Files to Update

| File | Purpose |
|------|---------|
| `playbooks/vars/manage-tablespaces-vars.yml` | DB hostname, port, service name, and tablespace definitions |
| `playbooks/vars/vault.yml` | SYS password (SYSDBA connect) — **encrypt with ansible-vault** |

---

## Step 1 — Update `manage-tablespaces-vars.yml`

> **Loop mechanics** (`with_subelements` over `tablespaces`):
> - `item.0` → outer dict: `service_name`
> - `item.1` → tablespace entry: `name`, `datafile`, `size`, `autoextend`, `next`, `maxsize`, `content`, `bigfile`, `state`

```yaml
# Manage Database Tablespaces - Variables section
hostname: ansible-db                        # AIX Lpar hostname where the database is running.
listener_port: 1521                         # Database port number.
# oracle_db_home not needed - oracle_tablespace module uses Thin mode (pure Python, no Oracle client required)

oracle_databases:
- service_name: prodpdb                     # PDB / CDB service name
  tablespaces:
  - name: demotbs                           # Tablespace name
    datafile: "/d01/19c/oradata/PROD/demo01.dbf"  # ASM diskgroup or filesystem path (e.g. '+DATA' or '/d01/.../demo01.dbf')
    size: 100M                              # Initial datafile size (e.g. 100M, 1G)
    autoextend: true                        # Enable autoextend: true | false
    next: 50M                               # Next extent allocation size
    maxsize: 2G                             # Maximum datafile size
    content: permanent                      # permanent | temp | undo
    bigfile: false                          # true | false
    state: present                          # present | absent | read_only | read_write | offline | online
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

When running against an encrypted vault, supply `--ask-vault-pass`:

```bash
ansible-playbook -i inventory.yml manage-tablespaces.yml --ask-vault-pass
```

---

## Step 4 — Review the Playbook

```yaml
# playbooks/manage-tablespaces.yml
- name: Manage DB Tablespaces
  hosts: localhost
  gather_facts: false
  vars_files:
    - vars/vault.yml
    - vars/manage-tablespaces-vars.yml
  roles:
    - { role: oradb_manage_tablespace }
```

---

## Step 5 — Execute the Playbook

```bash
ansible-playbook -i playbooks/inventory.yml playbooks/manage-tablespaces.yml --ask-vault-pass
```

```text
PLAY [Manage DB Tablespaces] **********************************************************************************************************

TASK [oradb_manage_tablespace : Manage tablespaces] ***********************************************************************************
changed: [localhost] => (item=port: 1521 service: prodpdb tablespace: demotbs content: permanent state: present)

PLAY RECAP ****************************************************************************************************************************
localhost                  : ok=1    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

---

## Step 6 — Verification (SQL)

Connect to the database / PDB and verify the tablespace and datafile:

```sql
SELECT tablespace_name, status, contents, bigfile FROM dba_tablespaces WHERE tablespace_name = 'DEMOTBS';
```

```
TABLESPACE_NAME                STATUS    CONTENTS  BIG
------------------------------ --------- --------- ---
DEMOTBS                        ONLINE    PERMANENT NO
```

```sql
SELECT tablespace_name, file_name, bytes/1024/1024 "SIZE_MB", autoextensible, maxbytes/1024/1024 "MAX_MB"
FROM dba_data_files WHERE tablespace_name = 'DEMOTBS';
```

---

## Variables Reference

| Variable | File | Description |
|----------|------|-------------|
| `hostname` | `manage-tablespaces-vars.yml` | AIX hostname of the database server (TCP endpoint) |
| `listener_port` | `manage-tablespaces-vars.yml` | Database listener port (default: 1521) |
| `service_name` | `manage-tablespaces-vars.yml` | PDB / CDB service name to connect to |
| `name` | `manage-tablespaces-vars.yml` | Tablespace name |
| `datafile` | `manage-tablespaces-vars.yml` | ASM diskgroup (e.g. `+DATA`) or filesystem datafile path |
| `numfiles` | `manage-tablespaces-vars.yml` | Number of datafiles (when OMF `db_create_file_dest` is enabled; mutually exclusive with `datafile`) |
| `size` | `manage-tablespaces-vars.yml` | Initial size of the datafile (e.g. `100M`, `1G`) |
| `content` | `manage-tablespaces-vars.yml` | Tablespace type: `permanent` \| `temp` \| `undo` (default: `permanent`) |
| `bigfile` | `manage-tablespaces-vars.yml` | `true` \| `false` (default: `false`) |
| `autoextend` | `manage-tablespaces-vars.yml` | Enable autoextend: `true` \| `false` (default: `false`) |
| `next` | `manage-tablespaces-vars.yml` | Next extent allocation size (e.g. `50M`, `100M`) |
| `maxsize` | `manage-tablespaces-vars.yml` | Maximum datafile size (e.g. `2G`, `unlimited`) |
| `state` | `manage-tablespaces-vars.yml` | `present` \| `absent` \| `read_only` \| `read_write` \| `offline` \| `online` (default: `present`) |
| `default_dbpass` | `vault.yml` | SYS password used to connect as SYSDBA |

---

To execute this playbook from a GUI, refer to: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
