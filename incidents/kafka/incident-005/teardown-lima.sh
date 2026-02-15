#!/usr/bin/env bash
set -euo pipefail

echo "=== Cleaning up Kafka Lima VMs ==="

limactl stop lima-monitoring lima-kafka1 lima-kafka2 lima-kafka3 2>/dev/null || true
limactl delete lima-monitoring lima-kafka1 lima-kafka2 lima-kafka3 2>/dev/null || true

echo "Cleanup complete!"
