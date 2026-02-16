# Cryptominer Investigation

**Difficulty:** Intermediate-Advanced
**Category:** Forensics
**Time estimate:** 35-45 minutes

## Scenario

Your cloud bill tripled this month. The finance team is asking questions. When you check the servers, CPU usage is at 95% constantly, but when you run `top` or `htop`, you only see normal processes using 10-15% CPU each.

Something is consuming massive CPU resources but hiding from standard monitoring tools. You need to find it and stop it before the next billing cycle.

## Prerequisites

- [Lima](https://lima-vm.io/) for VM management
- 2GB+ RAM free

## What You'll Learn

- Detecting hidden processes
- CPU usage analysis and discrepancies
- Process hiding techniques
- Network traffic analysis
- Cgroup inspection
- Cryptominer detection and removal

## Setup

```bash
./setup-lima.sh
```

This creates a compromised VM with a hidden cryptominer.

## Your Task

1. SSH into the system: `limactl shell lima-cryptominer`
2. Investigate the CPU usage discrepancy
3. Find the hidden mining process
4. Identify what it's mining and where it's sending data
5. Remove the miner and prevent reinfection

## Hints

Hint 1: Run `top` and note the total CPU usage at the top. Then add up the individual process CPU percentages. Do they match? If not, something is hidden.

Hint 2: Check CPU usage from the kernel's perspective: `cat /proc/stat | grep "^cpu "`. Compare this with what monitoring tools show.

Hint 3: List all processes directly from /proc: `ls -la /proc/[0-9]* | head -20`. Look for PIDs that exist in /proc but don't show up in `ps aux`.

Hint 4: Use alternative process listing tools that are harder to compromise: `pstree -p`, `systemctl status`, or read /proc directly: `for pid in /proc/[0-9]*; do echo "$pid: $(cat $pid/cmdline 2>/dev/null)"; done | grep -v "^/proc.*:$"`.

Hint 5: Check cgroup CPU usage: `cat /sys/fs/cgroup/cpu.stat` (cgroup v2) or `systemd-cgtop`. This shows actual CPU consumption that can't be hidden by LD_PRELOAD tricks.

Hint 6: Look for suspicious network connections: `sudo ss -antp` or `sudo lsof -i -P -n`. Cryptominers typically connect to mining pools on ports like 3333, 4444, 8080, or 14444.

Hint 7: Check for processes with suspicious names or running from unusual locations: `sudo find /proc -name exe -exec ls -l {} \; 2>/dev/null | grep -E "/tmp|/dev/shm|/var/tmp"`.

Hint 8: Look at network traffic to identify mining pool: `sudo tcpdump -i any -n port 3333 or port 4444 or port 8080` or check `/proc/net/tcp` for established connections.

Hint 9: Common cryptominer indicators: High CPU usage, connections to known mining pools (xmr-pool, nanopool, etc.), processes named similar to system processes (kworker, systemd-journal), running from /tmp or /dev/shm.

Hint 10: To remediate: Kill the process (`sudo kill -9 PID`), find and remove the binary, check for persistence (cron, systemd services, rc.local, .bashrc), patch the vulnerability that allowed initial access, monitor for reinfection.

## Cleanup

```bash
./teardown-lima.sh
```

## Production Parallels

This scenario mirrors:
- Cryptojacking attacks on cloud infrastructure
- Compromised servers mining cryptocurrency
- Process hiding techniques used by malware
- High cloud bills from unauthorized resource usage
- Need for proper resource monitoring
- Importance of least privilege and patching
