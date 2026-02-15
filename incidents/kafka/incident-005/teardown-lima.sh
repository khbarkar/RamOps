#!/usr/bin/env bash
set -euo pipefail

echo "=== Cleaning up Kafka Lima VMs ==="

limactl stop kafka1 kafka2 kafka3 monitoring 2>/dev/null || true
limactl delete kafka1 kafka2 kafka3 monitoring 2>/dev/null || true

echo "Cleanup complete!"
