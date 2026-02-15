# Alert Storm from Single Root Cause

**Difficulty:** Intermediate-Advanced
**Category:** Observability / Incident Response
**Time estimate:** 30-40 minutes

## Scenario

It's 3am and your phone won't stop buzzing. Dozens of alerts are firing: "Database connection failed", "API latency high", "Cache miss rate elevated", "Queue backlog growing", "Error rate spiking". The on-call engineer (you) needs to figure out what's actually wrong and stop the alert storm.

The problem: one root cause (disk full on the database server) is triggering cascading failures across the entire stack, creating an overwhelming number of alerts that obscure the real issue.

## Prerequisites

- [Vagrant](https://www.vagrantup.com/downloads) >= 2.0
- **Apple Silicon (ARM) Macs - Choose ONE:**
  - **QEMU (FREE, recommended):**
    ```bash
    brew install qemu
    vagrant plugin install vagrant-qemu
    ```
  - **VMware Fusion** (free for personal use)
  - **Parallels Desktop** (14-day trial)
- **Intel Macs / Linux / Windows:**
  - [VirtualBox](https://www.virtualbox.org/) >= 6.0
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

1. Access Alertmanager at http://localhost:9093
2. Observe the alert storm (20+ alerts firing)
3. Identify which alerts are symptoms vs root cause
4. SSH into the VM: `vagrant ssh`
5. Investigate and find the actual root cause
6. Fix the root issue
7. Configure alert grouping/silencing for better incident response
8. Run `./verify.sh` to confirm proper alert design

## Your Task

1. **Triage**: Determine which alert represents the root cause
2. **Fix**: Resolve the underlying issue
3. **Improve**: Configure Alertmanager to group related alerts
4. **Design**: Implement alert hierarchy to prevent future storms

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
