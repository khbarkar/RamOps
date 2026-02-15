#!/usr/bin/env bash
set -euo pipefail

echo "=== Cleaning up Lima VM ==="
limactl stop lima-terraform-drift 2>/dev/null || true
limactl delete lima-terraform-drift 2>/dev/null || true
echo "Cleanup complete!"
