# Manage DBMS Scheduler Job Schedules

## Description

This playbook creates, modifies or drops a DBMS_SCHEDULER schedule using the `oracle_jobschedule` module. The schedule can then be used by any DBMS scheduler job. After applying the change, it reads `dba_scheduler_schedules` with the `oracle_sql` module and displays what is now in effect.

Reference: https://docs.oracle.com/database/121/ADMIN/scheduse.htm#ADMIN12674

In the example below, a schedule that repeats every 30 minutes is created in the PDB `prodpdb`, owned by the schema `PBATCH`.

> **Migration note:** This collection has been migrated from `cx_Oracle` to `python-oracledb` (thin mode).
> Thin mode is pure Python — no Oracle Instant Client is required on the control node.
> All database connections are made over TCP from `localhost` directly to the database listener.
> The `oracle_db_home` variable is no longer needed.

---

## Files to Update

| File | Purpose |
|------|---------|
| `playbooks/vars/manage-jobschedule-vars.yml` | DB hostname, service name, schedule name, repeat interval, comments, state |
| `playbooks/vars/vault.yml` | SYS password (SYSDBA connect) — **encrypt with ansible-vault** |

---

## Step 1 — Update `manage-jobschedule-vars.yml`

```yaml
# Manage DBMS Scheduler Job Schedule - Variables section
hostname: ansible-db                        # AIX LPAR hostname where the database is running (TCP endpoint).
listener_port: 1521                         # Database listener port.
service_name: prodpdb                       # Database service name to connect to as SYSDBA.
# oracle_db_home not needed — oracle_jobschedule module uses Thin mode (pure Python, no Oracle client required)

state: present                              # present = create/modify the schedule | absent = drop it
schedule_name: pbatch.ansi_schedule         # <owner>.<schedule_name>. The owner schema must already exist.
repeat_interval: FREQ=MINUTELY;INTERVAL=30  # Repeat interval (DBMS_SCHEDULER calendar syntax).
comments: This is a test DBMS job schedule. # Optional comment.
```

> The unused `enabled` variable has been removed. The schedule name must be in the form `<owner>.<name>`.

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
# playbooks/manage-job-schedule.yml
- name: Manage DBMS Scheduler Job Schedule
  hosts: localhost
  gather_facts: false
  vars_files:
   - vars/vault.yml
   - vars/manage-jobschedule-vars.yml
  roles:
     - { role: oradb_manage_jobschedule }
```

---

## Step 5 — Execute the Playbook

```bash
ansible-playbook playbooks/manage-job-schedule.yml --ask-vault-pass
```

### Verified Execution Output

```
PLAY [Manage DBMS Scheduler Job Schedule] **************************************

TASK [oradb_manage_jobschedule : Create DBMS Job Schedule] *********************
changed: [localhost]

TASK [oradb_manage_jobschedule : Show job schedule result] *********************
ok: [localhost] => {
    "msg": "Job schedule PBATCH.ANSI_SCHEDULE: state=present, changed=True"
}

TASK [oradb_manage_jobschedule : Verify schedule in DBA_SCHEDULER_SCHEDULES] ***
ok: [localhost]

TASK [oradb_manage_jobschedule : Show schedule [owner, schedule name, repeat interval, comments]] ***
ok: [localhost] => {
    "msg": [
        [
            "PBATCH",
            "ANSI_SCHEDULE",
            "FREQ=MINUTELY;INTERVAL=30",
            "This is a test DBMS job schedule."
        ]
    ]
}

PLAY RECAP *********************************************************************
localhost                  : ok=4    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### Drop Schedule

To drop the schedule, set `state: absent` in `manage-jobschedule-vars.yml` and re-run.

---

## Step 6 — SQL Verification

Connect to the database and verify directly:

```sql
SELECT owner, schedule_name, repeat_interval, comments
FROM dba_scheduler_schedules
WHERE owner = 'PBATCH' AND schedule_name = 'ANSI_SCHEDULE';
```

---

## Variables Reference

| Variable | File | Description |
|----------|------|-------------|
| `hostname` | `manage-jobschedule-vars.yml` | AIX LPAR hostname (TCP endpoint for DB connection) |
| `listener_port` | `manage-jobschedule-vars.yml` | Database listener port (default: 1521) |
| `service_name` | `manage-jobschedule-vars.yml` | Database service name to connect to as SYSDBA |
| `state` | `manage-jobschedule-vars.yml` | `present` = create/modify \| `absent` = drop |
| `schedule_name` | `manage-jobschedule-vars.yml` | Schedule name in the form `<owner>.<name>` |
| `repeat_interval` | `manage-jobschedule-vars.yml` | Repeat interval in DBMS_SCHEDULER calendar syntax |
| `comments` | `manage-jobschedule-vars.yml` | Comment about the schedule |
| `default_dbpass` | `vault.yml` | SYS password used to connect as SYSDBA |
| `db_user` | role defaults | Connecting user (default: `sys`) |
| `db_mode` | role defaults | Connection mode (default: `sysdba`) |
| `convert_to_upper` | role defaults | Convert the schedule name to uppercase (default: `true`) |

---

To execute this playbook from a GUI, refer to: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
