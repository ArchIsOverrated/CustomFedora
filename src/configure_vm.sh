#!/bin/bash
set -Eeuo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Please run this script with sudo:"
  echo "  sudo $0 <vm-name>"
  exit 1
fi

trap 'echo "Error on line $LINENO while running: $BASH_COMMAND" | tee -a ./configure_vm.log >&2' ERR

usage() {
  echo "Usage: $0 <vm-name>"
  echo
  echo "This script configures libvirt hooks and XML for the specified VM."
  echo
  echo "Arguments:"
  echo "  vm-name    The name of the virtual machine to configure."
  exit 1
}

if [[ "${1:-}" == "-h" || $# -lt 1 ]]; then
  usage
fi

VM_NAME="$1"
HOOKS_DIR="/etc/libvirt/hooks"
QEMU_HOOKS_DIR="$HOOKS_DIR/qemu.d"
VM_DIR="$QEMU_HOOKS_DIR/$VM_NAME"
XML_PATH="/etc/libvirt/qemu/${VM_NAME}.xml"

configure_hooks() {
  # Create hooks directory if needed
  if [[ ! -d "$HOOKS_DIR" ]]; then
    cp -r "../hooks" "/etc/libvirt"
  fi

  # Create per-VM directory
  if [[ ! -d "$VM_DIR" ]]; then
    mkdir -p "$VM_DIR"
  fi
}

configure_xml() {
  if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 is not installed! exiting"
    exit 1
  fi

  echo
  echo "Detected CPU core layout:"
  cat /sys/devices/system/cpu/cpu*/topology/thread_siblings_list | sort -u | sort -t',' -t'-' -n
  echo

  read -rp "Enter comma-separated host CPU IDs to pin to (example: 2,3,4,5): " CPU_LIST

  echo "Applying hugepages + CPU pinning to XML..."
  python3 configure_xml.py "$XML_PATH" "$CPU_LIST"

  echo "XML updated successfully."
}

configure_hooks
configure_xml

echo
echo "VM configuration completed for $VM_NAME"
