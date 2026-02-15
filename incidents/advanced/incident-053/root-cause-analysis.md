---
title: "Distributed Consensus Failure"
difficulty: Expert
skills: [Distributed Systems, Raft, etcd]
technologies: [Kubernetes, etcd, Distributed Systems]
description: "etcd cluster in split-brain state with multiple leaders elected, causing data inconsistency and conflicting writes"
---

# Root Cause Analysis: Distributed Consensus Failure

## Incident Summary
etcd cluster entered split-brain state with multiple leaders elected simultaneously, causing data inconsistency.

## Root Cause
Network partition prevented nodes from reaching quorum (2 out of 3 nodes). Each isolated node attempted leader election, resulting in multiple leaders and conflicting writes.

## Technical Details
- Raft consensus requires majority quorum (N/2 + 1)
- Network policy blocked peer communication on port 2380
- Nodes could not maintain heartbeats, triggering elections
- Without quorum, multiple leaders elected in separate partitions

## Resolution
1. Identify split-brain via `etcdctl endpoint status --cluster`
2. Remove network partition policies
3. Force nodes to re-elect single leader
4. Restore from node with highest RAFT INDEX
5. Verify cluster consistency

## Prevention
- Monitor network latency between etcd nodes
- Use odd number of nodes (3, 5, 7)
- Spread nodes across failure domains
- Implement proper network policies
- Monitor clock skew
- Set appropriate heartbeat/election timeouts
