# Download Patches from My Oracle Support - Readme
# ================================================
# Description: This module can download multiple patches from My Oracle support. Must be provided with Patch ID and Oracle release versions.

In the following example we're going to download two patches, one for Oracle RDBMS and the other for Oracle E-Business Suite.

1. There are two files which need to be updated:
        a. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/patch-download-vars.yml: This file contains patch download path, patch id and relevant version.
        b. {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/vault.yml: This contains the My Oracle support username and password.

2. Update the common variables file: {{collection_dir}}/power_aix_oracle_dba/playbooks

oracle_patch_download_dir: /tmp/patches           # Path to save the patch files.
oracle_sw_patches:                    # Provide the patchid & relevant version as a list shown below.
      - patchid: 28676706             # Patch ID 1. Example: This is a one off patch for 19.19 RU version.
        version: 1919                 # To download this patch, mention 1919 in the version field.
      - patchid: 33672402             # Patch ID 2. Example: This is an Oracle E-Business Suite Technology Stack patch.
        version: R12                  # For EBS, mention the version as R12.

3. Update the passwords file: {{ collection_dir }}/power_aix_oracle_dba/playbooks/vars/vault.yml with MOS username and password. This file must to be encrypted using ansible-vault. While running the playbook, provide the vault password.

mos_login: 			# MOS Username
mos_password:			# MOS Password

4. Encrypt the passwords file using ansible-vault as shown below
$ ansible-vault encrypt vars/vault.yml
New Vault password:
Confirm New Vault password:
Encryption successful

5. Execute the playbook as shown below

$ cat patch_download.yml

- hosts: localhost             # Provide the hostname to which the patches needs to be downloaded. Either localhost or remote host.
  remote_user: oracle          # Username of the remote host in case you are downloading to remote hosts.
  gather_facts: False
  vars_files:
     - vars/vault.yml          # Set your MOS credentials in this file. Make sure to encrypt this file using Ansible Vault.
     - vars/patch-download-vars.yml            # Update this file with the required patchid and Oracle versions.
  roles:
     - { role: orasw_download_patches }

$ ansible-playbook patch_download.yml --ask-vault-pass
Vault password:
[WARNING]: provided hosts list is empty, only localhost is available. Note that the implicit localhost does not match 'all'

PLAY [localhost] **********************************************************************************************************************

TASK [orasw_download_patches : Check if credentials are known] ************************************************************************
ok: [localhost] => {
    "changed": false,
    "msg": "All assertions passed"
}

TASK [orasw_download_patches : Ensure destination directory exists] *******************************************************************
changed: [localhost]

TASK [orasw_download_patches : Login to Oracle] ***************************************************************************************
ok: [localhost]

TASK [orasw_download_patches : Get URL List] ******************************************************************************************
ok: [localhost] => (item=28676706  ARU=25176896 )
ok: [localhost] => (item=33672402  ARU=24547278 )

TASK [orasw_download_patches : Get ARU] ***********************************************************************************************
ok: [localhost] => (item={'patchid': 28676706, 'version': 1919})
ok: [localhost] => (item={'patchid': 33672402, 'version': 'R12'})

TASK [orasw_download_patches : List ARU] **********************************************************************************************
ok: [localhost]

TASK [orasw_download_patches : Fail When ARU is missing] ******************************************************************************
skipping: [localhost]

TASK [orasw_download_patches : Get Digest checksums] **********************************************************************************
ok: [localhost] => (item=28676706  SHA256:2cf3a9d41bec2e0c9eaf3aff633064e1e037c7e0fe416f39be12b1d48482d21b )
ok: [localhost] => (item=33672402  SHA256:624cdfe86fa56f2d683494ec89ccc11eaf1c21e8fc4aa7a9622ecaaf4538c2d6 )

TASK [orasw_download_patches : Download Patches] **************************************************************************************
changed: [localhost] => (item=28676706)
changed: [localhost] => (item=33672402)

PLAY RECAP ****************************************************************************************************************************
localhost                  : ok=8    changed=2    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0

To execute this playbook from GUI, please refer this link: https://github.com/IBM/ansible-power-aix-oracle-dba/blob/main/docs/PowerODBA_using_AAP2.pdf
