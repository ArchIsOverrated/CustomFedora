#!/bin/bash
set -Eeuo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Please run this script with sudo:"
  echo "  sudo $0"
  exit 1
fi

configure_hooks() {
  # Create hooks directory if it doesn't exist
  mkdir -p "$QEMU_HOOKS_DIR"

  VM_DIR
  echo "Hooks configured successfully in $QEMU_HOOKS_DIR"

  mkdir -p "$VM_DIR"
  
}

HOOKS_DIR="../hooks"
QEMU_HOOKS_DIR="$HOOKS_DIR/qemu.d"
VM_DIR="$QEMU_HOOKS_DIR/$1"

configure_hooks

trap 'echo "Error on line $LINENO while running: $BASH_COMMAND" >&2' ERR


