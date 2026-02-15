# The Vanishing Log Files (Lima)

**Difficulty:** Beginner-Intermediate
**Category:** System Administration
**Time estimate:** 15-20 minutes

## Scenario

Alerts fire at 3am: disk usage on the web server is at 95%. You check the logs directory and see the log rotation ran successfully - old logs were "deleted" hours ago. But the disk space was never freed. Running df shows the disk is nearly full, but du shows plenty of space should be available.

Something is holding onto disk space that should have been reclaimed.

## Prerequisites

- [Lima](https://lima-vm.io/) (installed via Homebrew)
- Basic understanding of Linux filesystems

## Setup

Run setup from the TUI or:
```bash
./setup-lima.sh
```

This creates a VM with a web server writing logs. The log rotation system has a bug that's preventing disk space from being freed.

## Your Task

1. SSH into the VM: `limactl shell lima-logserver`
2. Check disk usage: `df -h` and compare with `du -sh /var/log`
3. Find what's consuming the disk space
4. Understand why deleted files aren't freeing space
5. Learn about inodes, hard links, and soft links
6. Fix the issue and free up disk space
7. Run verify from the TUI to confirm the fix

## Hints

Hint 1: When a file is deleted but a process still has it open, the disk space isn't freed until the process closes the file descriptor. Use lsof to find deleted files that are still open.

Hint 2: Check the inode link count with ls -li. If a file has multiple hard links, deleting one name doesn't delete the inode until all links are removed.

Hint 3: Hard links share the same inode. Soft links (symlinks) are separate files that point to a path. If you delete the original file, hard links still work but symlinks break.

Hint 4: The fix involves either restarting the process to release file descriptors, or changing the log rotation strategy to use symlinks and signal the app to reopen files.

## Cleanup

Run teardown from the TUI or:
```bash
./teardown-lima.sh
```
