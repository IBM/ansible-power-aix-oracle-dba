# Manage DBMS Scheduler Job Windows

## Description

This playbook creates, modifies, enables, disables or drops a DBMS_SCHEDULER window using the `oracle_jobwindow` module. A window activates a resource plan for a repeating period of time. After applying the change, it reads `dba_scheduler_windows` with the `oracle_sql` module and displays what is now in effect.

Reference: https://docs.oracle.com/database/121/ADMIN/scheduse.htm#ADMIN12674

In the example below, the window `ANSI_WINDOW` is created in the PDB `prodpdb`. It opens every Sunday at 06:00 for 12 hours and activates `DEFAULT_MAINTENANCE_PLAN`.

> **Migration note:** This collection has been migrated from `cx_Oracle` to `python-oracledb` (thin mode).
> Thin mode is pure Python — no Oracle Instant Client is required on the control node.
> All database connections are made over TCP from `localhost` directly to the database listener.
> The `oracle_db_home` variable is no longer needed.

---

## Files to Update

| File | Purpose |
|------|---------|
| `playbooks/vars/manage-job-window-vars.yml` | DB hostname, service name, window name, resource plan, interval, duration, state |
| `playbooks/vars/vault.yml` | SYS password (SYSDBA connect) — **encrypt with ansible-vault** |

---

## Step 1 — Update `manage-job-window-vars.yml`

```yaml
# Manage DBMS Scheduler Job Window - Variables section
hostname: ansible-db                        # AIX LPAR hostname where the database is running (TCP endpoint).
listener_port: 1521                         # Database listener port.
service_name: prodpdb                       # Database service name to connect to as SYSDBA.
# oracle_db_home not needed — oracle_jobwindow module uses Thin mode (pure Python, no Oracle client required)

state: enabled                              # enabled = create/modify and enable | disabled = create/modify and disable | absent = drop
window_name: ANSI_WINDOW                    # Scheduler window name (stored uppercase, owned by SYS).
resource_plan: DEFAULT_MAINTENANCE_PLAN     # Resource plan activated while the window is open. Must already exist.
interval: freq=daily;byday=SUN;byhour=6;byminute=0;bysecond=0   # Repeat interval (DBMS_SCHEDULER calendar syntax).
duration_hour: 12                           # Window duration in hours.
comments: This is a window for Ansible testing   # Optional comment.
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
# playbooks/manage-job-window.yml
- name: Manage DBMS Scheduler Job Window
  hosts: localhost
  gather_facts: false
  vars_files:
   - vars/vault.yml
   - vars/manage-job-window-vars.yml
  roles:
     - { role: oradb_manage_job_window }
```

---

## Step 5 — Execute the Playbook

```bash
ansible-playbook playbooks/manage-job-window.yml --ask-vault-pass
```

### Verified Execution Output

```
PLAY [Manage DBMS Scheduler Job Window] ****************************************

TASK [oradb_manage_job_window : Create DBMS Job Window] ************************
changed: [localhost]

TASK [oradb_manage_job_window : Show job window result] ************************
ok: [localhost] => {
    "msg": "Job window ANSI_WINDOW: state=enabled, changed=True"
}

TASK [oradb_manage_job_window : Verify window in DBA_SCHEDULER_WINDOWS] ********
ok: [localhost]

TASK [oradb_manage_job_window : Show window [name, resource plan, enabled, duration, repeat interval]] ***
ok: [localhost] => {
    "msg": [
        [
            "ANSI_WINDOW",
            "DEFAULT_MAINTENANCE_PLAN",
            "TRUE",
            "+000 12:00:00",
            "freq=daily;byday=SUN;byhour=6;byminute=0;bysecond=0"
        ]
    ]
}

PLAY RECAP *********************************************************************
localhost                  : ok=4    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### Disable or Drop the Window

Set `state: disabled` in `manage-job-window-vars.yml` to keep the window but stop it from opening, or `state: absent` to drop it, then re-run.

---

## Step 6 — SQL Verification

Connect to the database and verify directly:

```sql
SELECT window_name, resource_plan, enabled, duration, repeat_interval
FROM dba_scheduler_windows
WHERE window_name = 'ANSI_WINDOW';
```

---

## Variables Reference

| Variable | File | Description |
|----------|------|-------------|
| `hostname` | `manage-job-window-vars.yml` | AIX LPAR hostname (TCP endpoint for DB connection) |
| `listener_port` | `manage-job-window-vars.yml` | Database listener port (default: 1521) |
| `service_name` | `manage-job-window-vars.yml` | Database service name to connect to as SYSDBA |
| `state` | `manage-job-window-vars.yml` | `enabled` \| `disabled` \| `absent` |
| `window_name` | `manage-job-window-vars.yml` | Scheduler window name (stored uppercase, owned by SYS) |
| `resource_plan` | `manage-job-window-vars.yml` | Resource plan activated while the window is open |
| `interval` | `manage-job-window-vars.yml` | Repeat interval in DBMS_SCHEDULER calendar syntax |
| `duration_hour` | `manage-job-window-vars.yml` | Window duration in hours |
| `comments` | `manage-job-window-vars.yml` | Comment about the window |
| `default_dbpass` | `vault.yml` | SYS password used to connect as SYSDBA |
| `db_user` | role defaults | Connecting user (default: `sys`) |
| `db_mode` | role defaults | Connection mode (default: `sysdba`) |

---

To execute this playbook from a GUI, refer to: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
