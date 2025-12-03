#!/bin/bash
set -Eeuo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Please run this script with sudo:"
  echo "  sudo $0"
  exit 1
fi

configure_hooks() {
  
}

trap 'echo "Error on line $LINENO while running: $BASH_COMMAND" >&2' ERR


