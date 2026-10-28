# Manage DBMS Scheduler Job Classes

## Description

This playbook creates, modifies or drops a DBMS_SCHEDULER job class using the `oracle_jobclass` module. After applying the change, it reads `dba_scheduler_job_classes` with the `oracle_sql` module and displays what is now in effect.

Reference: https://docs.oracle.com/database/121/ADMIN/scheduse.htm#ADMIN12674

In the example below, the job class `ANSICLASS` is created in the PDB `prodpdb` and associated with the resource consumer group `ANSIGROUP1`.

> **Prerequisite:** The resource consumer group must already exist, otherwise the module fails with `ORA-27475: unknown resource consumer group`. Create it first with [`manage-resource-consumer-group.yml`](Readme-Resource-Consumer-Groups.md).

> **Migration note:** This collection has been migrated from `cx_Oracle` to `python-oracledb` (thin mode).
> Thin mode is pure Python — no Oracle Instant Client is required on the control node.
> All database connections are made over TCP from `localhost` directly to the database listener.
> The `oracle_db_home` variable is no longer needed.

---

## Files to Update

| File | Purpose |
|------|---------|
| `playbooks/vars/manage-job-class-vars.yml` | DB hostname, service name, job class name, resource group, logging, history, state |
| `playbooks/vars/vault.yml` | SYS password (SYSDBA connect) — **encrypt with ansible-vault** |

---

## Step 1 — Update `manage-job-class-vars.yml`

```yaml
# Manage DBMS Scheduler Job Class - Variables section
hostname: ansible-db                        # AIX LPAR hostname where the database is running (TCP endpoint).
listener_port: 1521                         # Database listener port.
service_name: prodpdb                       # Database service name to connect to as SYSDBA.
# oracle_db_home not needed — oracle_jobclass module uses Thin mode (pure Python, no Oracle client required)

state: present                              # present = create/modify the job class | absent = drop it
class_name: ansiclass                       # Job class name (stored uppercase, owned by SYS).
resource_group: ansigroup1                  # Resource consumer group the class is associated with. Must already exist.
logging: failed runs                        # off | runs | failed runs | full
history: 14                                 # Number of days the logs for this job class are retained.
```

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
# playbooks/manage-jobclass.yml
- name: Manage DBMS Scheduler Job Class
  hosts: localhost
  gather_facts: false
  vars_files:
   - vars/vault.yml
   - vars/manage-job-class-vars.yml
  roles:
     - { role: oradb_manage_jobclass }
```

---

## Step 5 — Execute the Playbook

```bash
ansible-playbook playbooks/manage-jobclass.yml --ask-vault-pass
```

### Verified Execution Output

```
PLAY [Manage DBMS Scheduler Job Class] *****************************************

TASK [oradb_manage_jobclass : Oracle Job Class] ********************************
changed: [localhost]

TASK [oradb_manage_jobclass : Show job class result] ***************************
ok: [localhost] => {
    "msg": "Job class ANSICLASS: state=present, changed=True"
}

TASK [oradb_manage_jobclass : Verify job class in DBA_SCHEDULER_JOB_CLASSES] ***
ok: [localhost]

TASK [oradb_manage_jobclass : Show job class [name, resource group, logging level, log history (days)]] ***
ok: [localhost] => {
    "msg": [
        [
            "ANSICLASS",
            "ANSIGROUP1"
        ]
    ]
}

PLAY RECAP *********************************************************************
localhost                  : ok=4    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### Drop Job Class

To drop the job class, set `state: absent` in `manage-job-class-vars.yml` and re-run.

---

## Step 6 — SQL Verification

Connect to the database and verify directly:

```sql
SELECT job_class_name, resource_consumer_group, logging_level, log_history
FROM dba_scheduler_job_classes
WHERE job_class_name = 'ANSICLASS';
```

---

## Variables Reference

| Variable | File | Description |
|----------|------|-------------|
| `hostname` | `manage-job-class-vars.yml` | AIX LPAR hostname (TCP endpoint for DB connection) |
| `listener_port` | `manage-job-class-vars.yml` | Database listener port (default: 1521) |
| `service_name` | `manage-job-class-vars.yml` | Database service name to connect to as SYSDBA |
| `state` | `manage-job-class-vars.yml` | `present` = create/modify \| `absent` = drop |
| `class_name` | `manage-job-class-vars.yml` | Job class name (stored uppercase, owned by SYS) |
| `resource_group` | `manage-job-class-vars.yml` | Resource consumer group the class is associated with |
| `logging` | `manage-job-class-vars.yml` | `off` \| `runs` \| `failed runs` \| `full` |
| `history` | `manage-job-class-vars.yml` | Number of days job class logs are retained |
| `default_dbpass` | `vault.yml` | SYS password used to connect as SYSDBA |
| `db_user` | role defaults | Connecting user (default: `sys`) |
| `db_mode` | role defaults | Connection mode (default: `sysdba`) |

---

To execute this playbook from a GUI, refer to: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
