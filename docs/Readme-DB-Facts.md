# Gather Database Facts

## Description

This module gathers comprehensive, **read-only inventory and operational facts** about an Oracle database (CDB, PDB, Standalone, or RAC) using the `oracle_facts` module.

It connects from the Ansible control node over TCP using `python-oracledb` thin mode and reports on the following 9 key areas:

1. **Database & Instance Status** — DB name, unique name, database role, open mode, log mode, CDB architecture, instance name, host, instance status, logins, archiver, platform, and startup time (`v$database`, `v$instance`).
2. **Oracle Home & Patch Inventory** — Oracle Home path, database release banner, and installed binary OPatch / SQL patches with patch IDs, descriptions, and applied dates (`sys.dbms_qopatch.get_opatch_lsinventory()`, `dba_registry_sqlpatch`).
3. **Pluggable Databases (PDBs)** — PDB container IDs, names, open modes, restricted status, open times, and total sizes in GB (`v$pdbs`).
4. **Control Files** — Control file paths, status, block sizes, and sizes in MB (`v$controlfile`).
5. **Tablespaces, Datafiles & Tempfiles Storage**:
   - **Tablespace Summary**: Total allocation in GB, used GB, free space in GB, free %, used %, contents, bigfile status (`dba_tablespaces`, `dba_data_files`, `dba_free_space`).
   - **Datafiles Details**: File paths, file IDs, total GB, used/free GB and %, autoextensible status, maxsize in GB, and datafile status.
   - **Tempfiles**: Tempfile paths, tablespace names, total GB, autoextensible status, and maxsize in GB (`dba_temp_files`).
6. **Redo Logs (Online Primary & Standby)** — Group numbers, thread numbers, sequence numbers, size in MB, member count, member file paths, archived status, and log status for both online and standby redo logs (`v$log`, `v$standby_log`, `v$logfile`).
7. **Archive Log & Flashback Status**:
   - **Archive Destinations**: Destination IDs, destination names, paths/TNS targets, and status (`v$archive_dest`).
   - **Fast Recovery Area (FRA)**: Recovery area path, space limit in GB, space used in GB, reclaimable GB, number of files, and space used % (`v$recovery_file_dest`).
   - **Flashback Status**: Flashback status (`flashback_on`), log mode, and force logging (`v$database`).
8. **RMAN Backup History** — Recent RMAN backup sessions with input types, status, start/end times, elapsed seconds, input/output GB, and output device types (`v$rman_backup_job_details`).
9. **Scheduled Jobs** — Active and custom scheduled jobs with owner, job name, job type, action, state, enabled status, restartable, last start date, next run date, repeat interval, run counts, and failure counts (`dba_scheduler_jobs`).

> **Migration note:** This module has been migrated from `cx_Oracle` to `python-oracledb` (thin mode).
> Thin mode is pure Python — no Oracle Instant Client is required on the control node.
> All database connections are made over TCP from `localhost` directly to the database listener.
> The `oracle_db_home` variable is no longer needed.

---

## Files to Update

| File | Purpose |
|------|---------|
| `playbooks/vars/gather-dbfacts-vars.yml` | DB hostname, listener port, and database service name |
| `playbooks/vars/vault.yml` | SYS password (SYSDBA connect) — **encrypt with ansible-vault** |

---

## Step 1 — Update `gather-dbfacts-vars.yml`

```yaml
# Gather Database Facts - Variables section
hostname: ansible-db                        # AIX Lpar hostname where the database is running.
listener_port: 1521                         # Database port number.
# oracle_db_home not needed - oracle_facts module uses Thin mode (pure Python, no Oracle client required)

# Service name of a CDB, PDB, or Standalone database
service_name: prod                          # Target database service name (e.g. prod, prodpdb)
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
ansible-playbook -i inventory.yml gather-db-facts.yml --ask-vault-pass
```

---

## Step 4 — Review the Playbook

```yaml
# playbooks/gather-db-facts.yml
- name: Gather DB Facts
  hosts: localhost
  gather_facts: false
  vars_files:
    - vars/vault.yml
    - vars/gather-dbfacts-vars.yml
  roles:
    - { role: oradb_gather_dbfacts }
```

---

## Step 5 — Execute the Playbook

```bash
ansible-playbook -i playbooks/inventory.yml playbooks/gather-db-facts.yml --ask-vault-pass
```

```text
PLAY [Gather DB Facts] ****************************************************************************************************************

TASK [oradb_gather_dbfacts : Gather database facts] ***********************************************************************************
ok: [localhost]

TASK [oradb_gather_dbfacts : 1. Database & Instance Status] ***************************************************************************
ok: [localhost] => {
    "dbfacts.ansible_facts.oracle_db_facts.database_and_instance": {
        "archiver": "STOPPED",
        "cdb": "YES",
        "database_role": "PRIMARY",
        "database_status": "ACTIVE",
        "db_created": "2026-10-11 12:59:19",
        "db_name": "PROD",
        "db_open_mode": "READ WRITE",
        "db_unique_name": "prod",
        "host_name": "host242",
        "instance_name": "prod",
        "instance_status": "OPEN",
        "instance_version": "19.0.0.0.0",
        "is_rac": "NO",
        "log_mode": "NOARCHIVELOG",
        "logins": "ALLOWED",
        "platform_name": "AIX-Based Systems (64-bit)",
        "startup_time": "2026-10-26 15:02:30"
    }
}

TASK [oradb_gather_dbfacts : 2. Oracle Home & Patch Details (OPatch)] *****************************************************************
ok: [localhost] => {
    "dbfacts.ansible_facts.oracle_db_facts.oracle_home_and_patches": {
        "database_version": "19.30.0.0.0",
        "installed_patches": [
            {
                "description": "Database Release Update : 19.30.0.0.260120(REL-JAN260130) (38632161)",
                "installed_on": "11 Feb 2026, 14:59:13 hrs UTC",
                "patch_id": "38632161"
            },
            {
                "description": "OCW RELEASE UPDATE 19.3.0.0.0 (29585399)",
                "installed_on": "9 Apr 2019, 19:12:47 hrs PST8PDT",
                "patch_id": "29585399"
            }
        ],
        "oracle_home": "/d01/19c/dbhome"
    }
}

TASK [oradb_gather_dbfacts : 3. Pluggable Databases (PDBs)] ***************************************************************************
ok: [localhost] => {
    "dbfacts.ansible_facts.oracle_db_facts.pluggable_databases": [
        {
            "con_id": 2,
            "open_mode": "READ ONLY",
            "open_time": "2026-10-26 15:03:54",
            "pdb_name": "PDB$SEED",
            "restricted": "NO",
            "total_size_gb": 1.44
        },
        {
            "con_id": 3,
            "open_mode": "MOUNTED",
            "open_time": null,
            "pdb_name": "PRODPDB",
            "restricted": null,
            "total_size_gb": 1.63
        }
    ]
}

TASK [oradb_gather_dbfacts : 4. Control Files] ****************************************************************************************
ok: [localhost] => {
    "dbfacts.ansible_facts.oracle_db_facts.control_files": [
        {
            "block_size": 16384,
            "controlfile_path": "/d01/19c/fast_recovery_area/PROD/control02.ctl",
            "is_recovery_dest_file": "NO",
            "size_mb": 13.88,
            "status": null
        },
        {
            "block_size": 16384,
            "controlfile_path": "/d01/19c/oradata/PROD/control01.ctl",
            "is_recovery_dest_file": "NO",
            "size_mb": 13.88,
            "status": null
        }
    ]
}

TASK [oradb_gather_dbfacts : 5a. Tablespaces Summary (GB & %)] ************************************************************************
ok: [localhost] => {
    "dbfacts.ansible_facts.oracle_db_facts.tablespace_summary": [
        {
            "bigfile": "NO",
            "contents": "PERMANENT",
            "free_gb": 0.07,
            "free_pct": 5.02,
            "status": "ONLINE",
            "tablespace_name": "SYSAUX",
            "total_gb": 1.46,
            "used_gb": 1.39,
            "used_pct": 94.98
        },
        {
            "bigfile": "NO",
            "contents": "PERMANENT",
            "free_gb": 0,
            "free_pct": 0.14,
            "status": "ONLINE",
            "tablespace_name": "SYSTEM",
            "total_gb": 1.15,
            "used_gb": 1.15,
            "used_pct": 99.86
        },
        {
            "bigfile": "NO",
            "contents": "UNDO",
            "free_gb": 0.72,
            "free_pct": 97.83,
            "status": "ONLINE",
            "tablespace_name": "UNDOTBS1",
            "total_gb": 0.73,
            "used_gb": 0.02,
            "used_pct": 2.18
        },
        {
            "bigfile": "NO",
            "contents": "PERMANENT",
            "free_gb": 0,
            "free_pct": 46.25,
            "status": "ONLINE",
            "tablespace_name": "USERS",
            "total_gb": 0,
            "used_gb": 0,
            "used_pct": 53.75
        }
    ]
}

TASK [oradb_gather_dbfacts : 5b. Datafiles Details (GB & %)] **************************************************************************
ok: [localhost] => {
    "dbfacts.ansible_facts.oracle_db_facts.datafiles": [
        {
            "autoextensible": "YES",
            "file_id": 3,
            "file_name": "/d01/19c/oradata/PROD/sysaux01.dbf",
            "free_gb": 0.07,
            "free_pct": 5.02,
            "maxsize_gb": 32,
            "status": "AVAILABLE",
            "tablespace_name": "SYSAUX",
            "total_gb": 1.46,
            "used_gb": 1.39,
            "used_pct": 94.98
        },
        {
            "autoextensible": "YES",
            "file_id": 1,
            "file_name": "/d01/19c/oradata/PROD/system01.dbf",
            "free_gb": 0,
            "free_pct": 0.14,
            "maxsize_gb": 32,
            "status": "AVAILABLE",
            "tablespace_name": "SYSTEM",
            "total_gb": 1.15,
            "used_gb": 1.15,
            "used_pct": 99.86
        },
        {
            "autoextensible": "YES",
            "file_id": 4,
            "file_name": "/d01/19c/oradata/PROD/undotbs01.dbf",
            "free_gb": 0.72,
            "free_pct": 97.83,
            "maxsize_gb": 32,
            "status": "AVAILABLE",
            "tablespace_name": "UNDOTBS1",
            "total_gb": 0.73,
            "used_gb": 0.02,
            "used_pct": 2.18
        },
        {
            "autoextensible": "YES",
            "file_id": 7,
            "file_name": "/d01/19c/oradata/PROD/users01.dbf",
            "free_gb": 0,
            "free_pct": 46.25,
            "maxsize_gb": 32,
            "status": "AVAILABLE",
            "tablespace_name": "USERS",
            "total_gb": 0,
            "used_gb": 0,
            "used_pct": 53.75
        }
    ]
}

TASK [oradb_gather_dbfacts : 5c. Tempfiles] *******************************************************************************************
ok: [localhost] => {
    "dbfacts.ansible_facts.oracle_db_facts.tempfiles": [
        {
            "autoextensible": "YES",
            "file_id": 1,
            "file_name": "/d01/19c/oradata/PROD/temp01.dbf",
            "maxsize_gb": 32,
            "status": "ONLINE",
            "tablespace_name": "TEMP",
            "total_gb": 0.22
        }
    ]
}

TASK [oradb_gather_dbfacts : 6a. Online Redo Logs (Primary)] **************************************************************************
ok: [localhost] => {
    "dbfacts.ansible_facts.oracle_db_facts.online_redo_logs": [
        {
            "archived": "NO",
            "group#": 1,
            "is_recovery_dest_file": "NO",
            "log_status": "CURRENT",
            "log_type": "ONLINE",
            "member_path": "/d01/19c/oradata/PROD/redo01.log",
            "member_status": null,
            "members": 1,
            "sequence#": 61,
            "size_mb": 200,
            "thread#": 1
        },
        {
            "archived": "YES",
            "group#": 2,
            "is_recovery_dest_file": "NO",
            "log_status": "INACTIVE",
            "log_type": "ONLINE",
            "member_path": "/d01/19c/oradata/PROD/redo02.log",
            "member_status": null,
            "members": 1,
            "sequence#": 59,
            "size_mb": 200,
            "thread#": 1
        },
        {
            "archived": "NO",
            "group#": 3,
            "is_recovery_dest_file": "NO",
            "log_status": "INACTIVE",
            "log_type": "ONLINE",
            "member_path": "/d01/19c/oradata/PROD/redo03.log",
            "member_status": null,
            "members": 1,
            "sequence#": 60,
            "size_mb": 200,
            "thread#": 1
        }
    ]
}

TASK [oradb_gather_dbfacts : 6b. Standby Redo Logs] ***********************************************************************************
ok: [localhost] => {
    "dbfacts.ansible_facts.oracle_db_facts.standby_redo_logs": []
}

TASK [oradb_gather_dbfacts : 7a. Archive Destinations] ********************************************************************************
ok: [localhost] => {
    "dbfacts.ansible_facts.oracle_db_facts.archive_destinations": [
        {
            "archiver": "FOREGROUND",
            "dest_id": 1,
            "dest_name": "LOG_ARCHIVE_DEST_1",
            "destination": "USE_DB_RECOVERY_FILE_DEST",
            "error": null,
            "status": "VALID",
            "target": "PRIMARY"
        },
        {
            "archiver": "LGWR",
            "dest_id": 2,
            "dest_name": "LOG_ARCHIVE_DEST_2",
            "destination": "prod_stby",
            "error": "ORA-01034: ORACLE not available",
            "status": "ERROR",
            "target": "STANDBY"
        }
    ]
}

TASK [oradb_gather_dbfacts : 7b. Flash Recovery Area (FRA) & Flashback] ***************************************************************
ok: [localhost] => {
    "msg": [
        "FRA: {'recovery_area_name': '/d01/19c/fast_recovery_area', 'space_limit_gb': 12.35, 'space_used_gb': 4.45, 'space_reclaimable_gb': 0, 'number_of_files': 50, 'space_used_pct': 36.08}",
        "Flashback: {'flashback_on': 'NO', 'log_mode': 'NOARCHIVELOG', 'force_logging': 'YES'}"
    ]
}

TASK [oradb_gather_dbfacts : 8. RMAN Backup History] **********************************************************************************
ok: [localhost] => {
    "dbfacts.ansible_facts.oracle_db_facts.rman_backup_history": []
}

TASK [oradb_gather_dbfacts : 9. Scheduled Jobs] ***************************************************************************************
ok: [localhost] => {
    "dbfacts.ansible_facts.oracle_db_facts.scheduled_jobs": [
        {
            "enabled": "TRUE",
            "failure_count": 0,
            "job_action": "ORACLE_OCM.MGMT_CONFIG.collect_config",
            "job_name": "MGMT_CONFIG_JOB",
            "job_type": "STORED_PROCEDURE",
            "last_start_date": "2026-10-26 01:01:01",
            "next_run_date": "2026-10-27 01:01:01",
            "owner": "ORACLE_OCM",
            "repeat_interval": "freq=daily;byhour=01;byminute=01;bysecond=01",
            "restartable": "FALSE",
            "run_count": 14,
            "state": "SCHEDULED"
        },
        {
            "enabled": "TRUE",
            "failure_count": 0,
            "job_action": "ORACLE_OCM.MGMT_CONFIG.collect_stats",
            "job_name": "MGMT_STATS_CONFIG_JOB",
            "job_type": "STORED_PROCEDURE",
            "last_start_date": null,
            "next_run_date": "2026-11-01 01:01:01",
            "owner": "ORACLE_OCM",
            "repeat_interval": "freq=monthly;interval=1;bymonthday=1;byhour=01;byminute=01;bysecond=01",
            "restartable": "FALSE",
            "run_count": 0,
            "state": "SCHEDULED"
        },
        {
            "enabled": "TRUE",
            "failure_count": 0,
            "job_action": null,
            "job_name": "BSLN_MAINTAIN_STATS_JOB",
            "job_type": null,
            "last_start_date": "2026-10-25 00:00:02",
            "next_run_date": "2026-11-01 00:00:00",
            "owner": "SYS",
            "repeat_interval": null,
            "restartable": "FALSE",
            "run_count": 3,
            "state": "SCHEDULED"
        },
        {
            "enabled": "TRUE",
            "failure_count": 0,
            "job_action": "declare\n                  myinterval number;\n                begin\n                  myinterval := dbms_pdb.cleanup_task(1);\n                  if myinterval <> 0 then\n                    next_date := systimestamp +\n                      numtodsinterval(myinterval, 'second');\n                  end if;\n                end;",
            "job_name": "CLEANUP_NON_EXIST_OBJ",
            "job_type": "PLSQL_BLOCK",
            "last_start_date": "2026-10-26 13:28:20",
            "next_run_date": "2026-10-27 01:28:20",
            "owner": "SYS",
            "repeat_interval": "FREQ = HOURLY; INTERVAL = 12",
            "restartable": "FALSE",
            "run_count": 31,
            "state": "SCHEDULED"
        },
        {
            "enabled": "TRUE",
            "failure_count": 0,
            "job_action": "declare\n                  myinterval number;\n                begin\n                  myinterval := dbms_pdb.cleanup_task(2);\n                  if myinterval <> 0 then\n                    next_date := systimestamp +\n                      numtodsinterval(myinterval, 'second');\n                  end if;\n                end;",
            "job_name": "CLEANUP_ONLINE_IND_BUILD",
            "job_type": "PLSQL_BLOCK",
            "last_start_date": "2026-10-26 12:28:04",
            "next_run_date": "2026-10-26 13:28:04",
            "owner": "SYS",
            "repeat_interval": "FREQ = HOURLY; INTERVAL = 1",
            "restartable": "FALSE",
            "run_count": 362,
            "state": "SCHEDULED"
        },
        {
            "enabled": "TRUE",
            "failure_count": 0,
            "job_action": "declare\n                  myinterval number;\n                begin\n                  myinterval := dbms_pdb.cleanup_task(6);\n                  if myinterval <> 0 then\n                    next_date := systimestamp +\n                      numtodsinterval(myinterval, 'second');\n                  end if;\n                end;",
            "job_name": "CLEANUP_ONLINE_PMO",
            "job_type": "PLSQL_BLOCK",
            "last_start_date": "2026-10-26 12:28:44",
            "next_run_date": "2026-10-26 13:28:44",
            "owner": "SYS",
            "repeat_interval": "FREQ = HOURLY; INTERVAL = 1",
            "restartable": "FALSE",
            "run_count": 363,
            "state": "SCHEDULED"
        },
        {
            "enabled": "TRUE",
            "failure_count": 0,
            "job_action": "declare\n                  myinterval number;\n                begin\n                  myinterval := dbms_pdb.cleanup_task(3);\n                  if myinterval <> 0 then\n                    next_date := systimestamp +\n                      numtodsinterval(myinterval, 'second');\n                  end if;\n                end;",
            "job_name": "CLEANUP_TAB_IOT_PMO",
            "job_type": "PLSQL_BLOCK",
            "last_start_date": "2026-10-26 12:28:15",
            "next_run_date": "2026-10-26 13:28:14",
            "owner": "SYS",
            "repeat_interval": "FREQ = HOURLY; INTERVAL = 1",
            "restartable": "FALSE",
            "run_count": 362,
            "state": "SCHEDULED"
        },
        {
            "enabled": "TRUE",
            "failure_count": 0,
            "job_action": "declare\n                  myinterval number;\n                begin\n                  myinterval := dbms_pdb.cleanup_task(5);\n                  if myinterval <> 0 then\n                    next_date := systimestamp +\n                      numtodsinterval(myinterval, 'second');\n                  end if;\n                end;",
            "job_name": "CLEANUP_TRANSIENT_PKG",
            "job_type": "PLSQL_BLOCK",
            "last_start_date": "2026-10-26 11:28:34",
            "next_run_date": "2026-10-26 13:28:34",
            "owner": "SYS",
            "repeat_interval": "FREQ = HOURLY; INTERVAL = 2",
            "restartable": "FALSE",
            "run_count": 182,
            "state": "SCHEDULED"
        },
        {
            "enabled": "TRUE",
            "failure_count": 0,
            "job_action": "declare\n                  myinterval number;\n                begin\n                  myinterval := dbms_pdb.cleanup_task(4);\n                  if myinterval <> 0 then\n                    next_date := systimestamp +\n                      numtodsinterval(myinterval, 'second');\n                  end if;\n                end;",
            "job_name": "CLEANUP_TRANSIENT_TYPE",
            "job_type": "PLSQL_BLOCK",
            "last_start_date": "2026-10-26 13:28:19",
            "next_run_date": "2026-10-27 01:28:19",
            "owner": "SYS",
            "repeat_interval": "FREQ = HOURLY; INTERVAL = 2",
            "restartable": "FALSE",
            "run_count": 31,
            "state": "SCHEDULED"
        },
        {
            "enabled": "TRUE",
            "failure_count": 0,
            "job_action": "dbms_ir.reevaluateopenfailures",
            "job_name": "DRA_REEVALUATE_OPEN_FAILURES",
            "job_type": "STORED_PROCEDURE",
            "last_start_date": "2026-10-25 04:00:02",
            "next_run_date": null,
            "owner": "SYS",
            "repeat_interval": null,
            "restartable": "FALSE",
            "run_count": 14,
            "state": "SCHEDULED"
        },
        {
            "enabled": "TRUE",
            "failure_count": 0,
            "job_action": "declare\n                  myinterval number;\n                begin\n                  myinterval := dbms_pdb.cleanup_task(7);\n                  if myinterval <> 0 then\n                    next_date := systimestamp +\n                      numtodsinterval(myinterval, 'second');\n                  end if;\n                end;",
            "job_name": "FILE_SIZE_UPD",
            "job_type": "PLSQL_BLOCK",
            "last_start_date": "2026-10-11 11:28:15",
            "next_run_date": "2027-10-11 13:28:15",
            "owner": "SYS",
            "repeat_interval": "FREQ = MINUTELY; INTERVAL = 5",
            "restartable": "FALSE",
            "run_count": 1,
            "state": "SCHEDULED"
        },
        {
            "enabled": "TRUE",
            "failure_count": 0,
            "job_action": null,
            "job_name": "ORA$AUTOTASK_CLEAN",
            "job_type": null,
            "last_start_date": "2026-10-26 03:00:00",
            "next_run_date": "2026-10-27 03:00:00",
            "owner": "SYS",
            "repeat_interval": null,
            "restartable": "FALSE",
            "run_count": 17,
            "state": "SCHEDULED"
        },
        {
            "enabled": "TRUE",
            "failure_count": 0,
            "job_action": null,
            "job_name": "ORA$PREPLUGIN_BACKUP_JOB",
            "job_type": null,
            "last_start_date": null,
            "next_run_date": null,
            "owner": "SYS",
            "repeat_interval": null,
            "restartable": "FALSE",
            "run_count": 0,
            "state": "SCHEDULED"
        },
        {
            "enabled": "TRUE",
            "failure_count": 0,
            "job_action": null,
            "job_name": "PMO_DEFERRED_GIDX_MAINT_JOB",
            "job_type": null,
            "last_start_date": "2026-10-26 02:00:02",
            "next_run_date": "2026-10-27 02:00:00",
            "owner": "SYS",
            "repeat_interval": null,
            "restartable": "FALSE",
            "run_count": 16,
            "state": "SCHEDULED"
        },
        {
            "enabled": "TRUE",
            "failure_count": 0,
            "job_action": null,
            "job_name": "PURGE_LOG",
            "job_type": null,
            "last_start_date": "2026-10-26 03:00:00",
            "next_run_date": "2026-10-27 03:00:00",
            "owner": "SYS",
            "repeat_interval": null,
            "restartable": "FALSE",
            "run_count": 17,
            "state": "SCHEDULED"
        },
        {
            "enabled": "TRUE",
            "failure_count": 0,
            "job_action": "sys.dbms_streams_auto_int.clean_recoverable_script;",
            "job_name": "RSE$CLEAN_RECOVERABLE_SCRIPT",
            "job_type": "PLSQL_BLOCK",
            "last_start_date": "2026-10-26 00:00:02",
            "next_run_date": "2026-10-27 00:00:00",
            "owner": "SYS",
            "repeat_interval": "freq=daily;byhour=0;byminute=0;bysecond=0",
            "restartable": "FALSE",
            "run_count": 17,
            "state": "SCHEDULED"
        },
        {
            "enabled": "TRUE",
            "failure_count": 0,
            "job_action": "sys.dbms_streams_auto_int.clean_auto_split_merge;",
            "job_name": "SM$CLEAN_AUTO_SPLIT_MERGE",
            "job_type": "PLSQL_BLOCK",
            "last_start_date": "2026-10-26 00:00:02",
            "next_run_date": "2026-10-27 00:00:00",
            "owner": "SYS",
            "repeat_interval": "freq=daily;byhour=0;byminute=0;bysecond=0",
            "restartable": "FALSE",
            "run_count": 17,
            "state": "SCHEDULED"
        }
    ]
}

PLAY RECAP ****************************************************************************************************************************
localhost                  : ok=14   changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

---

## Variables Reference

| Variable | File | Description |
|----------|------|-------------|
| `hostname` | `gather-dbfacts-vars.yml` | AIX hostname of the database server (TCP endpoint) |
| `listener_port` | `gather-dbfacts-vars.yml` | Database listener port (default: 1521) |
| `service_name` | `gather-dbfacts-vars.yml` | CDB, PDB, or Standalone database service name |
| `default_dbpass` | `vault.yml` | SYS password used to connect as SYSDBA |

---

To execute this playbook from a GUI, refer to: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
