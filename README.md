<p align="center">
  <img src="logo.png" alt="RamOps" width="400">
</p>

# Ram Ops ( hrutur ) 

Incident simulation and training scenarios for Kubernetes and cloud infrastructure teams. Practice responding to outages, security breaches, chaos engineering events, and misconfigurations in a safe environment.

## Scenarios

| Directory | Description |
|-----------|-------------|
| `kubernetes/single-pod-crashloop` | A pod is stuck in CrashLoopBackOff — diagnose and fix it |
| `kubernetes/node-not-ready` | A cluster node has gone NotReady — find it and bring it back |
| `kafka/disk-bound-brokers` | Kafka brokers bottlenecked by slow disk I/O (VMs + Grafana) |
| `kafka/network-bound-brokers` | Kafka brokers bottlenecked by network bandwidth cap (VMs + Grafana) |
| `deployment/hard-link-trap` | Config rollback fails due to hard link inode semantics (VMs) |

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
cd kubernetes/single-pod-crashloop
./setup.sh      # creates infrastructure and deploys the broken scenario
# ... debug and fix ...
./verify.sh     # checks if your fix works
./teardown.sh   # cleans up everything
```

## Why "Hrutur"?

**Hrutur** (pronounced roughly "HROO-tur") is Icelandic for **ram** — as in the animal. Rams are known for charging headfirst into obstacles, which is exactly what on-call engineers do at 3 AM. This project helps you practice that headfirst collision in a safe environment, so when a real incident hits, you've already taken the blow.
