#!/usr/bin/env bash
set -euo pipefail

SCENARIO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Stopping app..."
if [ -f "$SCENARIO_DIR/app.pid" ]; then
  kill $(cat "$SCENARIO_DIR/app.pid") 2>/dev/null || true
fi

pkill -f "python.*app.py" 2>/dev/null || true

echo "Cleaning up..."
rm -rf "$SCENARIO_DIR/app" "$SCENARIO_DIR/configs" "$SCENARIO_DIR/app.log" "$SCENARIO_DIR/app.pid"

echo "Done."
