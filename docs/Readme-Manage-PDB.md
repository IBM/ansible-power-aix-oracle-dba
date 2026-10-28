# Manage Pluggable Databases

## Description

This module is used to **create, clone, drop, plug and unplug** Oracle Pluggable Databases (PDBs).

- **`oradb_manage_pdb`** — manages PDB lifecycle using the `oracle_pdb` module.

> **Migration note:** This collection has been migrated from `cx_Oracle` to `python-oracledb` (thin mode).
> Thin mode is pure Python — no Oracle Instant Client is required on the control node.
> The `oracle_db_home` variable is no longer needed.

> **Important:** Only **one** operation flag may be set to `true` at a time.
> Setting multiple flags simultaneously will fail fast with a clear validation error before any changes are made.

---

## Files to Update

| File | Purpose |
|------|---------|
| `playbooks/vars/manage-pdb-vars.yml` | DB hostname, port, CDB name, operation flag, PDB parameters |
| `playbooks/vars/vault.yml` | SYS password (SYSDBA connect) — **encrypt with ansible-vault** |

---

## Variables Overview

```yaml
# ── Operation flags — set exactly one to true ─────────────────────────────────
create_pdb: false       # true = create a fresh PDB from seed
plug_pdb: false         # true = plug a PDB from an existing XML file
clone_pdb: false        # true = clone an existing PDB (CREATE PLUGGABLE DATABASE <new> FROM <source>)
drop_pdb: false         # true = drop an existing PDB
unplug_pdb: false       # true = unplug a PDB to an XML file
```

### State values reference

| Operation | `state` value |
|-----------|--------------|
| Create PDB | `present` |
| Plug PDB from XML | `present` |
| Clone an existing PDB | `present` |
| Drop PDB | `absent` |
| Unplug PDB to XML | `unplugged` |

---

## Scenario 1 — Create a PDB from seed

Set `create_pdb: true`, all others `false`.

```yaml
create_pdb: true
plug_pdb: false
drop_pdb: false
unplug_pdb: false

create_oracle_pdbs:
- pdb_name: prodpdb1
  cdb: "{{ oracle_db_name }}"
  state: present
  datafile_dest: "{{ pdb_oradata_dest }}"
  file_name_convert: "{{ pdb_seed_dest }},{{ pdb_oradata_dest }}"
  xml_dest: "{{ xml_file_dest }}"
  xml_file: prodpdb1.xml
```

```text
TASK [oradb_manage_pdb : Validate — only one operation flag may be true at a time]
ok: [localhost] => { "msg": "Operation flag validation passed." }

TASK [oradb_manage_pdb : Create PDB from seed]
changed: [localhost] => (item=...pdb_name: prodpdb1, state: present...)
```

---

## Scenario 1b — Clone an existing PDB

Set `clone_pdb: true`, all others `false`. This runs
`CREATE PLUGGABLE DATABASE <pdb_name> FROM <source_pdb>` inside the CDB (the `FROM` clause is the
`source_pdb` option of the `oracle_pdb` module). No `ADMIN USER` clause is generated — the clone
inherits the users of the source PDB.

```yaml
create_pdb: false
plug_pdb: false
clone_pdb: true
drop_pdb: false
unplug_pdb: false

clone_oracle_pdbs:
- pdb_name: prodpdb1_clone
  source_pdb: prodpdb
  cdb: "{{ oracle_db_name }}"
  state: present
  datafile_dest: "{{ pdb_oradata_dest }}"      # CREATE_FILE_DEST. Alternative: file_name_convert: "<old path>,<new path>"
```

Notes:

- Use **either** `datafile_dest` **or** `file_name_convert` (mutually exclusive in the module).
- The clone is opened (`OPEN INSTANCES=ALL`) and its state saved (`save_state: true` by default).
- If a PDB named `pdb_name` already exists, nothing is cloned (idempotent).
- The source PDB must be in a state that allows cloning: open `READ ONLY`, or open `READ WRITE` when the CDB uses local undo
  (Oracle 18c+ hot clone). Otherwise Oracle returns `ORA-65081` / `ORA-65040`.
- Verify: `select name, open_mode from v$pdbs;`

Sample run:

```text
$ ansible-playbook manage-pdb.yml --ask-vault-pass
Vault password:

PLAY [Manage Pluggable Databases] *****************************************************************************************************

TASK [oradb_manage_pdb : Validate — only one operation flag may be true at a time] ****************************************************
ok: [localhost] => {
    "changed": false,
    "msg": "Operation flag validation passed."
}

TASK [oradb_manage_pdb : Configure PDB (create or plug)] ******************************************************************************
skipping: [localhost]

TASK [oradb_manage_pdb : Configure PDB (clone from an existing PDB)] ******************************************************************
included: /home/ansible/shiva/git/ansible-power-aix-oracle-dba/roles/oradb_manage_pdb/tasks/clone_pdb.yml for localhost

TASK [oradb_manage_pdb : Clone PDB from an existing PDB] ******************************************************************************
changed: [localhost] => (item=prodpdb -> prodpdb_clone)

TASK [oradb_manage_pdb : Configure PDB (drop or unplug)] ******************************************************************************
skipping: [localhost]

PLAY RECAP ****************************************************************************************************************************
localhost                  : ok=3    changed=1    unreachable=0    failed=0    skipped=2    rescued=0    ignored=0
```

---

## Scenario 2 — Unplug a PDB to an XML file

Set `unplug_pdb: true`, all others `false`.

```yaml
create_pdb: false
plug_pdb: false
drop_pdb: false
unplug_pdb: true

drop_oracle_pdbs:
- pdb_name: PRODPDB1
  cdb: "{{ oracle_db_name }}"
  state: unplugged
  datafile_dest: "{{ pdb_oradata_dest }}"
  xml_dest: /tmp
  xml_file: prodpdb1.xml
```

```text
TASK [oradb_manage_pdb : Validate — only one operation flag may be true at a time]
ok: [localhost] => { "msg": "Operation flag validation passed." }

TASK [oradb_manage_pdb : Remove existing XML manifest before unplug (prevents ORA-65170)]
ok: [localhost] => (item=...xml_file: prodpdb1.xml...)

TASK [oradb_manage_pdb : Unplug PDB to XML file]
changed: [localhost] => (item=...pdb_name: PRODPDB1, state: unplugged...)
```

> **Note:** The XML cleanup task runs automatically before each unplug to prevent `ORA-65170: XML file already exists` on repeated runs.

---

## Scenario 3 — Plug a PDB from an XML file

Set `plug_pdb: true`, all others `false`.

```yaml
create_pdb: false
plug_pdb: true
drop_pdb: false
unplug_pdb: false

create_oracle_pdbs:
- pdb_name: prodpdb2
  cdb: "{{ oracle_db_name }}"
  state: present
  datafile_dest: "{{ pdb_oradata_dest }}"
  file_name_convert: "{{ pdb_seed_dest }},{{ pdb_oradata_dest }}"
  xml_dest: /tmp
  xml_file: prodpdb1.xml
```

```text
TASK [oradb_manage_pdb : Validate — only one operation flag may be true at a time]
ok: [localhost] => { "msg": "Operation flag validation passed." }

TASK [oradb_manage_pdb : Create PDB from seed]
skipping: [localhost]

TASK [oradb_manage_pdb : Plug PDB from XML file]
changed: [localhost] => (item=...pdb_name: prodpdb2, state: present...)
```

---

## Scenario 4 — Drop a PDB

Set `drop_pdb: true`, all others `false`.

```yaml
create_pdb: false
plug_pdb: false
drop_pdb: true
unplug_pdb: false

drop_oracle_pdbs:
- pdb_name: PRODPDB2
  cdb: "{{ oracle_db_name }}"
  state: absent
  datafile_dest: "{{ pdb_oradata_dest }}"
  xml_dest: /tmp
  xml_file: prodpdb1.xml
```

```text
TASK [oradb_manage_pdb : Validate — only one operation flag may be true at a time]
ok: [localhost] => { "msg": "Operation flag validation passed." }

TASK [oradb_manage_pdb : Drop PDB]
changed: [localhost] => (item=...pdb_name: PRODPDB2, state: absent...)
```

---

## What happens if two flags are set to true

The playbook fails immediately before touching anything:

```text
TASK [oradb_manage_pdb : Validate — only one operation flag may be true at a time]
fatal: [localhost]: FAILED! => {
    "msg": "ERROR: More than one operation flag is set to true.
            Only one of create_pdb, plug_pdb, clone_pdb, drop_pdb, unplug_pdb may be true at a time.
            Current values — create_pdb: true, plug_pdb: false, clone_pdb: false, drop_pdb: false, unplug_pdb: true"
}
```

---

## Full vars file reference

```yaml
# Manage Pluggable Databases - Variables section
hostname: ansible-db                  # AIX hostname where the database is running.
listener_port: 1521                   # Database listener port.
oracle_db_name: prod                  # CDB service name (the container database).
# oracle_db_home not needed - oracle_pdb module uses Thin mode (pure Python, no Oracle client required)

# ── Operation flags — set exactly one to true ─────────────────────────────────
create_pdb: false       # true = create a fresh PDB from seed
plug_pdb: false         # true = plug a PDB from an existing XML file
clone_pdb: false        # true = clone an existing PDB
drop_pdb: false         # true = drop an existing PDB
unplug_pdb: false       # true = unplug a PDB to an XML file

# ── Storage ───────────────────────────────────────────────────────────────────
pdb_oradata_dest: /d01/19c/oradata
pdb_seed_dest: /d01/19c/oradata/PROD/pdbseed
xml_file_dest: /tmp

# ── PDB Create / Plug variables ───────────────────────────────────────────────
create_oracle_pdbs:
- pdb_name: prodpdb1
  cdb: "{{ oracle_db_name }}"
  state: present
  datafile_dest: "{{ pdb_oradata_dest }}"
  file_name_convert: "{{ pdb_seed_dest }},{{ pdb_oradata_dest }}"
  xml_dest: "{{ xml_file_dest }}"
  xml_file: prodpdb1.xml

# ── PDB Clone variables ───────────────────────────────────────────────────────
clone_oracle_pdbs:
- pdb_name: prodpdb1_clone
  source_pdb: prodpdb
  cdb: "{{ oracle_db_name }}"
  state: present
  datafile_dest: "{{ pdb_oradata_dest }}"

# ── PDB Drop / Unplug variables ───────────────────────────────────────────────
drop_oracle_pdbs:
- pdb_name: PRODPDB1
  cdb: "{{ oracle_db_name }}"
  state: absent                       # absent = drop | unplugged = unplug to XML
  datafile_dest: "{{ pdb_oradata_dest }}"
  xml_dest: "{{ xml_file_dest }}"
  xml_file: prodpdb1.xml
```

---

## Variables Reference

| Variable | File | Description |
|----------|------|-------------|
| `hostname` | `manage-pdb-vars.yml` | AIX hostname of the database server (TCP endpoint) |
| `listener_port` | `manage-pdb-vars.yml` | Database listener port (default: 1521) |
| `oracle_db_name` | `manage-pdb-vars.yml` | CDB service name (the container database) |
| `create_pdb` | `manage-pdb-vars.yml` | `true` to create a PDB from seed |
| `plug_pdb` | `manage-pdb-vars.yml` | `true` to plug a PDB from XML |
| `clone_pdb` | `manage-pdb-vars.yml` | `true` to clone an existing PDB (`FROM` clause) |
| `drop_pdb` | `manage-pdb-vars.yml` | `true` to drop a PDB |
| `unplug_pdb` | `manage-pdb-vars.yml` | `true` to unplug a PDB to XML |
| `pdb_oradata_dest` | `manage-pdb-vars.yml` | Datafile destination (ASM diskgroup or FS path) |
| `pdb_seed_dest` | `manage-pdb-vars.yml` | PDB seed datafiles location |
| `xml_file_dest` | `manage-pdb-vars.yml` | Directory for XML manifest files |
| `default_dbpass` | `vault.yml` | SYS password used to connect as SYSDBA |

---

To execute this playbook from a GUI, refer to: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
