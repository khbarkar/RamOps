#!/usr/bin/env bash
set -euo pipefail

echo "=== Migrating scenarios to incident-XXX naming ==="
echo ""

cd "$(dirname "$0")"

# Rename directories
echo "Renaming directories..."

if [ -d "kubernetes/single-pod-crashloop" ]; then
  mv kubernetes/single-pod-crashloop kubernetes/incident-001
  echo "✓ kubernetes/single-pod-crashloop → kubernetes/incident-001"
fi

if [ -d "kubernetes/node-not-ready" ]; then
  mv kubernetes/node-not-ready kubernetes/incident-002
  echo "✓ kubernetes/node-not-ready → kubernetes/incident-002"
fi

if [ -d "kubernetes/dns-outage" ]; then
  mv kubernetes/dns-outage kubernetes/incident-003
  echo "✓ kubernetes/dns-outage → kubernetes/incident-003"
fi

if [ -d "kubernetes/storage-volume-full" ]; then
  mv kubernetes/storage-volume-full kubernetes/incident-004
  echo "✓ kubernetes/storage-volume-full → kubernetes/incident-004"
fi

if [ -d "kafka/disk-bound-brokers" ]; then
  mv kafka/disk-bound-brokers kafka/incident-005
  echo "✓ kafka/disk-bound-brokers → kafka/incident-005"
fi

if [ -d "kafka/network-bound-brokers" ]; then
  mv kafka/network-bound-brokers kafka/incident-006
  echo "✓ kafka/network-bound-brokers → kafka/incident-006"
fi

if [ -d "deployment/hard-link-trap" ]; then
  mv deployment/hard-link-trap deployment/incident-007
  echo "✓ deployment/hard-link-trap → deployment/incident-007"
fi

echo ""
echo "Renaming solution.md files to root-cause-analysis.md..."

for dir in kubernetes/incident-* kafka/incident-* deployment/incident-*; do
  if [ -f "$dir/solution.md" ]; then
    mv "$dir/solution.md" "$dir/root-cause-analysis.md"
    echo "✓ $dir/solution.md → $dir/root-cause-analysis.md"
  fi
done

echo ""
echo "✓ Migration complete!"
