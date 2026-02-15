# Rootkit Detection

**Difficulty:** Advanced
**Category:** Forensics
**Time estimate:** 40-50 minutes

## Scenario

Your monitoring system shows unusual CPU spikes and network traffic, but when you SSH into the server and run `ps`, `top`, and `netstat`, everything looks normal. A few processes are running, but nothing suspicious.

However, your network IDS detected outbound connections to a known malicious IP address. Something is hiding on this system.

## Prerequisites

- [Lima](https://lima-vm.io/) for VM management
- 2GB+ RAM free

## What You'll Learn

- Detecting rootkit presence
- Comparing system binaries to known-good versions
- Using /proc filesystem for process discovery
- Rootkit detection tools
- System remediation after compromise

## Setup

```bash
./setup-lima.sh
```

This creates a compromised VM where a rootkit is hiding malicious processes.

## Your Task

1. SSH into the system: `limactl shell lima-rootkit`
2. Investigate why monitoring shows activity but system tools show nothing
3. Detect the rootkit and identify what it's hiding
4. Find the malicious processes and network connections
5. Document the compromise and remediate

## Hints

Hint 1: Run `ps aux` and `top`. Notice how few processes are shown? A normal Linux system has 100+ processes. Something is filtering the output.

Hint 2: System commands like `ps`, `netstat`, and `ls` might be compromised. Check their integrity with `rpm -V procps-ng net-tools coreutils` (on RPM systems) or `dpkg -V procps net-tools coreutils` (on Debian).

Hint 3: The `/proc` filesystem is the kernel's view of processes. List `/proc/[0-9]*` directories directly: `ls -la /proc/ | grep "^d" | grep -E "^d.*[0-9]+$"`. Compare this to what `ps` shows.

Hint 4: Install rootkit detection tools: `sudo apt-get install unhide chkrootkit rkhunter`. Run `sudo unhide proc` to find hidden processes.

Hint 5: Check for suspicious network connections by reading `/proc/net/tcp` directly instead of using `netstat`. Or use `ss -antp` which is harder to compromise.

Hint 6: Look for the hidden process's executable: `sudo ls -la /proc/[PID]/exe` where PID is a hidden process number. This shows what's actually running.

Hint 7: Common rootkit locations: `/tmp`, `/var/tmp`, `/dev/shm`, hidden directories like `/lib/...` (with spaces), `/usr/lib/.hidden`. Search for recently modified files: `sudo find / -type f -mtime -1 2>/dev/null`.

Hint 8: To remediate: Kill the malicious processes, remove the rootkit files, reinstall compromised system binaries from package manager, check for persistence mechanisms (cron, systemd, rc.local), and consider full system rebuild.

## Cleanup

```bash
./teardown-lima.sh
```

## Production Parallels

This scenario mirrors:
- Advanced persistent threats (APT) using rootkits
- Kernel-level malware hiding from userspace tools
- Compromised system utilities
- Need for trusted forensic tools
- Importance of file integrity monitoring
