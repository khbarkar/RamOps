#!/usr/bin/env bash
set -euo pipefail

echo "=== RamOps: Verifying alert storm resolution ==="
echo ""

# Check if disk space has been freed
DISK_USAGE=$(vagrant ssh -c 'df -h /var/lib/postgresql/data | tail -1 | awk "{print \$5}"' | tr -d '%')

echo "Database disk usage: ${DISK_USAGE}%"

if [ "$DISK_USAGE" -gt 90 ]; then
  echo ""
  echo "FAIL: Disk is still full (${DISK_USAGE}% used)."
  echo ""
  echo "Fix the root cause first:"
  echo "  vagrant ssh"
  echo "  df -h"
  echo "  sudo rm /var/lib/postgresql/data/fillup.bin"
  exit 1
fi

echo "Disk space looks healthy"

# Check if Alertmanager has grouping configured
echo ""
echo "Checking Alertmanager configuration..."

ALERTMANAGER_CONFIG=$(vagrant ssh -c 'cat /etc/alertmanager/alertmanager.yml 2>/dev/null' || echo "")

if [ -z "$ALERTMANAGER_CONFIG" ]; then
  echo "FAIL: Cannot read Alertmanager config"
  exit 1
fi

# Check for group_by configuration
if echo "$ALERTMANAGER_CONFIG" | grep -q "group_by:"; then
  echo "Found alert grouping configuration"

  # Check if it groups by severity or alertname
  if echo "$ALERTMANAGER_CONFIG" | grep -E "group_by:.*\[(.*severity.*|.*alertname.*)\]" > /dev/null; then
    echo "Grouping is configured properly (by severity or alertname)"
  else
    echo ""
    echo "WARNING: group_by is present but may not be optimal."
    echo "Consider grouping by: [alertname, severity, cluster]"
  fi
else
  echo ""
  echo "FAIL: Alert grouping is not configured."
  echo ""
  echo "Edit /etc/alertmanager/alertmanager.yml and add grouping:"
  echo ""
  echo "route:"
  echo "  group_by: ['alertname', 'severity']"
  echo "  group_wait: 10s"
  echo "  group_interval: 10s"
  echo "  repeat_interval: 1h"
  echo ""
  echo "Then reload: vagrant ssh -c 'sudo systemctl reload alertmanager'"
  exit 1
fi

# Check active alerts
echo ""
echo "Checking for active alerts..."

ACTIVE_ALERTS=$(vagrant ssh -c 'curl -s http://localhost:9093/api/v2/alerts | grep -o "\"status\":\"firing\"" | wc -l' 2>/dev/null || echo "0")

echo "Active firing alerts: $ACTIVE_ALERTS"

if [ "$ACTIVE_ALERTS" -gt 5 ]; then
  echo ""
  echo "WARNING: Still $ACTIVE_ALERTS alerts firing."
  echo "This might be normal immediately after the fix."
  echo "Alerts should resolve within a few minutes."
fi

# Verify Prometheus is healthy
PROM_HEALTH=$(vagrant ssh -c 'curl -s http://localhost:9090/-/healthy' 2>/dev/null || echo "fail")

if [ "$PROM_HEALTH" != "Prometheus is Healthy." ]; then
  echo ""
  echo "WARNING: Prometheus may not be healthy."
fi

echo ""
echo "============================================"
echo "  PASSED"
echo "  Root cause resolved and alerts improved."
echo "============================================"
echo ""
echo "Key learnings:"
echo ""
echo "1. Root Cause vs Symptoms:"
echo "   - Root: Disk full on database server"
echo "   - Symptoms: DB connection failures, API errors, cache misses"
echo ""
echo "2. Alert Design Best Practices:"
echo "   - Group related alerts together"
echo "   - Set alert dependencies (silence symptoms when root cause fires)"
echo "   - Use severity levels (critical, warning, info)"
echo "   - Include runbooks in alert annotations"
echo ""
echo "3. Alert Grouping Configuration:"
echo "   - Group by: alertname, severity, cluster, service"
echo "   - Use group_wait to batch related alerts"
echo "   - Set reasonable repeat_intervals to avoid spam"
echo ""
echo "4. Incident Response:"
echo "   - Start with the oldest/first alert"
echo "   - Look for infrastructure-level issues first"
echo "   - Fix root cause, not symptoms"
echo "   - Document for post-incident review"
