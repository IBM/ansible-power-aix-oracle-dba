# Oracle 19c Cross-Endian Migration (M5) — Readme

**Oracle 19c cross-endian platform migration** — x86 Linux → IBM AIX Power  
Method: Oracle M5 (RMAN incremental backups + Full Transportable Data Pump), driven by Oracle's DBMIG 5.1 scripts ([MOS Doc 2999157.1](https://support.oracle.com/epmos/faces/DocumentDisplay?id=2999157.1))

The migration is one playbook, three roles and one variables file inside the PowerODBA collection. It runs as five tagged stages, from prechecks to go-live, and only ever touches the two hosts in the inventory's `mig` group.

---

## Where it lives in the collection

```
ansible-power-aix-oracle-dba/
├── playbooks/
│   ├── ansible.cfg                  ← shared PowerODBA settings (unchanged)
│   ├── inventory.yml                ← shared inventory; migration hosts in the [mig] group
│   ├── m5_migration.yml             ← the migration playbook, one tag per stage
│   └── vars/
│       └── m5_migration/
│           ├── mig_vars.yml         ← all migration settings
│           └── mig_vault.yml        ← SYS / SYSTEM passwords (ansible-vault encrypted)
└── roles/
    ├── mig_prechecks/               ← OS/DB checks, patch checks, SSH, DB prep, DBMIG deploy → tag: prechecks
    ├── mig_rman_l0_l1/              ← L0 baseline + L1 incremental                          → tags: rman_l0 | rman_l1
    └── mig_rman_l1f/                ← L1F + import + postchecks + validation (cutover)      → tag: rman_l1f  ⚠ DOWNTIME
```

Run every command **from the `playbooks/` directory**, like the other PowerODBA playbooks. The `playbooks/roles` symlink lets the playbook find the roles.

### Roles

| Role | Tag | Plays | What it does |
|------|-----|-------|--------------|
| `mig_prechecks` | `prechecks` | one play on `mig_source:mig_destination`, then a mark-complete play | OS/DB checks, patch checks, SSH equivalence, source/destination DB prep, DBMIG 5.1 deploy |
| `mig_rman_l0_l1` | `rman_l0` or `rman_l1` | one play on `mig_source:mig_destination` | RMAN backup on source → restore on destination (L0 once, L1 repeated) |
| `mig_rman_l1f` | `rman_l1f` | a source play, a destination play, then a mark-complete play | L1F backup → restore → Data Pump import → table-count check → tablespaces READ WRITE → utlrp → stats → validate |

Each role's tasks carry their own `when: inventory_hostname in groups[...]` guard, so a host runs only its own half of a combined play.

---

## Inventory — the `mig` group

`inventory.yml` is shared with the other PowerODBA playbooks, so the migration hosts sit in their own groups:

```ini
# ── x86 Linux source ──────────────────────────────────────────────────────
[mig_source]
source-linux-host ansible_host=333.33.33.333

# ── IBM AIX Power destination ─────────────────────────────────────────────
[mig_destination]
dest-aix-host ansible_host=444.44.44.444

# ── Parent group: both migration hosts ────────────────────────────────────
[mig:children]
mig_source
mig_destination

# ── Settings for the migration hosts only ─────────────────────────────────
[mig:vars]
ansible_user=oracle
ansible_python_interpreter=/usr/bin/python3
```

- Replace only the two host lines: `<server hostname> ansible_host=<server IP or DNS name>`. Keep exactly one host in each of `[mig_source]` and `[mig_destination]`.
- Leave `[mig:children]` as it is — it lists group names, not hosts.
- `[mig:vars]` applies to the two migration hosts only. `ansible_user` is the account Ansible logs in as **on those hosts**; on the controller, Ansible still runs as whoever starts it.

The playbook's first play checks the inventory. If it was run without `-i inventory.yml`, or the groups are missing, it stops straight away with: *"The inventory doesn't define the migration hosts. Run from the playbooks/ directory with -i inventory.yml…"*.

---

## ansible.cfg 

PowerODBA's `playbooks/ansible.cfg` is shared, so the migration doesn't change it. Instead:

| Setting | How the migration handles it |
|---|---|
| Login user | `ansible_user=oracle` in `[mig:vars]` |
| Inventory | Pass `-i inventory.yml` on every command |
| Vault password | Pass `--vault-password-file ~/.vault_pass` on every command (or `--ask-vault-pass` when running interactively). Without it, even `--syntax-check` fails with *"Attempting to decrypt but no vault secrets found"* |
| Python interpreter | PowerODBA sets `/usr/bin/python`; `[mig:vars]` overrides it with `/usr/bin/python3` (RHEL 8 has no `/usr/bin/python` by default) |
| `remote_tmp` | PowerODBA uses `~/.ansible/tmp`, so each login user (here oracle) gets its own temp directory — nothing to change |
| Output format, task timings, separate log file | Not set. Add them for a single run if wanted: `ANSIBLE_STDOUT_CALLBACK=yaml`, `ANSIBLE_CALLBACKS_ENABLED=timer,profile_tasks`, `ANSIBLE_LOG_PATH=/tmp/m5_migration_ansible.log` |

---

## Prerequisites

The collection **checks** these and stops with a fix-it message — it doesn't install or fix them.

1. **Oracle 19c Enterprise Edition ≥ 19.18** installed and running on both source (x86, Little-Endian) and destination (AIX, Big-Endian). Both databases in **ARCHIVELOG** mode; the destination database already created and **OPEN**.
2. **Matching character set, NCHAR character set and timezone file version** on both databases — there is no automated fix for a mismatch.
3. **DataPump Bundle Patch 38170982 applied by hand** (`opatch apply` + `datapatch`) on both hosts before prechecks. The patch ID is specific to your Release Update — set `datapump_patch_id` to match.
4. **Bugfix 35564253 on the destination**, unless the RU is ≥ 19.27 (which already includes it). If the source uses TDE: bugfix 30817822 (or RU ≥ 19.20). If backing up from a physical standby: bugfix 35675516.
5. **DBMIG 5.1 ZIP** from MOS Doc 2999157.1, staged at `roles/mig_prechecks/files/DBMIG_5.1.zip`. It's Oracle-proprietary, so `.gitignore` keeps it out of the repository.
6. **Controller:** Ansible ≥ 2.14, Python ≥ 3.9, and the `ansible.posix` collection (listed in `collections/requirements.yml`).
7. **Database hosts:** `/usr/bin/python3` on both (or change `ansible_python_interpreter` in `[mig:vars]`), and `/bin/bash` on AIX — the vendor `impdp.sh` needs bash.
8. **oracle OS user** reachable over SSH from the controller on both hosts. Prechecks sets up source ↔ destination SSH equivalence itself.
9. **If the source uses TDE:** export the keystore keys and import them on the destination by hand, then `touch /u01/m5/done/tde_keys_transferred.done` on the source.

---

## Quick start

```bash
cd <collection>/playbooks

# 1. Install the collection dependency
ansible-galaxy collection install -r ../collections/requirements.yml

# 2. Put the source and destination hosts into [mig_source] / [mig_destination]
vi inventory.yml

# 3. Edit the migration settings — SIDs, Oracle homes, topology, tablespace list, paths
vi vars/m5_migration/mig_vars.yml

# 4. Set the real SYS / SYSTEM passwords, then encrypt the file
vi vars/m5_migration/mig_vault.yml       # vault_sys_password / vault_system_password
ansible-vault encrypt vars/m5_migration/mig_vault.yml

# 5. Create the vault password file on the controller
echo "YourVaultPassword" > ~/.vault_pass && chmod 600 ~/.vault_pass

# 6. Confirm the hosts resolve and the playbook parses
ansible-inventory -i inventory.yml --graph mig
ansible-playbook m5_migration.yml -i inventory.yml --syntax-check --vault-password-file ~/.vault_pass
```

---

## Nohup runbook

All steps are **tag-based** and run from `playbooks/`:

```bash
# ── Step 1: Pre-checks & preparation (once) ─────────────────────────────────
nohup ansible-playbook m5_migration.yml -i inventory.yml --tags prechecks \
      --vault-password-file ~/.vault_pass > /tmp/m5_01_prechecks.out 2>&1 &
tail -f /tmp/m5_01_prechecks.out

# ── Step 2: L0 baseline backup + restore (once, no downtime) ────────────────
nohup ansible-playbook m5_migration.yml -i inventory.yml --tags rman_l0 \
      --vault-password-file ~/.vault_pass > /tmp/m5_02_rman_l0.out 2>&1 &
tail -f /tmp/m5_02_rman_l0.out

# ── Step 3: L1 incremental (repeat until cutover, no downtime) ──────────────
nohup ansible-playbook m5_migration.yml -i inventory.yml --tags rman_l1 \
      --vault-password-file ~/.vault_pass > /tmp/m5_02_rman_l1.out 2>&1 &
tail -f /tmp/m5_02_rman_l1.out

# ── Step 4: L1F final cutover  *** DOWNTIME WINDOW *** ──────────────────────
nohup ansible-playbook m5_migration.yml -i inventory.yml --tags rman_l1f \
      --vault-password-file ~/.vault_pass > /tmp/m5_03_cutover.out 2>&1 &
tail -f /tmp/m5_03_cutover.out

# ── Step 5: Go live — drop the guaranteed restore point (manual, after sign-off)
ansible-playbook m5_migration.yml -i inventory.yml --tags golive_drop_restore_point --ask-vault-pass
```

- `--ask-vault-pass` can't prompt under `nohup`, so the background steps use `--vault-password-file`.
- Step 5 is tagged `never` and only runs when you name its tag. It's irreversible — it removes the flashback restore point you'd roll back to — so run it only once the migrated database is accepted.
- **The cutover's confirmation pause doesn't wait under `nohup`.** Ansible logs *"Not waiting for response to prompt as stdin is not interactive"* and carries on, so make sure every user is disconnected **before** launching step 4.
- Running without `--tags` runs steps 1–4 in one go — fine for a test, not for production, where L1 repeats and L1F needs a chosen maintenance window.

### Re-running a stage

Prechecks and L0 each write a done-file to `done_dir` (`/u01/m5/done`) **on the source host** when they succeed; running the same tag again prints "already completed" and does nothing. Delete the file on the source to force a re-run. L1 has no gate and is meant to run repeatedly. L1F writes `rman_l1f.done` when it finishes, but nothing checks it.

A missing `prechecks.done` means the next prechecks run does everything again for real — including replacing the destination USERS tablespace — so delete done-files deliberately.

---

## Downtime window

| Event | What happens |
|-------|-------------|
| Confirmation pause | Asks you to confirm users are disconnected (doesn't wait under `nohup`) |
| `dbmig_driver_m5.sh L1F` starts | Transport tablespaces set **READ ONLY** on source → **DOWNTIME STARTS** |
| L1F RMAN restore completes on destination | Destination datafiles caught up to the final incremental |
| `impdp.sh` completes on destination | Full Transportable import finished; a guaranteed restore point (`before_imp_<timestamp>`) is created |
| `verify_migration_correctness.yml` | Source vs destination table counts compared — the run stops here on a mismatch |
| `set_tablespaces_readwrite.yml` | All transport tablespaces set **READ WRITE** on destination → **DOWNTIME ENDS** |
| `restore_source_tablespaces.yml` | Source tablespaces back to READ WRITE (best effort), so the source stays usable as a fallback |

Downtime covers only the final L1F incremental and the metadata import, so its length depends mostly on how much changed since the last L1 run.

---

## Variables — `playbooks/vars/m5_migration/mig_vars.yml`

All migration settings are in one file, in this section order. Within each section, mandatory variables come first and optional ones are marked *Optional*.

| Section | Key variables |
|---------|--------------|
| **Database Identity** | `source_oracle_sid`, `dest_oracle_sid`, `listener_port`, `source_oracle_home`, `dest_oracle_home`, `db_create_file_dest`, `dest_oracle_home_gi` (Optional — ASM only; blank skips the GI check) |
| **Host Identity** | `dest_user`, `source_user` — host addresses come from `inventory.yml`, not this file |
| **File Transfer** | `shared_filesystem`, `scp_transfer_timeout` (Optional) |
| **Migration Working Directories** | `done_dir` (on the source), `precheck_report_dir` (controller), `m5_workdir`, `m5_dumpdir`, `m5_backupdir` (identical path on both hosts), `dest_workdir`, `dest_dpdmp`, `validation_report_dir` (controller) |
| **Topology** | `mig_pdb`, `pdb_name`, `dest_cdb_sid`, `dest_pdb_name` — selects Non-CDB→Non-CDB, Non-CDB→PDB or PDB→PDB |
| **Tablespaces to Migrate** | `m5_tablespace_list_items` — every tablespace except SYSTEM, SYSAUX, UNDO, TEMP |
| **RMAN / DBMIG Parameters** | `rman_channels`, `rman_section_size`, `rman_timeout_l0/l1/l1f`, `rman_poll`, `lock_file`, `bkp_dest_type`, `bkp_dest_parm`, `rman_log_benign_patterns` (Optional) |
| **DataPump Parameters** | `impdp_timeout`, `impdp_poll`, `source_dpdmp`, `dp_parallel` (keep 1 on 19c), `dp_enc_prompt`, `dp_trace` |
| **Credentials** | `sys_password`, `system_password` — both read from `mig_vault.yml` |
| **DBMIG misc / Utility** | `remove_ts_quote`, `bkp_from_stdby`, `rman_debug`, `rman_scan`, `cat_cred`, `dbmig_zip` |
| **DataPump Bundle Patch** | `datapump_patch_id` — version-specific, edit per environment |
| **Application Schema** | `app_schema` — used for stats gathering and the table-count checks |
| **Computed Values — Do Not Edit** | `dest_host_effective`, `dest_oracle_sid_effective`, `dest_connect_string_effective`, `src_scan`, `m5_tablespace_list` |

Precheck and validation reports are both written on the controller, to `/home/ansible/m5_migration/reports` by default (`precheck_report_dir`, `validation_report_dir`).

Fixed values that shouldn't change per environment live in the roles' `defaults/main.yml`: the standalone bugfix patch IDs (`bugfix_patch_id`, `tde_bugfix_patch_id`, `stdby_bugfix_patch_id`), disk/memory thresholds, `system_usr` and the TDE marker path in `mig_prechecks`; `impdp_run_mode` in `mig_rman_l1f`.

### Vault variables — `playbooks/vars/m5_migration/mig_vault.yml`
```yaml
vault_sys_password:    "..."
vault_system_password: "..."
```
This is separate from PowerODBA's own `vars/vault.yml`, which the migration doesn't read.

---

## Role details

### `mig_prechecks`
Runs once, skipped when `prechecks.done` exists. Tasks in sequence:
1. `os_checks_source.yml` — endian (Little), version ≥ 19.18, Enterprise Edition, ARCHIVELOG, charset/timezone/compatible facts, RMAN encryption off, TDE detection, network to destination, disk, memory
2. `os_checks_dest.yml` — Oracle and GI homes, DB open, endian (Big), version, ARCHIVELOG, compatible ≥ source, charset/NCHAR/timezone match the source, M5 directories, disk, memory, reverse connectivity
3. `patch_apply_source.yml` — **checks** patch 38170982 is applied on the source (`opatch lsinventory`); never applies it
4. `patch_apply_dest.yml` — **checks** patch 38170982, bugfix 35564253 (skipped when RU ≥ 19.27), and the TDE/standby bugfixes when relevant
5. `ssh_equivalence.yml` — keygen, key push only if needed, assert oracle SSH in both directions
6. `db_prepare_source.yml` — streams_pool, audit_trail, Block Change Tracking (path from `orabase`), USERS tablespace report, DBMS_TTS self-containment check, M5DIR/DATA_PUMP_DIR, RMAN config
7. `db_prepare_dest.yml` — db_create_file_dest, USERS → USERS_DEF replacement, streams_pool, M5DIR/DATA_PUMP_DIR, SYS/SYSTEM dictionary stats
8. `deploy_dbmig.yml` — M5 directory tree on both hosts, copy + unzip DBMIG to both, `dbmig_driver.properties`, tablespace list
9. `generate_report.yml` — `precheck_<source-host>.txt` in `precheck_report_dir` on the controller

### `mig_rman_l0_l1`
Single role, tag-selected level:
- `--tags rman_l0` → `rman_level: L0` (full baseline, run once — gated by `rman_l0.done`)
- `--tags rman_l1` → `rman_level: L1` (incremental, repeat — no gate)

Flow: lock-check → backup (source) → verify log → get cmdfile → copy backup pieces → restore (destination) → verify log

### `mig_rman_l1f`
Combined cutover role:
1. Confirmation pause, lock check, L1F backup (source) — sets tablespaces READ ONLY → **DOWNTIME STARTS**
2. Verify backup log, get restore cmdfile, copy backup pieces, capture the Data Pump dump file
3. L1F restore (destination) and restore-log check
4. Pre-import checks (L0 + L1F restore logs present, dump file known, `impdp.sh` exists)
5. Data Pump Full Transportable import (`impdp.sh`, run with bash)
6. Verify import (informational ORA-/KUP- scan, DB OPEN check, restore point lookup)
7. `verify_migration_correctness.yml` — source vs destination table counts; hard stop on mismatch
8. Set all transport tablespaces READ WRITE on destination → **DOWNTIME ENDS**
9. Restore source tablespaces READ WRITE
10. `utlrp.sql` recompile (with before/after invalid count)
11. `DBMS_STATS.GATHER_SCHEMA_STATS` for `app_schema`
12. Validation report (table counts, tablespace status, invalid objects, DB size)
13. Go live (separate run, `--tags golive_drop_restore_point`) — drops the guaranteed restore point after a confirmation

---

## Troubleshooting

- **Logs:** playbook output in `/tmp/m5_*.out` on the controller; RMAN and DBMIG logs in `/u01/m5/log` on each host.
- **"The inventory doesn't define the migration hosts"** — run from `playbooks/` with `-i inventory.yml`, and keep exactly one host in each of `[mig_source]` and `[mig_destination]`.
- **"Attempting to decrypt but no vault secrets found"** — add `--vault-password-file ~/.vault_pass` (or `--ask-vault-pass`); PowerODBA's `ansible.cfg` doesn't set a vault password file.
- **"Failed to create temporary directory"**, reported as `UNREACHABLE` although SSH works — `remote_tmp` points at a directory the oracle user can't write to. This happens when `ansible.cfg` sets a shared path such as `/tmp/.ansible` and another user (for example root, mode `drwx------`) created it first. Keep `remote_tmp = ~/.ansible/tmp` in `ansible.cfg`, or give the migration hosts their own temp directory by adding this line to `[mig:vars]` in `inventory.yml`:
  ```ini
  ansible_remote_tmp=~/.ansible/tmp
  ```
- **Python "not found" on a host** — change `ansible_python_interpreter` in `[mig:vars]` to that host's Python 3, or to `auto_silent` to let Ansible detect it.
- **RMAN restore fails with "censored" output** — PDB→PDB restores run with `no_log` because the connect string carries the SYS password. Read the restore log in `/u01/m5/log` on the destination.
- **Sessions hang on "log file switch (archiving needed)"** — the FRA quota (`db_recovery_file_dest_size`) is full. Check `v$recovery_file_dest` before starting L0.

For a failed L0, L1 or L1F, reset fully before retrying: clear RMAN datafile copies on the destination (`CROSSCHECK` / `DELETE DATAFILECOPY ALL`), empty `/u01/m5` on both hosts (this also removes the done-files), remove old `/tmp/m5_*.out` output, then restart from prechecks.

---

## Reference

- [Oracle MOS Doc 2999157.1](https://support.oracle.com/epmos/faces/DocumentDisplay?id=2999157.1) — M5 cross-endian migration and DBMIG 5.1 download
- [IBM ansible-power-aix-oracle-dba](https://github.com/IBM/ansible-power-aix-oracle-dba) — the PowerODBA collection
