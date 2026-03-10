#!/usr/bin/env bash
set -euo pipefail

echo "Destroying VM..."
limactl stop lima-alertmanager 2>/dev/null || true
limactl delete -f lima-alertmanager 2>/dev/null || true
echo "Done."
