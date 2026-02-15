# Hard Link Deployment Trap (Vagrant)

**Difficulty:** Intermediate-Advanced
**Category:** Deployment / Configuration Management
**Time estimate:** 20-25 minutes

## Scenario

Your deployment system uses hard links to rotate config files atomically. When a deployment of v2.0.0 with a broken config crashes the app, the engineer tries to roll back to v1.0.0. But the rollback doesn't work — the app still crashes with the same error.

The problem: hard links share the same inode. When the broken v2 config was deployed using hard links, it overwrote the v1 inode. Now "rolling back" to v1 just creates another hard link to the corrupted data.

## Prerequisites

- [Vagrant](https://www.vagrantup.com/downloads) >= 2.0
- **For Apple Silicon (ARM) Macs:**
  ```bash
  brew install --cask vmware-fusion
  vagrant plugin install vagrant-vmware-desktop
  ```
- **For Intel Macs / Linux / Windows:**
  - [VirtualBox](https://www.virtualbox.org/wiki/Downloads) >= 6.0

- Basic understanding of filesystems and inodes

## Setup

```bash
./setup.sh
```

This creates a VM with a Python app that reads a JSON config file, deploys v1 successfully, attempts to deploy broken v2, and then attempts a rollback that fails due to hard link semantics.

## Your Task

1. SSH into the VM: `vagrant ssh`
2. Examine the config files and their inodes:
   ```bash
   cd /home/vagrant/configs
   ls -li
   cat config.v1.json config.v2.json
   ```
3. Understand why the rollback didn't restore v1 behavior
4. Fix the config files to have proper v1 and v2 separation
5. Restart the app with a working v1 config
6. Run `./verify.sh` to confirm

## Hints

<details>
<summary>Hint 1</summary>
Use <code>ls -li</code> in the <code>configs/</code> directory to see inode numbers. If two files have the same inode, they're hard links pointing to the same data.
</details>

<details>
<summary>Hint 2</summary>
Hard links are different from symlinks. When you edit one hard-linked file, you're modifying the inode itself, so ALL hard links to that inode see the change.
</details>

<details>
<summary>Hint 3</summary>
To fix: delete the corrupted files, recreate proper v1 and v2 configs as separate files (with different inodes), then link or copy v1 to <code>app/config.json</code>.
</details>

## Cleanup

```bash
./teardown.sh
```
