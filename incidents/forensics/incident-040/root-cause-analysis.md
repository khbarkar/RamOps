# Root Cause Analysis: Log Tampering

## Incident Summary
Attacker deleted log entries to cover tracks, leaving gaps in audit trail.

## Root Cause
Log files modified to remove evidence of unauthorized access. Some logs deleted but still open by processes.

## Resolution
Recover from deleted-but-open files via /proc, check journalctl, review bash history, implement log protection.
