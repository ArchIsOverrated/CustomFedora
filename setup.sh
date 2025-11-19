#!/bin/bash
set -Eeuo pipefail

trap 'echo "Error on line $LINENO while running: $BASH_COMMAND" >&2' ERR

TARGET_USER="${SUDO_USER:-$USER}"

run_step() {
    local fail_msg="$1"
    shift
    if ! "$@"; then
        echo "$fail_msg"
        exit 1
    fi
}

update_system() {
    echo "Starting system update..."
    run_step "System update failed." sudo dnf update -y
    echo "System update completed successfully."
}

setup_snapshots() {
    echo "Setting up automatic snapshots..."

    run_step "Installation of snapper failed." \
        sudo dnf install snapper python3-dnf-plugin-snapper -y

    run_step "Creating snapper config failed." \
        sudo snapper -c root create-config /

    run_step "Enabling snapper timeline timer failed." \
        sudo systemctl enable --now snapper-timeline.timer

    run_step "Enabling snapper cleanup timer failed." \
        sudo systemctl enable --now snapper-cleanup.timer

    echo "Automatic snapshots setup completed successfully."
}

setup_virtualization_tools() {
    echo "Starting installation of virtualization tools..."

    run_step "Installation of virtualization tools failed." \
        sudo dnf group install --with-optional "virtualization" -y

    echo "Virtualization tools installed successfully."

    run_step "Enabling libvirtd service failed." \
        sudo systemctl enable libvirtd

    echo "libvirtd service enabled successfully."

    run_step "Adding user to libvirt group failed." \
        sudo usermod -aG libvirt "$TARGET_USER"

    echo "User $TARGET_USER added to libvirt group."
}

setup_desktop_environment() {
    echo "Starting installation of desktop environment..."

    run_step "Installation of desktop packages failed" \
        sudo dnf install sway \
            waybar \
            pavucontrol \
            gtk-murrine-engine \
            wofi \
            network-manager-applet \
            NetworkManager-tui \
            nm-connection-editor \
            firefox \
            sddm -y

    run_step "Enabling SDDM failed." \
        sudo systemctl enable sddm

    run_step "Setting default target to graphical failed." \
        sudo systemctl set-default graphical.target

    if [ ! -d "/home/$TARGET_USER/.themes" ]; then
        mkdir -p "/home/$TARGET_USER/.themes"
    fi

    run_step "Copying theme failed" \
        cp -rf ./.themes/Gruvbox-B-MB-Dark "/home/$TARGET_USER/.themes/"

    run_step "Copying config files failed" \
        cp ./.gtkrc-2.0 "/home/$TARGET_USER/"

    run_step "Copying config files failed" \
        cp -rf ./.config "/home/$TARGET_USER/.config"

    sudo chown -R "$TARGET_USER:$TARGET_USER" "/home/$TARGET_USER/.themes"
    sudo chown -R "$TARGET_USER:$TARGET_USER" "/home/$TARGET_USER/.config"
    sudo chown "$TARGET_USER:$TARGET_USER" "/home/$TARGET_USER/.gtkrc-2.0"

    echo "Desktop environment installed successfully."
}

update_system
setup_snapshots
setup_virtualization_tools
setup_desktop_environment
echo "Setup completed successfully."