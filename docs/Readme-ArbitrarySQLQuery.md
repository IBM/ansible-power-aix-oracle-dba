# Run Arbitrary SQL Queries

## Description

This playbook runs arbitrary SQL queries (`SELECT`) against an Oracle database using the `oracle_sql` module. A single query or multiple queries can be run, in the order listed, and the result of each query is printed.

In the example below, two simple queries are executed against a PDB.

> **Migration note:** This collection has been migrated from `cx_Oracle` to `python-oracledb` (thin mode).
> Thin mode is pure Python — no Oracle Instant Client is required on the control node.
> All database connections are made over TCP from `localhost` directly to the database listener.
> The `oracle_db_home` variable is no longer needed.

---

## Files to Update

| File | Purpose |
|------|---------|
| `playbooks/vars/manage-arbitrarysqlquery-vars.yml` | DB hostname, service name, listener port, list of SQL queries |
| `playbooks/vars/vault.yml` | SYS password (SYSDBA connect) — **encrypt with ansible-vault** |

---

## Step 1 — Update `manage-arbitrarysqlquery-vars.yml`

```yaml
# Run Arbitrary SQL Queries - Variables section
hostname: ansible-db                        # AIX LPAR hostname where the database is running (TCP endpoint).
listener_port: 1521                         # Database listener port.
service_name: prodpdb                       # Database service name to connect to as SYSDBA.
# oracle_db_home not needed — oracle_sql module uses Thin mode (pure Python, no Oracle client required)

sql_query:                                  # Queries are run in the order listed.
- { query: 'select name,open_mode from v$database' }   # SQL Query 1.
- { query: 'select instance_name from v$instance' }    # SQL Query 2.
```

> Queries must start with `select`. Any other statement is executed as DML/DDL and reported as `changed`. To run scripts, use [`manage-arbitrarysql.yml`](Readme-ArbitrarySQL.md) instead.

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
# playbooks/manage-arbitrarysqlquery.yml
- name: Run Arbitrary SQL Queries
  hosts: localhost
  gather_facts: false
  vars_files:
   - vars/vault.yml
   - vars/manage-arbitrarysqlquery-vars.yml
  roles:
     - { role: oradb_manage_sqlqueries }
```

---

## Step 5 — Execute the Playbook

```bash
ansible-playbook -i playbooks/inventory.yml playbooks/manage-arbitrarysqlquery.yml --ask-vault-pass
```

### Verified Execution Output

> Run against the PDB `prodpdb` after the refactor. `v$database` and `v$instance` report the container database (`PROD`/`prod`) even when connected to a PDB.

```
PLAY [Run Arbitrary SQL Queries] ***********************************************

TASK [oradb_manage_sqlqueries : Run SQL queries] *******************************
ok: [localhost] => (item=select name,open_mode from v$database)
ok: [localhost] => (item=select instance_name from v$instance)

TASK [oradb_manage_sqlqueries : SQL Output] ************************************
ok: [localhost] => (item=select name,open_mode from v$database) => {
    "msg": "select name,open_mode from v$database: [['PROD', 'READ WRITE']]"
}
ok: [localhost] => (item=select instance_name from v$instance) => {
    "msg": "select instance_name from v$instance: [['prod']]"
}

PLAY RECAP *********************************************************************
localhost                  : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

---

## Step 6 — SQL Verification

Run the same queries directly in SQL*Plus to compare:

```sql
SELECT name, open_mode FROM v$database;
SELECT instance_name FROM v$instance;
```

---

## Variables Reference

| Variable | File | Description |
|----------|------|-------------|
| `hostname` | `manage-arbitrarysqlquery-vars.yml` | AIX LPAR hostname (TCP endpoint for DB connection) |
| `listener_port` | `manage-arbitrarysqlquery-vars.yml` | Database listener port (default: 1521) |
| `service_name` | `manage-arbitrarysqlquery-vars.yml` | Database service name to connect to as SYSDBA |
| `sql_query` | `manage-arbitrarysqlquery-vars.yml` | List of `{ query: '<select statement>' }` entries, run in order |
| `default_dbpass` | `vault.yml` | SYS password used to connect as SYSDBA |
| `db_user` | role defaults | Connecting user (default: `sys`) |
| `db_mode` | role defaults | Connection mode (default: `sysdba`) |

---

To execute this playbook from a GUI, refer to: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
