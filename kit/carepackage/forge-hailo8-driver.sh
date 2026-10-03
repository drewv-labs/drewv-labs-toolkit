#!/bin/bash
# VisionForge2 Hailo-8 NPU Driver Forge:
#    PCIe Direct Compilation, Firmware Fetch, and Installation
# Run with: sudo ./forge-hailo8-driver.sh

set -e

echo "=== 1. Cloning the HailoRT Driver Source ==="
rm -rf hailort-drivers
git clone -b hailo8 https://github.com/hailo-ai/hailort-drivers.git

echo "=== 2. Compiling the PCIe Driver ==="
cd hailort-drivers/linux/pcie
make all

echo "=== 3. Installing the Kernel Module ==="
# Bypassing DKMS for direct installation
make install

echo "=== 4. Fetching the Hailo-8 Firmware ==="
# Navigate back to the repo root to execute the download script
cd ../../
./download_firmware.sh

# Ensure the kernel firmware directory exists and move the downloaded binary
mkdir -p /lib/firmware/hailo
mv hailo8_fw*.bin /lib/firmware/hailo/hailo8_fw.bin

echo "=== 5. Activating the Kernel Module ==="
# Remove the module if it loaded previously without firmware
rmmod hailo_pci 2>/dev/null || true
modprobe hailo_pci

echo "=== Hailo-8 Driver Provisioning Complete! ==="
echo "Run 'dmesg | grep hailo' to verify the firmware loaded successfully."
