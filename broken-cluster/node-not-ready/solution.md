# Solution: Node Goes NotReady

## Root Cause

One of the worker nodes has been **paused at the Docker level** (`docker pause`), simulating a node that has become unresponsive (e.g. kernel panic, network partition, resource exhaustion).

When kubelet stops sending heartbeats, the control plane marks the node as `NotReady` after the node-monitor grace period.

## How to Diagnose

```bash
kubectl get nodes
# One node shows STATUS: NotReady

kubectl describe node <notready-node>
# Look at Conditions — KubeletNotReady, last heartbeat timestamp is stale
# Look at Events — node status is now "NodeNotReady"

kubectl get pods -o wide
# Pods on the failed node may show Terminating or Unknown status
```

## Fix

The node's Docker container has been paused. Unpause it:

```bash
# List docker containers to find the paused one
docker ps -a | grep ramops

# Unpause the paused container
docker unpause <container-name>
```

After unpausing, kubelet will resume sending heartbeats and the node will return to `Ready` within ~30 seconds.

## Key Takeaways

- `kubectl get nodes` is your first command when pods are misbehaving across the cluster
- `kubectl describe node` shows heartbeat timestamps and conditions that reveal when the node went down
- Pods on a NotReady node are not immediately evicted — Kubernetes waits for the `pod-eviction-timeout` (default 5 minutes) before rescheduling
- In production, node failures can be caused by: OOM killer, disk pressure, network issues, or kubelet crashes
