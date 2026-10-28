# Create Database

## Description

This playbook creates an Oracle Container Database (CDB) or Non-CDB on IBM AIX using Oracle Database Configuration Assistant (`dbca`). It supports Single Instance (SI) on both Filesystem (FS) and ASM storage as well as RAC databases.

The playbook connects to the target AIX LPAR via SSH as the `oracle` OS user and runs `dbca -createDatabase` using a generated response file.

> **Note:** This playbook uses DBCA over SSH — it does **not** use `python-oracledb` or require the Oracle Instant Client on the control node.
> SSH passwordless authentication must be established between the Ansible control node and the target LPAR for the `oracle` user.

---

## Files to Update

| File | Purpose |
|------|---------|
| `playbooks/vars/create-db-vars.yml` | OS user, Oracle base, datafile paths, database definition |
| `playbooks/vars/vault.yml` | SYS/SYSTEM/PDBADMIN passwords — **encrypt with ansible-vault** |

---

## Step 1 — Update `create-db-vars.yml`

> **Loop mechanics** (`with_together` over `oracle_databases` + `checkdbexist.results`):
> - `item.0` → database definition dict
> - `item.1` → oratab check result (skip if database already exists)

```yaml
# Create Database - Variables section
oracle_user: oracle             # OS user that owns the Oracle installation.
oracle_group: oinstall          # Primary OS group for oracle_user.
oracle_stage: /tmp/podba_ansible  # Path on the target AIX LPAR to stage response files.
oracle_base: /stage/app         # Oracle base directory.
oracle_dbf_dir_fs: /stage/oradata   # Datafile destination for FS storage (used when storage_type: FS)
oracle_dbf_dir_asm: '+DATA'         # ASM diskgroup name for datafiles (used when storage_type: ASM)

# Set create_listener: true ONLY for standalone SI without Grid Infrastructure.
create_listener: false

oracle_databases:
- home: db                          # Last segment of ORACLE_HOME path
  oracle_version_db: 19c            # Oracle version
  oracle_home: /stage/db            # Full Oracle Home path
  oracle_db_name: proddb            # Database name
  oracle_db_type: SI                # SI | RAC | RACONENODE
  is_container: true                # true = CDB, false = non-CDB
  pdb_prefix: prodpdb               # PDB name prefix
  num_pdbs: 1                       # Number of PDBs to create
  storage_type: FS                  # ASM | FS
  redolog_size_in_mb: 50            # Redo log size in MB
  state: present                    # present | absent
  # Explicitly set pga_aggregate_target to prevent DBCA auto-calculating a negative value
  # when sga_max_size exceeds the memoryPercentage-based allocation.
  oracle_init_params: "sga_max_size=20g,sga_target=20g,pga_aggregate_target=4g"
```

> **Memory note:** Always set `pga_aggregate_target` explicitly when using `sga_max_size`.
> DBCA calculates PGA as `(RAM × memoryPercentage%) − sga_max_size`. If SGA exceeds the
> percentage-allocated total, DBCA writes a negative `pga_aggregate_target` and the instance
> fails to start with `ORA-01078`.

---

## Step 2 — Update `vault.yml`

```yaml
default_dbpass: Oracle4u    # SYS / SYSTEM / PDBADMIN password set on the new database.
default_gipass: Oracle4u    # ASM SYS password (required for ASM storage).
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
# playbooks/create-db.yml
- name: Create a Database
  hosts: pilotdb                    # Target LPAR hostname defined in the inventory
  remote_user: oracle               # Oracle OS user that owns the Oracle installation
  gather_facts: false
  vars_files:
   - vars/vault.yml                 # SYS/GI passwords — load first
   - vars/create-db-vars.yml
  roles:
     - { role: oradb_create }
```

---

## Step 5 — Execute the Playbook

```bash
ansible-playbook -i playbooks/inventory.yml playbooks/create-db.yml --ask-vault-pass
```

### Verified Execution Output (SI / FS / Oracle Restart)

```
PLAY [Create a Database] *******************************************************

TASK [oradb_create : Set create_listener fact] *********************************
ok: [pilotdb] => (item={...oracle_db_name: proddb...})

TASK [oradb_create : Create stage directory for response files] ****************
ok: [pilotdb]

TASK [oradb_create : Configure listener] ***************************************
skipping: [pilotdb]

TASK [oradb_create : Check if database already exists in /etc/oratab] **********
ok: [pilotdb] => (item={...oracle_db_name: proddb...})

TASK [oradb_create : Copy custom dbca templates to ORACLE_HOME] ****************
skipping: [pilotdb]

TASK [oradb_create : Create dbca response file] ********************************
changed: [pilotdb]

TASK [oradb_create : Create database(s) via dbca] ******************************
changed: [pilotdb]

TASK [oradb_create : Show dbca output] *****************************************
ok: [pilotdb] => {
    "item": [
        "[WARNING] [DBT-06208] The 'SYS' password entered does not conform to the Oracle recommended standards.",
        "Prepare for db operation",
        "7% complete",
        "Registering database with Oracle Restart",
        "11% complete",
        "Copying database files",
        "33% complete",
        "Creating and starting Oracle instance",
        "35% complete",
        "38% complete",
        "42% complete",
        "45% complete",
        "48% complete",
        "Completing Database Creation",
        "53% complete",
        "55% complete",
        "56% complete",
        "Creating Pluggable Databases",
        "60% complete",
        "78% complete",
        "Executing Post Configuration Actions",
        "100% complete",
        "Database creation complete. For details check the logfiles at:",
        " /stage/app/cfgtoollogs/dbca/proddb.",
        "Database Information:",
        "Global Database Name:proddb",
        "System Identifier(SID):proddb",
        "Look at the log file \"/stage/app/cfgtoollogs/dbca/proddb/proddb6.log\" for further details."
    ]
}

TASK [oradb_create : Add dotprofile for each database] *************************
changed: [pilotdb]

TASK [oradb_create : Check if database is running (pmon)] **********************
ok: [pilotdb]

PLAY RECAP *********************************************************************
pilotdb                    : ok=9    changed=3    unreachable=0    failed=0    skipped=3    rescued=0    ignored=0
```

---

## Step 6 — Verification

Verify the database is running and registered with Oracle Restart:

```bash
# Check pmon process
ps -ef | grep ora_pmon_proddb | grep -v grep

# Check Oracle Restart registration
/u01/19c/grid/home/bin/srvctl status database -d proddb

# Connect as SYSDBA and verify PDB
sqlplus / as sysdba
SQL> show pdbs
SQL> select name, open_mode from v$database;
```

---

## Variables Reference

| Variable | File | Description |
|----------|------|-------------|
| `oracle_user` | `create-db-vars.yml` | OS user that owns the Oracle installation |
| `oracle_group` | `create-db-vars.yml` | Primary OS group for `oracle_user` |
| `oracle_stage` | `create-db-vars.yml` | Path to stage DBCA response files on the target LPAR |
| `oracle_base` | `create-db-vars.yml` | Oracle base directory |
| `oracle_dbf_dir_fs` | `create-db-vars.yml` | Datafile path for `storage_type: FS` |
| `oracle_dbf_dir_asm` | `create-db-vars.yml` | ASM diskgroup for `storage_type: ASM` (e.g. `+DATA`) |
| `create_listener` | `create-db-vars.yml` | `false` for GI/ASM environments; `true` for standalone SI without GI |
| `home` | `oracle_databases` item | Last path segment of `ORACLE_HOME` |
| `oracle_version_db` | `oracle_databases` item | `19c`, `12.2.0.1`, etc. — selects the response file template |
| `oracle_home` | `oracle_databases` item | Full Oracle Home path on the LPAR |
| `oracle_db_name` | `oracle_databases` item | Database name / SID |
| `oracle_db_type` | `oracle_databases` item | `SI` \| `RAC` \| `RACONENODE` |
| `is_container` | `oracle_databases` item | `true` = CDB, `false` = non-CDB |
| `pdb_prefix` | `oracle_databases` item | PDB name (used when `is_container: true`) |
| `num_pdbs` | `oracle_databases` item | Number of PDBs to create |
| `storage_type` | `oracle_databases` item | `FS` \| `ASM` (ASM mandatory for RAC) |
| `redolog_size_in_mb` | `oracle_databases` item | Redo log size in MB |
| `oracle_init_params` | `oracle_databases` item | Comma-separated init parameters passed to `dbca -initParams` |
| `state` | `oracle_databases` item | `present` = create the database |
| `default_dbpass` | `vault.yml` | Password set for SYS, SYSTEM, and PDBADMIN |
| `default_gipass` | `vault.yml` | ASM SYS password |
| `libpath_freeware` | `defaults/main.yml` | Path prepended to `LIBPATH` for `libexpat.a` (default: `/opt/freeware/lib`) |

---

To execute this playbook from a GUI, refer to: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
