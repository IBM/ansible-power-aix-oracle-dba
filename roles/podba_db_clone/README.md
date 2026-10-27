# podba_db_clone

Clones a database with RMAN `DUPLICATE`, either `FROM ACTIVE DATABASE` or from a backup location.

- Playbook: `playbooks/db-clone.yml`, vars: `playbooks/vars/db-clone-vars.yml`
- Documentation: `docs/Readme-DB-Clone.md`
- To clone a PDB inside a CDB use `oradb_manage_pdb` with `clone_pdb: true`.
