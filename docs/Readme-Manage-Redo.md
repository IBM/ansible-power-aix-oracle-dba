# Manage Redo Logs

## Description

This module is used to manage online redo log groups and redo log file sizes in Oracle databases (Standalone and RAC environments) using the `oracle_redo` module.

It supports:
- **Resizing redo logs** — replaces existing redo log files with new ones of the specified size across all threads.
- **Adjusting redo log group count** — automatically adds or drops online redo log groups to match the target group count.
- **RAC & Single Instance awareness** — handles thread switching and global checkpoints accordingly.

> **Migration note:** This collection has been migrated from `cx_Oracle` to `python-oracledb` (thin mode).
> Thin mode is pure Python — no Oracle Instant Client is required on the control node.
> All database connections are made over TCP from `localhost` directly to the database listener.
> Redo log management operates at the **CDB / Instance level** using SYSDBA privilege.
> The `oracle_db_home` variable is no longer needed.

---

## Files to Update

| File | Purpose |
|------|---------|
| `playbooks/vars/manage-redo-vars.yml` | DB hostname, listener port, service name, target redo groups and size |
| `playbooks/vars/vault.yml` | SYS password (SYSDBA connect) — **encrypt with ansible-vault** |

---

## Step 1 — Update `manage-redo-vars.yml`

> **Loop mechanics** (`loop` over `oracle_databases`):
> - `item` → dict: `service_name`, `redolog_groups`, `redolog_size`, `state`

```yaml
# Manage Redo Logs - Variables section
hostname: ansible-db                        # AIX Lpar hostname where the database is running.
listener_port: 1521                         # Database port number.
# oracle_db_home not needed - oracle_redo module uses Thin mode (pure Python, no Oracle client required)

oracle_databases:
- service_name: prod                        # CDB / Standalone DB service name
  redolog_groups: 8                         # Total number of redo log groups per thread
  redolog_size: 200M                        # Target redo log file size (suffix: M, G, or T)
  # datafile: "/d01/19c/oradata/PROD"       # Optional: directory or ASM diskgroup (+DATA). Auto-discovered from v$logfile if omitted.
  state: present                            # present
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
ansible-playbook -i inventory.yml manage-redo.yml --ask-vault-pass
```

---

## Step 4 — Review the Playbook

```yaml
# playbooks/manage-redo.yml
- name: Manage DB Redo Logs
  hosts: localhost
  gather_facts: false
  vars_files:
    - vars/vault.yml
    - vars/manage-redo-vars.yml
  roles:
    - { role: oradb_manage_redo }
```

---

## Step 5 — Execute the Playbook

```bash
ansible-playbook -i playbooks/inventory.yml playbooks/manage-redo.yml --ask-vault-pass
```

```text
PLAY [Manage DB Redo Logs] ************************************************************************************************************

TASK [oradb_manage_redo : Manage redologs] ********************************************************************************************
changed: [localhost] => (item=port: 1521 service: prod groups: 8 size: 200M)

PLAY RECAP ****************************************************************************************************************************
localhost                  : ok=1    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

---

## Step 6 — Verification (SQL)

Connect to the container database as SYSDBA and verify redo log groups and sizes:

```sql
SELECT group#, thread#, sequence#, bytes/1024/1024 "SIZE_MB", members, status FROM v$log ORDER BY thread#, group#;
```

```sql
SELECT group#, member, type, is_recovery_dest_file FROM v$logfile ORDER BY group#;
```

```
    GROUP# MEMBER                                             TYPE
---------- -------------------------------------------------- -------
         1 /d01/19c/oradata/PROD/redo01.log                   ONLINE
         2 /d01/19c/oradata/PROD/redo02.log                   ONLINE
         3 /d01/19c/oradata/PROD/redo03.log                   ONLINE
         4 /d01/19c/oradata/PROD/stdbyredo01.log              STANDBY
         5 /d01/19c/oradata/PROD/stdbyredo02.log              STANDBY
         6 /d01/19c/oradata/PROD/stdbyredo03.log              STANDBY
         7 /d01/19c/oradata/PROD/stdbyredo04.log              STANDBY
         8 /d01/19c/oradata/PROD/redo08.log                   ONLINE
         9 /d01/19c/oradata/PROD/redo09.log                   ONLINE
        10 /d01/19c/oradata/PROD/redo10.log                   ONLINE
        11 /d01/19c/oradata/PROD/redo11.log                   ONLINE
        12 /d01/19c/oradata/PROD/redo12.log                   ONLINE
```

---

## Variables Reference

| Variable | File | Description |
|----------|------|-------------|
| `hostname` | `manage-redo-vars.yml` | AIX hostname of the database server (TCP endpoint) |
| `listener_port` | `manage-redo-vars.yml` | Database listener port (default: 1521) |
| `service_name` | `manage-redo-vars.yml` | CDB / database service name to connect to as SYSDBA |
| `redolog_groups` | `manage-redo-vars.yml` | Total number of redo log groups per thread |
| `redolog_size` | `manage-redo-vars.yml` | Desired redo log size (must include suffix `M`, `G`, or `T`, e.g. `150M`, `1G`) |
| `datafile` | `manage-redo-vars.yml` | *(Optional)* Target directory or ASM diskgroup (`+DATA`). Auto-discovered if omitted. |
| `state` | `manage-redo-vars.yml` | `present` |
| `default_dbpass` | `vault.yml` | SYS password used to connect as SYSDBA |

---

To execute this playbook from a GUI, refer to: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
