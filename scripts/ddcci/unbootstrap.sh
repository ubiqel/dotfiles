#!/bin/bash
set -euo pipefail

# Remove everything bootstrap.sh installed on the system.
#
# Reverses the system-level setup:
#   - stops/disables the ddcci systemd units,
#   - deletes the installed unit files, udev rule and modules-load config,
#   - removes the ddcci-setup helper from /usr/local/bin,
#   - removes ddcci I2C clients and unloads the ddcci kernel modules,
#   - removes the ddcci-driver-linux-dkms-git package (unless --keep-driver).
#
# The dotfiles that stow_pc.sh deploys into $HOME are intentionally NOT touched:
# undoing a stow --adopt deployment could delete unrelated user configuration.
#
# Usage: unbootstrap.sh [OPTIONS]
#   --remove-packages   also remove brightnessctl and ddcutil (pacman)
#   --keep-driver       keep the ddcci-driver-linux-dkms-git package installed
#   -h, --help          show this help

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

REMOVE_PACKAGES=0
KEEP_DRIVER=0

usage() {
    cat <<'EOF'
Remove everything bootstrap.sh installed on the system.

Reverses the system-level setup:
  - stops/disables the ddcci systemd units,
  - deletes the installed unit files, udev rule and modules-load config,
  - removes the ddcci-setup helper from /usr/local/bin,
  - removes ddcci I2C clients and unloads the ddcci kernel modules,
  - removes the ddcci-driver-linux-dkms-git package (unless --keep-driver).

The dotfiles that stow_pc.sh deploys into $HOME are intentionally NOT touched:
undoing a stow --adopt deployment could delete unrelated user configuration.

Usage: unbootstrap.sh [OPTIONS]
  --remove-packages   also remove brightnessctl and ddcutil (pacman)
  --keep-driver       keep the ddcci-driver-linux-dkms-git package installed
  -h, --help          show this help
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --remove-packages) REMOVE_PACKAGES=1 ;;
        --keep-driver)     KEEP_DRIVER=1 ;;
        -h|--help)         usage; exit 0 ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Try --help." >&2
            exit 1
            ;;
    esac
    shift
done

log() { echo "[ddcci-unbootstrap] $*"; }

# --- Privilege helper ------------------------------------------------------
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
    else
        log "This script needs root (or sudo) to modify system files."
        exit 1
    fi
fi

# --- Stop and disable units ------------------------------------------------
log "Stopping and disabling ddcci units..."
# Ignore failures: the units may not be installed (already uninstalled).
$SUDO systemctl disable --now ddcci.timer 2>/dev/null || true
$SUDO systemctl disable --now ddcci.service 2>/dev/null || true
$SUDO systemctl disable --now ddcci-resume.service 2>/dev/null || true

# --- Remove installed system files -----------------------------------------
log "Removing installed system files..."
SYSTEM_FILES=(
    /etc/systemd/system/ddcci.service
    /etc/systemd/system/ddcci.timer
    /etc/systemd/system/ddcci-resume.service
    /etc/modules-load.d/ddcci.conf
    /etc/udev/rules.d/99-ddcci.rules
    /usr/local/bin/ddcci-setup
)
for file in "${SYSTEM_FILES[@]}"; do
    if [ -e "$file" ]; then
        log "  removing $file"
        $SUDO rm -f "$file"
    fi
done

log "Reloading systemd and udev..."
$SUDO systemctl daemon-reload
$SUDO udevadm control --reload

# --- Remove ddcci I2C clients and unload modules ---------------------------
# Delete the 0x37 clients first so the driver can be unloaded cleanly and to
# avoid leaving stale clients behind (which cause EBUSY on future probes).
for adapter in /sys/bus/i2c/devices/i2c-*; do
    [ -d "$adapter" ] || continue
    bus="$(basename "$adapter" | sed 's/i2c-//')"
    if [ -e "$adapter/${bus}-0037" ]; then
        log "Removing I2C client i2c-${bus}/0x37"
        echo "0x37" | $SUDO tee "$adapter/delete_device" >/dev/null 2>&1 || true
    fi
done

if lsmod 2>/dev/null | grep -q '^ddcci'; then
    log "Unloading ddcci kernel modules..."
    $SUDO modprobe -r ddcci-backlight 2>/dev/null || true
    $SUDO modprobe -r ddcci 2>/dev/null || true
    if lsmod 2>/dev/null | grep -q '^ddcci'; then
        log "Warning: ddcci modules are still loaded (in use?)."
    fi
fi

# --- Clean runtime state ----------------------------------------------------
$SUDO rm -f /run/ddcci-setup.lock 2>/dev/null || true
RUNTIME_CACHE="${XDG_RUNTIME_DIR:-/tmp}/waybar-brightness-cache"
if [ -d "$RUNTIME_CACHE" ]; then
    log "Removing Waybar brightness cache at $RUNTIME_CACHE"
    rm -rf "$RUNTIME_CACHE" 2>/dev/null || $SUDO rm -rf "$RUNTIME_CACHE" 2>/dev/null || true
fi

# --- Remove packages --------------------------------------------------------
remove_pkg() {
    local pkg="$1"
    if $SUDO pacman -Q "$pkg" >/dev/null 2>&1; then
        log "Removing package $pkg..."
        $SUDO pacman -Rns --noconfirm "$pkg"
    else
        log "Package $pkg is not installed."
    fi
}

if [ -f /etc/os-release ] && grep -q '^ID=arch' /etc/os-release; then
    if [ "$KEEP_DRIVER" -eq 0 ]; then
        remove_pkg ddcci-driver-linux-dkms-git
    else
        log "Keeping ddcci-driver-linux-dkms-git (--keep-driver)."
    fi

    if [ "$REMOVE_PACKAGES" -eq 1 ]; then
        remove_pkg brightnessctl
        remove_pkg ddcutil
    else
        log "Keeping brightnessctl and ddcutil (use --remove-packages to remove)."
    fi
else
    log "Not Arch Linux; skipping package removal."
fi

log "Done."
log "Dotfiles in \$HOME were left untouched."
