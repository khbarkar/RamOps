# Hard Link Deployment Trap (Lima)

**Difficulty:** Intermediate-Advanced
**Category:** Deployment / Configuration Management
**Time estimate:** 20-25 minutes

## Scenario

You're on-call when alerts fire: the production app server has crashed and won't restart. Looking at the deployment logs, you see:

- v1.0.0 was deployed successfully yesterday using hard links
- v2.0.0 was deployed 30 minutes ago (also using hard links)
- The v2 deployment had a broken config file with invalid JSON
- The app crashed immediately after v2 went live
- An engineer attempted to roll back to v1.0.0 by re-linking config.v1.json
- The rollback failed - the app still crashes with the same JSON parse error

Your task: figure out why the rollback didn't work and get the app running again with the v1.0.0 config.

## Prerequisites

- [Lima](https://lima-vm.io/) (installed via Homebrew)
- Basic understanding of filesystems and inodes

## Setup

Run setup from the TUI or:
```bash
./setup-lima.sh
```

This creates a VM with a crashed Python web app. The app reads /opt/app/config.json on startup. The systemd service is trying to restart but failing because the config is invalid JSON.

## Your Task

1. SSH into the VM: `limactl shell lima-app-server`
2. Check the app status: `systemctl status app.service`
3. Examine the config files in /opt/configs
4. Figure out why the rollback to v1.0.0 didn't work
5. Fix the configuration and get the app running with v1.0.0
6. Verify it's running: `systemctl status app.service`
7. Run verify from the TUI to confirm the fix

## Hints

Hint 1: Use ls -li in the /opt/configs/ directory to see inode numbers. If two files have the same inode, they're hard links pointing to the same data.

Hint 2: Hard links are different from symlinks. When you edit one hard-linked file, you're modifying the inode itself, so ALL hard links to that inode see the change.

Hint 3: To fix: delete the corrupted files, recreate proper v1 and v2 configs as separate files (with different inodes), then link or copy v1 to /opt/app/config.json.

## Cleanup

Run teardown from the TUI or:
```bash
./teardown-lima.sh
```
