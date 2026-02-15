#!/usr/bin/env bash
set -euo pipefail

SCENARIO_DIR="$(cd "$(dirname "$0")" && pwd)"
TF_DIR="$SCENARIO_DIR/tf"

echo "=== RamOps: Terraform State Drift (Vagrant) ==="
echo ""

# Check prerequisites
for cmd in terraform vagrant VBoxManage; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "Error: '$cmd' is required but not installed."
    [ "$cmd" = "VBoxManage" ] && echo "Install VirtualBox from https://www.virtualbox.org/"
    [ "$cmd" = "vagrant" ] && echo "Install Vagrant from https://www.vagrantup.com/"
    exit 1
  fi
done

# Clean up any previous run
echo "Cleaning up previous run..."
vagrant destroy -f 2>/dev/null || true
rm -rf "$TF_DIR/.terraform" "$TF_DIR/.terraform.lock.hcl" "$TF_DIR/terraform.tfstate" "$TF_DIR/terraform.tfstate.backup"
rm -rf "$SCENARIO_DIR/generated"
rm -rf "$SCENARIO_DIR/.vagrant"

echo ""
echo "Starting VM..."
vagrant up

echo ""
echo "Initializing Terraform..."
terraform -chdir="$TF_DIR" init -input=false

echo ""
echo "Applying Terraform configuration (creating managed resources)..."
terraform -chdir="$TF_DIR" apply -auto-approve -input=false

echo ""
echo "Terraform apply complete. Simulating out-of-band changes..."

# Drift 1: App config was manually edited
APP_CONFIG="$SCENARIO_DIR/generated/app-config.json"
jq '.log_level = "debug" | .debug_mode = true | .admin_backdoor = "enabled"' "$APP_CONFIG" > "$APP_CONFIG.tmp"
mv "$APP_CONFIG.tmp" "$APP_CONFIG"

# Drift 2: Nginx config was manually edited
NGINX_CONFIG="$SCENARIO_DIR/generated/nginx.conf"
cat >> "$NGINX_CONFIG" <<'DRIFT'

    # Added by on-call engineer
    location /admin {
        proxy_pass http://127.0.0.1:9090;
    }
DRIFT

echo ""
echo "============================================"
echo ""
echo "  SCENARIO: Terraform State Drift"
echo ""
echo "  CONTEXT:"
echo "  Infrastructure is managed with Terraform."
echo "  Someone made manual changes bypassing Terraform."
echo ""
echo "  WHAT THEY DID:"
echo ""
echo "  1. APP CONFIG (app-config.json):"
echo "     - Changed log_level to 'debug'"
echo "     - Enabled debug_mode"
echo "     - Added 'admin_backdoor' key"
echo "     -> Security risk!"
echo ""
echo "  2. NGINX CONFIG (nginx.conf):"
echo "     - Added /admin route"
echo "     -> Unauthorized endpoint!"
echo ""
echo "--------------------------------------------"
echo ""
echo "  YOUR GOAL:"
echo "  Use Terraform to detect and fix the drift."
echo ""
echo "  STEPS:"
echo "    1. cd tf/"
echo "    2. terraform plan    — detect drift"
echo "    3. terraform apply   — revert to managed state"
echo "    4. cd .. && ./verify.sh"
echo ""
echo "  VM Access:"
echo "    vagrant ssh"
echo ""
echo "============================================"
echo ""
echo "Run ./verify.sh when drift is resolved."
