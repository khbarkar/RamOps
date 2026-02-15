# Kafka Network-Bound Brokers

**Difficulty:** Intermediate-Advanced
**Category:** Kafka / Performance
**Time estimate:** 20-25 minutes

## Scenario

Your Kafka cluster has increasing consumer lag even though brokers have plenty of CPU and disk I/O headroom. The problem: network bandwidth is saturated. Brokers can't send/receive data fast enough.

This simulates scenarios where network throughput is the bottleneck — common with low-tier cloud instances or oversubscribed network switches.

## Prerequisites

- [Kind](https://kind.sigs.k8s.io/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- Docker running

## Setup

```bash
./setup.sh
```

This creates a Kind cluster with:
- 3 Kafka brokers (throttled to 50 Mbit/s network)
- 1 Zookeeper instance
- Prometheus + Grafana for monitoring

## Your Task

1. Access Grafana: http://localhost:30300 (admin/admin)
2. Check Kafka metrics and identify the bottleneck
3. Investigate the network throttling
4. Remove the bandwidth limit
5. Verify performance improves
6. Run `./verify.sh` to confirm

## Hints

Hint 1: Check network traffic control rules with: kubectl exec -n kafka kafka-0 -- tc qdisc show

Hint 2: The network is throttled using Linux tc (traffic control) with a token bucket filter

Hint 3: Remove throttling with: kubectl exec -n kafka kafka-0 -- tc qdisc del dev eth0 root

Hint 4: You'll need to remove throttling from all 3 Kafka pods

## Cleanup

```bash
./teardown.sh
```
