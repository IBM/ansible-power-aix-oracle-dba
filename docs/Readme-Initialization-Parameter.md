# Manage Database Initialization Parameters

## Description

This module allows administrators to **set, modify, clear, or reset Oracle database initialization parameters** dynamically or in the SPFILE using the `oracle_parameter` module.

It connects from the Ansible control node over TCP directly to the target database listener using `python-oracledb` thin mode (no Oracle Instant Client required) with `SYSDBA` privileges.

### Capabilities:
- **Set parameter values**: Configure numeric, string, boolean, or path-based parameters (`alter system set <name>=<value>`).
- **Clear / Null string parameters**: Pass an empty value `""` to set string parameters to empty (`alter system set <name>=''`).
- **Reset to default**: Set `state: reset` or `state: absent` to clear parameter overrides and restore database default values (`alter system reset <name>`).
- **Scope control**: Apply parameter changes to `both` (SPFILE and running memory), `spfile` only, or `memory` only.
- **RAC instance targeting**: Target all instances with `sid: "*"` or specific RAC instances (`sid: "prod1"`).
- **Underscore / Hidden parameters**: Supports managing hidden/internal parameters (`_parameter`) when connected as `SYSDBA`.

> **Migration note:** This module has been migrated from `cx_Oracle` to `python-oracledb` (thin mode).
> Thin mode is pure Python — no Oracle Instant Client is required on the control node.
> All database connections are made over TCP from `localhost` directly to the database listener.
> The `oracle_db_home` variable is no longer needed.

---

## Files to Update

| File | Purpose |
|------|---------|
| `playbooks/vars/manage-init-parameters-vars.yml` | Database hostname, service name, port, parameter name, value, scope, SID, and state |
| `playbooks/vars/vault.yml` | SYS password (SYSDBA connect) — **encrypt with ansible-vault** |

---

## Step 1 — Update `vars/manage-init-parameters-vars.yml`

```yaml
# Manage Database Initialization Parameters - Variables section
hostname: ansible-db                           # AIX hostname where the Database is running.
service_name: prod                             # Target database service name (e.g. prod, prodpdb, devdb).
listener_port: 1521                            # Database listener port.
# oracle_db_home not needed - oracle_parameter module uses Thin mode (pure Python, no Oracle client required)

param_name: log_archive_dest_2                 # Initialization Parameter Name
param_value:                                   # Initialization Parameter Value (e.g. enable, defer, 100, or blank/empty to clear)
param_scope: both                              # Parameter scope: both, spfile, memory (default: both)
param_sid: "*"                                 # Target instance SID (default: "*")
state: present                                 # State: present (sets value) or reset / absent (resets to default)
```

---

## Step 2 — Update `vars/vault.yml`

Ensure `default_dbpass` is set with the SYS password:

```yaml
default_dbpass: Oracle4u                       # SYS password — used to CONNECT to the DB as SYSDBA.
default_gipass: Oracle4u                       # ASM sys password.
```

Encrypt the vault file:

```bash
ansible-vault encrypt vars/vault.yml
```

---

## Step 3 — Review the Playbook (`manage-init-parameters.yml`)

```yaml
# Playbook to manage database initialization parameters.
# Before executing this playbook, please refer to the documentation inside the collection docs directory.
#
- name: Manage Database Initialization Parameters
  hosts: localhost
  connection: local
  gather_facts: false
  vars_files:
    - vars/vault.yml
    - vars/manage-init-parameters-vars.yml
  roles:
    - { role: oradb_manage_initparams }
```

---

## Step 4 — Execute the Playbook

```bash
cd playbooks
ansible-playbook manage-init-parameters.yml -i inventory.yml --ask-vault-pass
```

### Verified Execution Output (Clearing / Nulling Parameter)

```
PLAY [Manage Database Initialization Parameters] **************************************************************************************

TASK [oradb_manage_initparams : Manage Oracle initialization parameter] ***************************************************************
changed: [localhost]

TASK [oradb_manage_initparams : Parameter change status] ******************************************************************************
ok: [localhost] => {
    "parameter.msg": "The parameter (log_archive_dest_2) has been changed successfully, new: '', old: service=\"prod_stby\", async noaffirm delay=0 optional compression=disable max_failure=0 reopen=300 db_unique_name=\"prod_stby\" net_timeout=30, valid_for=(online_logfile,all_roles)"
}

PLAY RECAP ****************************************************************************************************************************
localhost                  : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

---

## Idempotency Check

Running the playbook again when the parameter is already at the desired value will return `ok` with `changed=0`:

```
TASK [oradb_manage_initparams : Manage Oracle initialization parameter] ***************************************************************
ok: [localhost]

TASK [oradb_manage_initparams : Parameter change status] ******************************************************************************
ok: [localhost] => {
    "parameter.msg": "The parameter (log_archive_dest_2) is already set to ''"
}
```

---

## Manual SQL Verification

Verify the parameter value in `v$parameter` and `v$spparameter` via SQL*Plus:

```sql
sqlplus / as sysdba

-- Check parameter value in active memory and SPFILE
SELECT name, value, display_value, isdefault
FROM v$parameter 
WHERE name = 'log_archive_dest_2';

-- Check SPFILE entry
SELECT name, value, display_value, sid 
FROM v$spparameter 
WHERE name = 'log_archive_dest_2';
```
