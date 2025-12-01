# CustomFedora

This repository contains a small collection of helper scripts I use to build and
configure a custom Fedora VM environment (GPU passthrough, VM creation and a
helper to download Looking Glass artifacts). The README documents what each
script does and how to run them safely.

**Overview**
- **Purpose:** provide scripts to create VMs, enable GPU passthrough and fetch
	Looking Glass source artifacts easily.
- **Location:** repository root contains the main scripts referenced below.

**Files**
- **`createvm.sh`**: helper to create and configure a VM (see script header
	for usage). Behavior depends on your system configuration.
- **`gpu_passthrough.sh`**: configures VFIO for GPU passthrough and updates
	kernel boot args (must be run as `root`). It will create/modify
	`settings.conf` in the current directory.
- **`setup.sh`**: general setup helper for initial system configuration (see
	the script header for details).
- **`download_looking-glass.sh`**: small downloader that defaults to
	`https://looking-glass.io/artifact/stable/source`, preserving the filename the
	server supplies (uses `curl` with `-J` or falls back to `wget`).
- **`install_looking-glass.sh`**: installer for Looking Glass (if present) —
	read the script header for options.

**Quick Start**
- **Make scripts executable:**
```bash
chmod +x ./createvm.sh ./gpu_passthrough.sh ./setup.sh ./download_looking-glass.sh
```

**`gpu_passthrough.sh` usage**
- **What it does:** detects CPU vendor, enables IOMMU kernel args appropriate
	for Intel/AMD, writes `vfio` module configs and (optionally) sets
	`options vfio-pci ids=...` to bind your GPU devices to `vfio-pci`.
- **Important:** the script will create a `settings.conf` file in the current
	directory if one isn't present. That file controls interactive behaviour:
	- `PROMPT_FOR_VFIO=1` — prompt before enabling/disabling VFIO
	- `VFIO_ENABLED=0|1` — enable or disable teh vfio configuration
	- `SELECTED_GPU_IDS` — comma-separated `vendor:device` IDs
- **Run example (interactive):**
```bash
sudo ./gpu_passthrough.sh
```
- **Non-interactive workflow:** edit or create `settings.conf` next to the
	script with your desired values, then run the script (it will skip prompts):
```ini
# settings.conf
PROMPT_FOR_VFIO=0
VFIO_ENABLED=1
SELECTED_GPU_IDS="10de:1b80,10de:10f0"
```
Then:
```bash
sudo ./gpu_passthrough.sh
```
- **Reboot required:** changes to GRUB/initramfs require reboot to take effect.

# explicit curl one-liner (equivalent behavior)
curl -fL -J -O https://looking-glass.io/artifact/stable/source
```
- **Notes:** the script prefers `curl` (uses `-J -O -L`) and falls back to
	`wget --content-disposition`. If neither is installed the script exits with
	an error.

**General tips & troubleshooting**
- **Read the script header:** most scripts include usage/help instructions at
	the top — use `head -n 50 ./script.sh` to quickly view them.
- **Safety:** always review scripts before running as `root`. `gpu_passthrough.sh`
	will modify kernel boot arguments and regenerate initramfs (`dracut`).
- **Undoing changes:** if `gpu_passthrough.sh` was used to enable VFIO, you
	can re-run it with `VFIO_ENABLED=0` (or use the interactive prompt) to
	remove VFIO configs and remove the `vfio` module configuration files;
	remember to reboot after reverting.
- **Shallow clones for this repo:** to avoid downloading full Git history use
	`git clone --depth 1 <repo>`.


