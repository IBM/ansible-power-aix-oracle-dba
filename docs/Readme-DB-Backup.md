# RMAN Database Backup

## Description

The **`podba_db_backup`** role takes RMAN backups of one or more Oracle databases on the AIX host.
It runs on the target LPAR as the Oracle software owner, using OS authentication (`rman target /`).
No database password is needed, and it does not use the `oracledb` modules.

> **Intended use: development and test databases. Not for production.**
> Both backup modes this role offers are meant for dev/test use. A **cold** backup shuts the database down for the
> whole backup. A **hot** backup can switch the database to ARCHIVELOG, which restarts it. The role does not
> manage production concerns such as backup scheduling, offsite copies, tape/cloud targets or PDB state.

Supported `backup_type` values:

| `backup_type` | RMAN command |
|---|---|
| `full` | `BACKUP DATABASE [PLUS ARCHIVELOG]` |
| `incremental_0` | `BACKUP INCREMENTAL LEVEL 0 DATABASE [PLUS ARCHIVELOG]` |
| `incremental_1` | `BACKUP INCREMENTAL LEVEL 1 DATABASE [PLUS ARCHIVELOG]` |
| `archivelog` | `BACKUP ARCHIVELOG ALL [DELETE INPUT]` |
| `cold` | `SHUTDOWN IMMEDIATE` → `STARTUP MOUNT` → `BACKUP DATABASE` → reopen. **Not for production use.** |

> **Cold backup is not for production use.** `backup_type: cold` shuts the database down for the whole backup, so
> every application connection is dropped and the database is unavailable until the backup finishes. Use it for
> test/development databases, or for a one-off consistent copy before a risky change. A cold backup works in
> NOARCHIVELOG mode and is restorable without archived logs. It is refused for RAC databases
> (`cluster_database=TRUE`).
>
> After the backup — also when RMAN fails — the role returns the instance to the state it found it in: an OPEN
> database is reopened, and a database that was down is shut down again.

### Pluggable databases after a restart — your responsibility

The role restarts the instance for a cold backup and when `enable_archivelog: true` switches the log mode. It
reopens the **CDB** only (`ALTER DATABASE OPEN`). A CDB open leaves the PDBs `MOUNTED` unless they have a saved
state (`ALTER PLUGGABLE DATABASE ... SAVE STATE`). **The role does not reopen PDBs or restore their open mode.**
Check them afterwards and open them yourself if needed:

```sql
select name, open_mode from v$pdbs;
alter pluggable database all open;     -- or open individual PDBs, READ WRITE / READ ONLY
```

This was seen on a test run: `PRODPDB` came back `MOUNTED` after the restart.

For `full` and `incremental_*` the current control file and SPFILE are also backed up.
If `retention_days` is set, `DELETE NOPROMPT OBSOLETE RECOVERY WINDOW OF <n> DAYS` runs afterwards.

For every database the role:

1. validates the parameters,
2. creates `backup_location` and the script directory,
3. hot backups: checks that the instance is `OPEN` and in `ARCHIVELOG` mode (see below),
   cold backups: shuts the database down and mounts it,
4. generates the RMAN command file from `templates/rman_backup.rcv.j2` and runs it,
5. optional (`validate_backup: true`): runs `RESTORE ... VALIDATE` (see below),
6. prints `LIST BACKUP SUMMARY`,
7. cold backups: puts the instance back in its original state.

## ARCHIVELOG mode (hot backups)

Hot backups need the database to be `OPEN` and in `ARCHIVELOG` mode.

| Situation | `enable_archivelog: false` (default) | `enable_archivelog: true` |
|---|---|---|
| Already `ARCHIVELOG` | backup runs | backup runs, **no restart** |
| `NOARCHIVELOG` | fails before touching anything, with a message | `SHUTDOWN IMMEDIATE`, `STARTUP MOUNT`, `ALTER DATABASE ARCHIVELOG`, `ALTER DATABASE OPEN`, then the backup |
| Instance not `OPEN` | fails (use `cold`) | fails (use `cold`) |

> Enabling ARCHIVELOG **restarts the database** (downtime), so it is off by default and must be requested
> explicitly. It is refused for RAC databases. Make sure the archive destination (the fast recovery area, see
> `db_recovery_file_dest_size`) has room: archived logs accumulate until they are backed up and deleted
> (`delete_input_archivelog` or `retention_days`). The role prints `ARCHIVE LOG LIST` after switching.

## Validating the backup (optional)

`validate_backup: true` runs, after the backup:

```text
RESTORE DATABASE VALIDATE;      -- for archivelog backups: RESTORE ARCHIVELOG ALL VALIDATE;
RESTORE CONTROLFILE VALIDATE;
RESTORE SPFILE VALIDATE;
```

RMAN reads every backup piece and checks it can be restored, but restores nothing. The play fails on any
`RMAN-` / `ORA-` error. It is **off by default** because it re-reads the whole backup: on a test backup of
about 2.7 GB it took roughly 4 minutes. `LIST BACKUP SUMMARY` alone only shows that the backups exist.

The backup is a point-in-time copy in `backup_location`. Use the same location as `backup_location` in
[`db-clone.yml`](Readme-DB-Clone.md) to create a clone from it.

> The role is **not idempotent by design**: each run takes a new backup and reports `changed`.

---

## Files to Update

| File | Purpose |
|------|---------|
| `playbooks/db-backup.yml` | Target host (`hosts:`) and `remote_user` |
| `playbooks/vars/db-backup-vars.yml` | Databases and backup options |

## Run

```bash
ansible-playbook playbooks/db-backup.yml
```

---

## Variables

```yaml
rman_backups:
- oracle_db_name: prod              # ORACLE_SID of the instance on the target host
  oracle_db_home: /d01/19c/dbhome    # ORACLE_HOME
  backup_location: /backup/prod     # Backup piece directory (created if missing)
  backup_type: full                 # full | incremental_0 | incremental_1 | archivelog | cold
  enable_archivelog: false          # true = enable ARCHIVELOG first if needed (restarts the database)
  channels: 4
  compressed: true
  include_archivelog: true
  delete_input_archivelog: false
  validate_backup: false            # true = RESTORE ... VALIDATE after the backup (slow)
  retention_days: 7                 # optional
  tag: PROD_FULL                    # optional, default ANSIBLE_<BACKUP_TYPE>
```

| Variable | Default | Description |
|---|---|---|
| `oracle_db_name` | — (required) | `ORACLE_SID` of the database |
| `oracle_db_home` | — (required) | `ORACLE_HOME` of the database |
| `backup_location` | — (required) | Directory for the backup pieces |
| `backup_type` / `rman_backup_type` | `full` | See table above (`cold` is not for production) |
| `enable_archivelog` / `rman_backup_enable_archivelog` | `false` | Switch `NOARCHIVELOG` → `ARCHIVELOG` before a hot backup (restarts the database) |
| `channels` / `rman_backup_channels` | `4` | Parallel disk channels |
| `compressed` / `rman_backup_compressed` | `true` | `AS COMPRESSED BACKUPSET` |
| `include_archivelog` / `rman_backup_include_archivelog` | `true` | `PLUS ARCHIVELOG` (not for `archivelog`) |
| `delete_input_archivelog` / `rman_backup_delete_input_archivelog` | `false` | `DELETE INPUT` |
| `validate_backup` / `rman_backup_validate` | `false` | Run `RESTORE ... VALIDATE` after the backup (re-reads all pieces) |
| `retention_days` | not set | Recovery window for `DELETE OBSOLETE`. **Deletes existing backups** (including older control file autobackups in the fast recovery area) that fall outside the window |
| `tag` | `ANSIBLE_<TYPE>` | RMAN backup tag |
| `rman_log_dir` | `/tmp/ansible_rman` | Where the generated RMAN command file is written on the target |

Per-database keys override the `rman_*` role defaults.

## Verify

```sql
-- rman target /
LIST BACKUP SUMMARY;
```
