#!/usr/bin/env bash
set -euo pipefail

echo "=== RamOps: Verifying fix ==="
echo ""

ISSUES=0

if ! limactl list | grep -q "lima-logserver.*Running"; then
  echo "FAIL: lima-logserver VM is not running."
  exit 1
fi

echo "[ok] VM is running."

DELETED_OPEN=$(limactl shell lima-logserver lsof 2>/dev/null | grep -c deleted || echo 0)

if [ "$DELETED_OPEN" -gt 0 ]; then
  echo "FAIL: $DELETED_OPEN deleted file(s) still open."
  ISSUES=$((ISSUES + 1))
else
  echo "[ok] No deleted files held open."
fi

DISK_USAGE=$(limactl shell lima-logserver df -h / | tail -1 | awk '{print $5}' | tr -d '%')

if [ "$DISK_USAGE" -gt 50 ]; then
  echo "FAIL: Disk usage still high: ${DISK_USAGE}%"
  ISSUES=$((ISSUES + 1))
else
  echo "[ok] Disk usage is reasonable: ${DISK_USAGE}%"
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
echo "  - No deleted files held open"
echo "  - Disk space has been freed"
echo "  - You understand inodes and file descriptors"
echo "============================================"
