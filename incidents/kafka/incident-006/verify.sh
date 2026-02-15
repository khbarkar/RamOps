#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="kafka-network-bound"

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

THROTTLE_CHECK=$(kubectl exec -n kafka kafka-0 -- tc qdisc show dev eth0 2>/dev/null | grep -c "tbf" || echo 0)

if [ "$THROTTLE_CHECK" -gt 0 ]; then
  echo "FAIL: Network throttling still active."
  echo "      Remove tc qdisc rules to fix."
  exit 1
fi

echo "[ok] Network throttling removed."

echo ""
echo "============================================"
echo "  PASSED"
echo "  - Kafka cluster is healthy"
echo "  - Network throttling has been removed"
echo "  - Bandwidth should be improved"
echo "============================================"
