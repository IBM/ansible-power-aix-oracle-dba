# Delete Database

## Description

This playbook drops an Oracle Container Database (CDB) or Non-CDB (Standalone or RAC) on IBM AIX using Oracle Database Configuration Assistant (`dbca`).

The playbook connects to the target AIX LPAR via SSH as the `oracle` OS user and runs `dbca -deleteDatabase` silently. All database files and Oracle Restart registration are removed.

> **Note:** This playbook uses DBCA over SSH — it does **not** use `python-oracledb` or require the Oracle Instant Client on the control node.
> SSH passwordless authentication must be established between the Ansible control node and the target LPAR for the `oracle` user.

> **Warning:** This operation is irreversible. All datafiles, redo logs, and control files will be permanently deleted.

---

## Files to Update

| File | Purpose |
|------|---------|
| `playbooks/vars/delete-db-vars.yml` | Oracle Home path and database name to delete |
| `playbooks/vars/vault.yml` | SYS password used by DBCA (`default_dbpass`) — **encrypt with ansible-vault** |

---

## Step 1 — Update `delete-db-vars.yml`

> **Loop mechanics** (`with_items` over `oracle_databases`):
> - `item` → dict: `home`, `oracle_home`, `oracle_db_name`, `state`

```yaml
# Delete Database - Variables section
oracle_databases:                          # List of databases to delete
- home: db                             # Last segment of ORACLE_HOME path (e.g. /stage/db)
  oracle_home: /stage/db                  # Full Oracle Home path on the target LPAR
  oracle_db_name: proddb                  # Database name (DB_UNIQUE_NAME / SID)
  state: absent                           # absent = delete the database
```

---

## Step 2 — Update `vault.yml`

```yaml
default_dbpass: Oracle4u    # SYS password — passed to dbca -sysDBAPassword.
default_gipass: Oracle4u    # ASM SYS password.
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
# playbooks/delete-db.yml
- name: Drop a Database
  hosts: pilotdb                    # Target LPAR hostname defined in the inventory
  remote_user: oracle               # Oracle OS user that owns the Oracle installation
  gather_facts: false
  vars_files:
   - vars/vault.yml                 # SYS password — load first
   - vars/delete-db-vars.yml
  roles:
     - { role: oradb_delete }
```

---

## Step 5 — Execute the Playbook

```bash
ansible-playbook -i playbooks/inventory.yml playbooks/delete-db.yml --ask-vault-pass
```

### Verified Execution Output (SI / Oracle Restart)

```
PLAY [Drop a Database] ****************************************************************************************************************

TASK [oradb_delete : Delete database(s)] **********************************************************************************************
changed: [pilotdb]

TASK [oradb_delete : Collect DBCA output lines] ***************************************************************************************
ok: [pilotdb]

TASK [oradb_delete : Print DBCA output] ***********************************************************************************************
ok: [pilotdb] => {
    "msg": [
        "[WARNING] [DBT-19202] The Database Configuration Assistant will delete the Oracle instances and datafiles for your database. All information in the database will be destroyed.",
        "Prepare for db operation",
        "32% complete",
        "Connecting to database",
        "35% complete",
        "39% complete",
        "42% complete",
        "45% complete",
        "48% complete",
        "52% complete",
        "65% complete",
        "Updating network configuration files",
        "68% complete",
        "Deleting instance and datafiles",
        "84% complete",
        "100% complete",
        "Database deletion completed.",
        "Look at the log file \"/stage/app/cfgtoollogs/dbca/proddb/proddb7.log\" for further details."
    ]
}

PLAY RECAP ****************************************************************************************************************************
pilotdb                    : ok=3    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

---

## Step 6 — Verification

Confirm the database has been removed:

```bash
# Check pmon is gone
ps -ef | grep ora_pmon_proddb | grep -v grep

# Check Oracle Restart deregistration
$GRID_HOME/bin/srvctl status database -d proddb

# Check oratab
grep proddb /etc/oratab
```

Expected: no pmon process, `PRCR-1001: Resource ora.proddb.db does not exist`, no oratab entry.

---

## Variables Reference

| Variable | File | Description |
|----------|------|-------------|
| `home` | `delete-db-vars.yml` | Last segment of the ORACLE_HOME path (fallback if `oracle_home` is absent) |
| `oracle_home` | `delete-db-vars.yml` | Full Oracle Home path on the target LPAR (e.g. `/stage/db`) |
| `oracle_db_name` | `delete-db-vars.yml` | Database name / SID to delete |
| `state` | `delete-db-vars.yml` | Must be `absent` to trigger deletion |
| `default_dbpass` | `vault.yml` | SYS password passed to `dbca -sysDBAPassword` |

---

To execute this playbook from a GUI, refer to: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
