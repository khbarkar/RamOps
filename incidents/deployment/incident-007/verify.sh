#!/usr/bin/env bash
set -euo pipefail

SCENARIO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== RamOps: Verifying fix ==="
echo ""

ISSUES=0

# Check if VM is running
if ! vagrant status | grep -q "app-server.*running"; then
  echo "FAIL: app-server VM is not running."
  exit 1
fi

echo "[ok] VM is running."

# Check if app is running
APP_RUNNING=$(vagrant ssh -c "ps -p \$(cat /home/vagrant/app/app.pid 2>/dev/null || echo 0) > /dev/null 2>&1 && echo yes || echo no" 2>/dev/null | tr -d '\r')

if [ "$APP_RUNNING" != "yes" ]; then
  echo "FAIL: App process is not running."
  ISSUES=$((ISSUES + 1))
else
  echo "[ok] App is running."
fi

# Check that config.json is valid JSON
vagrant ssh -c "cd /home/vagrant/app && python3 -m json.tool config.json > /dev/null" 2>/dev/null && echo "[ok] config.json is valid JSON." || {
  echo "FAIL: config.json is not valid JSON."
  ISSUES=$((ISSUES + 1))
}

# Check that config is v1 (not v2)
VERSION=$(vagrant ssh -c "cd /home/vagrant/app && python3 -c \"import json; print(json.load(open('config.json'))['version'])\"" 2>/dev/null | tr -d '\r')
if [ "$VERSION" = "1.0.0" ]; then
  echo "[ok] App is running with v1.0.0 config."
else
  echo "FAIL: App is running with version '$VERSION', expected '1.0.0'."
  ISSUES=$((ISSUES + 1))
fi

# Check that config files are NOT hard linked (different inodes)
V1_INODE=$(vagrant ssh -c "ls -i /home/vagrant/configs/config.v1.json" 2>/dev/null | awk '{print $1}' | tr -d '\r')
V2_INODE=$(vagrant ssh -c "ls -i /home/vagrant/configs/config.v2.json" 2>/dev/null | awk '{print $1}' | tr -d '\r')

if [ "$V1_INODE" = "$V2_INODE" ]; then
  echo "FAIL: config.v1.json and config.v2.json share the same inode ($V1_INODE)."
  echo "      They should be separate files, not hard links."
  ISSUES=$((ISSUES + 1))
else
  echo "[ok] config.v1.json and config.v2.json are separate files (different inodes)."
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
echo "  - App is running with valid v1.0.0 config"
echo "  - Config files are properly separated"
echo "  - Hard link trap has been fixed"
echo "============================================"
