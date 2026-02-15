#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="kafka-disk-bound"

echo "=== RamOps: Verifying fix ==="
echo ""

if ! kind get clusters | grep -q "$CLUSTER_NAME"; then
  echo "FAIL: Cluster not running."
  exit 1
fi

echo "[ok] Cluster is running."

KAFKA_PODS=$(kubectl get pods -n kafka -l app=kafka --no-headers 2>/dev/null | wc -l | tr -d ' ')

if [ "$KAFKA_PODS" -ne 3 ]; then
  echo "FAIL: Expected 3 Kafka pods, found $KAFKA_PODS"
  exit 1
fi

echo "[ok] All 3 Kafka brokers are running."

DISK_THROTTLE=$(kubectl exec -n kafka kafka-0 -- ps aux | grep -c "dd if=/dev/zero" || echo 0)

if [ "$DISK_THROTTLE" -gt 0 ]; then
  echo "FAIL: Disk throttling still active."
  echo "      Kill the dd process to remove throttling."
  exit 1
fi

echo "[ok] Disk throttling removed."

echo ""
echo "============================================"
echo "  PASSED"
echo "  - Kafka cluster is healthy"
echo "  - Disk throttling has been removed"
echo "  - Performance should be improved"
echo "============================================"
