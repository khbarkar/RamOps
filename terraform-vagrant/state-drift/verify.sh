#!/usr/bin/env bash
set -euo pipefail

SCENARIO_DIR="$(cd "$(dirname "$0")" && pwd)"
TF_DIR="$SCENARIO_DIR/tf"

echo "=== RamOps: Verifying fix ==="
echo ""

if [ ! -f "$TF_DIR/terraform.tfstate" ]; then
  echo "FAIL: No Terraform state found."
  exit 1
fi

# Check terraform plan shows no drift
PLAN_OUTPUT=$(terraform -chdir="$TF_DIR" plan -detailed-exitcode -input=false 2>&1) || PLAN_EXIT=$?
PLAN_EXIT=${PLAN_EXIT:-0}

if [ "$PLAN_EXIT" -eq 2 ]; then
  echo "FAIL: Terraform still detects drift."
  echo ""
  echo "$PLAN_OUTPUT"
  exit 1
elif [ "$PLAN_EXIT" -eq 1 ]; then
  echo "FAIL: Terraform plan returned an error."
  echo "$PLAN_OUTPUT"
  exit 1
fi

echo "[ok] Terraform plan shows no changes."

# Check that security issues are resolved
ISSUES=0

APP_CONFIG="$SCENARIO_DIR/generated/app-config.json"

if jq -e '.admin_backdoor' "$APP_CONFIG" &>/dev/null; then
  echo "FAIL: app-config.json still contains 'admin_backdoor' key."
  ISSUES=$((ISSUES + 1))
fi

if jq -e '.debug_mode == true' "$APP_CONFIG" &>/dev/null; then
  echo "FAIL: app-config.json still has debug_mode enabled."
  ISSUES=$((ISSUES + 1))
fi

LOG_LEVEL=$(jq -r '.log_level' "$APP_CONFIG")
if [ "$LOG_LEVEL" != "warn" ]; then
  echo "FAIL: log_level is '$LOG_LEVEL', expected 'warn'."
  ISSUES=$((ISSUES + 1))
fi

if [ "$ISSUES" -gt 0 ]; then
  echo ""
  echo "FAIL: Drift resolved but security issues remain."
  exit 1
fi

echo "[ok] Security issues resolved."
echo ""
echo "============================================"
echo "  PASSED"
echo "  - No drift detected"
echo "  - Security issues fixed"
echo "============================================"
