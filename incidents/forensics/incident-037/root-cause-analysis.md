# Root Cause Analysis: Rootkit Detection

## Incident Summary
System compromised with rootkit hiding malicious processes from standard monitoring tools.

## Root Cause
LD_PRELOAD rootkit library filtering readdir() calls to hide processes. Compromised ps and netstat binaries.

## Resolution
Detect using unhide, chkrootkit, or direct /proc inspection. Remove rootkit library and restore system binaries.
