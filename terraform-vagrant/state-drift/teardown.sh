#!/usr/bin/env bash
set -euo pipefail

SCENARIO_DIR="$(cd "$(dirname "$0")" && pwd)"
TF_DIR="$SCENARIO_DIR/tf"

echo "Destroying Terraform resources..."
if [ -f "$TF_DIR/terraform.tfstate" ]; then
  terraform -chdir="$TF_DIR" destroy -auto-approve -input=false 2>/dev/null || true
fi

echo "Destroying VM..."
vagrant destroy -f

echo "Cleaning up..."
rm -rf "$TF_DIR/.terraform" "$TF_DIR/.terraform.lock.hcl" "$TF_DIR/terraform.tfstate" "$TF_DIR/terraform.tfstate.backup"
rm -rf "$SCENARIO_DIR/generated"
rm -rf "$SCENARIO_DIR/.vagrant"

echo "Done."
