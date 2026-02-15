#!/usr/bin/env bash
set -euo pipefail

SCENARIO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== RamOps: Kafka Network-Bound Brokers (Lima) ==="
echo ""

if ! command -v limactl &> /dev/null; then
  echo "ERROR: Lima is not installed. Run: brew install lima"
  exit 1
fi

echo "Cleaning up previous run..."
limactl stop kafka1 kafka2 kafka3 monitoring 2>/dev/null || true
limactl delete kafka1 kafka2 kafka3 monitoring 2>/dev/null || true

echo ""
echo "Starting VMs with Lima..."
limactl start --tty=false "$SCENARIO_DIR/lima-monitoring.yaml"
sleep 20

limactl start --tty=false "$SCENARIO_DIR/lima-kafka1.yaml" &
limactl start --tty=false "$SCENARIO_DIR/lima-kafka2.yaml" &
limactl start --tty=false "$SCENARIO_DIR/lima-kafka3.yaml" &
wait

limactl shell monitoring sudo systemctl start zookeeper
sleep 5
limactl shell kafka1 sudo systemctl start kafka &
limactl shell kafka2 sudo systemctl start kafka &
limactl shell kafka3 sudo systemctl start kafka &
wait

sleep 30

echo ""
echo "============================================"
echo "  SCENARIO: Kafka Network-Bound Brokers"
echo "  SETUP COMPLETE"
echo ""
echo "  Kafka: localhost:9092-9094"
echo "  Grafana: http://localhost:3000"
echo "  Prometheus: http://localhost:9090"
echo "============================================"
