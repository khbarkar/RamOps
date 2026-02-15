# Root Cause Analysis: Cryptominer Investigation

## Incident Summary
Hidden cryptominer consuming CPU resources while hiding from standard monitoring tools.

## Root Cause
LD_PRELOAD library hiding miner processes. Compromised top command showing false CPU usage.

## Resolution
Detect using cgroup inspection or direct /proc analysis. Kill miner, remove binaries and persistence.
