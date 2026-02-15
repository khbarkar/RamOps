#!/usr/bin/env bash
set -euo pipefail

SCENARIO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Destroying VMs..."
vagrant destroy -f

echo "Cleaning up Vagrant state..."
rm -rf .vagrant

echo "Done."
