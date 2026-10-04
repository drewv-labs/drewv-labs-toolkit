# DREW-V Labs RISC-V Edge AI Toolkit

![RISC-V Architecture](https://img.shields.io/badge/Architecture-RISC--V-orange?style=for-the-badge) ![Hailo-8 NPU](https://img.shields.io/badge/NPU-Hailo--8-blue?style=for-the-badge) ![Debian Unstable](https://img.shields.io/badge/OS-Debian_Unstable-red?style=for-the-badge) ![Astral uv](https://img.shields.io/badge/Env-Astral_uv-purple?style=for-the-badge)

## About  
This repo represents a collection of tools for working with a variety of software and hardware types, specifically Debian based RISC-V Edge AI research.  

Currently, this lab focuses on using StarFive's VisionFive 2 SBC powered by the JH7110 SoC (RV64GC instruction set) but plans on expanding available hardware and RISC-V chip and instruction sets.  

The lab utilizes a hybrid Apple Silicon Macs and Debian based development machines.  

## Kit File Structure

```text
lildebbyhelpers/
├── harden.sh                   → Removes default "user" from VF2 boards
└── pregame.sh                  → Updates <user> and <hostname> from default

vf2-hailo8-kit/
├── flash-sd.sh                 → SD card flashing utility
├── deploy-carepackage.sh       → Pushes toolkit to remote nodes
└── forge/
    └── forge-node.sh           → Unified Hailo-8 & RISC-V provisioning engine
```
*   The root directory contains `flash-sd.sh` and `deploy-carepackage.sh`.
*   The `forge-node.sh` script is now located in the `forge` subdirectory.

## `forge-node.sh` Monoscript Usage
The `forge-node.sh` engine serves as the single entrypoint for provisioning nodes. Run the script as your standard user, as it internally escalates to `sudo` when necessary.

**Standard Provisioning**
To run the generic core setup:
```bash
./forge-node.sh --all
```

**DREW-V Lab Deployments**
To run the full core setup and append the DREW-V Software Suite (MendelCode, Caroline-V):
```bash
./forge-node.sh --all --mendelcode --caroline-v
```

**Headless Tailscale Mesh**
To run the core setup and install Tailscale:
```bash
./forge-node.sh --all --tailscale
```

**Granular Stage Execution**
You can execute individual phases manually if a kernel update forces a reboot mid-process:
*   `--core`: Executes `run_core()` for system locales, APT sources, and OS de-bloating.
*   `--driver`: Executes `run_driver()` to compile and install the PCIe driver and firmware.
*   `--api`: Executes `run_api()` to compile the HailoRT C++ API and `pyhailort` wheel.
*   `--uv`: Executes `run_uv()` to install the Astral `uv` tool.
*   `--tailscale`: Executes `run_tailscale()` to install Tailscale and enable zero-trust SSH.
*   `--mendelcode`: Executes `run_mendelcode()` to install the MendelCode environment.
*   `--caroline-v`: Executes `run_caroline_v()` to install the Caroline-V environment.


----

Made with ♥️ by
```py
DREW-V := {
  "Simplicity in the Architecture",
  "Efficiency in the Engineering",
  "Purity in the Science",
  "Audacity in the Art",
  "Life in the Logic"
}
```
