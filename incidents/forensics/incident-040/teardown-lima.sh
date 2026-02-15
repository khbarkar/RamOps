#!/usr/bin/env bash
set -euo pipefail

INSTANCE_NAME="lima-logtamper"

echo "Cleaning up Log Tampering scenario..."

limactl delete --force "$INSTANCE_NAME" 2>/dev/null || true

echo "Cleanup complete!"
