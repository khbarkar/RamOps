# Solution: Kafka Disk-Bound Brokers

## Root Cause

Kafka brokers are throttled to **10MB/s disk write speed** (via Linux cgroup `blkio` throttling). This simulates slow disks (spinning disks, network-attached storage, or under-provisioned cloud volumes).

When producers send 100 MB/s of data across 3 brokers (~33 MB/s per broker), each broker's disk can't keep up. Segments queue in memory waiting to flush, request handlers block, and the entire pipeline backs up.

## Diagnosis

### 1. Check Grafana Metrics

Open http://localhost:3000 and look for:

**Consumer Lag Graph**
- Should show steady increase (10k → 100k → 1M+)
- Lag grows because consumers can't fetch data that brokers haven't flushed yet

**Produce Request Latency (p99)**
- Should spike from ~20ms to 500ms+
- Producers wait for acks, but brokers are slow to flush and replicate

**Request Handler Idle Percent**
- Should drop from ~80% to < 5%
- Handlers are blocked waiting for disk I/O

**Disk Metrics**
- `iowait%` high (50-90%)
- Write throughput capped at ~10 MB/s per broker

### 2. SSH Into Broker

```bash
vagrant ssh kafka1
```

Check disk I/O:
```bash
iostat -x 5
# Look for high %util (near 100%) and avgqu-sz (queue depth)
```

Check throttle configuration:
```bash
cat /sys/fs/cgroup/blkio/blkio.throttle.write_bps_device
# Should show: 8:32 10485760 (10 MB/s limit on /dev/sdc)
```

Check Kafka logs:
```bash
sudo journalctl -u kafka -f
# Look for slow log flush warnings
```

## The Fix

### Option A: Remove I/O Throttle (Simulates Faster Disk)

Remove the cgroup throttle on all brokers:

```bash
vagrant ssh kafka1 -c 'echo "" | sudo tee /sys/fs/cgroup/blkio/blkio.throttle.write_bps_device'
vagrant ssh kafka2 -c 'echo "" | sudo tee /sys/fs/cgroup/blkio/blkio.throttle.write_bps_device'
vagrant ssh kafka3 -c 'echo "" | sudo tee /sys/fs/cgroup/blkio/blkio.throttle.write_bps_device'
```

Within 30-60 seconds:
- Disk write throughput jumps to 100+ MB/s
- Produce latency drops back to < 50ms
- Consumer lag starts draining
- Request handler idle % returns to normal

### Option B: Add More Brokers (Scale Horizontally)

If you can't upgrade disk speed, spread load across more brokers:

1. Add a 4th broker (edit `Vagrantfile`, add `kafka4`)
2. Reassign partitions to use the new broker
3. Each broker now handles less throughput (25 MB/s instead of 33 MB/s)

This approach works in production when:
- Disk upgrade isn't feasible
- You're already on the fastest storage available
- Horizontal scaling is easier/cheaper

### Option C: Tune Kafka Configuration

Less effective but worth trying:

```properties
# Reduce flush frequency (trade durability for throughput)
log.flush.interval.messages=10000
log.flush.interval.ms=10000

# Increase batch sizes
batch.size=65536
linger.ms=100

# Compression (reduces bytes written)
compression.type=lz4
```

**Warning**: Reducing flush frequency increases risk of data loss on broker crash.

## Verification

After fixing, run the load generator again:

```bash
python3 scripts/load-generator.py --target-mbps 100 --duration 60
```

Healthy metrics:
- ✅ Consumer lag stays < 10k messages
- ✅ Produce latency p99 < 100ms
- ✅ Disk I/O wait < 20%
- ✅ Request handler idle % > 30%

## Key Takeaways

- **Disk I/O is often the Kafka bottleneck**, not CPU or network
- **Symptom pattern**: lag grows + produce latency rises + handlers idle % drops = disk bound
- **"Bigger nodes" works** if the bottleneck is storage performance
- **Faster storage types**:
  - Cloud: GP2 → GP3 → io2 → instance storage (NVMe)
  - On-prem: SATA → SAS → NVMe
- **RAID matters**: RAID0/10 for Kafka (avoid RAID5/6 write penalty)
- **Monitor** `iostat` on brokers — `%util` near 100% = disk saturated
- **Production fix**: Upgrade to faster disks (io2, instance storage) or add brokers

## Production War Story

> "We were running Kafka on GP2 EBS (100 IOPS baseline). At 10k msg/s we hit constant lag. Switched to io2 with 10k provisioned IOPS — lag disappeared. Same cluster, same load, just faster disks. Cost $200/mo more, saved 2 weeks of optimization work."

This is the most common "why is Kafka slow?" root cause in the wild.
