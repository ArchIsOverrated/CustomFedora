#!/bin/bash
set -euo pipefail

TARGET_USER="${SUDO_USER:-$USER}"

update_system() {
    echo "Starting system update..."
    sudo dnf update -y
    if [ $? -ne 0 ]; then
        echo "System update failed."
        exit 1
    fi
    echo "System update completed successfully."
}

setup_virtualization_tools() {
    echo "Starting installation of virtualization tools..."
    sudo dnf group install --with-optional "virtualization" -y
    if [ $? -ne 0 ]; then
        echo "Installation of virtualization tools failed."
        exit 1
    fi
    echo "Virtualization tools installed successfully."

    sudo systemctl enable libvirtd
        if [ $? -ne 0 ]; then
            echo "Enabling libvirtd service failed."
            exit 1
        fi
        echo "libvirtd service enabled successfully."

    sudo usermod -aG libvirt $TARGET_USER
    if [ $? -ne 0 ]; then
        echo "Adding user to libvirt group failed."
        exit 1
    fi
    echo "User $TARGET_USER added to libvirt group."
}

setup_desktop_environment() {
    echo "Starting installation of desktop environment..." # I have installed sway, waybar, firefox and sddm, and gtk-murrine-engine rofi-wayland
    sudo dnf install sway \
    waybar \
    pavuconrol \
    gtk-murrine-engine \
    wofi \
    network-manager-applet \
    NetworkManager-tui \
    nm-connection-editor \
    firefox \
    sddm -y
    if [ $? -ne 0 ]; then
        echo "Installation of desktop packages failed"
        exit 1
    fi

    sudo systemctl enable sddm
    if [ $? -ne 0 ]; then
        echo "Enabling SDDM failed."
        exit 1
    fi

    sudo systemctl set-default graphical.target
    if [ $? -ne 0 ]; then
        echo "Setting default target to graphical failed."
        exit 1
    fi

    mkdir -p ~/.config/sway
    if [ $? -ne 0 ]; then
       echo "Making ~/.config/sway failed"
       exit 1
    fi

    cp /etc/sway/config ~/.config/sway/
    if [ $? -ne 0 ]; then
       echo "Copying config failed"
       exit 1
    fi

    cp -r /etc/xdg/waybar ~/.config/waybar
    if [ $? -ne 0 ]; then
       echo "Copying waybar config failed"
       exit 1
    fi

    if [ ! -d "/home/$TARGET_USER/.themes" ]; then
        mkdir -p "/home/$TARGET_USER/.themes"
    fi

    cp -r ./.themes/Gruvbox-B-MB-Dark "/home/$TARGET_USER/.themes/Gruvbox-B-MB-Dark"
    if [ $? -ne 0 ]; then
       echo "Copying theme failed"
       exit 1
    fi

    if [ ! -d "/home/$TARGET_USER/.config/gtk-3.0" ]; then
        mkdir -p "/home/$TARGET_USER/.config/gtk-3.0"
    fi

    if [ ! -d "/home/$TARGET_USER/.config/gtk-4.0" ]; then
        mkdir -p "/home/$TARGET_USER/.config/gtk-4.0"
    fi

    if [ ! -d "/home/$TARGET_USER/.config/sway" ]; then
        mkdir -p "/home/$TARGET_USER/.config/sway"
    fi

    cp ./gtkrc-2.0 "/home/$TARGET_USER/.gtkrc-2.0"
    if [ $? -ne 0 ]; then
       echo "Copying gtk-2.0 settings failed"
       exit 1
    fi

    cp ./.config/settings.ini "/home/$TARGET_USER/.config/gtk-3.0/"
    if [ $? -ne 0 ]; then
       echo "Copying gtk-3.0 settings failed"
       exit 1
    fi

    cp ./ConfigFiles/gtk-4.0settings.ini "/home/$TARGET_USER/.config/gtk-4.0/"
    if [ $? -ne 0 ]; then
       echo "Copying gtk-4.0 settings failed"
       exit 1
    fi

    cp ./.config/sway "/home/$TARGET_USER/.config/sway/config"
    if [ $? -ne 0 ]; then
       echo "Copying sway config settings failed"
       exit 1
    fi

    echo "Desktop environment installed successfully."
}

update_system
setup_virtualization_tools
#setup_desktop_environment
