# Gather Grid Infrastructure Facts

## Description

This module gathers comprehensive, **read-only inventory and operational facts** about an Oracle Grid Infrastructure environment (Standalone / Oracle Restart or Real Application Clusters - RAC) on IBM AIX / Linux hosts using the `oracle_gi_facts` module.

Because Grid Infrastructure operations interact directly with the local cluster stack, daemons (`crsd`, `has`, `cssd`, `evmd`), ASM instance, and binaries on the target host, this playbook executes via **SSH against the target host** as the Grid Infrastructure owner (e.g. `grid` or `oracle`).

It gathers and reports on the following key areas:

1. **Cluster & GI Version Status** — Cluster name, release version, Grid Home path, and cluster type (Clusterware / RAC vs Oracle Restart / Standalone).
2. **Applied GI Patches (OPatch)** — Inventory of applied Release Updates, One-offs, and Interim Patches with patch IDs and descriptions (`$GRID_HOME/OPatch/opatch lspatches`).
3. **Grid & Cluster Resource Status** — Tabular runtime status of local and cluster resources (`crsctl stat res -t`).
4. **Network & VIP Configuration (RAC Only)** — Configured cluster networks and VIP endpoints (`srvctl config network`, `srvctl config vip`). Automatically skipped on Single-Instance / Oracle Restart.
5. **SCAN & SCAN Listeners (RAC Only)** — Single Client Access Name (SCAN) addresses, VIPs, and SCAN listener endpoints (`srvctl config scan`, `srvctl config scan_listener`). Automatically skipped on Single-Instance / Oracle Restart.
6. **Local Listeners** — Local listener names, types, network bindings, and TCP endpoints (`srvctl status listener`, `srvctl config listener`).
7. **Registered Databases** — All databases registered in Grid Infrastructure / Oracle Restart (`srvctl config database`).
8. **ASM Status & Diskgroups** — ASM instance running status and mounted diskgroup metrics with state, redundancy type, total size, free space, usable file space, free percentage, and voting disk placement (`asmcmd lsdg`).

---

## Files to Update

| File | Purpose |
|------|---------|
| `playbooks/vars/gather-gifacts-vars.yml` | Oracle Grid Infrastructure Home path on target AIX LPAR |
| `playbooks/inventory.yml` | Target host entry (`pilotdb` or RAC cluster hosts) |

---

## Step 1 — Update `vars/gather-gifacts-vars.yml`

```yaml
# Gather Grid Infrastructure Facts - Variables section
grid_home: /u01/19c/grid/home       # Oracle Grid Infrastructure Home path on target AIX LPAR (e.g. /u01/19c/grid/home)
```

---

## Step 2 — Review the Playbook (`gather-gi-facts.yml`)

```yaml
# Playbook to gather facts about Oracle Grid Infrastructure (Standalone or RAC).
# Before executing this playbook, please refer to the documentation inside the collection docs directory.
#
- name: Gather Grid Infrastructure Facts
  hosts: pilotdb
  remote_user: grid
  gather_facts: true
  vars_files:
    - vars/gather-gifacts-vars.yml
  roles:
    - { role: oradb_gather_gifacts }
```

---

## Step 3 — Execute the Playbook

```bash
cd playbooks
ansible-playbook gather-gi-facts.yml -i inventory.yml
```

### Verified Execution Output (Oracle Restart / Standalone ASM)

```
PLAY [Gather Grid Infrastructure Facts] ***********************************************************************************************

TASK [Gathering Facts] ****************************************************************************************************************
ok: [pilotdb]

TASK [oradb_gather_gifacts : Return GI facts] *****************************************************************************************
ok: [pilotdb]

TASK [oradb_gather_gifacts : 1. Cluster & GI Version Status] **************************************************************************
ok: [pilotdb] => {
    "msg": [
        "Cluster Name: ORACLE_RESTART",
        "GI Version: 19.0.0.0.0",
        "Grid Home: /u01/19c/grid/home",
        "Clusterware: False"
    ]
}

TASK [oradb_gather_gifacts : 2. Applied GI Patches (OPatch)] **************************************************************************
ok: [pilotdb] => {
    "gifacts.ansible_facts.oracle_gi_facts.patches": [
        {
            "description": "TOMCAT RELEASE UPDATE 19.0.0.0.0 (39107855)",
            "patch_id": "39107855"
        },
        {
            "description": "DBWLM RELEASE UPDATE 19.0.0.0.0 (39107825)",
            "patch_id": "39107825"
        },
        {
            "description": "ACFS RELEASE UPDATE 19.31.0.0.0 (39055473)",
            "patch_id": "39055473"
        },
        {
            "description": "OCW RELEASE UPDATE 19.31.0.0.0 (39039430)",
            "patch_id": "39039430"
        },
        {
            "description": "Database Release Update : 19.31.0.0.260421 (REL-APR2026) (39034528)",
            "patch_id": "39034528"
        }
    ]
}

TASK [oradb_gather_gifacts : 3. Grid & Cluster Resource Status (crsctl stat res -t)] **************************************************
ok: [pilotdb] => {
    "gifacts.ansible_facts.oracle_gi_facts.resource_status": [
        "--------------------------------------------------------------------------------",
        "Name           Target  State        Server                   State details",
        "--------------------------------------------------------------------------------",
        "Local Resources",
        "--------------------------------------------------------------------------------",
        "ora.DATA.dg",
        "               ONLINE  ONLINE       pilotdb                  STABLE",
        "ora.LISTENER.lsnr",
        "               ONLINE  ONLINE       pilotdb                  STABLE",
        "ora.asm",
        "               ONLINE  ONLINE       pilotdb                  Started,STABLE",
        "ora.ons",
        "               OFFLINE OFFLINE      pilotdb                  STABLE",
        "--------------------------------------------------------------------------------",
        "Cluster Resources",
        "--------------------------------------------------------------------------------",
        "ora.cssd",
        "      1        ONLINE  ONLINE       pilotdb                  STABLE",
        "ora.devdb.db",
        "      1        ONLINE  ONLINE       pilotdb                  Open,HOME=/stage/db,",
        "                                                             STABLE",
        "ora.diskmon",
        "      1        OFFLINE OFFLINE                               STABLE",
        "ora.evmd",
        "      1        ONLINE  ONLINE       pilotdb                  STABLE",
        "--------------------------------------------------------------------------------"
    ]
}

TASK [oradb_gather_gifacts : 4. Network & VIP Configuration] **************************************************************************
skipping: [pilotdb]

TASK [oradb_gather_gifacts : 5. SCAN & SCAN Listeners] ********************************************************************************
skipping: [pilotdb]

TASK [oradb_gather_gifacts : 6. Local Listeners] **************************************************************************************
ok: [pilotdb] => {
    "gifacts.ansible_facts.oracle_gi_facts.local_listener": [
        {
            "endpoints": "TCP:1521",
            "name": "LISTENER",
            "tcp": "1521",
            "type": "Database Listener"
        }
    ]
}

TASK [oradb_gather_gifacts : 7. Registered Databases] *********************************************************************************
ok: [pilotdb] => {
    "gifacts.ansible_facts.oracle_gi_facts.database_list": [
        "devdb"
    ]
}

TASK [oradb_gather_gifacts : 8. ASM Status & Diskgroups] ******************************************************************************
ok: [pilotdb] => {
    "msg": [
        "ASM Status: ['ASM is running on pilotdb']",
        "ASM Diskgroups (asmcmd lsdg): [{'name': 'DATA', 'state': 'MOUNTED', 'type': 'EXTERN', 'total_mb': 102400, 'free_mb': 95620, 'usable_file_mb': 95620, 'pct_free': 93.38, 'voting_files': 'N'}]"
    ]
}

PLAY RECAP ****************************************************************************************************************************
pilotdb                    : ok=8    changed=0    unreachable=0    failed=0    skipped=2    rescued=0    ignored=0
```

---

## Manual Verification Commands

You can verify the gathered GI facts directly on the AIX host:

```bash
# Check OPatch release updates
export ORACLE_HOME=/u01/19c/grid/home
$ORACLE_HOME/OPatch/opatch lspatches

# Check Grid / HAS resource status
$ORACLE_HOME/bin/crsctl stat res -t

# Check ASM Diskgroups
export ORACLE_SID=+ASM
$ORACLE_HOME/bin/asmcmd lsdg

# Check Registered Databases and Listeners
$ORACLE_HOME/bin/srvctl config database
$ORACLE_HOME/bin/srvctl status listener
```
