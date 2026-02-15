# DNS Outage

**Difficulty:** Intermediate
**Category:** Incidents & Outages
**Time estimate:** 20-25 minutes

## Scenario

The cluster's DNS system (CoreDNS) has been misconfigured and is failing. Pods cannot resolve service names or external domains. Your application's backend service keeps failing to connect to the database because DNS lookups are timing out.

## Prerequisites

- [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- Docker running

## Setup

```bash
./setup.sh
```

## Your Task

1. Diagnose why services cannot resolve DNS names
2. Identify the CoreDNS misconfiguration
3. Fix the DNS system
4. Verify services can communicate again
5. Run `./verify.sh` to confirm your fix

## Symptoms You'll See

- Pods stuck in `CrashLoopBackOff` or failing health checks
- Application logs showing "Name or service not known"
- DNS lookups timing out or returning NXDOMAIN
- Services unable to reach each other by name

## Hints

<details>
<summary>Hint 1</summary>
Start by checking if CoreDNS pods are running: <code>kubectl get pods -n kube-system -l k8s-app=kube-dns</code>
</details>

<details>
<summary>Hint 2</summary>
Exec into a pod and try resolving a service name manually: <code>kubectl exec -it &lt;pod-name&gt; -- nslookup kubernetes.default</code>
</details>

<details>
<summary>Hint 3</summary>
Check the CoreDNS ConfigMap: <code>kubectl get configmap coredns -n kube-system -o yaml</code>. Look for syntax errors or misconfigurations.
</details>

<details>
<summary>Hint 4</summary>
The CoreDNS config has a typo that breaks the DNS resolution. Fix the ConfigMap and restart CoreDNS pods.
</details>

## Cleanup

```bash
./teardown.sh
```

## Production Parallels

This scenario mirrors:
- Accidental CoreDNS config changes during upgrades
- DNS cache poisoning or stale entries
- CoreDNS resource exhaustion
- Network policy blocking DNS traffic
- Cloud provider DNS service outages
