# Distributed Consensus Failure

**Difficulty:** Expert
**Category:** Advanced
**Time estimate:** 60-90 minutes

## Scenario

Your etcd cluster is behaving erratically. Some API requests succeed, others fail. Different nodes report different cluster states. Your monitoring shows multiple leaders elected simultaneously.

The cluster has entered a split-brain state - a catastrophic failure of the Raft consensus algorithm. Data is being written to multiple leaders, creating conflicting state. You need to understand what went wrong and safely recover the cluster without losing data.

## Prerequisites

- [Kind](https://kind.sigs.k8s.io/) for Kubernetes cluster
- Deep understanding of distributed systems
- Familiarity with Raft consensus algorithm
- 4GB+ RAM free

## What You'll Learn

- Raft consensus algorithm internals
- Split-brain detection and recovery
- Quorum mathematics and leader election
- etcd cluster operations
- Data consistency in distributed systems
- Safe cluster recovery procedures

## Setup

```bash
./setup.sh
```

This creates a Kubernetes cluster with an etcd cluster in a split-brain state.

## Your Task

1. Detect the split-brain condition
2. Understand how the consensus failure occurred
3. Identify which nodes have conflicting data
4. Safely recover the cluster to a consistent state
5. Implement safeguards to prevent future split-brain

## Hints

Hint 1: Check etcd cluster health: `kubectl exec -n kube-system etcd-0 -- etcdctl endpoint health --cluster`. Multiple leaders indicate split-brain.

Hint 2: Check Raft state on each node: `kubectl exec -n kube-system etcd-0 -- etcdctl endpoint status --cluster -w table`. Look at the RAFT TERM and RAFT INDEX columns.

Hint 3: A split-brain occurs when network partitions prevent nodes from reaching quorum (N/2 + 1). Check for network policies or firewall rules blocking etcd peer communication (port 2380).

Hint 4: Examine etcd logs for leader election messages: `kubectl logs -n kube-system etcd-0 | grep -E "leader|election|quorum"`. Look for repeated elections or "lost leader" messages.

Hint 5: Understand quorum: With 3 nodes, you need 2 for quorum. If the cluster splits 1-1-1 (all isolated), each node might try to become leader. With 5 nodes, you need 3 for quorum.

Hint 6: Check for time skew between nodes: `kubectl exec -n kube-system etcd-0 -- date` on each node. Clock drift can cause election timeouts and split-brain.

Hint 7: To recover: First, stop writes to prevent more conflicts. Then identify the node with the highest RAFT INDEX (most up-to-date). Force other nodes to follow this leader.

Hint 8: Use `etcdctl member list` to see cluster membership. Remove members that are permanently unreachable, then re-add them as new members to force them to sync from the leader.

Hint 9: For data conflicts, you may need to restore from backup. Check `etcdctl snapshot save` and `etcdctl snapshot restore`. The node with highest RAFT INDEX should be the source of truth.

Hint 10: Prevent future split-brain: Ensure odd number of nodes (3, 5, 7), monitor network latency between nodes, use anti-affinity to spread nodes across failure domains, implement proper network policies, monitor clock skew.

Hint 11: Advanced: Understand Raft terms. Each leader election increments the term. If you see nodes with different terms, they've had separate elections. The node with the highest term won the most recent election.

Hint 12: Read the Raft paper or visualization at raft.github.io to understand leader election, log replication, and safety properties. Understanding the algorithm is crucial for recovery.

## Cleanup

```bash
./teardown.sh
```

## Production Parallels

This scenario mirrors:
- Real etcd split-brain incidents in production Kubernetes
- Consul/Zookeeper consensus failures
- Database replication conflicts
- Network partition scenarios
- The CAP theorem in practice (Consistency vs Availability)
- Why distributed systems are hard

## Further Reading

- [Raft Consensus Algorithm](https://raft.github.io/)
- [etcd Disaster Recovery](https://etcd.io/docs/latest/op-guide/recovery/)
- [Understanding Quorum](https://etcd.io/docs/latest/faq/#what-is-failure-tolerance)
- [Split-Brain Scenarios](https://en.wikipedia.org/wiki/Split-brain_(computing))
