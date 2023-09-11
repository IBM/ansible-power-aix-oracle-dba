# Readme to download patches from My Oracle Support

- Ported from https://github.com/oravirt/ansible-oracle
- Author: bartowl <github@bartowl.eu>
- Works with Ansible 2.10 and higher.

# Changes from the original version:

- Uses Patchid & Oracle Version instead of Patch filename.

# Prerequisites:
- Needs Patch ID & Oracle Version to download the patches.
- Go to the collections directory and update vault.yml file under playbooks/vars directory.

```
# Provide MOS Username & Password here

mos_login:
mos_password:
```

- Encrypt the vault.yml file using ansible-vault

```
ansible_vault encrypt vault.yml
```
 
- Go to the collections directory and update vars.yml file under playbooks/vars directory as shown below. 
```
# Provide Patch ID, Patch Version and path to store the patch patch files to get started.

oracle_patch_download_dir: /home/ansible/patches           # Path on local/remote host to save the patch files.
oracle_sw_patches:                     # Provide the patchid & relevant version as a list shown below.
      - patchid: 34762026              # Patch ID 1. Example: This is a 19.18 Release Update patch.
        version: 1900                  # To download this patch, mention 1900 in the version field.
      - patchid: 28676706              # Patch ID 2. This patch is available for multiple Release Updates.
        version: 1916                  # To download this patch for version 19.16, mention 1916 in the version field.
      - patchid: 28676706              # Patch ID 2. This patch is available for multiple Release Updates.
        version: 1919                  # To download this patch for version 19.19, mention 1919 in the version field.
      - patchid: 28676706              # Patch ID 2. This patch is available for multiple Release Updates.
        version: 1900                  # To download this patch for version 19.0.0, mention 1900 in the version field.
```
- Update the playbook download_patch.yml with either local/remote host & user details.

```
# Playbook to download patches from My Oracle Support
# Supported to download single and multiple patches in one go.
# Supported ansible version is 2.10 and higher.

- hosts: localhost              # Provide the hostname from the ansible inventory onto which the patches needs to be downloaded. Either localhost or remote host.
  remote_user: ansible          # Username of the local/remote host where passwordless ssh is setup.
  gather_facts: False
  vars_files:
     - vars/vault.yml       # Set your MOS credentials in this file. Make sure to encrypt this file using Ansible Vault.
     - vars/vars.yml            # This file contains all the required variables. Update this file with required patchid and versions.
  roles:
     - role: orasw_download_patches
```

- Execute the playbook

```
ansible-playbook download_mos_patch.yml --ask-vault-pass
```
