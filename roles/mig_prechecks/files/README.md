# roles/mig_prechecks/files/

Place the Oracle DBMIG utility zip here before running the `prechecks` tag.

`deploy_dbmig.yml` copies `{{ dbmig_zip }}` (default: `DBMIG_5.1.zip`, see
`playbooks/vars/m5_migration/mig_vars.yml`) from this directory to both the source and destination
hosts and unzips it.

DBMIG.zip is Oracle-proprietary and is **not** distributed with this
collection. Download it per MOS Doc 2999157.1 ("M5 Cross Endian Platform
Migration using Full Transportable Data Pump Export/Import and RMAN
Incremental Backups"), step "1. Preparation" — Download DBMIG.zip
(md5sum 24b5acb9e7cbe600de7547faf1e86962) — and place it here, named to
match `dbmig_zip` in `playbooks/vars/m5_migration/mig_vars.yml`.

`deploy_dbmig.yml` asserts this file exists before attempting the copy, so
prechecks will fail early with a clear message if it is missing.
