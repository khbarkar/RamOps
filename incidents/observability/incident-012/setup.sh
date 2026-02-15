#!/usr/bin/env bash
set -euo pipefail

SCENARIO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== RamOps: Alert Storm from Single Root Cause ==="
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
    echo "Option 2 - VMware Fusion (free for personal use):"
    echo "  Download from: https://www.vmware.com/products/desktop-hypervisor/workstation-and-fusion"
    echo "  vagrant plugin install vagrant-vmware-desktop"
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

echo "Cleaning up previous run..."
vagrant destroy -f 2>/dev/null || true

echo ""
echo "Starting VM with $VM_PROVIDER (this takes ~5 minutes)..."
vagrant up --provider="$VM_PROVIDER"

echo ""
echo "Waiting for Prometheus and Alertmanager to start..."
sleep 20

echo ""
echo "Triggering the incident (disk full)..."
vagrant ssh -c 'sudo dd if=/dev/zero of=/var/lib/postgresql/data/fillup.bin bs=1M count=950 2>/dev/null || true'

echo ""
echo "Waiting for alert storm to develop (30s)..."
sleep 30

echo ""
echo "============================================"
echo ""
echo "  SCENARIO: Alert Storm"
echo ""
echo "  SETUP COMPLETE"
echo ""
echo "  Multiple alerts are now firing due to a"
echo "  single root cause. Your phone is buzzing"
echo "  non-stop at 3am."
echo ""
echo "  Access points:"
echo "    - Alertmanager: http://localhost:9093"
echo "    - Prometheus: http://localhost:9090"
echo ""
echo "  Current state:"
echo "    - 15+ alerts firing"
echo "    - All symptoms of one root cause"
echo "    - Database disk is full"
echo ""
echo "  Your tasks:"
echo "    1. Open Alertmanager to see the storm"
echo "    2. Identify the root cause alert"
echo "    3. SSH in and fix: vagrant ssh"
echo "    4. Check disk: df -h"
echo "    5. Clear space: sudo rm /var/lib/postgresql/data/fillup.bin"
echo "    6. Configure alert grouping in Alertmanager"
echo ""
echo "============================================"
echo ""
echo "Run ./verify.sh when you've fixed the issue and improved alerts."
