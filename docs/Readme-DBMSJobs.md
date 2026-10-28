# Manage DBMS Scheduler Jobs

## Description

This playbook creates, modifies or drops a DBMS_SCHEDULER job using the `oracle_job` module. After applying the change, it reads `dba_scheduler_jobs` with the `oracle_sql` module and displays what is now in effect.

More information on DBMS jobs can be found here: https://docs.oracle.com/database/121/ARPLS/d_sched.htm

In the example below, the job `ANSI_JOB` is created in the PDB `prodpdb` under the schema `PBATCH`. It runs a PL/SQL block every 35 minutes.

> **Migration note:** This collection has been migrated from `cx_Oracle` to `python-oracledb` (thin mode).
> Thin mode is pure Python — no Oracle Instant Client is required on the control node.
> All database connections are made over TCP from `localhost` directly to the database listener.
> The `oracle_db_home` variable is no longer needed.

---

## Files to Update

| File | Purpose |
|------|---------|
| `playbooks/vars/manage-job-vars.yml` | DB hostname, service name, job name, type, action, repeat interval, state |
| `playbooks/vars/vault.yml` | SYS password (SYSDBA connect) — **encrypt with ansible-vault** |

---

## Step 1 — Update `manage-job-vars.yml`

```yaml
# Manage DBMS Scheduler Job - Variables section
hostname: ansible-db                        # AIX LPAR hostname where the database is running (TCP endpoint).
listener_port: 1521                         # Database listener port.
service_name: prodpdb                       # Database service name to connect to as SYSDBA.
# oracle_db_home not needed — oracle_job module uses Thin mode (pure Python, no Oracle client required)

state: present                              # present = create/modify the job | absent = drop it
enabled: true                               # true = enable the job | false = disable the job
job_name: pbatch.ansi_job                   # <owner>.<job_name>. The owner schema must already exist.
job_type: plsql_block                       # plsql_block | stored_procedure | executable | external_script | sql_script | backup_script
job_action: BEGIN NULL; END;                # PL/SQL block, or <owner>.<package>.<procedure> / <owner>.<procedure> for stored_procedure.
repeat_interval: FREQ=MINUTELY;INTERVAL=35  # Job repeat interval (DBMS_SCHEDULER calendar syntax).
```

> To run a stored procedure instead, set `job_type: stored_procedure` and `job_action: <owner>.<package>.<procedure>`. The procedure must already exist.

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
# playbooks/manage-job.yml
- name: Manage DBMS Scheduler Job
  hosts: localhost
  gather_facts: false
  vars_files:
   - vars/vault.yml
   - vars/manage-job-vars.yml
  roles:
     - { role: oradb_manage_job }
```

---

## Step 5 — Execute the Playbook

```bash
ansible-playbook playbooks/manage-job.yml --ask-vault-pass
```

### Verified Execution Output

```
PLAY [Manage DBMS Scheduler Job] ***********************************************

TASK [oradb_manage_job : Create Job] *******************************************
changed: [localhost]

TASK [oradb_manage_job : Show job result] **************************************
ok: [localhost] => {
    "msg": "Job PBATCH.ANSI_JOB: state=present, changed=True"
}

TASK [oradb_manage_job : Verify job in DBA_SCHEDULER_JOBS] *********************
ok: [localhost]

TASK [oradb_manage_job : Show job [owner, job name, job type, enabled, repeat interval]] ***
ok: [localhost] => {
    "msg": [
        [
            "PBATCH",
            "ANSI_JOB",
            "PLSQL_BLOCK",
            "TRUE",
            "FREQ=MINUTELY;INTERVAL=35"
        ]
    ]
}

PLAY RECAP *********************************************************************
localhost                  : ok=4    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### Re-run (idempotent)

Running the playbook again with the same values reports `changed=0`:

```
PLAY RECAP *********************************************************************
localhost                  : ok=4    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### Modify or Drop the Job

If any job attribute changes, the module drops and re-creates the job. To drop the job, set `state: absent` in `manage-job-vars.yml` and re-run. To keep the job but stop it from running, set `enabled: false`.

---

## Step 6 — SQL Verification

Connect to the database and verify directly:

```sql
SELECT owner, job_name, job_type, enabled, repeat_interval
FROM dba_scheduler_jobs
WHERE owner = 'PBATCH' AND job_name = 'ANSI_JOB';
```

---

## Variables Reference

| Variable | File | Description |
|----------|------|-------------|
| `hostname` | `manage-job-vars.yml` | AIX LPAR hostname (TCP endpoint for DB connection) |
| `listener_port` | `manage-job-vars.yml` | Database listener port (default: 1521) |
| `service_name` | `manage-job-vars.yml` | Database service name to connect to as SYSDBA |
| `state` | `manage-job-vars.yml` | `present` = create/modify \| `absent` = drop |
| `enabled` | `manage-job-vars.yml` | `true` = enable the job \| `false` = disable it |
| `job_name` | `manage-job-vars.yml` | Job name in the form `<owner>.<name>` |
| `job_type` | `manage-job-vars.yml` | `plsql_block` \| `stored_procedure` \| `executable` \| `external_script` \| `sql_script` \| `backup_script` |
| `job_action` | `manage-job-vars.yml` | PL/SQL block or procedure name, depending on `job_type` |
| `repeat_interval` | `manage-job-vars.yml` | Repeat interval in DBMS_SCHEDULER calendar syntax |
| `default_dbpass` | `vault.yml` | SYS password used to connect as SYSDBA |
| `db_user` | role defaults | Connecting user (default: `sys`) |
| `db_mode` | role defaults | Connection mode (default: `sysdba`) |

---

To execute this playbook from a GUI, refer to: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
