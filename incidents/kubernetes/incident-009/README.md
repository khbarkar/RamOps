# Incident-009

**Difficulty:** Intermediate
**Category:** Incidents & Outages
**Time estimate:** 20-25 minutes

## Scenario

A critical microservice keeps getting killed and restarting. The service runs fine for a few minutes, then suddenly dies. Users are experiencing intermittent errors when the service is unavailable during restarts.

## Prerequisites

- [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- Docker running

## Setup

```bash
./setup.sh
```

## Your Task

1. Diagnose why the service keeps dying
2. Identify what's causing the kills
3. Implement a fix to stabilize the service
4. Run `./verify.sh` to confirm your fix

## Symptoms You'll See

- Pod frequently restarting (high RESTARTS count)
- Service intermittently unavailable
- Pod status showing `OOMKilled` or `CrashLoopBackOff`
- Memory usage climbing over time

## Hints

<details>
<summary>Hint 1</summary>
Check the pod's restart count and status: <code>kubectl get pods</code>. Look for high RESTARTS numbers.
</details>

<details>
<summary>Hint 2</summary>
Use <code>kubectl describe pod &lt;pod-name&gt;</code> and look for the last termination reason in the container status.
</details>

<details>
<summary>Hint 3</summary>
Check memory usage with <code>kubectl top pod &lt;pod-name&gt;</code>. Watch it grow over time.
</details>

<details>
<summary>Hint 4</summary>
The application has a memory leak. Either fix the leak in the code or increase the memory limit as a temporary workaround.
</details>

## Cleanup

```bash
./teardown.sh
```

## Production Parallels

This scenario mirrors:
- Memory leaks in application code
- Kubernetes OOMKiller terminating containers
- Resource limits set too low
- Missing memory profiling and monitoring
- Gradual memory growth leading to crashes
