# VisionFive2 Hailo-8 Toolkit

Headless RISC-V NPU-accelerated Edge AI provisioning utilities for StarFive's [VisionFive 2](https://starfivetech.com/) + [Hailo-8(L)](https://hailo.ai/) development kits.

Focused on **Astrophotography Edge AI** and experimental **Evolutionary Code Synthesis Machines**.

---

## Hardware Requirements

| Component | Notes |
|-----------|-------|
| StarFive VisionFive 2 | RISC-V SBC (RV64GC) |
| Hailo-8 or Hailo-8L AI accelerator PCIe M.2 module | ~26 TOPS / ~13 TOPS INT8 inference |

## Quick Start

```
# 1. Flash a StarFive Debian SD card from macOS
sudo VF2IMG=/path/to/starfive-debian.img ./flash-sd.sh <disk_number>

# 2. Fix any missing locale issues (if encountered)
ssh root@<vf2-ip> "sudo bash /root/setup-locale.sh"

# 3. SSH into the VisionFive 2 and run the core engine provisioner
scp -r carepackage/* <user>@<vf2-ip>:~/
ssh <user>@<vf2-ip> "sudo bash /home/<user>/forge-core.sh"
```

Alternatively, use the convenience deploy script from your workstation:

```bash
./deploy-carepackage.sh <user>@<vf2-ip>
```

## Scripts

### `flash-sd.sh`

Writes a StarFive Debian image to an SD card from macOS.

```bash
VF2IMG=/path/to/image.img ./flash-sd.sh <disk_number>
```

Requires:
- macOS (uses `diskutil`)
- `$VF2IMG` env var pointing to the `.img` file

### `deploy-carepackage.sh`

Copies all scripts from `carepackage/` to a target VF2 node via SCP.

```bash
./deploy-carepackage.sh root@<vf2-ip>
```

### `carepackage/setup-locale.sh`

Fixes missing locales on freshly provisioned VF2 systems. Run with `sudo`.

Enables `en_US.UTF-8` as the system locale and applies it immediately.

### `carepackage/forge-core.sh`

Headless RISC-V NPU Edge AI engine provisioning. Run with `sudo`.

**What it does:**

1. Injects official Debian unstable + StarFive APT repositories
2. Upgrades the full system and secures APT keyring validation
3. Strips all desktop environment, Wayland, Weston, and X11 packages — targets a minimal headless CLI baseline
4. Installs Hailo-8 PCIe driver build dependencies (`build-essential`, `dkms`, `linux-headers`) plus homelab tooling (`htop`, `jq`, `tmux`, `golang-go`)
5. Reboots on completion

> ⚠️ **This is destructive to any existing GUI.** It purges X11/Wayland packages and sets the default target to `multi-user.target`. Only run on a fresh or intended headless VisionFive 2 install.

## Architecture

```
workstation (macOS)
  └── flash-sd.sh          → SD card write
  └── deploy-carepackage.sh → scp scripts to VF2
                    │
                    ▼
VisionFive 2 (RISC-V / Debian)
  ├── setup-locale.sh       → locale fixup
  ├── forge-core.sh         → full engine provisioning
```

## License

MIT — see [LICENSE](./LICENSE). Copyright (c) 2026 Drew Vandagriff (DREW-V).
