#!/usr/bin/env bash
set -euo pipefail

SCENARIO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== RamOps: Hard Link Deployment Trap ==="
echo ""

# Detect architecture and set provider
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
  echo "Detected ARM architecture (Apple Silicon)"

  # Check for QEMU first (free and works well)
  if vagrant plugin list | grep -q vagrant-qemu; then
    echo "Using QEMU provider"
    VM_PROVIDER="qemu"
  # Then check for VMware
  elif command -v vmrun &> /dev/null && vagrant plugin list | grep -q vagrant-vmware-desktop; then
    echo "Using VMware Fusion provider"
    VM_PROVIDER="vmware_desktop"
  # Then check for Parallels
  elif command -v prlctl &> /dev/null && vagrant plugin list | grep -q vagrant-parallels; then
    echo "Using Parallels provider"
    VM_PROVIDER="parallels"
  else
    echo ""
    echo "No compatible VM provider found for ARM Mac."
    echo ""
    echo "Install one of the following:"
    echo ""
    echo "Option 1 (Recommended - Free):"
    echo "  brew install qemu"
    echo "  vagrant plugin install vagrant-qemu"
    echo ""
    echo "Option 2 (Commercial):"
    echo "  brew install --cask vmware-fusion"
    echo "  vagrant plugin install vagrant-vmware-desktop"
    echo ""
    echo "Option 3 (Commercial):"
    echo "  brew install --cask parallels"
    echo "  vagrant plugin install vagrant-parallels"
    echo ""
    exit 1
  fi
else
  echo "Detected x86_64 architecture"
  VM_PROVIDER="virtualbox"

  # Check if VirtualBox is installed
  if ! command -v VBoxManage &> /dev/null; then
    echo ""
    echo "VirtualBox is required for x86 systems."
    echo "Install from: https://www.virtualbox.org/"
    echo ""
    exit 1
  fi
fi

# Check vagrant
if ! command -v vagrant &> /dev/null; then
  echo "Error: 'vagrant' is required but not installed."
  echo "Install from: https://www.vagrantup.com/"
  exit 1
fi

echo "Cleaning up previous run..."
vagrant destroy -f 2>/dev/null || true
rm -rf .vagrant

echo ""
echo "Starting VM with $VM_PROVIDER..."
vagrant up --provider="$VM_PROVIDER"

echo ""
echo "=== Phase 1: Deploying v1.0.0 (working config) ==="

# Create configs directory on VM
vagrant ssh -c "mkdir -p /home/vagrant/configs /home/vagrant/app"

# Create v1 config
vagrant ssh -c "cat > /home/vagrant/configs/config.v1.json" <<'EOF'
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

# Create v2 config (broken - invalid JSON)
vagrant ssh -c "cat > /home/vagrant/configs/config.v2.json" <<'EOF'
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

# Create app.py on VM
vagrant ssh -c "cat > /home/vagrant/app/app.py" <<'PYEOF'
#!/usr/bin/env python3
import json
import time

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
PYEOF

vagrant ssh -c "chmod +x /home/vagrant/app/app.py"

# Deploy v1 using hard link
vagrant ssh -c "cd /home/vagrant/app && ln ../configs/config.v1.json config.json"

# Start app in background
vagrant ssh -c "cd /home/vagrant/app && nohup python3 app.py > app.log 2>&1 & echo \$! > app.pid"

sleep 3
echo ""
echo "App is running with v1.0.0 config (working)."
vagrant ssh -c "tail -3 /home/vagrant/app/app.log"
echo ""
sleep 2

echo "=== Phase 2: Attempting to deploy v2.0.0 (broken config) ==="
echo ""

# The "deployment" - remove old hard link and create new one
vagrant ssh -c "cd /home/vagrant/app && rm config.json && ln ../configs/config.v2.json config.json"

sleep 3

# App will crash because v2 config has invalid JSON
echo "Checking app health..."
sleep 2

APP_RUNNING=$(vagrant ssh -c "ps -p \$(cat /home/vagrant/app/app.pid 2>/dev/null || echo 0) > /dev/null 2>&1 && echo yes || echo no" | tr -d '\r')

if [ "$APP_RUNNING" = "yes" ]; then
  echo "App is still running... checking logs..."
else
  echo "App has crashed!"
fi

echo ""
vagrant ssh -c "tail -5 /home/vagrant/app/app.log"
echo ""

sleep 2

echo "=== Phase 3: Attempting rollback to v1.0.0 ==="
echo ""

# The "rollback" - but the hard link means this doesn't work as expected
vagrant ssh -c "cd /home/vagrant/app && rm config.json && ln ../configs/config.v1.json config.json"

echo "Rollback complete. Restarting app..."
vagrant ssh -c "cd /home/vagrant/app && nohup python3 app.py > app.log 2>&1 & echo \$! > app.pid"

sleep 3

APP_RUNNING=$(vagrant ssh -c "ps -p \$(cat /home/vagrant/app/app.pid 2>/dev/null || echo 0) > /dev/null 2>&1 && echo yes || echo no" | tr -d '\r')

if [ "$APP_RUNNING" = "yes" ]; then
  echo "App restarted... checking behavior..."
else
  echo "App crashed again on startup!"
fi

echo ""
vagrant ssh -c "tail -5 /home/vagrant/app/app.log"
echo ""

echo "============================================"
echo ""
echo "  SCENARIO: Hard Link Deployment Trap"
echo ""
echo "  WHAT HAPPENED:"
echo "  Your deployment system uses hard links to rotate"
echo "  config files atomically."
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
echo "--------------------------------------------"
echo ""
echo "  YOUR GOAL:"
echo "  Understand why the rollback failed and fix it."
echo ""
echo "  STEPS:"
echo "    1. SSH into the VM: vagrant ssh"
echo "    2. cd /home/vagrant/configs"
echo "    3. ls -li    # check inode numbers"
echo "    4. cat config.v1.json config.v2.json"
echo "    5. Fix the config files and deployment"
echo ""
echo "============================================"
echo ""
echo "Run ./verify.sh when the app is running with clean v1 config."
