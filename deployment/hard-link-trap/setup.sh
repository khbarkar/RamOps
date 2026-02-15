#!/usr/bin/env bash
set -euo pipefail

SCENARIO_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$SCENARIO_DIR/app"
CONFIG_DIR="$SCENARIO_DIR/configs"

echo "=== RamOps: Hard Link Deployment Trap ==="
echo ""

# Clean up any previous run
rm -rf "$APP_DIR" "$CONFIG_DIR"
pkill -f "python.*app.py" 2>/dev/null || true

# Create directories
mkdir -p "$APP_DIR" "$CONFIG_DIR"

# Create a simple Python app that reads its config
cat > "$APP_DIR/app.py" <<'EOF'
#!/usr/bin/env python3
import json
import time
import os

CONFIG_FILE = "config.json"

def load_config():
    with open(CONFIG_FILE, 'r') as f:
        return json.load(f)

def main():
    print("Starting app...")
    while True:
        try:
            config = load_config()
            print(f"[{time.strftime('%H:%M:%S')}] Running with config: {config}")
            time.sleep(5)
        except Exception as e:
            print(f"Error loading config: {e}")
            time.sleep(5)

if __name__ == "__main__":
    main()
EOF

chmod +x "$APP_DIR/app.py"

# Create initial v1 config (working)
cat > "$CONFIG_DIR/config.v1.json" <<'EOF'
{
  "version": "1.0.0",
  "feature_flags": {
    "new_api": false,
    "debug_mode": false
  },
  "database": {
    "host": "localhost",
    "port": 5432
  }
}
EOF

# Create v2 config (broken - invalid JSON on purpose)
cat > "$CONFIG_DIR/config.v2.json" <<'EOF'
{
  "version": "2.0.0",
  "feature_flags": {
    "new_api": true,
    "debug_mode": true,
    "experimental_cache": true
  },
  "database": {
    "host": "localhost",
    "port": 5432,
    "pool_size": 50
  }
  "cache": {
    "enabled": true
  }
}
EOF

echo "=== Phase 1: Deploying v1.0.0 (working config) ==="
echo ""

# Create a hard link to v1 config
ln "$CONFIG_DIR/config.v1.json" "$APP_DIR/config.json"

echo "Starting the app with v1 config..."
cd "$APP_DIR"
python3 app.py > "$SCENARIO_DIR/app.log" 2>&1 &
APP_PID=$!
echo $APP_PID > "$SCENARIO_DIR/app.pid"

sleep 3
echo ""
echo "App is running with v1.0.0 config (working)."
echo ""
tail -3 "$SCENARIO_DIR/app.log"
echo ""
sleep 2

echo "=== Phase 2: Attempting to deploy v2.0.0 (broken config) ==="
echo ""
echo "An engineer runs the deployment script to rotate to v2..."
echo ""

# The "deployment" - remove old hard link and create new one
# But they use hard links, so both links point to the same inode
rm "$APP_DIR/config.json"
ln "$CONFIG_DIR/config.v2.json" "$APP_DIR/config.json"

sleep 3

echo "Deployment complete. Checking app health..."
sleep 2

# The app will crash because v2 config has invalid JSON
if ps -p $APP_PID > /dev/null 2>&1; then
  echo ""
  echo "App is still running... checking logs..."
else
  echo ""
  echo "App has crashed!"
fi

echo ""
tail -5 "$SCENARIO_DIR/app.log"
echo ""

sleep 2

echo "=== Phase 3: Attempting rollback to v1.0.0 ==="
echo ""
echo "The engineer panics and runs the rollback script..."
echo ""

# The "rollback" - but the hard link means this doesn't work as expected
rm "$APP_DIR/config.json"
ln "$CONFIG_DIR/config.v1.json" "$APP_DIR/config.json"

echo "Rollback complete. Restarting app..."
cd "$APP_DIR"
python3 app.py > "$SCENARIO_DIR/app.log" 2>&1 &
APP_PID=$!
echo $APP_PID > "$SCENARIO_DIR/app.pid"

sleep 3

echo ""
if ps -p $APP_PID > /dev/null 2>&1; then
  echo "App restarted... checking behavior..."
else
  echo "App crashed again on startup!"
fi

echo ""
tail -5 "$SCENARIO_DIR/app.log"
echo ""

echo "============================================"
echo ""
echo "  SCENARIO: Hard Link Deployment Trap"
echo ""
echo "  WHAT HAPPENED:"
echo "  Your deployment system uses hard links to rotate"
echo "  config files atomically. The process:"
echo ""
echo "    1. v1 deployed: ln config.v1.json config.json"
echo "    2. v2 deployed: rm config.json && ln config.v2.json config.json"
echo "    3. Rollback:    rm config.json && ln config.v1.json config.json"
echo ""
echo "  The v2 config had a syntax error (invalid JSON)."
echo "  The app crashed. The engineer rolled back."
echo ""
echo "  BUT THE ROLLBACK DIDN'T WORK."
echo ""
echo "  THE PROBLEM:"
echo "  Hard links share the same inode. When the engineer"
echo "  edited config.v2.json to fix the bug, they actually"
echo "  modified the inode that BOTH config.v1.json AND"
echo "  config.v2.json point to."
echo ""
echo "  Now config.v1.json has the v2 content (broken)."
echo "  Rolling back just creates a new hard link to the"
echo "  same corrupted inode."
echo ""
echo "  CURRENT STATE:"
echo "    - config.v1.json: CORRUPTED (has v2 content)"
echo "    - config.v2.json: same inode as v1"
echo "    - config.json:    hard link to corrupted v1"
echo "    - App: CRASHED or running with broken config"
echo ""
echo "--------------------------------------------"
echo ""
echo "  YOUR GOAL:"
echo "  Understand why the rollback failed and fix it."
echo ""
echo "  STEPS:"
echo "    1. Examine the config files and their inodes"
echo "       (use 'ls -li' to see inode numbers)"
echo "    2. Understand why v1 and v2 share the same data"
echo "    3. Fix the deployment to use proper file copies"
echo "       or symlinks instead of hard links"
echo "    4. Restore a working v1 config"
echo ""
echo "  Start with:"
echo "    cd configs/"
echo "    ls -li        # check inode numbers"
echo "    cat config.v1.json config.v2.json"
echo ""
echo "============================================"
echo ""
echo "Run ../verify.sh when the app is running with clean v1 config."
