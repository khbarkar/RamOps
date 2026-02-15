# Root Cause Analysis: Backdoor User Account

## Incident Summary
Unauthorized user accounts with root privileges and SSH keys providing persistent access.

## Root Cause
Backdoor accounts created with UID 0, NOPASSWD sudo access, and unauthorized SSH keys.

## Resolution
Audit user accounts, remove backdoor users, delete unauthorized SSH keys, remove persistence mechanisms.
