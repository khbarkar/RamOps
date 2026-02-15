#!/usr/bin/env bash
set -euo pipefail

echo "=== Cleaning up Lima VM ==="
limactl stop lima-alertmanager 2>/dev/null || true
limactl delete lima-alertmanager 2>/dev/null || true
echo "Cleanup complete!"
