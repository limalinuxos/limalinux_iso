#!/bin/bash

# ---
# LIMALINUX - Version Synchronization Script
# This script updates the version string across all critical files
# using the current date: vYY.MM.DD.01
# ---

set -e

# --- Configuration ---
# Create the new version based on current date
year=$(date +%y)   
month=$(date +%m)  
day=$(date +%d)    
extra="01" # Incremental build number for the same day
newversion="v${year}.${month}.${day}.${extra}"

# Paths to critical files (Relative to the project root)
DEV_REL="archiso/airootfs/etc/dev-rel"
PROFILEDEF="archiso/profiledef.sh"

# ANSI Colors for terminal output
info=$(tput setaf 6)
success=$(tput setaf 2)
warning=$(tput setaf 3)
reset=$(tput sgr0)

echo "${info}################################################################"
echo "### LIMALINUX VERSION UPDATE: $newversion"
echo "################################################################${reset}"

# --- Step 1: Update /etc/dev-rel ---
# This file is used by the system to identify its release version
if [ -f "$DEV_REL" ]; then
    echo "Updating version in: $DEV_REL"
    sed -i "s|^ISO_RELEASE=.*|ISO_RELEASE=$newversion|" "$DEV_REL"
else
    echo "${warning}Warning: $DEV_REL not found. Skipping.${reset}"
fi

# --- Step 2: Update profiledef.sh ---
# This file is critical for mkarchiso (labels and versioning)
if [ -f "$PROFILEDEF" ]; then
    echo "Updating version in: $PROFILEDEF"
    
    # Update iso_label (Format: limalinux-vYY.MM.DD.01)
    sed -i "s|\(iso_label=\"limalinux-\)v[0-9.]*\(.*\)|\1$newversion\2|" "$PROFILEDEF"
    
    # Update iso_version (Format: vYY.MM.DD.01)
    sed -i "s|\(iso_version=\"\)v[0-9.]*\(.*\)|\1$newversion\2|" "$PROFILEDEF"
else
    echo "${warning}Error: $PROFILEDEF not found! This file is mandatory.${reset}"
    exit 1
fi

# --- Step 3: Summary ---
echo ""
echo "${success}Version synchronization complete!${reset}"
echo "Current project version: ${info}$newversion${reset}"
echo "Ready to run build_iso_final.sh"
