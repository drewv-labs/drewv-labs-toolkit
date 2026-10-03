# VisionFive2 Hailo-8 Toolkit

Headless RISC-V NPU-accelerated Edge AI provisioning utilities for StarFive's [VisionFive 2](https://starfivetech.com/) + [Hailo-8(L)](https://hailo.ai/) development kits.

Focused on **Astrophotography Edge AI** and experimental **Evolutionary Code Synthesis Machines**.

---

## Hardware Requirements

| Component | Notes |
|-----------|-------|
| StarFive VisionFive 2 | RISC-V SBC (RV64GC) |
| Hailo-8 or Hailo-8L AI accelerator PCIe M.2 module | ~26 TOPS / ~13 TOPS INT8 inference |

## File Structure

```
kit/
├── flash-sd.sh               → SD card writer (macOS)
├── deploy-carepackage.sh     → SCP carepackage to VF2
├── update_all.sh             → all-in-one provisioning orchestration
└── carepackage/
    ├── setup-locale.sh       → locale fixup
    ├── forge-core.sh         → headless engine provisioning
    ├── forge-hailo8-driver.sh   → Hailo-8 PCIe driver + firmware
    ├── forge-hailort-api.sh     → HailoRT C++ core & pyhailort wheel
    └── forge-mendelcode-env.sh  → MendelCode uv virtualenv with PyHailoRT
```

## Quick Start

```bash
cd kit

# 1. Flash a StarFive Debian SD card from macOS
sudo VF2IMG=/path/to/starfive-debian.img ./flash-sd.sh <disk_number>

# 2. Fix any missing locale issues (if encountered)
ssh root@<vf2-ip> "sudo bash /root/setup-locale.sh"

# 3. Deploy the carepackage via SCP
deploy-carepackage.sh <user>@<vf2-ip>

# 4. SSH into the VisionFive 2 and run the core engine provisioner
ssh <user>@<vf2-ip> "sudo bash /home/<user>/forge-core.sh"
```

Or use the all-in-one orchestrator script that runs every forge step sequentially:

```bash
cd kit && ./update_all.sh <user>@<vf2-ip>
```

## Scripts

### `update_all.sh`

All-in-one provisioning orchestrator. Runs every forge step sequentially on a target VF2 node.

```
bash ./update_all.sh <user>@<vf2-ip>
```

**What it does:**
1. Deploys all carepackage scripts via SCP
2. Runs `setup-locale.sh` → fixes locale on the target
3. Runs `forge-core.sh` → headless engine provisioning (with reboot)
4. Runs `forge-hailo8-driver.sh` → Hailo-8 PCIe driver + firmware compilation
5. Runs `forge-hailort-api.sh` → HailoRT C++ core & pyhailort wheel
6. Runs `forge-mendelcode-env.sh` → MendelCode uv virtualenv with PyHailoRT

> ⚠️ This is a long-running pipeline. Each step must complete successfully before the next begins.

### `deploy-carepackage.sh`

Copies all scripts from `carepackage/` to a target VF2 node via SCP.

```bash
./deploy-carepackage.sh <user>@<vf2-ip>
```

### `carepackage/setup-locale.sh`

Fixes missing locales on freshly provisioned VF2 systems. Run with `sudo`.

Enables `en_US.UTF-8` as the system locale and applies it immediately.

### `carepackage/forge-core.sh`

Headless RISC-V NPU Edge AI engine provisioning. Run with `sudo`.

**What it does:**

1. Injects official Debian unstable + StarFive APT repositories
2. Cleans out corrupted APT lists and installs a modern keyring
3. Strips all desktop environment, Wayland, Weston, and X11 packages — targets a minimal headless CLI baseline
4. Executes a full system upgrade (`apt full-upgrade`)
5. Installs Hailo-8 PCIe driver build dependencies (`build-essential`, `dkms`, `linux-headers`) plus homelab tooling (`htop`, `jq`, `tmux`, `golang-go`)
6. Prompts to reboot on completion

> ⚠️ **This is destructive to any existing GUI.** It purges X11/Wayland packages and sets the default target to `multi-user.target`. Only run on a fresh or intended headless VisionFive 2 install.

### `carepackage/forge-hailo8-driver.sh`

Hailo-8 PCIe direct compilation, firmware fetch, and installation. Run with `sudo`.

**What it does:**

1. Clones the official `hailo-ai/hailort-drivers` repo (branch `hailo8`)
2. Compiles the PCIe kernel module via Make
3. Downloads the Hailo-8 firmware binary and installs it to `/lib/firmware/hailo/`
4. Loads the `hailo_pci` kernel module

Verify with: `dmesg | grep hailo`

### `carepackage/forge-hailort-api.sh`

HailoRT C++ core library & pyhailort Python wheel compilation. Do NOT use `sudo`.

**What it does:**

1. Installs compilation dependencies (`cmake`, `python3-dev`, `pybind11-dev`, etc.)
2. Clones the official `hailo-ai/hailort` repository
3. Compiles the HailoRT C++ shared libraries and installs them globally (`/usr/lib`)
4. Builds a standalone pyhailort `.whl` in `~/hailort/hailort/libhailort/bindings/python/platform/dist/`

### `carepackage/forge-mendelcode-env.sh`

Sets up an isolated MendelCode Python environment using Astral's `uv`. No arguments needed.

**What it does:**

1. Installs `uv` (fast Python package manager) via curl
2. Creates an isolated virtualenv at `~/mendel-env`
3. Activates the venv and installs the pyhailort wheel built by `forge-hailort-api.sh`

## Architecture

```
workstation (macOS)
  └── kit/
      ├── flash-sd.sh            → SD card write
      ├── deploy-carepackage.sh  → scp scripts to VF2
      └── update_all.sh          → all-in-one orchestration
                    │
                    ▼
VisionFive 2 (RISC-V / Debian)
  ├── setup-locale.sh            → locale fixup
  ├── forge-core.sh              → headless engine provisioning
  ├── forge-hailo8-driver.sh     → Hailo-8 PCIe driver + firmware
  ├── forge-hailort-api.sh       → HailoRT C++ core & pyhailort wheel
  └── forge-mendelcode-env.sh    → MendelCode uv venv with PyHailoRT
```

## License

MIT — see [LICENSE](./LICENSE). Copyright (c) 2026 Drew Vandagriff (DREW-V).
