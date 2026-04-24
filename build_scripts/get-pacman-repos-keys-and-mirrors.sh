#!/bin/bash

# ---
# LIMALINUX - Repository and Keyring Setup Script
# This script installs Chaotic-AUR keys and mirrors, and synchronizes 
# the system's pacman.conf with the project's configuration.
# ---

set -euo pipefail

# ANSI color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- Path Configuration ---
# Defining absolute paths to avoid "file not found" errors
BASE_DIR="$HOME/limalinuxos/limalinux_iso"
LIMA_PACMAN_CONF="$BASE_DIR/archiso/pacman.conf"
TARGET_PACMAN_CONF="/etc/pacman.conf"
BACKUP_PACMAN_CONF="/etc/pacman.conf.limalinux"

# --- Step 1: System Update & Dependencies ---
echo -e "${YELLOW}Updating system and installing required tools (wget, jq, curl)...${NC}"
sudo pacman -Syu --needed --noconfirm wget jq curl

# --- Step 2: Chaotic-AUR Setup ---
# Base URL for Chaotic-AUR repository
BASE_URL="https://builds.garudalinux.org/repos/chaotic-aur/x86_64/"

# Function to fetch the latest package URL from the repo index
fetch_package_url() {
    local package_name="$1"
    local package_url
    package_url=$(curl -s "$BASE_URL" | grep -oP "${package_name}-[0-9][^\"]+\.pkg\.tar\.zst" | sort -V | tail -n 1)
    echo "${BASE_URL}${package_url}"
}

echo -e "${YELLOW}Fetching Chaotic-AUR keyring and mirrorlist package URLs...${NC}"
KEYRING_URL=$(fetch_package_url "chaotic-keyring")
MIRRORLIST_URL=$(fetch_package_url "chaotic-mirrorlist")

# Verify if URLs were retrieved successfully
if [[ -z "$KEYRING_URL" || -z "$MIRRORLIST_URL" ]]; then
    echo -e "${RED}Error: Failed to retrieve Chaotic-AUR package URLs.${NC}"
    exit 1
fi

# Download packages to a temporary location
echo -e "${YELLOW}Downloading packages...${NC}"
wget -q "$KEYRING_URL" -O /tmp/chaotic-keyring.pkg.tar.zst
wget -q "$MIRRORLIST_URL" -O /tmp/chaotic-mirrorlist.pkg.tar.zst

# Install the downloaded packages
echo -e "${YELLOW}Installing Chaotic-AUR keyring and mirrorlist...${NC}"
sudo pacman -U --noconfirm --needed /tmp/chaotic-keyring.pkg.tar.zst /tmp/chaotic-mirrorlist.pkg.tar.zst

# Cleanup temporary files
rm -f /tmp/chaotic-keyring.pkg.tar.zst /tmp/chaotic-mirrorlist.pkg.tar.zst
echo -e "${GREEN}Chaotic-AUR keyring and mirrorlist installed successfully.${NC}"

# --- Step 3: Synchronize pacman.conf ---
echo -e "${YELLOW}Synchronizing pacman.conf with LimaLinux configuration...${NC}"

if [ -f "$LIMA_PACMAN_CONF" ]; then
    # Create a backup of the original pacman.conf if it doesn't exist
    if [ ! -f "$BACKUP_PACMAN_CONF" ]; then
        echo -e "${YELLOW}Creating backup at $BACKUP_PACMAN_CONF...${NC}"
        sudo cp "$TARGET_PACMAN_CONF" "$BACKUP_PACMAN_CONF"
    else
        echo -e "${YELLOW}Backup already exists. Skipping backup step.${NC}"
    fi

    # Overwrite the system pacman.conf with the project one
    echo -e "${GREEN}Applying $LIMA_PACMAN_CONF to $TARGET_PACMAN_CONF...${NC}"
    sudo cp -v "$LIMA_PACMAN_CONF" "$TARGET_PACMAN_CONF"
    
    # Refresh package databases
    echo -e "${YELLOW}Refreshing pacman databases...${NC}"
    sudo pacman -Sy
else
    echo -e "${RED}Error: Project pacman.conf not found at $LIMA_PACMAN_CONF${NC}"
    exit 1
fi

echo -e "${GREEN}##############################################################${NC}"
echo -e "${GREEN}###  $(basename "$0") DONE SUCCESSFULLY"
echo -e "${GREEN}##############################################################${NC}"
