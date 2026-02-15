<p align="center">
  <img src="logo.png" alt="openRam" width="400">
</p>

# Ram Ops ( hrutur ) 

Incident simulation and training scenarios for Kubernetes and cloud infrastructure teams. Practice responding to outages, security breaches, chaos engineering events, and misconfigurations in a safe environment.

## Scenarios

| Directory | Description |
|-----------|-------------|
| `broken-cluster` | Kubernetes cluster failures: crashloops, node issues, control plane outages |
| `degraded-platform` | Performance degradation: memory leaks, CPU runaways, IOPS throttling |
| `oom` | Out-of-memory and resource exhaustion |
| `harden-security` | Security breach simulations: stolen creds, RBAC misconfig, pod breakouts |
| `find-the-issue-in-grafana` | Observability challenges: alert storms, missing metrics, SLO breaches |
| `wrong-alarm` | False positive alert scenarios |
| `bad-ai-advice` | Scenarios where AI-generated suggestions lead to bad incident response |

## Getting Started

Each scenario is self-contained with its own setup, verification, and teardown scripts. You need [Kind](https://kind.sigs.k8s.io/), [kubectl](https://kubernetes.io/docs/tasks/tools/), and Docker.

```bash
cd broken-cluster/single-pod-crashloop
./setup.sh      # creates a Kind cluster and deploys the broken workload
# ... debug and fix ...
./verify.sh     # checks if your fix works
./teardown.sh   # cleans up the cluster
```

See [TODO.md](TODO.md) for the full list of 100 planned scenarios across all categories.

## Why "Hrutur"?

**Hrutur** (pronounced roughly "HROO-tur") is Icelandic for **ram** — as in the animal. Rams are known for charging headfirst into obstacles, which is exactly what on-call engineers do at 3 AM. This project helps you practice that headfirst collision in a safe environment, so when a real incident hits, you've already taken the blow.
