#!/bin/bash
# DREW-V Edge Lab: Unified VisionFive 2 & Hailo-8 Provisioning Engine
# Usage: ./forge-node.sh [flags]

set -e

# Prevent running entire script as root to avoid permission leaks in user environments
if [ "$EUID" -eq 0 ]; then
    echo "[-] Do NOT run this script with sudo."
    echo "    Run as your standard user (e.g., ./forge-node.sh --all --add-drewv-labs)."
    echo "    The script will escalate to sudo internally when needed."
    exit 1
fi

# Keep sudo credentials alive during long compilations
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
SUDO_PID=$!
trap 'kill $SUDO_PID 2>/dev/null' EXIT

# ==============================================================================
# ARGUMENT PARSER
# ==============================================================================
RUN_CORE=false
RUN_DRIVER=false
RUN_API=false
RUN_ENV=false
RUN_TAILSCALE=false

# Default to generic core (--all behavior) if no arguments provided
if [ $# -eq 0 ]; then
    RUN_CORE=true
    RUN_DRIVER=true
    RUN_API=true
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        --all)
            RUN_CORE=true
            RUN_DRIVER=true
            RUN_API=true
            ;;
        --add-drewv-labs)
            RUN_ENV=true
            RUN_TAILSCALE=true
            ;;
        --add-tailscale)
            RUN_TAILSCALE=true
            ;;
        --core) RUN_CORE=true ;;
        --driver) RUN_DRIVER=true ;;
        --api) RUN_API=true ;;
        --env) RUN_ENV=true ;;
        --tailscale) RUN_TAILSCALE=true ;;
        *)
            echo "Usage: ./forge-node.sh [--all | --add-drewv-labs | --add-tailscale]"
            echo "Standalone Stages: [--core | --driver | --api | --env | --tailscale]"
            exit 1
            ;;
    esac
    shift
done

# ==============================================================================
# 1. CORE OS & LOCALE PROVISIONING
# ==============================================================================
run_core() {
    echo "=== [Phase 1/5] System Locales, Sources & CLI De-bloating ==="

    cat << 'EOF' | sudo tee /etc/apt/sources.list > /dev/null
deb [trusted=yes] http://deb.debian.org/debian unstable main
deb https://debianrepo-t.starfivetech.com starfive-debian main
EOF

    sudo apt update -y
    sudo apt install -y locales
    sudo sed -i 's/^# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
    sudo locale-gen
    sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

    sudo rm -rf /var/lib/apt/lists/*
    sudo apt clean
    sudo apt update -y
    sudo apt install -y debian-archive-keyring

    sudo sed -i 's/\[trusted=yes\] //' /etc/apt/sources.list
    sudo apt update -y

    sudo systemctl set-default multi-user.target
    sudo apt purge -y "weston*" "wayland*" "x11-common" "libx11-*" "libgtk*" "lightdm*" "task-desktop" "plymouth"
    sudo apt autoremove --purge -y
    sudo apt clean

    # --- T64 Migration Unblock Patch ---
    echo "=== Unblocking libcurl t64 transition dependencies ==="
    if dpkg -l | grep -q "libcurl3-gnutls"; then
        sudo dpkg --remove --force-depends libcurl3-gnutls:riscv64 2>/dev/null || true
    fi

    sudo apt full-upgrade -o Dpkg::Options::="--force-overwrite" -y
    sudo apt install -y \
        build-essential dkms pciutils git curl wget htop jq tmux \
        linux-headers-$(uname -r) \
        golang-go \
        cmake python3-dev pybind11-dev python3-setuptools python3-wheel

    echo "=== Core OS Baseline Provisioned ==="
    echo "If a new kernel was installed, reboot now and run './forge-node.sh --driver' next."
}

# ==============================================================================
# 2. HAILO-8 PCIE DRIVER & FIRMWARE
# ==============================================================================
run_driver() {
    echo "=== [Phase 2/5] Compiling Hailo-8 PCIe Driver & Firmware ==="
    cd "$HOME"
    rm -rf hailort-drivers
    git clone -b hailo8 https://github.com/hailo-ai/hailort-drivers.git

    cd hailort-drivers/linux/pcie
    make all
    sudo make install

    cd ../../
    ./download_firmware.sh
    sudo mkdir -p /lib/firmware/hailo
    sudo mv hailo8_fw*.bin /lib/firmware/hailo/hailo8_fw.bin

    sudo rmmod hailo_pci 2>/dev/null || true
    sudo modprobe hailo_pci

    echo "=== Hailo-8 Kernel Driver Online ==="
    dmesg | grep -i hailo || true
}

# ==============================================================================
# 3. HAILORT C++ API & PYTHON WHEEL
# ==============================================================================
run_api() {
    echo "=== [Phase 3/5] Compiling HailoRT C++ Core & pyhailort Wheel ==="
    cd "$HOME"
    rm -rf hailort
    git clone https://github.com/hailo-ai/hailort.git
    cd hailort

    cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release -DCMAKE_POLICY_VERSION_MINIMUM=3.5
    cmake --build build -j$(nproc)

    sudo cmake --install build
    sudo ldconfig

    cd "$HOME/hailort/hailort/libhailort/bindings/python/platform"
    python3 setup.py bdist_wheel

    echo "=== HailoRT API & Python Wheel Compiled ==="
    ls -lh dist/*.whl
}

# ==============================================================================
# 4. ASTRAL UV & DREW-V LAB ENVIRONMENTS
# ==============================================================================
run_env() {
    echo "=== [Phase 4/5] Installing Astral uv & Scaffolding DREW-V Lab Environments (MendelCode, Caroline-V) ==="

    if ! command -v uv &> /dev/null; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
        export PATH="$HOME/.local/bin:$PATH"
    fi

    cd "$HOME"
    uv venv mendel-env
    source mendel-env/bin/activate

    WHEEL_PATH=$(find "$HOME/hailort/hailort/libhailort/bindings/python/platform/dist" -name "*.whl" | head -n 1)
    if [ -z "$WHEEL_PATH" ]; then
        echo "[-] Error: Could not locate compiled pyhailort .whl file. Did you run the API generation phase?"
        exit 1
    fi

    uv pip install "$WHEEL_PATH"

    python -c "from hailo_platform import VDevice; print('[✓] Hailo-8 User-Space API successfully imported inside DREW-V environment!')"
}

# ==============================================================================
# 5. TAILSCALE SECURE MESH
# ==============================================================================
run_tailscale() {
    echo "=== [Phase 5/5] Installing Tailscale & Enabling Zero-Trust SSH ==="

    if ! command -v tailscale &> /dev/null; then
        curl -fsSL https://tailscale.com/install.sh | sh
    else
        echo "Tailscale is already installed. Updating..."
        sudo tailscale update
    fi

    echo "Initiating interactive authentication with SSH enabled..."
    sudo tailscale up --ssh

    echo "=== Tailscale Provisioning Complete! ==="
    echo "Run 'tailscale ip -4' to get your routing address."
}

# ==============================================================================
# EXECUTION ROUTER
# ==============================================================================
if [ "$RUN_CORE" = true ]; then run_core; fi
if [ "$RUN_DRIVER" = true ]; then run_driver; fi
if [ "$RUN_API" = true ]; then run_api; fi
if [ "$RUN_ENV" = true ]; then run_env; fi
if [ "$RUN_TAILSCALE" = true ]; then run_tailscale; fi

echo "=== Operation Complete! ==="
