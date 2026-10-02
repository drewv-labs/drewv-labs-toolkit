#!/bin/bash
# VisionFive2 Hailo-8 Engine Forge:
#    Headless RISC-V NPU accelerated Edge AI Provisioning Script
# Run with: sudo ./forge-core.sh

set -e

echo "=== 1. Injecting Live 2026 Official Debian & StarFive Repos ==="
cat << 'EOF' > /etc/apt/sources.list
deb [trusted=yes] http://deb.debian.org/debian unstable main
deb https://debianrepo-t.starfivetech.com starfive-debian main
EOF

# Clean out the corrupted/failed APT lists from any previous runs
rm -rf /var/lib/apt/lists/*
apt clean

apt update -y
apt install -y debian-archive-keyring

echo "=== 2. Eradicating Desktop Environment to Bypass t64 Conflicts ==="
# Remove the temporary trusted flag now that the modern keyring is installed
sed -i 's/\[trusted=yes\] //' /etc/apt/sources.list
apt update -y

# Force the system to boot to the CLI terminal instead of a display manager
systemctl set-default multi-user.target

# Aggressively strip Wayland, Weston, X11, and GTK packages *before* upgrading
apt purge -y "weston*" "wayland*" "x11-common" "libx11-*" "libgtk*" "lightdm*" "task-desktop" "plymouth"
apt autoremove --purge -y
apt clean

echo "=== 3. Executing Full System Upgrade ==="
apt full-upgrade -y

echo "=== 4. Provisioning Edge AI & Telemetry Dependencies ==="
# Install compilation headers for the Hailo-8 PCIe driver, plus standard homelab tools
apt install -y \
    build-essential dkms pciutils git curl wget htop jq tmux \
    linux-headers-$(uname -r) \
    golang-go

echo "=== VisionFive2 Hailo-8 Engine Core Provisioning Complete! ==="
echo "Please reboot the system to flush the GUI from memory."

echo "Reboot Now? [Y/n]:"
read -r reboot_choice
if [[ "$reboot_choice" == "Y" || "$reboot_choice" == "y" || -z "$reboot_choice" ]]; then
    reboot
fi
