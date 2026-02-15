#!/usr/bin/env bash
set -euo pipefail

echo "=== Provisioning App Server ==="

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y python3 python3-pip jq

echo "App server provisioned"
