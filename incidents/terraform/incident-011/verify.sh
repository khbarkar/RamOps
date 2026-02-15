#!/usr/bin/env bash
set -euo pipefail

echo "=== RamOps: Verifying drift resolution ==="
echo ""

# Run terraform plan and check for drift
PLAN_OUTPUT=$(vagrant ssh -c 'cd /vagrant/tf && terraform plan -detailed-exitcode' 2>&1) || PLAN_EXIT=$?

# Exit code 0 = no changes needed (drift resolved)
# Exit code 1 = error
# Exit code 2 = changes needed (drift still exists)

if [ "${PLAN_EXIT:-0}" -eq 2 ]; then
  echo "FAIL: Drift still detected."
  echo ""
  echo "Terraform plan shows changes needed:"
  echo "$PLAN_OUTPUT"
  echo ""
  echo "Hint: Run 'terraform apply' to restore infrastructure to the desired state."
  exit 1
fi

if [ "${PLAN_EXIT:-0}" -eq 1 ]; then
  echo "FAIL: Terraform plan failed with an error."
  echo "$PLAN_OUTPUT"
  exit 1
fi

# Verify resources are in the expected state
echo "Checking managed resources..."

APP_CONFIG=$(vagrant ssh -c 'cat /tmp/managed-resources/app-config.txt 2>/dev/null || echo "MISSING"')
API_KEY=$(vagrant ssh -c 'cat /tmp/managed-resources/api-key.txt 2>/dev/null || echo "MISSING"')
DB_BACKUP=$(vagrant ssh -c 'cat /tmp/managed-resources/database-backup.txt 2>/dev/null || echo "MISSING"')

echo "  app-config.txt: $APP_CONFIG"
echo "  api-key.txt: $API_KEY"
echo "  database-backup.txt: $DB_BACKUP"

if [ "$APP_CONFIG" != "production-config-v1.2.3" ]; then
  echo ""
  echo "FAIL: app-config.txt has incorrect content."
  echo "Expected: production-config-v1.2.3"
  echo "Got: $APP_CONFIG"
  exit 1
fi

if [ "$API_KEY" != "prod-api-key-abc123" ]; then
  echo ""
  echo "FAIL: api-key.txt has incorrect content."
  echo "Expected: prod-api-key-abc123"
  echo "Got: $API_KEY"
  exit 1
fi

if [ "$DB_BACKUP" != "daily-backup-enabled" ]; then
  echo ""
  echo "FAIL: database-backup.txt has incorrect content."
  echo "Expected: daily-backup-enabled"
  echo "Got: $DB_BACKUP"
  exit 1
fi

echo ""
echo "============================================"
echo "  PASSED"
echo "  Infrastructure drift has been resolved."
echo "  All resources match Terraform state."
echo "============================================"
echo ""
echo "Key learnings:"
echo "  - Always use 'terraform plan' to detect drift"
echo "  - Manual changes bypass IaC and create inconsistencies"
echo "  - Implement drift detection in CI/CD pipelines"
echo "  - Use read-only credentials where possible"
echo "  - Enable cloud audit logs to track manual changes"
