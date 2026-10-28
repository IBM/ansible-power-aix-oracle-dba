# Manage Pluggable Databases

## Description

This module is used to **create, drop, plug and unplug** Oracle Pluggable Databases (PDBs).

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
drop_pdb: false         # true = drop an existing PDB
unplug_pdb: false       # true = unplug a PDB to an XML file
```

### State values reference

| Operation | `state` value |
|-----------|--------------|
| Create PDB | `present` |
| Plug PDB from XML | `present` |
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
            Only one of create_pdb, plug_pdb, drop_pdb, unplug_pdb may be true at a time.
            Current values — create_pdb: true, plug_pdb: false, drop_pdb: false, unplug_pdb: true"
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
| `drop_pdb` | `manage-pdb-vars.yml` | `true` to drop a PDB |
| `unplug_pdb` | `manage-pdb-vars.yml` | `true` to unplug a PDB to XML |
| `pdb_oradata_dest` | `manage-pdb-vars.yml` | Datafile destination (ASM diskgroup or FS path) |
| `pdb_seed_dest` | `manage-pdb-vars.yml` | PDB seed datafiles location |
| `xml_file_dest` | `manage-pdb-vars.yml` | Directory for XML manifest files |
| `default_dbpass` | `vault.yml` | SYS password used to connect as SYSDBA |

---

To execute this playbook from a GUI, refer to: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
