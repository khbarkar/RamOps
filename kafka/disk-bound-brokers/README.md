## Kafka Disk-Bound Brokers

**Difficulty:** Intermediate-Advanced
**Category:** Kafka / Performance Troubleshooting
**Time estimate:** 30-45 minutes

## Scenario

Your Kafka cluster is experiencing increasing consumer lag despite having sufficient CPU and network capacity. Producers are timing out. The problem: brokers can't write to disk fast enough.

This simulates the most common "bigger nodes fix it" scenario — disk I/O bottlenecks that are resolved by faster storage or adding more brokers.

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

- How to identify disk I/O bottlenecks in Kafka
- Reading Kafka JMX metrics (via Prometheus + Grafana)
- Understanding `RequestHandlerAvgIdlePercent`, disk flush rate, produce latency
- How slow storage impacts the entire Kafka pipeline
- Proper remediation: faster disks vs more brokers vs tuning

## Setup

```bash
./setup.sh
```

This creates:
- 3 Kafka brokers (KRaft mode) with **throttled disk I/O** (10MB/s write limit)
- 1 monitoring VM running Prometheus + Grafana
- Pre-configured Grafana dashboard for Kafka metrics

## The Exercise

1. **Baseline**: Open Grafana at http://localhost:3000 (admin/admin) and observe normal metrics

2. **Generate load**:
   ```bash
   python3 scripts/load-generator.py --target-mbps 100 --duration 600
   ```

3. **Watch symptoms develop** (in Grafana):
   - Consumer lag growing steadily
   - Disk I/O wait spiking
   - Produce request latency (p99) rising
   - `RequestHandlerAvgIdlePercent` dropping toward 0

4. **Diagnose**:
   - SSH into broker: `vagrant ssh kafka1`
   - Check disk I/O: `iostat -x 5`
   - Check throttle: `cat /sys/fs/cgroup/blkio/blkio.throttle.write_bps_device`

5. **Fix** (choose one approach):
   - **Option A**: Remove I/O throttle (simulates faster disk)
     ```bash
     vagrant ssh kafka1 -c 'echo "" | sudo tee /sys/fs/cgroup/blkio/blkio.throttle.write_bps_device'
     vagrant ssh kafka2 -c 'echo "" | sudo tee /sys/fs/cgroup/blkio/blkio.throttle.write_bps_device'
     vagrant ssh kafka3 -c 'echo "" | sudo tee /sys/fs/cgroup/blkio/blkio.throttle.write_bps_device'
     ```
   - **Option B**: Add more brokers and rebalance (see solution.md)

6. **Verify**: Run `./verify.sh` and watch lag drain in Grafana

## Key Metrics

| Metric | What it means | Healthy | Unhealthy |
|--------|---------------|---------|-----------|
| Consumer lag | Messages behind | < 10k | > 100k, growing |
| Produce latency p99 | Time to ack writes | < 50ms | > 500ms |
| RequestHandlerAvgIdlePercent | Broker thread idle % | > 30% | < 5% |
| Disk I/O wait % | Time waiting for disk | < 10% | > 50% |
| Log flush rate | Segments flushed/sec | Steady | Spiking |

## Cleanup

```bash
./teardown.sh
```

## Production Parallels

This scenario mirrors:
- Running Kafka on GP2 EBS instead of io2 / NVMe instance storage
- Over-provisioned brokers (too many partitions per broker)
- Network-attached storage that can't keep up with write load
- RAID misconfiguration or failing disks
