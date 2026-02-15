# Root Cause Analysis: Reverse Shell Discovery

## Incident Summary
Persistent reverse shell connection providing attacker with remote access.

## Root Cause
Bash reverse shell script connecting to external C2 server, maintained via cron persistence.

## Resolution
Identify connection with ss/netstat, kill process, remove script, remove cron job, implement egress filtering.
