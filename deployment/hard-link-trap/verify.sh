#!/usr/bin/env bash
set -euo pipefail

SCENARIO_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$SCENARIO_DIR/app"
CONFIG_DIR="$SCENARIO_DIR/configs"

echo "=== RamOps: Verifying fix ==="
echo ""

ISSUES=0

# Check if app is running
if [ ! -f "$SCENARIO_DIR/app.pid" ]; then
  echo "FAIL: No app process found."
  ISSUES=$((ISSUES + 1))
else
  APP_PID=$(cat "$SCENARIO_DIR/app.pid")
  if ! ps -p "$APP_PID" > /dev/null 2>&1; then
    echo "FAIL: App process is not running."
    ISSUES=$((ISSUES + 1))
  else
    echo "[ok] App is running."
  fi
fi

# Check that config.json exists
if [ ! -f "$APP_DIR/config.json" ]; then
  echo "FAIL: config.json does not exist in app directory."
  ISSUES=$((ISSUES + 1))
fi

# Check that config is valid JSON
if ! jq empty "$APP_DIR/config.json" 2>/dev/null; then
  echo "FAIL: config.json is not valid JSON."
  ISSUES=$((ISSUES + 1))
else
  echo "[ok] config.json is valid JSON."
fi

# Check that config is v1 (not v2)
if [ -f "$APP_DIR/config.json" ]; then
  VERSION=$(jq -r '.version' "$APP_DIR/config.json" 2>/dev/null || echo "unknown")
  if [ "$VERSION" = "1.0.0" ]; then
    echo "[ok] App is running with v1.0.0 config."
  else
    echo "FAIL: App is running with version '$VERSION', expected '1.0.0'."
    ISSUES=$((ISSUES + 1))
  fi
fi

# Check that config files are NOT hard linked (different inodes)
if [ -f "$CONFIG_DIR/config.v1.json" ] && [ -f "$CONFIG_DIR/config.v2.json" ]; then
  V1_INODE=$(ls -i "$CONFIG_DIR/config.v1.json" | awk '{print $1}')
  V2_INODE=$(ls -i "$CONFIG_DIR/config.v2.json" | awk '{print $1}')

  if [ "$V1_INODE" = "$V2_INODE" ]; then
    echo "FAIL: config.v1.json and config.v2.json share the same inode ($V1_INODE)."
    echo "      They should be separate files, not hard links."
    ISSUES=$((ISSUES + 1))
  else
    echo "[ok] config.v1.json and config.v2.json are separate files (different inodes)."
  fi
fi

# Check that v1 config is actually v1 content
if [ -f "$CONFIG_DIR/config.v1.json" ]; then
  V1_VERSION=$(jq -r '.version' "$CONFIG_DIR/config.v1.json" 2>/dev/null || echo "unknown")
  if [ "$V1_VERSION" != "1.0.0" ]; then
    echo "FAIL: config.v1.json contains wrong version '$V1_VERSION'."
    echo "      It should contain v1.0.0 content."
    ISSUES=$((ISSUES + 1))
  fi
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
