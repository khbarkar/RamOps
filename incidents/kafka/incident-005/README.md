# Kafka Disk-Bound Brokers

**Difficulty:** Intermediate
**Category:** Kafka / Performance
**Time estimate:** 20-25 minutes

## Scenario

Your Kafka cluster is experiencing growing consumer lag. Producers are backing up, and the monitoring dashboard shows high disk I/O wait times. CPU and network look fine, but something is bottlenecking the brokers.

The issue: Kafka brokers are experiencing slow disk I/O (simulated with continuous disk writes). This prevents them from flushing messages to disk quickly, causing producer timeouts and consumer lag.

## Prerequisites

- [Kind](https://kind.sigs.k8s.io/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- Docker running

## Setup

```bash
./setup.sh
```

This creates a Kind cluster with:
- 3 Kafka brokers (with simulated slow disk)
- 1 Zookeeper instance
- Prometheus + Grafana for monitoring

## Your Task

1. Access Grafana: http://localhost:30300 (admin/admin)
2. Check Kafka metrics and identify the bottleneck
3. Investigate the disk I/O issue
4. Find and stop the process causing disk pressure
5. Verify performance improves
6. Run `./verify.sh` to confirm

## Hints

Hint 1: Check pod resource usage with kubectl top pods -n kafka

Hint 2: Look for processes doing heavy disk I/O inside the Kafka pods with ps aux

Hint 3: The disk throttling is simulated by a background dd process writing to disk continuously

Hint 4: Kill the dd process to remove the disk bottleneck

## Cleanup

```bash
./teardown.sh
```
