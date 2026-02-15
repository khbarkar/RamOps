#!/usr/bin/env bash
set -euo pipefail

echo "=== Cleaning up Lima VM ==="
limactl stop alertmanager 2>/dev/null || true
limactl delete alertmanager 2>/dev/null || true
echo "Cleanup complete!"
