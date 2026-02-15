# Node Goes NotReady

**Difficulty:** Beginner
**Category:** Incidents & Outages
**Time estimate:** 10-15 minutes

## Scenario

Your monitoring dashboard shows one of the cluster nodes has gone `NotReady`. A 3-replica deployment was running across the cluster. You need to identify the failed node, understand the blast radius, and bring it back online.

## Prerequisites

- [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- Docker running

## Setup

```bash
./setup.sh
```

This creates a 3-node Kind cluster (1 control-plane + 2 workers), deploys a workload, then simulates a node failure.

## Your Task

1. Identify which node is down and why
2. Check what pods are affected
3. Bring the node back to `Ready` status
4. Run `./verify.sh` to confirm recovery

## Hints

<details>
<summary>Hint 1</summary>
<code>kubectl get nodes</code> and <code>kubectl describe node &lt;name&gt;</code> are your starting points.
</details>

<details>
<summary>Hint 2</summary>
The node is a Docker container managed by Kind. What Docker commands show container state?
</details>

<details>
<summary>Hint 3</summary>
Try <code>docker ps -a</code> and look for a container that isn't in a normal state.
</details>

## Cleanup

```bash
./teardown.sh
```
