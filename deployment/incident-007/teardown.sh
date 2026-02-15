#!/usr/bin/env bash
set -euo pipefail

SCENARIO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Destroying VM..."
vagrant destroy -f

echo "Cleaning up..."
rm -rf .vagrant

echo "Done."
