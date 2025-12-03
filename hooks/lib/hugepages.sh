#!/bin/bash

PROG_NAME=$(basename "$0")

# Decide what action based on the name we were called as
if [ "$PROG_NAME" = "allocpages.sh" ] || [ "$PROG_NAME" = "allocpages" ]; then
    ACTION="alloc"
else
    ACTION="remove"
fi

VM_NAME="$1"

if [ -z "$VM_NAME" ]; then
    echo "No VM Name"
    exit 1
fi

# Number of 2MiB hugepages to use (same for all VMs with this script)
HUGEPAGE_SIZE_KB=$(grep Hugepagesize /proc/meminfo | awk '{print $2}')

if [ -z "$HUGEPAGE_SIZE_KB" ]; then
    echo "Cannot determine hugepage size"
    exit 1
fi

LIBVIRT_XML_DIR="/etc/libvirt/qemu"
VM_XML="$LIBVIRT_XML_DIR/$VM_NAME.xml"

if [ ! -f "$VM_XML" ]; then
    echo "VM XML file $VM_XML not found"
    exit 1
fi

VM_MEM_KIB=$(grep "<memory" "$VM_XML" | head -n 1 | sed -E 's/.*>([0-9]+)<.*/\1/')
echo "Memory in KiB: $VM_MEM_KIB"


if [ -z "$VM_MEM_KIB" ]; then
    exit 0
fi

HUGEPAGES=$((VM_MEM_KIB / HUGEPAGE_SIZE_KB))

# If nothing set or invalid, do nothing
if [ "$HUGEPAGES" -le 0 ] 2>/dev/null; then
    exit 0
fi

HUGEPAGES_SYS_FILE="/proc/sys/vm/nr_hugepages"

if [ ! -w "$HUGEPAGES_SYS_FILE" ]; then
    echo "Cannot write to $HUGEPAGES_SYS_FILE (need root)" >&2
    exit 1
fi

current=$(cat "$HUGEPAGES_SYS_FILE")
if [ "$ACTION" = "alloc" ]; then
    target=$(( current + HUGEPAGES ))
else
    if [ "$current" -le "$HUGEPAGES" ]; then
        target=0
    else
        target=$(( current - HUGEPAGES ))
    fi
fi

echo "$target" > "$HP_SYS_FILE"

exit 0
