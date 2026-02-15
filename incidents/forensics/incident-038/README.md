# Backdoor User Account

**Difficulty:** Intermediate
**Category:** Forensics
**Time estimate:** 30-40 minutes

## Scenario

Your security team received an alert about unusual sudo activity at 3am. When you check the server, you notice SSH sessions from IP addresses you don't recognize. 

The application team swears they didn't create any new accounts, but someone has been accessing the system with elevated privileges. You need to find out who has access and how they got in.

## Prerequisites

- [Lima](https://lima-vm.io/) for VM management
- 2GB+ RAM free

## What You'll Learn

- Auditing user accounts and privileges
- Analyzing SSH authentication logs
- Finding unauthorized SSH keys
- Detecting persistence mechanisms
- User account forensics
- Proper account management

## Setup

```bash
./setup-lima.sh
```

This creates a compromised VM with backdoor user accounts.

## Your Task

1. SSH into the system: `limactl shell lima-backdoor`
2. Investigate unauthorized access
3. Find all backdoor accounts and SSH keys
4. Determine how the attacker maintains persistence
5. Document findings and remediate

## Hints

Hint 1: Start by listing all user accounts: `cat /etc/passwd`. Look for accounts with UID 0 (root privileges) or high UIDs that shouldn't exist. Normal system accounts are usually < 1000.

Hint 2: Check for users with login shells: `grep -v '/nologin\|/false' /etc/passwd`. Any unexpected accounts with `/bin/bash` or `/bin/sh`?

Hint 3: Look for users with sudo privileges: `sudo cat /etc/sudoers` and `sudo ls -la /etc/sudoers.d/`. Check for NOPASSWD entries.

Hint 4: Examine SSH authorized_keys for all users: `sudo find /home -name authorized_keys -exec echo "=== {} ===" \; -exec cat {} \;`. Also check `/root/.ssh/authorized_keys`.

Hint 5: Check recent login history: `last -f /var/log/wtmp`, `lastlog`, and `who /var/log/wtmp`. Look for logins from unexpected IPs or at unusual times.

Hint 6: Review SSH authentication logs: `sudo grep -i "Accepted publickey\|Accepted password" /var/log/auth.log`. Look for successful logins from unknown users or IPs.

Hint 7: Check for hidden users by comparing `/etc/passwd` with actual home directories: `ls -la /home/`. Sometimes attackers create users without proper home directories.

Hint 8: Look for accounts with empty passwords: `sudo awk -F: '($2 == "" || $2 == "!") {print $1}' /etc/shadow`. These can be security risks.

Hint 9: To remediate: Delete backdoor accounts with `sudo userdel -r username`, remove unauthorized SSH keys, review and tighten sudoers configuration, rotate credentials for legitimate accounts, enable SSH key fingerprint logging.

Hint 10: Check for persistence: Look in `/etc/rc.local`, systemd services, cron jobs (`crontab -l` for all users), and `/etc/profile.d/` for scripts that might recreate the backdoor.

## Cleanup

```bash
./teardown-lima.sh
```

## Production Parallels

This scenario mirrors:
- Compromised credentials leading to backdoor accounts
- Attackers establishing persistence via SSH keys
- Privilege escalation through sudo misconfigurations
- Need for regular user account audits
- Importance of centralized authentication (LDAP/SSO)
- SSH key management challenges
