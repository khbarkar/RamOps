#!/usr/bin/env bash
set -euo pipefail

SCENARIO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== RamOps: Kafka Disk-Bound Brokers ==="
echo ""

# Detect architecture and VM provider
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
  echo "Detected ARM architecture (Apple Silicon)"

  # Check for QEMU (free, open source option)
  if command -v qemu-system-aarch64 &> /dev/null && vagrant plugin list 2>/dev/null | grep -q vagrant-qemu; then
    VM_PROVIDER="qemu"
    echo "Using QEMU provider (free, open source)"
  # Check for VMware Fusion
  elif (command -v vmrun &> /dev/null || [ -f "/Applications/VMware Fusion.app/Contents/Library/vmrun" ]) && \
       vagrant plugin list 2>/dev/null | grep -q vagrant-vmware-desktop && \
       [ -f "/opt/vagrant-vmware-desktop/bin/vagrant-vmware-utility" ]; then
    VM_PROVIDER="vmware_desktop"
    # Add VMware to PATH if needed
    [ -f "/Applications/VMware Fusion.app/Contents/Library/vmrun" ] && export PATH="/Applications/VMware Fusion.app/Contents/Library:$PATH"
    echo "Using VMware Fusion provider"
  # Check for Parallels
  elif command -v prlctl &> /dev/null && vagrant plugin list 2>/dev/null | grep -q vagrant-parallels; then
    VM_PROVIDER="parallels"
    echo "Using Parallels Desktop provider"
  else
    echo ""
    echo "ERROR: No ARM-compatible VM provider found."
    echo ""
    echo "Install one of the following:"
    echo ""
    echo "Option 1 - QEMU (FREE, recommended):"
    echo "  brew install qemu"
    echo "  vagrant plugin install vagrant-qemu"
    echo ""
    echo "Option 2 - VMware Fusion (free for personal use, requires account):"
    echo "  Download from: https://www.vmware.com/products/desktop-hypervisor/workstation-and-fusion"
    echo "  vagrant plugin install vagrant-vmware-desktop"
    echo "  Download utility from: https://www.vagrantup.com/downloads/vmware"
    echo ""
    echo "Option 3 - Parallels Desktop (commercial, 14-day trial):"
    echo "  brew install --cask parallels"
    echo "  vagrant plugin install vagrant-parallels"
    echo ""
    exit 1
  fi
else
  echo "Detected x86_64 architecture"

  if command -v VBoxManage &> /dev/null; then
    VM_PROVIDER="virtualbox"
  else
    echo ""
    echo "ERROR: VirtualBox is required."
    echo "Install from: https://www.virtualbox.org/"
    echo ""
    exit 1
  fi
fi

# Check vagrant
if ! command -v vagrant &> /dev/null; then
  echo "Error: 'vagrant' is required but not installed."
  echo "Install from: https://www.vagrantup.com/"
  exit 1
fi

# Check python3
if ! command -v python3 &> /dev/null; then
  echo "Error: 'python3' is required but not installed."
  exit 1
fi

echo "Cleaning up previous run..."
vagrant destroy -f 2>/dev/null || true
rm -f *.vdi

echo ""
echo "Starting VMs with $VM_PROVIDER (this takes ~5-10 minutes)..."
echo "  - 3 Kafka brokers with slow disk I/O throttling"
echo "  - 1 monitoring VM (Prometheus + Grafana)"
echo ""

vagrant up --provider="$VM_PROVIDER"

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
echo "    - kafka1: 192.168.56.11:9092"
echo "    - kafka2: 192.168.56.12:9092"
echo "    - kafka3: 192.168.56.13:9092"
echo ""
echo "  Monitoring:"
echo "    - Grafana: http://localhost:3000 (admin/admin)"
echo "    - Prometheus: http://localhost:9090"
echo ""
echo "  Each broker has:"
echo "    - 10MB/s disk write throttle (simulates slow disk)"
echo "    - 2GB RAM, 2 CPUs"
echo "    - 24 partitions spread across 3 brokers"
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
echo "    - RequestHandlerAvgIdlePercent near 0"
echo ""
echo "  STEPS:"
echo "    1. Open Grafana (http://localhost:3000)"
echo "    2. View the Kafka dashboard"
echo "    3. Run load generator:"
echo "       python3 scripts/load-generator.py --duration 600"
echo ""
echo "    4. Watch metrics:"
echo "       - Consumer lag graph"
echo "       - Disk I/O wait"
echo "       - Produce latency p99"
echo ""
echo "    5. Fix the bottleneck:"
echo "       - SSH into a broker: vagrant ssh kafka1"
echo "       - Remove I/O throttle (see solution.md)"
echo "       - Watch lag drain"
echo ""
echo "============================================"
echo ""
echo "Run ./verify.sh to check if the fix worked."
