#!/bin/sh -e

color_echo() {
    local color="$1"
    local text="$2"
    case "$color" in
        "red")     echo -e "\033[0;31m$text\033[0m" ;;
        "green")   echo -e "\033[0;32m$text\033[0m" ;;
        "yellow")  echo -e "\033[1;33m$text\033[0m" ;;
        "blue")    echo -e "\033[0;34m$text\033[0m" ;;
        *)         echo "$text" ;;
    esac
}

installflathub() {
    color_echo "yellow" "Enabling Flathub..."
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    color_echo "green" "Flathub Enabled"
}
installflathub

removefedoraflatpak() {
    color_echo "yellow" "Checking for Fedora Flatpak..."
    if flatpak remotes | grep -q fedora; then
        color_echo "yellow" "Removing Fedora Flatpak..."
        if flatpak remote-delete fedora; then
            color_echo "green" "Fedora Flatpak removed"
        else
            color_echo "red" "Failed to remove Fedora Flatpak"
            exit 1
        fi
    else
        color_echo "green" "Fedora Flatpak is not installed"
    fi
}
removefedoraflatpak

installRPMFusion() {
    if [ ! -e /etc/yum.repos.d/rpmfusion-free.repo ] || [ ! -e /etc/yum.repos.d/rpmfusion-nonfree.repo ]; then
        color_echo "yellow" "Installing RPM Fusion..."
        sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
        sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1
        sudo dnf config-manager setopt rpmfusion-nonfree-updates.enabled=1
        sudo dnf config-manager setopt rpmfusion-free-updates.enabled=1
        color_echo "green" "RPM Fusion installed and enabled"
    else
        color_echo "green" "RPM Fusion already installed"
    fi
}
installRPMFusion

installFFmpeg() {
    color_echo "yellow" "Installing FFmpeg..."
    sudo dnf swap ffmpeg-free ffmpeg --allowerasing -y
    if [ $? -ne 0 ]; then
        color_echo "red" "Failed to install FFmpeg"
        exit 1
    fi
    color_echo "green" "FFmpeg installed"
}
installFFmpeg

# Asking for CPU information
color_echo "blue" "Select your CPU manufacturer:"
color_echo "yellow" "1. INTEL"
color_echo "yellow" "2. AMD"

while true; do
    echo "Enter your choice (1 or 2): "
    read choice
    case "$choice" in
        1)
            CPU_INFO="INTEL"
            break
            ;;
        2)
            CPU_INFO="AMD"
            break
            ;;
        *)
            color_echo "red" "Invalid choice. Please enter '1' for INTEL or '2' for AMD."
            ;;
    esac
done

# Ask for GPU information
color_echo "green" "Select your GPU manufacturer:"
color_echo "yellow" "1. INTEL"
color_echo "yellow" "2. AMD"
color_echo "yellow" "3. NVIDIA"

while true; do
    echo "Enter your choice (1,2 or 3): "
    read choice
    case "$choice" in
        1)
            GPU_INFO="INTEL"
            break
            ;;
        2)
            GPU_INFO="AMD"
            break
            ;;
        3)
            GPU_INFO="NVIDIA"
            break
            ;;
        *)
            color_echo "red" "Invalid choice. Please enter '1' for INTEL, '2' for AMD, or '3' for NVIDIA."
            ;;
    esac
done

color_echo "yellow" "You have provided the following:"
color_echo "red" "CPU: $CPU_INFO"
color_echo "red" "GPU: $GPU_INFO"

# Install the necessary drivers for Intel
if [ "$CPU_INFO" = "INTEL" ] || [ "$GPU_INFO" = "INTEL" ]; then
    sudo dnf install intel-media-driver -y

fi

# install the necessary drivers for AMD
if [ "$CPU_INFO" = "AMD" ] || [ "$GPU_INFO" = "AMD" ]; then
    sudo dnf swap mesa-va-drivers mesa-va-drivers-freeworld -y
    sudo dnf swap mesa-vdpau-drivers mesa-vdpau-drivers-freeworld
fi

# Install the necessary drivers for NVIDIA
if [ "$GPU_INFO" = "NVIDIA" ]; then
    color_echo "red" "Make sure you are on the latest kernel version!"
    sudo dnf install akmod-nvidia xorg-x11-drv-nvidia-cuda -y
    color_echo "red" "Wait for 5 minutes for the kernel modules to build or check the status using" 

    color_echo "blue" "modinfo -F version nvidia"
fi

configure_dnf() {
    color_echo "green" "Do you want to do some tweaks to DNF (Recommended) " 
    while true; do
      echo "Enter your choice (y/n): "
      read yn
      case "$yn" in
        [Yy]* ) 
          curl -o /tmp/dnf.conf https://raw.githubusercontent.com/Angxddeep/Fedora-Freedom/refs/heads/main/dnf.conf
          sudo cp /tmp/dnf.conf /etc/dnf/dnf.conf
          color_echo "green" "DNF configuration updated."
          break
          ;;
        [Nn]* )
          color_echo "yellow" "No changes made to DNF configuration."
          exit 0
          ;;
        * )
          color_echo "red" "Invalid choice. Please enter 'y' for yes or 'n' for no."
          ;;
      esac
    done
}

configure_dnf
