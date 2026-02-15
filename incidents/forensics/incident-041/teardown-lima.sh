#!/usr/bin/env bash
set -euo pipefail

INSTANCE_NAME="lima-revshell"

echo "Cleaning up Reverse Shell Discovery scenario..."

limactl delete --force "$INSTANCE_NAME" 2>/dev/null || true

echo "Cleanup complete!"
