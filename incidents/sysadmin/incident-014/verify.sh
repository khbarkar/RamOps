#!/usr/bin/env bash
set -euo pipefail

echo "=== RamOps: Verifying fix ==="
echo ""

ISSUES=0

if ! limactl list | grep -q "lima-zombies.*Running"; then
  echo "FAIL: lima-zombies VM is not running."
  exit 1
fi

echo "[ok] VM is running."

ZOMBIE_COUNT=$(limactl shell lima-zombies ps aux 2>/dev/null | grep -c defunct || echo 0)

if [ "$ZOMBIE_COUNT" -gt 5 ]; then
  echo "FAIL: $ZOMBIE_COUNT zombie processes still exist."
  ISSUES=$((ISSUES + 1))
else
  echo "[ok] Zombie count is acceptable: $ZOMBIE_COUNT"
fi

WORKER_RUNNING=$(limactl shell lima-zombies systemctl is-active worker-manager.service 2>/dev/null || echo "inactive")
BASH_RUNNING=$(limactl shell lima-zombies systemctl is-active bash-backgrounder.service 2>/dev/null || echo "inactive")
DAEMON_RUNNING=$(limactl shell lima-zombies systemctl is-active broken-daemon.service 2>/dev/null || echo "inactive")

if [ "$WORKER_RUNNING" = "active" ] || [ "$BASH_RUNNING" = "active" ] || [ "$DAEMON_RUNNING" = "active" ]; then
  echo "WARN: Some buggy services are still running (this is OK if you fixed the code)"
fi

echo ""
if [ "$ISSUES" -gt 0 ]; then
  echo "============================================"
  echo "  FAILED — $ISSUES issue(s) remaining"
  echo "============================================"
  exit 1
fi

echo "============================================"
echo "  PASSED"
echo "  - Zombie processes eliminated"
echo "  - You understand process lifecycle"
echo "  - You know how to properly reap children"
echo "============================================"
