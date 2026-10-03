#!/bin/bash
# HailoTwin NPU Driver Forge: PCIe DKMS Compilation
# Run with: sudo bash compile_hailo_driver.sh

set -e

echo "=== 1. Cloning the HailoRT Driver Source ==="
rm -rf hailort-drivers
git clone -b hailo8 https://github.com/hailo-ai/hailort-drivers.git

echo "=== 2. Compiling the PCIe Driver ==="
cd hailort-drivers/linux/pcie
make all

echo "=== 3. Installing and Registering via DKMS ==="
make install_dkms

echo "=== 4. Activating the Kernel Module ==="
modprobe hailo_pci

echo "=== Hailo-8 Driver Compilation Complete! ==="
echo "Run 'dmesg | grep hailo' to verify the kernel successfully initialized the NPU."
