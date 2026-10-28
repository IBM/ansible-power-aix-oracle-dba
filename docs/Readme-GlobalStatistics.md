# Manage Global Statistics Preferences

## Description

This playbook sets (or resets) DBMS_STATS global preferences using the `oracle_stats_prefs` module. After applying the change, it calls `DBMS_STATS.GET_PREFS` with the `oracle_sql` module and displays the value now in effect.

More information on DBMS_STATS can be found here: https://docs.oracle.com/database/121/ARPLS/d_stats.htm

In the example below, the global preference `CONCURRENT` is set to `ALL` in the CDB `prod`.

> **Migration note:** This collection has been migrated from `cx_Oracle` to `python-oracledb` (thin mode).
> Thin mode is pure Python — no Oracle Instant Client is required on the control node.
> All database connections are made over TCP from `localhost` directly to the database listener.
> The `oracle_db_home` variable is no longer needed.

---

## Files to Update

| File | Purpose |
|------|---------|
| `playbooks/vars/manage-globalstats-vars.yml` | DB hostname, service name, preference name, value, state |
| `playbooks/vars/vault.yml` | SYS password (SYSDBA connect) — **encrypt with ansible-vault** |

---

## Step 1 — Update `manage-globalstats-vars.yml`

```yaml
# Manage Global Statistics Preferences - Variables section
hostname: ansible-db                        # AIX LPAR hostname where the database is running (TCP endpoint).
listener_port: 1521                         # Database listener port.
service_name: prod                          # Database service name to connect to as SYSDBA.
# oracle_db_home not needed — oracle_stats_prefs module uses Thin mode (pure Python, no Oracle client required)

preference_name: CONCURRENT                 # DBMS_STATS preference name.
preference_value: ALL                       # Preference value (ignored when state: absent).
state: present                              # present = set the preference | absent = reset it to the default
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
# playbooks/manage-globalstats.yml
- name: Manage Global Statistics Preferences
  hosts: localhost
  gather_facts: false
  vars_files:
   - vars/vault.yml
   - vars/manage-globalstats-vars.yml
  roles:
     - { role: oradb_manage_stats }
```

---

## Step 5 — Execute the Playbook

```bash
ansible-playbook playbooks/manage-globalstats.yml --ask-vault-pass
```

### Verified Execution Output

```
PLAY [Manage Global Statistics Preferences] *******************************************************************************************

TASK [oradb_manage_stats : Manage Global preferences] *********************************************************************************
changed: [localhost]

TASK [oradb_manage_stats : Show global preference result] *****************************************************************************
ok: [localhost] => {
    "msg": "Old value OFF changed to ALL"
}

TASK [oradb_manage_stats : Verify preference with DBMS_STATS.GET_PREFS] ***************************************************************
ok: [localhost]

TASK [oradb_manage_stats : Show current preference value [preference, value]] *********************************************************
ok: [localhost] => {
    "msg": [
        [
            "CONCURRENT",
            "ALL"
        ]
    ]
}

PLAY RECAP ****************************************************************************************************************************
localhost                  : ok=4    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

If the preference already has the requested value, the first task reports `ok` and the message is `Not changed`.

### Reset to Default

To reset the preference to its default, set `state: absent` in `manage-globalstats-vars.yml` and re-run. `preference_value` is ignored in this case.

---

## Step 6 — SQL Verification

Connect to the database and verify directly:

```sql
SELECT 'CONCURRENT' AS preference, DBMS_STATS.GET_PREFS('CONCURRENT') AS value FROM dual;
```

---

## Variables Reference

| Variable | File | Description |
|----------|------|-------------|
| `hostname` | `manage-globalstats-vars.yml` | AIX LPAR hostname (TCP endpoint for DB connection) |
| `listener_port` | `manage-globalstats-vars.yml` | Database listener port (default: 1521) |
| `service_name` | `manage-globalstats-vars.yml` | Database service name to connect to as SYSDBA |
| `preference_name` | `manage-globalstats-vars.yml` | DBMS_STATS preference name (for example `CONCURRENT`) |
| `preference_value` | `manage-globalstats-vars.yml` | Preference value to set (ignored when `state: absent`) |
| `state` | `manage-globalstats-vars.yml` | `present` = set the preference \| `absent` = reset it to the default |
| `default_dbpass` | `vault.yml` | SYS password used to connect as SYSDBA |
| `db_user` | role defaults | Connecting user (default: `sys`) |
| `db_mode` | role defaults | Connection mode (default: `sysdba`) |

---

To execute this playbook from a GUI, refer to: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
