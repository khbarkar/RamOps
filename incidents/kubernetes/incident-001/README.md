# Single Pod Crashloop

**Difficulty:** Beginner
**Category:** Incidents & Outages
**Time estimate:** 10-15 minutes

## Scenario

The `web-frontend` deployment was recently pushed to production. Users are reporting the site is down. The on-call engineer (you) needs to figure out why the pod keeps restarting.

## Prerequisites

- [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- Docker running

## Setup

```bash
./setup.sh
```

## Your Task

1. Find out why the `web-frontend` pod is crash-looping
2. Fix the issue so the pod runs stably
3. Run `./verify.sh` to confirm your fix

## Hints

<details>
<summary>Hint 1</summary>
Start with <code>kubectl describe pod</code> and look at the Events section.
</details>

<details>
<summary>Hint 2</summary>
The container logs show nginx started successfully. The problem isn't the application itself.
</details>

<details>
<summary>Hint 3</summary>
Look at the probe configuration. Is it checking the right place?
</details>

## Cleanup

```bash
./teardown.sh
```
