# Manage Roles

## Description

This module is used to **create or drop** Oracle database roles.

- **`oradb_manage_roles`** — creates or drops role objects using the `oracle_role` module.

> **Note:** This playbook only manages the role object itself (create/drop).
> To assign privileges **to** a role, use [`manage-grants.yml`](../manage-grants.yml) with a `roles` subelement.
> For Oracle role privilege reference, see: https://docs.oracle.com/en/database/oracle/oracle-database/19/sqlrf/CREATE-ROLE.html

> **Migration note:** This collection has been migrated from `cx_Oracle` to `python-oracledb` (thin mode).
> Thin mode is pure Python — no Oracle Instant Client is required on the control node.
> The `oracle_db_home` variable is no longer needed.

---

## Files to Update

| File | Purpose |
|------|---------|
| `playbooks/vars/manage-roles-vars.yml` | DB hostname, port, service name, role list |
| `playbooks/vars/vault.yml` | SYS password (SYSDBA connect) — **encrypt with ansible-vault** |

---

## Step 1 — Update `manage-roles-vars.yml`

> **Loop mechanics** (`with_subelements` over `roles`):
> - `item.0` → outer dict: `service_name`, `state`
> - `item.1` → role entry: `name`

```yaml
# Manage Database Roles - Variables section
hostname: ansible-db                        # AIX Lpar hostname where the database is running.
listener_port: 1521                         # Database port number.
# oracle_db_home not needed - oracle_role module uses Thin mode (pure Python, no Oracle client required)

oracle_databases:
- service_name: prodpdb
  state: present                            # present | absent
  roles:
  - name: devrole                           # Developer role
  - name: reportrole                        # Reporting role
  - name: batchrole                         # Batch processing role
```

**Notes:**
- Add or remove entries under `roles:` to manage more role objects.
- `state: absent` drops the role from the database.
- To create roles in multiple PDBs, add another entry under `oracle_databases:`.

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

When running against an encrypted vault, add `--ask-vault-pass`:

```bash
ansible-playbook manage-roles.yml --ask-vault-pass
```

---

## Step 4 — Review the Playbook

```yaml
# playbooks/manage-roles.yml
- name: Manage DB Roles
  hosts: localhost                  # Runs on the Ansible control node (thin mode — no SSH to AIX)
  gather_facts: false
  vars_files:
   - vars/vault.yml
   - vars/manage-roles-vars.yml
  roles:
     - { role: oradb_manage_roles }
```

---

## Step 5 — Execute the Playbook

```bash
ansible-playbook manage-roles.yml
```

```text
PLAY [Manage DB Roles] ****************************************************************************************************************

TASK [oradb_manage_roles : Manage roles] **********************************************************************************************
changed: [localhost] => (item=port: 1521, service: prodpdb, role: devrole, state: present)
changed: [localhost] => (item=port: 1521, service: prodpdb, role: reportrole, state: present)
changed: [localhost] => (item=port: 1521, service: prodpdb, role: batchrole, state: present)

PLAY RECAP ****************************************************************************************************************************
localhost                  : ok=1    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

---

## Step 6 — Verify Roles Were Created

```sql
SELECT role, authentication_type
FROM dba_roles
WHERE role IN ('DEVROLE','REPORTROLE','BATCHROLE')
ORDER BY role;
```

---

## Variables Reference

| Variable | File | Description |
|----------|------|-------------|
| `hostname` | `manage-roles-vars.yml` | AIX hostname of the database server (TCP endpoint) |
| `listener_port` | `manage-roles-vars.yml` | Database listener port (default: 1521) |
| `service_name` | `manage-roles-vars.yml` | PDB service name to connect to |
| `state` | `manage-roles-vars.yml` | `present` (create role) \| `absent` (drop role) |
| `name` | `manage-roles-vars.yml` | Name of the role to create or drop |
| `default_dbpass` | `vault.yml` | SYS password used to connect as SYSDBA |

---

To execute this playbook from a GUI, refer to: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
