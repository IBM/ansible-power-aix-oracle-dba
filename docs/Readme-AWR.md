# Manage AWR Snapshot Settings

## Description

This playbook sets the Automatic Workload Repository (AWR) snapshot interval and retention period using the `oracle_awr` module. After applying the settings, it reads `dba_hist_wr_control` with the `oracle_sql` module and displays the values now in effect.

More information about AWR can be found here: https://docs.oracle.com/cd/E11882_01/server.112/e41573/autostat.htm#PFGRF94188

In the example below, the snapshot interval is set to 45 minutes and the retention period to 25 days.

> **Migration note:** This collection has been migrated from `cx_Oracle` to `python-oracledb` (thin mode).
> Thin mode is pure Python — no Oracle Instant Client is required on the control node.
> All database connections are made over TCP from `localhost` directly to the database listener.
> The `oracle_db_home` variable is no longer needed.

---

## Files to Update

| File | Purpose |
|------|---------|
| `playbooks/vars/manage-awr-vars.yml` | DB hostname, service name, snapshot interval, retention |
| `playbooks/vars/vault.yml` | SYS password (SYSDBA connect) — **encrypt with ansible-vault** |

---

## Step 1 — Update `manage-awr-vars.yml`

```yaml
# Manage AWR Snapshot Settings - Variables section
hostname: ansible-db                        # AIX LPAR hostname where the database is running (TCP endpoint).
listener_port: 1521                         # Database listener port.
service_name: prod                          # Database service name to connect to as SYSDBA.
# oracle_db_home not needed — oracle_awr module uses Thin mode (pure Python, no Oracle client required)

interval: 45                                # Snapshot interval (in minutes). Minimum 10. '0' disables snapshots.
retention: 25                               # Snapshot retention period (in days).
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
# playbooks/manage-awr.yml
- name: Manage AWR Snapshot Settings
  hosts: localhost
  gather_facts: false
  vars_files:
   - vars/vault.yml
   - vars/manage-awr-vars.yml
  roles:
     - { role: oradb_manage_awr }
```

---

## Step 5 — Execute the Playbook

```bash
ansible-playbook playbooks/manage-awr.yml --ask-vault-pass
```

### Verified Execution Output

```
PLAY [Manage AWR Snapshot Settings] ***************************************************************************************************

TASK [oradb_manage_awr : Modify AWR settings] *****************************************************************************************
changed: [localhost]

TASK [oradb_manage_awr : Verify AWR settings in DBA_HIST_WR_CONTROL] ******************************************************************
ok: [localhost]

TASK [oradb_manage_awr : Show AWR settings [snapshot interval (min), retention (days)]] ***********************************************
ok: [localhost] => {
    "msg": [
        [
            45,
            25
        ]
    ]
}

PLAY RECAP ****************************************************************************************************************************
localhost                  : ok=3    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

The result is a list of rows, each `[snapshot interval in minutes, retention in days]`. If the database is already set to the requested values, the first task reports `ok` instead of `changed`.

---

## Step 6 — SQL Verification

Connect to the database and verify directly:

```sql
SELECT EXTRACT(DAY FROM snap_interval)*24*60
     + EXTRACT(HOUR FROM snap_interval)*60
     + EXTRACT(MINUTE FROM snap_interval) AS snapshot_interval_min,
       EXTRACT(DAY FROM retention)
     + EXTRACT(HOUR FROM retention)/24
     + EXTRACT(MINUTE FROM retention)/1440 AS retention_days
FROM dba_hist_wr_control;
```

---

## Variables Reference

| Variable | File | Description |
|----------|------|-------------|
| `hostname` | `manage-awr-vars.yml` | AIX LPAR hostname (TCP endpoint for DB connection) |
| `listener_port` | `manage-awr-vars.yml` | Database listener port (default: 1521) |
| `service_name` | `manage-awr-vars.yml` | Database service name to connect to as SYSDBA |
| `interval` | `manage-awr-vars.yml` | Snapshot interval in minutes. Minimum 10; `0` disables snapshots |
| `retention` | `manage-awr-vars.yml` | Snapshot retention period in days |
| `default_dbpass` | `vault.yml` | SYS password used to connect as SYSDBA |
| `db_user` | role defaults | Connecting user (default: `sys`) |
| `db_mode` | role defaults | Connection mode (default: `sysdba`) |
| `sql_query` | role defaults | Verification query against `dba_hist_wr_control` |

---

To execute this playbook from a GUI, refer to: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
