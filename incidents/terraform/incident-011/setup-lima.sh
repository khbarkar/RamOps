#!/usr/bin/env bash
set -euo pipefail

SCENARIO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== RamOps: Infrastructure Drift Detection (Lima) ==="
echo ""

if ! command -v limactl &> /dev/null; then
  echo "ERROR: Lima is not installed. Run: brew install lima"
  exit 1
fi

echo "Cleaning up previous run..."
limactl stop lima-terraform-drift 2>/dev/null || true
limactl delete lima-terraform-drift 2>/dev/null || true

echo ""
echo "Starting VM with Lima..."
limactl start --tty=false "$SCENARIO_DIR/lima-terraform-drift.yaml"

echo "Waiting for provisioning to complete..."
sleep 30

echo "Verifying setup..."
if limactl shell lima-terraform-drift test -d /opt/terraform; then
  echo "[ok] Terraform directory created"
else
  echo "WARN: /opt/terraform not found, provisioning may have failed"
  echo "Check logs with: limactl shell lima-terraform-drift journalctl -xe"
fi

echo ""
echo "============================================"
echo "  SCENARIO: Infrastructure Drift Detection"
echo "  SETUP COMPLETE"
echo ""
echo "  Terraform project: /opt/terraform"
echo "  SSH: limactl shell lima-terraform-drift"
echo "============================================"
