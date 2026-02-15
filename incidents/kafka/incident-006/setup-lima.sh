#!/usr/bin/env bash
set -euo pipefail

SCENARIO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== RamOps: Kafka Network-Bound Brokers (Lima) ==="
echo ""

if ! command -v limactl &> /dev/null; then
  echo "ERROR: Lima is not installed. Run: brew install lima"
  exit 1
fi

if ! brew list socket_vmnet &>/dev/null; then
  echo "ERROR: socket_vmnet is required for multi-VM networking."
  echo ""
  read -p "Install socket_vmnet now? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    brew install socket_vmnet
    brew tap homebrew/services
    HOMEBREW_PREFIX=$(brew --prefix)
    sudo ${HOMEBREW_PREFIX}/opt/socket_vmnet/bin/socket_vmnet --pidfile=/var/run/socket_vmnet.pid /var/run/socket_vmnet &
    sleep 2
  else
    echo "Cannot proceed without socket_vmnet."
    exit 1
  fi
fi

if [ ! -f ~/.lima/_config/override.yaml ]; then
  echo "Configuring Lima networking..."
  mkdir -p ~/.lima/_config
  SOCKET_VMNET_PATH=$(brew --prefix socket_vmnet)/bin/socket_vmnet
  cat > ~/.lima/_config/override.yaml << EOF
networks:
  - lima: shared
    socketVMNet: ${SOCKET_VMNET_PATH}
EOF
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

limactl shell lima-monitoring sudo systemctl start zookeeper
sleep 5
limactl shell lima-kafka1 sudo systemctl start kafka &
limactl shell lima-kafka2 sudo systemctl start kafka &
limactl shell lima-kafka3 sudo systemctl start kafka &
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
