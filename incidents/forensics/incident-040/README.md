# Log Tampering

**Difficulty:** Intermediate
**Category:** Forensics
**Time estimate:** 30-40 minutes

## Scenario

Your security team received an alert about a potential breach last night at 2:47 AM. When you check the logs to investigate, you find gaps in the timeline. Auth logs show normal activity, then suddenly jump from 2:30 AM to 3:15 AM with no entries in between.

The attacker has tampered with the logs to cover their tracks. You need to find evidence of what happened and recover any deleted log data.

## Prerequisites

- [Lima](https://lima-vm.io/) for VM management
- 2GB+ RAM free

## What You'll Learn

- Detecting log tampering
- Finding deleted but open log files
- Analyzing filesystem timestamps
- Log integrity verification
- Recovering deleted logs
- Implementing log protection

## Setup

```bash
./setup-lima.sh
```

This creates a compromised VM with tampered logs.

## Your Task

1. SSH into the system: `limactl shell lima-logtamper`
2. Investigate the missing log entries
3. Find evidence of log tampering
4. Recover deleted log data if possible
5. Determine what the attacker was hiding

## Hints

Hint 1: Check for gaps in log files: `sudo ls -lh /var/log/auth.log*` and look at file sizes and timestamps. Compare modification times with expected log rotation.

Hint 2: Look for deleted files that are still open by processes: `sudo lsof +L1 | grep deleted`. If a process has a log file open and it was deleted, you can still read it from `/proc/[PID]/fd/`.

Hint 3: Check filesystem timestamps on log files: `sudo stat /var/log/auth.log /var/log/syslog`. Look for suspicious modification times (mtime) that don't match change times (ctime).

Hint 4: Search for evidence of log clearing commands in bash history: `sudo cat /root/.bash_history /home/*/.bash_history | grep -E "rm.*log|truncate|shred|>/var/log"`.

Hint 5: Check journal logs which are harder to tamper with: `sudo journalctl --since "2 hours ago" --until "now"`. Compare with text logs to find discrepancies.

Hint 6: Look for backup or rotated logs that might not have been deleted: `sudo ls -la /var/log/*.gz /var/log/*.1 /var/log/archive/`.

Hint 7: Check for log entries about the attacker's actions in other logs they might have missed: `sudo grep -r "sudo\|su\|ssh" /var/log/ 2>/dev/null | grep -v "Binary"`.

Hint 8: Examine wtmp and utmp for login records: `last -f /var/log/wtmp`, `lastlog`. These binary files are harder to edit cleanly.

Hint 9: If logs were deleted but the file descriptor is still open, recover with: `sudo ls -l /proc/*/fd/* 2>/dev/null | grep deleted | grep log` then `sudo cat /proc/[PID]/fd/[FD] > recovered.log`.

Hint 10: To prevent future tampering: Use remote syslog server, enable log immutability with `chattr +a`, implement log signing, use auditd for tamper-evident logging, monitor log file integrity with AIDE or Tripwire.

## Cleanup

```bash
./teardown-lima.sh
```

## Production Parallels

This scenario mirrors:
- Attackers covering tracks by deleting logs
- Importance of centralized logging
- Need for log integrity protection
- Forensic recovery of deleted data
- Log retention and backup strategies
- Compliance requirements for log preservation
