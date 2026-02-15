# Solution: Kafka Network-Bound Brokers

## Root Cause

Kafka brokers are throttled to **50 Mbit/s network bandwidth** (via Linux `tc` traffic control). This simulates slow network links, oversubscribed switches, or low-tier cloud instances.

When producers send 100 MB/s of data across 3 brokers (~33 MB/s per broker), and consumers try to fetch data, the network saturates. Replication traffic also competes for bandwidth. The entire pipeline backs up waiting for network I/O.

## Diagnosis

### 1. Check Grafana Metrics

Open http://localhost:3000 and look for:

**Network Bytes In/Out Graph**
- Should show throughput plateauing at ~50 Mbit/s (~6 MB/s)
- Both ingress and egress are capped
- Throughput won't increase no matter the demand

**Consumer Lag Graph**
- Steady increase because consumers can't fetch fast enough
- Lag grows even though brokers have the data

**Request Queue Time**
- Spikes as fetch/produce requests queue waiting for network
- Normally < 10ms, now 100ms+

### 2. SSH Into Broker

```bash
vagrant ssh kafka1
```

Check live network usage:
```bash
sudo iftop -i eth1
# Should show traffic capped at ~50 Mbit/s
```

Check traffic control rules:
```bash
sudo tc qdisc show dev eth1
# Should show htb qdisc with 50mbit rate limit
```

Check Kafka metrics:
```bash
sudo journalctl -u kafka -f
# Look for "request queue" warnings
```

## The Fix

### Option A: Remove Network Throttle (Simulates Faster Network)

Remove the `tc` throttle on all brokers:

```bash
vagrant ssh kafka1 -c 'sudo tc qdisc del dev eth1 root'
vagrant ssh kafka2 -c 'sudo tc qdisc del dev eth1 root'
vagrant ssh kafka3 -c 'sudo tc qdisc del dev eth1 root'
```

Within 30 seconds:
- Network throughput jumps to 100+ MB/s (limited only by VM)
- Consumer lag starts draining immediately
- Request queue time drops back to < 50ms
- Fetch requests complete faster

### Option B: Add More Brokers (Scale Horizontally)

If you can't upgrade network speed, spread load across more brokers:

1. Add a 4th broker (edit `Vagrantfile`, add `kafka4`)
2. Reassign partitions to distribute across 4 brokers
3. Each broker now handles less network traffic (25 MB/s instead of 33 MB/s)

This works when:
- You're already on the fastest network tier available
- Horizontal scaling is cheaper than network upgrades
- You need to spread both bandwidth and replication load

### Option C: Reduce Throughput (Last Resort)

If you can't upgrade or scale:

```properties
# Limit producer throughput to match network capacity
# Producer side:
max.in.flight.requests.per.connection=1
batch.size=16384
linger.ms=100

# Enable compression to reduce bytes over network
compression.type=lz4
```

**Warning**: This caps your cluster's max throughput permanently.

## Verification

After fixing, run the load generator again:

```bash
python3 scripts/load-generator.py --target-mbps 100 --duration 60
```

Healthy metrics:
- [ok] Consumer lag stays < 10k messages
- [ok] Network throughput > 100 Mbit/s (no longer capped at 50)
- [ok] Request queue time < 50ms
- [ok] Fetch request latency < 200ms

## Key Takeaways

- **Network bandwidth can be the Kafka bottleneck**, not just disk/CPU
- **Symptom pattern**: lag grows + network bytes plateau + request queue time high = network bound
- **"Bigger nodes" works** if it means more network bandwidth
- **Cloud network tiers**:
  - AWS: t3 (5 Gbit baseline) vs c5n (up to 100 Gbit)
  - GCP: n1 (10 Gbit) vs n2 (32 Gbit)
  - Azure: D-series vs E-series
- **Inter-AZ traffic costs and caps** — replication across AZs hits bandwidth limits fast
- **Monitor** network usage with `iftop` or `nload` on brokers
- **Production fix**: Upgrade to instances with higher network limits or add brokers

## Production War Story

> "We were running Kafka on t3.large instances (5 Gbit network). At peak we hit constant lag — CPU/disk were fine. Switched to c5n.large (25 Gbit network) — lag disappeared instantly. Same CPU, same disk, just more network. Cost difference: $20/mo per broker."

Network is often the forgotten bottleneck. Always check bytes in/out before adding more CPUs or disks.
