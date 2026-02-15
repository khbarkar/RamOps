#!/usr/bin/env bash
# Ram Ops Installer

set -euo pipefail

REPO_URL="https://github.com/khbarkar/openRam"
INSTALL_DIR="$HOME/.ramops"
BIN_DIR="$HOME/.local/bin"

echo "Installing Ram Ops..."

# Create bin directory
mkdir -p "$BIN_DIR"

# Clone repo
if [ ! -d "$INSTALL_DIR" ]; then
  git clone "$REPO_URL" "$INSTALL_DIR"
else
  cd "$INSTALL_DIR" && git pull
fi

# Symlink to bin
ln -sf "$INSTALL_DIR/ramops" "$BIN_DIR/ramops"

# Add to PATH if needed
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
  echo ""
  echo "Add this to your ~/.zshrc or ~/.bashrc:"
  echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

echo ""
echo "✓ Ram Ops installed!"
echo ""
echo "Run: ramops"
