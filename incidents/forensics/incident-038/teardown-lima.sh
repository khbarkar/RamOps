#!/usr/bin/env bash
set -euo pipefail

INSTANCE_NAME="lima-backdoor"

echo "Cleaning up Backdoor User Account scenario..."

limactl delete --force "$INSTANCE_NAME" 2>/dev/null || true

echo "Cleanup complete!"
