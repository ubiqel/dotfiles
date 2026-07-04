#!/bin/bash
set -euo pipefail

# Bootstrap ddcci-backlight setup on a fresh Arch Linux system.
# Idempotent: safe to run multiple times.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

log() { echo "[ddcci-bootstrap] $*"; }

# --- Distro check ----------------------------------------------------------
if [ ! -f /etc/os-release ]; then
    log "Cannot detect distribution. Exiting."
    exit 1
fi

source /etc/os-release
if [ "${ID:-}" != "arch" ]; then
    log "This script is Arch Linux only. Detected: ${ID:-unknown}"
    exit 1
fi

# --- AUR helper check ------------------------------------------------------
AUR_HELPER=""
for helper in yay paru; do
    if command -v "$helper" >/dev/null 2>&1; then
        AUR_HELPER="$helper"
        break
    fi
done

if [ -z "$AUR_HELPER" ]; then
    log "No AUR helper found. Please install yay or paru first."
    exit 1
fi

log "Using AUR helper: $AUR_HELPER"

# --- Install packages ------------------------------------------------------
if ! pacman -Q ddcci-driver-linux-dkms-git >/dev/null 2>&1; then
    log "Installing ddcci-driver-linux-dkms-git..."
    "$AUR_HELPER" -S --needed --noconfirm ddcci-driver-linux-dkms-git
else
    log "ddcci-driver-linux-dkms-git already installed."
fi

for pkg in brightnessctl ddcutil; do
    if ! command -v "$pkg" >/dev/null 2>&1; then
        log "Installing $pkg..."
        sudo pacman -S --needed --noconfirm "$pkg"
    else
        log "$pkg already installed."
    fi
done

# --- Install system files --------------------------------------------------
log "Installing system files..."
sudo install -Dm755 "$SCRIPT_DIR/ddcci-setup.sh" /usr/local/bin/ddcci-setup
sudo install -Dm644 "$SCRIPT_DIR/ddcci.service" /etc/systemd/system/ddcci.service
sudo install -Dm644 "$SCRIPT_DIR/ddcci-resume.service" /etc/systemd/system/ddcci-resume.service
sudo install -Dm644 "$SCRIPT_DIR/ddcci.modules.conf" /etc/modules-load.d/ddcci.conf

# --- Enable and start services ---------------------------------------------
log "Enabling ddcci services..."
sudo systemctl daemon-reload
sudo systemctl enable --now ddcci.service ddcci-resume.service

# --- Deploy dotfiles -------------------------------------------------------
log "Deploying dotfiles..."
cd "$DOTFILES_DIR"
stow -d common -t "$HOME" home --adopt
stow -d pc -t "$HOME" home --adopt

# --- Verify mapping --------------------------------------------------------
log "Verifying device mapping..."
"$SCRIPT_DIR/verify-mapping.sh"

# --- Reload Waybar ---------------------------------------------------------
log "Reloading Waybar..."
pkill -USR2 waybar 2>/dev/null || true

log "Done."
