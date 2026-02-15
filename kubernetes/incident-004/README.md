# Storage Volume Full

**Difficulty:** Beginner-Intermediate
**Category:** Incidents & Outages
**Time estimate:** 15-20 minutes

## Scenario

Your application pod is crash-looping with cryptic errors. The application logs show "No space left on device" errors. The pod has filled its allocated storage volume and can no longer write files, causing it to fail.

## Prerequisites

- [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- Docker running

## Setup

```bash
./setup.sh
```

## Your Task

1. Diagnose why the log-processor pod is failing
2. Identify that the storage volume is full
3. Clean up unnecessary files or expand storage
4. Get the pod running stably
5. Run `./verify.sh` to confirm your fix

## Symptoms You'll See

- Pod stuck in `CrashLoopBackOff` or `Error` state
- Application logs showing "No space left on device"
- Container unable to write files
- OOMKilled or write errors in pod events

## Hints

<details>
<summary>Hint 1</summary>
Check the pod logs: <code>kubectl logs &lt;pod-name&gt;</code>. Look for disk space errors.
</details>

<details>
<summary>Hint 2</summary>
Exec into the pod and check disk usage: <code>kubectl exec -it &lt;pod-name&gt; -- df -h</code>
</details>

<details>
<summary>Hint 3</summary>
Use <code>du -sh /*</code> to find which directories are consuming space.
</details>

<details>
<summary>Hint 4</summary>
The <code>/data</code> directory has unnecessary log files. Delete them or configure log rotation. You might also need to increase the emptyDir size limit.
</details>

## Cleanup

```bash
./teardown.sh
```

## Production Parallels

This scenario mirrors:
- Log files filling up container storage
- Application cache growing unbounded
- Database storage exhaustion
- Pod ephemeral storage limits being hit
- Persistent volumes running out of space
- Lack of log rotation policies
