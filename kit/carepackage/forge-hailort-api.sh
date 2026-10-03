#!/bin/bash
# VisionForge2 HailoRT API Forge:
#    C++ Core Library & pyhailort Wheel Compilation
# Run with: ./forge-hailort-api.sh (Do NOT use sudo)

set -e

echo "=== 1. Installing Compilation Dependencies ==="
sudo apt install -y cmake python3-dev pybind11-dev build-essential python3-setuptools python3-wheel

echo "=== 2. Cloning the HailoRT Repository ==="
cd ~
rm -rf hailort
git clone https://github.com/hailo-ai/hailort.git
cd hailort

echo "=== 3. Compiling the HailoRT C++ Core API ==="
# Scaffold the build system for the C++ libraries
cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release
cmake --build build -j$(nproc)

echo "=== 4. Installing the C++ Shared Libraries ==="
# Install globally and refresh the linker cache so the system finds libhailort.so
sudo cmake --install build
sudo ldconfig

echo "=== 5. Building the pyhailort Python Wheel ==="
cd hailort/libhailort/bindings/python
# Generate the standalone .whl file without installing it to the system python
python3 setup.py bdist_wheel

echo "=== HailoRT API Compilation Complete! ==="
echo "The C++ libraries are installed globally."
echo "The pyhailort wheel is ready for deployment in: $(pwd)/dist/"
