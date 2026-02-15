#!/usr/bin/env bash
# Common VM provider detection for all scenarios
# Source this file in setup.sh scripts

detect_vm_provider() {
  ARCH=$(uname -m)

  if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
    echo "Detected ARM architecture (Apple Silicon)" >&2

    # Check for VMware Fusion
    if command -v vmrun &> /dev/null && vagrant plugin list 2>/dev/null | grep -q vagrant-vmware-desktop; then
      echo "vmware_desktop"
      return 0
    fi

    # Check for Parallels
    if command -v prlctl &> /dev/null && vagrant plugin list 2>/dev/null | grep -q vagrant-parallels; then
      echo "parallels"
      return 0
    fi

    # No ARM-compatible provider found
    echo "" >&2
    echo "ERROR: No ARM-compatible VM provider found." >&2
    echo "" >&2
    echo "For Apple Silicon Macs, install one of:" >&2
    echo "" >&2
    echo "Option 1 - VMware Fusion (recommended, free):" >&2
    echo "  brew install --cask vmware-fusion" >&2
    echo "  vagrant plugin install vagrant-vmware-desktop" >&2
    echo "" >&2
    echo "Option 2 - Parallels Desktop (paid):" >&2
    echo "  brew install --cask parallels" >&2
    echo "  vagrant plugin install vagrant-parallels" >&2
    echo "" >&2
    return 1
  else
    echo "Detected x86_64 architecture" >&2

    # Check for VirtualBox
    if command -v VBoxManage &> /dev/null; then
      echo "virtualbox"
      return 0
    fi

    # Check for VMware (also works on Intel)
    if command -v vmrun &> /dev/null && vagrant plugin list 2>/dev/null | grep -q vagrant-vmware-desktop; then
      echo "vmware_desktop"
      return 0
    fi

    # No provider found
    echo "" >&2
    echo "ERROR: No VM provider found." >&2
    echo "" >&2
    echo "Install VirtualBox:" >&2
    echo "  https://www.virtualbox.org/" >&2
    echo "" >&2
    return 1
  fi
}

# Export for use in scripts
export -f detect_vm_provider 2>/dev/null || true
