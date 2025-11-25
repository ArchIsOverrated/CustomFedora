#!/bin/bash
set -Eeuo pipefail

trap 'echo "Error on line $LINENO while running: $BASH_COMMAND" >&2' ERR

check_for_settings_file() {
    if [[ ! -f ./settings.conf ]]; then
        echo "ERROR: settings.conf not found! Creating one now..."
          cat <<EOF > ./settings.conf
# GPU Passthrough Settings
VFIO_ENABLED=0
SELECTED_GPU_IDS=""
EOF
    fi
}

select_vfio_mode() {
  read -p "Enter Passthrough mode? 1 = yes 0 = no " VFIO_ENABLED
  if [[ "$VFIO_ENABLED" != "0" && "$VFIO_ENABLED" != "1" ]]; then
    echo "Invalid input. Please enter 1 for yes or 0 for no."
    exit 1
  fi
}

select_gpu() {
  source ./settings.conf
  # Get all GPU-type devices
  mapfile -t GPUS < <(lspci -nn | grep -Ei "VGA compatible controller|3D controller|Display controller")

  echo "Detected GPU devices:"
  for i in "${!GPUS[@]}"; do
    # Simple echo-based menu, 1-based index
    echo "$((i + 1))) ${GPUS[$i]}"
  done

  echo
  read -r -p "Select a GPU [1-${#GPUS[@]}]: " CHOICE

  GPU_LINE="${GPUS[$((CHOICE - 1))]}"

  # Validate choice
  if [[ -z "$GPU_LINE" ]]; then
    echo "Invalid selection. Exiting."
    exit 1
  fi

  # Extract PCI address (e.g. 01:00.0)
  GPU_PCI=$(awk '{print $1}' <<< "$GPU_LINE")

  # Strip the function (.0) → e.g. 01:00
  SLOT="${GPU_PCI%.*}"

  # Get all vendor:device IDs for this slot (GPU + audio, etc.)
  GPU_IDS=$(lspci -nn -s "$SLOT" \
    | grep -oE '\[[0-9a-fA-F]{4}:[0-9a-fA-F]{4}\]' \
    | tr -d '[]' \
    | paste -sd "," -)

  echo "PCI IDs for all devices on slot: $SLOT"
  SELECTED_GPU_IDS="$GPU_IDS"
}



# Example usage:
check_for_settings_file
select_vfio_mode
select_gpu