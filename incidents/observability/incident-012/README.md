# Alert Storm from Single Root Cause

**Difficulty:** Intermediate-Advanced
**Category:** Observability / Incident Response
**Time estimate:** 30-40 minutes

## Scenario

It's 3am and your phone won't stop buzzing. Dozens of alerts are firing: "Database connection failed", "API latency high", "Cache miss rate elevated", "Queue backlog growing", "Error rate spiking". The on-call engineer (you) needs to figure out what's actually wrong and stop the alert storm.

## Prerequisites

- [Lima](https://lima-vm.io/) for VM management
- 4GB+ RAM free

## What You'll Learn

- Identifying root cause vs symptoms in alert storms
- Designing effective alert hierarchies
- Implementing alert grouping and routing
- Using alert dependencies and silencing
- Differentiating between symptom-based and cause-based alerts

## Setup

```bash
./setup.sh
```

This creates a VM with:
- Prometheus for metrics collection
- Alertmanager for alert routing
- Multiple simulated services with interdependencies
- A triggered root cause (disk full) causing cascading failures

## The Exercise

1. Access Prometheus at http://localhost:9090
2. Access Alertmanager at http://localhost:9093
3. Observe the alert storm (multiple alerts firing)
4. Identify which alerts are symptoms vs root cause
5. SSH into the VM to investigate: `limactl shell lima-alertmanager`
6. Find and fix the actual root cause
7. Configure alert grouping/silencing for better incident response
8. Run `./verify.sh` to confirm proper alert design

## Your Task

1. Open Prometheus at http://localhost:9090/alerts to see firing alerts
2. Open Alertmanager at http://localhost:9093 to see alert notifications
3. Observe the alert storm (multiple alerts firing simultaneously)
4. Identify which alerts are symptoms vs root cause
5. SSH into the VM: `limactl shell lima-alertmanager`
6. Investigate and find the actual root cause
7. Fix the underlying issue
8. Configure Alertmanager to group related alerts
9. Implement alert hierarchy to prevent future storms

## Hints

<details>
<summary>Hint 1</summary>
Look at the alert timestamps. Which alert fired first? That's often closer to the root cause.
</details>

<details>
<summary>Hint 2</summary>
SSH into the VM and check disk space: <code>df -h</code>. The database server has run out of disk space.
</details>

<details>
<summary>Hint 3</summary>
Use Alertmanager's grouping feature to combine related alerts. Edit <code>/etc/alertmanager/alertmanager.yml</code>.
</details>

<details>
<summary>Hint 4</summary>
Implement alert dependencies - silence symptom alerts when root cause alert is firing.
</details>

## Cleanup

```bash
./teardown.sh
```

## Production Parallels

This scenario mirrors:
- Infrastructure failures causing application-level alerts
- Network partitions triggering hundreds of unreachability alerts
- Database issues cascading to all dependent services
- Alert fatigue leading to ignored pages
- Poor alert design hiding critical issues
