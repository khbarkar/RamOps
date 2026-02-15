#!/usr/bin/env bash
set -euo pipefail

echo "Destroying VM..."
vagrant destroy -f
echo "Done."
