#!/usr/bin/env bash
set -euo pipefail

SCENARIO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== RamOps: Kafka Disk-Bound Brokers (Lima) ==="
echo ""

# Check for Lima
if ! command -v limactl &> /dev/null; then
  echo "ERROR: Lima is not installed."
  echo ""
  echo "Install with:"
  echo "  brew install lima"
  echo ""
  exit 1
fi

# Check python3
if ! command -v python3 &> /dev/null; then
  echo "ERROR: python3 is required but not installed."
  exit 1
fi

echo "Cleaning up previous run..."
limactl stop lima-monitoring lima-kafka1 lima-kafka2 lima-kafka3 2>/dev/null || true
limactl delete lima-monitoring lima-kafka1 lima-kafka2 lima-kafka3 2>/dev/null || true

echo ""
echo "Starting VMs with Lima (this takes ~5-10 minutes)..."
echo "  - 1 monitoring VM (Zookeeper + Prometheus + Grafana)"
echo "  - 3 Kafka brokers with slow disk I/O throttling"
echo ""

# Start monitoring first (has Zookeeper)
echo "Starting monitoring VM..."
limactl start --tty=false "$SCENARIO_DIR/lima-monitoring.yaml"

echo "Waiting for Zookeeper to be ready..."
sleep 20

# Start Kafka brokers in parallel
echo "Starting Kafka brokers..."
limactl start --tty=false "$SCENARIO_DIR/lima-kafka1.yaml" &
limactl start --tty=false "$SCENARIO_DIR/lima-kafka2.yaml" &
limactl start --tty=false "$SCENARIO_DIR/lima-kafka3.yaml" &
wait

echo ""
echo "Starting Kafka services..."
limactl shell lima-monitoring sudo systemctl start zookeeper
sleep 5
limactl shell lima-kafka1 sudo systemctl start kafka &
limactl shell lima-kafka2 sudo systemctl start kafka &
limactl shell lima-kafka3 sudo systemctl start kafka &
wait

echo ""
echo "Waiting for Kafka cluster to stabilize..."
sleep 30

echo ""
echo "Installing Python Kafka client on host..."
pip3 install kafka-python 2>/dev/null || pip3 install --user kafka-python || echo "Note: Install kafka-python manually if this failed"

echo ""
echo "============================================"
echo ""
echo "  SCENARIO: Kafka Disk-Bound Brokers"
echo ""
echo "  SETUP COMPLETE"
echo ""
echo "  Kafka Cluster:"
echo "    - kafka1: localhost:9092"
echo "    - kafka2: localhost:9093"
echo "    - kafka3: localhost:9094"
echo ""
echo "  Monitoring:"
echo "    - Grafana: http://localhost:3000 (admin/admin)"
echo "    - Prometheus: http://localhost:9090"
echo ""
echo "  Each broker has:"
echo "    - 10MB/s disk write throttle (simulates slow disk)"
echo "    - 2GB RAM, 2 CPUs"
echo ""
echo "--------------------------------------------"
echo ""
echo "  THE SCENARIO:"
echo ""
echo "  You'll generate high-throughput load (100 MB/s)"
echo "  against brokers with throttled disk I/O."
echo ""
echo "  SYMPTOMS YOU'LL SEE:"
echo "    - Consumer lag growing steadily"
echo "    - High disk I/O wait on brokers"
echo "    - Produce request latency increasing"
echo ""
echo "  STEPS:"
echo "    1. Open Grafana (http://localhost:3000)"
echo "    2. Run load generator:"
echo "       python3 scripts/load-generator.py --duration 600"
echo ""
echo "    3. SSH into a broker:"
echo "       limactl shell kafka1"
echo ""
echo "    4. Check disk I/O:"
echo "       iostat -x 1"
echo ""
echo "    5. Fix the bottleneck (see solution.md)"
echo ""
echo "============================================"
echo ""
echo "Run ./verify-lima.sh to check if the fix worked."
echo "Run ./teardown-lima.sh to clean up."
