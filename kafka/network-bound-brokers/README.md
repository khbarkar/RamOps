# Kafka Network-Bound Brokers

**Difficulty:** Intermediate-Advanced
**Category:** Kafka / Performance Troubleshooting
**Time estimate:** 30-45 minutes

## Scenario

Your Kafka cluster has increasing consumer lag even though brokers have plenty of CPU and disk I/O headroom. The problem: network bandwidth is saturated. Brokers can't send/receive data fast enough.

This simulates the "bigger nodes fix it" scenario where network throughput is the bottleneck — resolved by higher network bandwidth or adding more brokers.

## Prerequisites

- [Vagrant](https://www.vagrantup.com/downloads) >= 2.0
- **Apple Silicon (ARM) Macs:**
  1. **VMware Fusion** (free for personal use):
     - Download from: https://www.vmware.com/products/desktop-hypervisor/workstation-and-fusion
     - Create free Broadcom account and download
     - Launch once and select "Use for Personal Use"
  2. **Vagrant VMware plugin:**
     ```bash
     vagrant plugin install vagrant-vmware-desktop
     ```
  3. **Vagrant VMware Utility:**
     - Download from: https://www.vagrantup.com/downloads/vmware
- **Intel Macs / Linux / Windows:**
  - [VirtualBox](https://www.virtualbox.org/) >= 6.0
- Python 3 with `kafka-python` (`pip3 install kafka-python`)
- 8GB+ RAM free (4 VMs: 3 brokers @ 2GB + monitoring @ 2GB)

## What You'll Learn

- How to identify network bottlenecks in Kafka
- Reading network throughput metrics (bytes in/out)
- Understanding request queue behavior under network saturation
- How network caps impact Kafka's ability to replicate and serve data
- Proper remediation: faster network vs more brokers

## Setup

```bash
./setup.sh
```

This creates:
- 3 Kafka brokers (KRaft mode) with **50 Mbit/s network throttle**
- 1 monitoring VM running Prometheus + Grafana
- Pre-configured Grafana dashboard for Kafka metrics

## The Exercise

1. **Baseline**: Open Grafana at http://localhost:3000 (admin/admin)

2. **Generate load**:
   ```bash
   python3 scripts/load-generator.py --target-mbps 100 --duration 600
   ```

3. **Watch symptoms develop** (in Grafana):
   - Network bytes in/out plateauing at ~50 Mbit/s per broker
   - Consumer lag growing steadily
   - Request queue time increasing
   - Fetch requests backing up

4. **Diagnose**:
   - SSH into broker: `vagrant ssh kafka1`
   - Check network usage: `iftop -i eth1`
   - Check throttle: `sudo tc qdisc show dev eth1`

5. **Fix** (choose one approach):
   - **Option A**: Remove network throttle (simulates faster network)
     ```bash
     vagrant ssh kafka1 -c 'sudo tc qdisc del dev eth1 root'
     vagrant ssh kafka2 -c 'sudo tc qdisc del dev eth1 root'
     vagrant ssh kafka3 -c 'sudo tc qdisc del dev eth1 root'
     ```
   - **Option B**: Add more brokers to spread network load (see solution.md)

6. **Verify**: Run `./verify.sh` and watch lag drain in Grafana

## Key Metrics

| Metric | What it means | Healthy | Unhealthy |
|--------|---------------|---------|-----------|
| Consumer lag | Messages behind | < 10k | > 100k, growing |
| Network bytes out | Data sent/sec | Variable | Flat at cap |
| Network bytes in | Data received/sec | Variable | Flat at cap |
| Request queue time | Time waiting in queue | < 50ms | > 500ms |
| Fetch request latency | Consumer fetch time | < 100ms | > 1000ms |

## Cleanup

```bash
./teardown.sh
```

## Production Parallels

This scenario mirrors:
- Running Kafka on EC2 instances with limited network (t3 vs c5n)
- Oversubscribed network in on-prem data centers
- Reaching NIC limits (1 Gbit vs 10 Gbit vs 25 Gbit)
- Cross-AZ replication saturating inter-AZ bandwidth caps
- Network-attached storage limiting throughput
