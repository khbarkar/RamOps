#!/usr/bin/env bash
set -euo pipefail

SCENARIO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== RamOps: Infrastructure Drift Detection ==="
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
echo "Starting VM with $VM_PROVIDER..."
vagrant up --provider="$VM_PROVIDER"

echo ""
echo "Initializing Terraform and applying initial configuration..."
vagrant ssh -c 'cd /vagrant/tf && terraform init && terraform apply -auto-approve'

echo ""
echo "Simulating manual infrastructure changes (drift)..."
vagrant ssh -c '
  # Simulate someone manually changing managed resources
  echo "Manually modified content - DRIFT!" > /tmp/managed-resources/app-config.txt
  echo "unauthorized-key" > /tmp/managed-resources/api-key.txt
  rm -f /tmp/managed-resources/database-backup.txt
'

echo ""
echo "============================================"
echo ""
echo "  SCENARIO: Infrastructure Drift"
echo ""
echo "  SETUP COMPLETE"
echo ""
echo "  Infrastructure was deployed with Terraform,"
echo "  but someone made manual changes directly."
echo ""
echo "  Your task:"
echo "    1. SSH into the VM: vagrant ssh"
echo "    2. Navigate to: cd /vagrant/tf"
echo "    3. Detect drift: terraform plan"
echo "    4. Understand what changed"
echo "    5. Restore infrastructure: terraform apply"
echo ""
echo "  Current state:"
echo "    - Terraform state expects specific resources"
echo "    - Actual infrastructure has been modified"
echo "    - Drift needs to be detected and resolved"
echo ""
echo "============================================"
echo ""
echo "Run ./verify.sh to check if drift is resolved."
