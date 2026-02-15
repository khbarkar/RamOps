<p align="center">
  <img src="docs/img/logo.png" alt="RamOps" width="400">
</p>

# Ram Ops 

Incident simulation and training scenarios for Kubernetes and cloud infrastructure teams. Practice responding to outages, security breaches, chaos engineering events, and misconfigurations in a safe environment.

## Incidents

| Incident | Description | Root Cause Analysis |
|----------|-------------|---------------------|
| `kubernetes/incident-001` | Production pod crash-looping — users reporting site is down | [RCA](kubernetes/incident-001/root-cause-analysis.md) |
| `kubernetes/incident-002` | Cluster node unresponsive — workloads not scheduling | [RCA](kubernetes/incident-002/root-cause-analysis.md) |
| `kubernetes/incident-003` | Services failing to connect — intermittent resolution failures | [RCA](kubernetes/incident-003/root-cause-analysis.md) |
| `kubernetes/incident-004` | Application pods failing with write errors | [RCA](kubernetes/incident-004/root-cause-analysis.md) |
| `kafka/incident-005` | Kafka cluster experiencing high latency and growing consumer lag (VMs + Grafana) | [RCA](kafka/incident-005/root-cause-analysis.md) |
| `kafka/incident-006` | Kafka performance degraded despite available CPU and disk (VMs + Grafana) | [RCA](kafka/incident-006/root-cause-analysis.md) |
| `deployment/incident-007` | Config rollback attempted but application still broken (VMs) | [RCA](deployment/incident-007/root-cause-analysis.md) |
| `kubernetes/incident-008` | API gateway HTTPS connections failing with certificate errors | [RCA](kubernetes/incident-008/root-cause-analysis.md) |
| `kubernetes/incident-009` | Critical microservice keeps dying and restarting every few minutes | [RCA](kubernetes/incident-009/root-cause-analysis.md) |
| `kubernetes/incident-010` | Security audit flagged exposed credentials in cluster configuration | [RCA](kubernetes/incident-010/root-cause-analysis.md) |
| `terraform/incident-011` | Infrastructure changes not matching Terraform configuration (VMs) | [RCA](terraform/incident-011/root-cause-analysis.md) |
| `observability/incident-012` | Alert storm: 15+ alerts firing simultaneously at 3am (VMs) | [RCA](observability/incident-012/root-cause-analysis.md) |

## Getting Started

Each scenario is self-contained with its own setup, verification, and teardown scripts.

**Prerequisites:**
- **Kubernetes scenarios**: [Kind](https://kind.sigs.k8s.io/), [kubectl](https://kubernetes.io/docs/tasks/tools/), Docker
- **VM-based scenarios** (Kafka, Deployment, Terraform):
  - [Vagrant](https://www.vagrantup.com/downloads) >= 2.0
  - **Apple Silicon (ARM) Macs - Choose ONE:**
    - **QEMU (FREE, recommended):**
      ```bash
      brew install qemu
      vagrant plugin install vagrant-qemu
      ```
    - **VMware Fusion** (free, requires Broadcom account)
    - **Parallels Desktop** (14-day trial)
  - **Intel Macs / Linux / Windows:**
    - [VirtualBox](https://www.virtualbox.org/) >= 6.0
  - Python 3 with `kafka-python` (for Kafka scenarios only)


```bash
cd kubernetes/incident-001
./setup.sh      # creates infrastructure and deploys the broken scenario
# ... debug and fix ...
./verify.sh     # checks if your fix works
./teardown.sh   # cleans up everything
```

