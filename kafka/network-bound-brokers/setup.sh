#!/usr/bin/env bash
set -euo pipefail

SCENARIO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== RamOps: Kafka Network-Bound Brokers ==="
echo ""

# Check prerequisites
for cmd in vagrant VBoxManage python3; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "Error: '$cmd' is required but not installed."
    [ "$cmd" = "VBoxManage" ] && echo "Install VirtualBox from https://www.virtualbox.org/"
    [ "$cmd" = "vagrant" ] && echo "Install Vagrant from https://www.vagrantup.com/"
    exit 1
  fi
done

echo "Cleaning up previous run..."
vagrant destroy -f 2>/dev/null || true

echo ""
echo "Starting VMs (this takes ~5-10 minutes)..."
echo "  - 3 Kafka brokers with 50 Mbit/s network throttling"
echo "  - 1 monitoring VM (Prometheus + Grafana)"
echo ""

vagrant up

echo ""
echo "Waiting for Kafka cluster to stabilize..."
sleep 30

echo ""
echo "Installing Python Kafka client on host..."
pip3 install kafka-python 2>/dev/null || pip3 install --user kafka-python || echo "Note: Install kafka-python manually if this failed"

echo ""
echo "============================================"
echo ""
echo "  SCENARIO: Kafka Network-Bound Brokers"
echo ""
echo "  SETUP COMPLETE"
echo ""
echo "  Kafka Cluster:"
echo "    - kafka1: 192.168.56.11:9092"
echo "    - kafka2: 192.168.56.12:9092"
echo "    - kafka3: 192.168.56.13:9092"
echo ""
echo "  Monitoring:"
echo "    - Grafana: http://localhost:3000 (admin/admin)"
echo "    - Prometheus: http://localhost:9090"
echo ""
echo "  Each broker has:"
echo "    - 50 Mbit/s network bandwidth cap (simulates slow network)"
echo "    - 2GB RAM, 2 CPUs"
echo "    - 24 partitions spread across 3 brokers"
echo ""
echo "--------------------------------------------"
echo ""
echo "  THE SCENARIO:"
echo ""
echo "  You'll generate high-throughput load (100 MB/s)"
echo "  against brokers with throttled network bandwidth."
echo ""
echo "  SYMPTOMS YOU'LL SEE:"
echo "    - Consumer lag growing"
echo "    - Network bytes in/out near 50 Mbit/s cap"
echo "    - Fetch/produce request queueing"
echo "    - High request queue time"
echo ""
echo "  STEPS:"
echo "    1. Open Grafana (http://localhost:3000)"
echo "    2. View the Kafka dashboard"
echo "    3. Run load generator:"
echo "       python3 scripts/load-generator.py --duration 600"
echo ""
echo "    4. Watch metrics:"
echo "       - Network bytes in/out (should plateau at ~50 Mbit/s)"
echo "       - Consumer lag growing"
echo "       - Request queue time"
echo ""
echo "    5. Fix the bottleneck:"
echo "       - SSH into brokers: vagrant ssh kafka1"
echo "       - Remove network throttle (see solution.md)"
echo "       - Watch throughput increase and lag drain"
echo ""
echo "============================================"
echo ""
echo "Run ./verify.sh to check if the fix worked."
