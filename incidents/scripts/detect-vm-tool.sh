#!/usr/bin/env bash
# Detect best VM tool for the current system

detect_vm_tool() {
  local arch=$(uname -m)
  local os=$(uname -s)
  
  if [ "$arch" = "arm64" ] || [ "$arch" = "aarch64" ]; then
    # ARM architecture (Apple Silicon)
    
    # Check for Lima (best for multi-VM on Mac)
    if command -v limactl &> /dev/null; then
      echo "lima"
      return 0
    fi
    
    # Check for QEMU + Vagrant (limited networking)
    if command -v qemu-system-aarch64 &> /dev/null && vagrant plugin list 2>/dev/null | grep -q vagrant-qemu; then
      echo "vagrant-qemu"
      return 0
    fi
    
    # Check for VMware Fusion
    if (command -v vmrun &> /dev/null || [ -f "/Applications/VMware Fusion.app/Contents/Library/vmrun" ]) && \
       vagrant plugin list 2>/dev/null | grep -q vagrant-vmware-desktop; then
      echo "vagrant-vmware"
      return 0
    fi
    
    # Check for Parallels
    if command -v prlctl &> /dev/null && vagrant plugin list 2>/dev/null | grep -q vagrant-parallels; then
      echo "vagrant-parallels"
      return 0
    fi
    
    echo "none"
    return 1
  else
    # x86_64 architecture
    
    # Check for VirtualBox + Vagrant
    if command -v VBoxManage &> /dev/null && command -v vagrant &> /dev/null; then
      echo "vagrant-virtualbox"
      return 0
    fi
    
    echo "none"
    return 1
  fi
}

print_install_instructions() {
  local arch=$(uname -m)
  
  if [ "$arch" = "arm64" ] || [ "$arch" = "aarch64" ]; then
    cat <<EOF

ERROR: No compatible VM tool found for Apple Silicon.

Recommended option - Lima (FREE, best networking support):
  brew install lima

Alternative options:

Option 2 - VMware Fusion + Vagrant (free for personal use):
  Download from: https://www.vmware.com/products/desktop-hypervisor/workstation-and-fusion
  brew install vagrant
  vagrant plugin install vagrant-vmware-desktop

Option 3 - QEMU + Vagrant (free, limited multi-VM networking):
  brew install qemu vagrant
  vagrant plugin install vagrant-qemu

Option 4 - Parallels + Vagrant (commercial, 14-day trial):
  brew install --cask parallels vagrant
  vagrant plugin install vagrant-parallels

EOF
  else
    cat <<EOF

ERROR: VirtualBox and Vagrant are required.

Install with:
  brew install virtualbox vagrant

Or download from:
  - VirtualBox: https://www.virtualbox.org/
  - Vagrant: https://www.vagrantup.com/

EOF
  fi
}

# If run directly, detect and print
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  VM_TOOL=$(detect_vm_tool)
  if [ "$VM_TOOL" = "none" ]; then
    print_install_instructions
    exit 1
  fi
  echo "$VM_TOOL"
fi
