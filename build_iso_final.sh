#!/bin/bash
set -euo pipefail

################################################################################
# LIMALINUX ISO ORCHESTRATOR
# Handles: versioning, external paths, forced cleanup, and ISO building.
################################################################################

# --- Path Configuration ---
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARCHISO_DIR="$BASE_DIR/archiso"

# EXTERNAL PATHS (Located in ~/limalinuxos/Iso-out)
BUILD_ROOT="$HOME/limalinuxos/Iso-out"
WORK_DIR="$BUILD_ROOT/work"
OUT_DIR="$BUILD_ROOT/out"
CACHE_DIR="$BUILD_ROOT/cache"

# --- UI Colors ---
info=$(tput setaf 6)
success=$(tput setaf 2)
error=$(tput setaf 1)
reset=$(tput sgr0)

required_cmds=(mkarchiso sha256sum sed ls)
for cmd in "${required_cmds[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "${error}Error: Required command not found: $cmd${reset}"
        exit 1
    fi
done

SUDO_CMD=()
if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    echo "${info}>> Requesting sudo once for the ISO build flow...${reset}"
    sudo -v
    SUDO_CMD=(sudo -n)
    (
        while true; do
            sudo -n true
            sleep 50
        done
    ) &
    SUDO_KEEPALIVE_PID=$!
    trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT
fi

echo "${info}################################################################"
echo "### LIMALINUX - ISO BUILD STARTING"
echo "################################################################${reset}"

# Ensure directories exist
mkdir -p "$WORK_DIR" "$OUT_DIR" "$CACHE_DIR"

# --- STEP 1: Version Synchronization ---
echo "${info}>> Step 1: Running version synchronization...${reset}"
if [ -f "$BASE_DIR/change_version.sh" ]; then
    bash "$BASE_DIR/change_version.sh"
else
    echo "${error}Error: change_version.sh not found in $BASE_DIR.${reset}"
    exit 1
fi

# --- STEP 2: Forced Environment Cleanup ---
echo "${info}>> Step 2: Cleaning previous build environment...${reset}"

# Lazy unmount prevents "Device or resource busy" errors
if [ -d "$WORK_DIR" ]; then
    echo "Unmounting resources in $WORK_DIR..."
    "${SUDO_CMD[@]}" umount -l "$WORK_DIR" 2>/dev/null || true
    
    # Forced removal of root-owned files created by archiso
    echo "Deleting residual work files..."
    "${SUDO_CMD[@]}" rm -rf "$WORK_DIR"
fi

# Recreate clean work directory
mkdir -p "$WORK_DIR"

# --- STEP 2.5: Sanitize package cache for local repos ---
echo "${info}>> Step 2.5: Cleaning cache for LimaLinux packages...${reset}"
"${SUDO_CMD[@]}" rm -f "$CACHE_DIR"/calamares-limalinux-*.pkg.tar.zst \
           "$CACHE_DIR"/limalinux_calamares_config-*.pkg.tar.zst \
           /var/cache/pacman/pkg/calamares-limalinux-*.pkg.tar.zst \
           /var/cache/pacman/pkg/limalinux_calamares_config-*.pkg.tar.zst

# --- STEP 3: ISO Building ---
echo "${info}>> Step 3: Starting mkarchiso process...${reset}"

# -v: Verbose | -w: Work directory | -o: Output directory
"${SUDO_CMD[@]}" mkarchiso -v -w "$WORK_DIR" -o "$OUT_DIR" "$ARCHISO_DIR"

# --- STEP 3.5: Validate critical installer files in airootfs ---
echo "${info}>> Step 3.5: Validating Calamares payload in airootfs...${reset}"
AIROOTFS_DIR="$WORK_DIR/x86_64/airootfs"
required_files=(
    "$AIROOTFS_DIR/etc/calamares/settings.conf"
    "$AIROOTFS_DIR/usr/bin/calamares"
    "$AIROOTFS_DIR/usr/bin/calamares_wrapper"
    "$AIROOTFS_DIR/etc/xdg/autostart/calamares.desktop"
)

for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "${error}ERROR: Missing required file in airootfs: $file${reset}"
        echo "${error}Build aborted to avoid generating a broken ISO.${reset}"
        exit 1
    fi
done

if ! grep -q "calamares_wrapper" "$AIROOTFS_DIR/etc/xdg/autostart/calamares.desktop"; then
    echo "${error}ERROR: Autostart does not call calamares_wrapper.${reset}"
    exit 1
fi

# --- STEP 4: Final Verification ---
ISO_FILE=$(ls -t "$OUT_DIR"/*.iso 2>/dev/null | head -n 1)

if [ -f "$ISO_FILE" ]; then
    echo ""
    echo "${success}################################################################"
    echo "### SUCCESS: ISO generated successfully!"
    echo "### Location: $ISO_FILE"
    echo "################################################################${reset}"
    
    # Generate SHA256 checksum for the new ISO
    echo "${info}>> Generating checksum...${reset}"
    cd "$OUT_DIR"
    sha256sum "$(basename "$ISO_FILE")" > checksums.txt
    echo "Checksum saved in: $OUT_DIR/checksums.txt"
else
    echo ""
    echo "${error}################################################################"
    echo "### ERROR: ISO generation failed. Check the logs above."
    echo "################################################################${reset}"
    exit 1
fi
