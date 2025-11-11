#!/bin/bash
set -euo pipefail

zypper -n update
zypper -n install xorg-x11-server labwc lightdm grim rofi-wayland swaybg waybar
update-alternatives --set default-displaymanager /usr/sbin/lightdm
zypper -n install -t pattern kvm_server kvm_tools
systemctl enable --now libvirtd
systemctl enable --now virtlogd
usermod -aG libvirt,kvm $USER
