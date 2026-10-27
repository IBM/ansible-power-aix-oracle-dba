# Clone a Database with RMAN DUPLICATE

## Description

The **`podba_db_clone`** role creates a copy of an Oracle database with RMAN `DUPLICATE`. It runs on the
AIX LPAR that will host the **clone** (the *auxiliary* instance) as the Oracle software owner.

| `clone_method` | RMAN command | Needs |
|---|---|---|
| `active` | `DUPLICATE TARGET DATABASE TO <clone> FROM ACTIVE DATABASE` | Source database open and reachable over TCP |
| `backup` | `DUPLICATE DATABASE TO <clone> BACKUP LOCATION '<dir>'` | A backup in `backup_location` (see [`db-backup.yml`](Readme-DB-Backup.md)); no connection to the source |

To clone a **PDB inside a CDB**, use [`oradb_manage_pdb`](Readme-Manage-PDB.md) with `clone_pdb: true`.

For every clone the role:

1. validates the parameters,
2. skips the clone if an instance with that SID is already `OPEN` on the host,
3. writes a minimal auxiliary pfile (`$ORACLE_HOME/dbs/init<aux>.ora`) and starts the instance `NOMOUNT`
   (a leftover non-open instance with the same SID is shut down with `SHUTDOWN ABORT` first),
4. active only: creates the password file and a TNS alias (`<aux>_AUX`, with `UR=A`) in a private `TNS_ADMIN`,
5. generates the RMAN command file from `templates/rman_duplicate.rcv.j2` and runs it,
6. queries `v$database` and prints `name, db_unique_name, open_mode, dbid`,
7. always removes the RMAN command file (it contains the SYS password for the active method) and the private `TNS_ADMIN`.

> **Prerequisites**
> - Same Oracle software version at source and clone; the clone `ORACLE_HOME` must exist.
> - Active duplicate: the source must be open (and in `ARCHIVELOG` mode) and have a password file whose SYS password matches `default_dbpass`. The clone host must reach the source listener, and the source must reach the clone listener on `aux_listener_port`. An instance in `NOMOUNT` is not dynamically registered, so the clone listener needs a **static** `SID_DESC` entry for the clone SID. The role does not configure listeners.
> - Backup duplicate: the clone host must be able to read `backup_location`, which must contain the backups plus archived logs and control file backup.
> - The clone `db_name` must differ from the source if both are on the same host/ORACLE_HOME.
> - Not tested against a live Oracle database yet. Run once on a non-production host first.

---

## Files to Update

| File | Purpose |
|------|---------|
| `playbooks/db-clone.yml` | Clone host (`hosts:`) and `remote_user` |
| `playbooks/vars/db-clone-vars.yml` | Clones and options |
| `playbooks/vars/vault.yml` | `default_dbpass` — SYS password (active method) — **encrypt with ansible-vault** |

## Run

```bash
ansible-playbook playbooks/db-clone.yml
```

---

## Example 1 — Active duplicate

```yaml
db_clones:
- aux_db_name: clonedb
  oracle_db_home: /d01/19c/db19c
  clone_method: active
  source_host: ansible-db
  source_service: prod
  db_create_file_dest: /d01/19c/oradata
  db_create_online_log_dest_1: /d01/19c/oradata
  db_recovery_file_dest: /d01/19c/fra
  db_recovery_file_dest_size: 10G
  channels: 4
  nofilenamecheck: true
```

Generated RMAN script:

```text
CONNECT TARGET sys/***@//ansible-db:1521/prod;
CONNECT AUXILIARY sys/***@clonedb_AUX;
RUN {
  ALLOCATE AUXILIARY CHANNEL aux1 DEVICE TYPE DISK;
  ...
  DUPLICATE TARGET DATABASE TO clonedb
    FROM ACTIVE DATABASE
    SPFILE
      SET db_create_file_dest='/d01/19c/oradata'
      SET db_create_online_log_dest_1='/d01/19c/oradata'
      SET db_recovery_file_dest='/d01/19c/fra'
      SET db_recovery_file_dest_size='10G'
      SET db_unique_name='clonedb'
    NOFILENAMECHECK
  ;
  RELEASE CHANNEL aux1;
  ...
}
EXIT;
```

## Example 2 — Duplicate from backup

```yaml
db_clones:
- aux_db_name: clonedb
  oracle_db_home: /d01/19c/db19c
  clone_method: backup
  backup_location: /backup/prod
  source_dbid: 1234567890              # optional
  until_time: "2025-01-31 23:00:00"    # optional
  db_file_name_convert: [/d01/19c/oradata/PROD, /d02/19c/oradata/CLONEDB]
  log_file_name_convert: [/d01/19c/oradata/PROD, /d02/19c/oradata/CLONEDB]
  control_files: [/d02/19c/oradata/CLONEDB/control01.ctl]
```

Generated RMAN script:

```text
CONNECT AUXILIARY /;
RUN {
  ALLOCATE AUXILIARY CHANNEL aux1 DEVICE TYPE DISK;
  SET DBID 1234567890;
  DUPLICATE DATABASE TO clonedb
    BACKUP LOCATION '/backup/prod'
    SPFILE
      SET control_files='/d02/19c/oradata/CLONEDB/control01.ctl'
      SET db_file_name_convert='/d01/19c/oradata/PROD','/d02/19c/oradata/CLONEDB'
      SET log_file_name_convert='/d01/19c/oradata/PROD','/d02/19c/oradata/CLONEDB'
      SET db_unique_name='clonedb'
    UNTIL TIME "TO_DATE('2025-01-31 23:00:00','YYYY-MM-DD HH24:MI:SS')"
  ;
  RELEASE CHANNEL aux1;
}
EXIT;
```

---

## Variables reference

Per-clone keys (under `db_clones`):

| Key | Required | Description |
|---|---|---|
| `aux_db_name` | yes | `DB_NAME` / `ORACLE_SID` of the clone (max. 8 chars, letters/digits/`_`) |
| `oracle_db_home` | yes | `ORACLE_HOME` on the clone host |
| `clone_method` | no | `active` or `backup` (default `db_clone_method`) |
| `source_host`, `source_service` | active | TCP endpoint and service name of the source database |
| `source_port` | no | Source listener port (default `db_clone_source_port`) |
| `aux_host`, `aux_listener_port` | no | How the source reaches the clone (default: the inventory host / `db_clone_aux_listener_port`) |
| `backup_location` | backup | Directory holding the RMAN backups |
| `source_dbid`, `until_time` | no | Backup method only: `SET DBID`, `UNTIL TIME` |
| `db_create_file_dest` | one of these two | OMF destination for datafiles |
| `db_file_name_convert`, `log_file_name_convert` | one of these two | Lists of old/new path pairs |
| `control_files`, `db_create_online_log_dest_1`, `db_recovery_file_dest`, `db_recovery_file_dest_size` | no | `SPFILE ... SET` values |
| `db_unique_name` | no | Default `aux_db_name` |
| `pfile_params`, `spfile_set` | no | Extra parameters for the temporary pfile / the `SET` clause |
| `channels`, `nofilenamecheck`, `noopen`, `use_backupset`, `compressed` | no | Override the role defaults |

Role defaults (`db_clone_*`) are listed in `playbooks/vars/db-clone-vars.yml`.

## Verify

```sql
select name, db_unique_name, open_mode from v$database;
```
