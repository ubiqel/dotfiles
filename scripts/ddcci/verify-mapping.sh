#!/bin/bash
set -euo pipefail

# Verify that the Waybar ddcci device mapping matches the current hardware.
# Prints a warning if it differs. With --fix, recreates missing ddcci backlight
# devices and updates the Waybar config to use the detected mapping.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$HOME/.config/waybar/config.jsonc"
FIX=0

if [ "${1:-}" = "--fix" ]; then
    FIX=1
fi

# Extract current device names from Waybar config.
config_dev() {
    local module="$1"
    grep -A10 "\"custom/${module}_brightness\"" "$CONFIG" 2>/dev/null | grep -oP 'waybar-ddcci get \K[^" ]+' | head -1 || true
}

# Check whether a bus already has a bound ddcci backlight device.
has_backlight() {
    local bus="$1"
    [ -d "/sys/class/backlight/ddcci${bus}" ]
}

# Check whether a stale I2C client exists at 0x37 without a backlight device.
has_stale_client() {
    local bus="$1"
    [ -d "/sys/bus/i2c/devices/i2c-${bus}/${bus}-0037" ] && ! has_backlight "$bus"
}

# Determine the expected mapping from ddcutil: display number -> ddcci device name.
detect_mapping() {
    if ! command -v ddcutil >/dev/null 2>&1; then
        return
    fi

    local disp= bus=
    while IFS= read -r line; do
        if [[ "$line" =~ ^Display[[:space:]]+([0-9]+) ]]; then
            disp="${BASH_REMATCH[1]}"
            bus=""
        elif [[ "$line" =~ I2C[[:space:]]bus:[[:space:]]+/dev/i2c-([0-9]+) ]]; then
            bus="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ DRM_connector: ]]; then
            if has_backlight "$bus"; then
                echo "M${disp}=ddcci${bus}"
            fi
        fi
    done < <(ddcutil detect 2>/dev/null || true)
}

# Show current ddcci backlight devices.
echo "Detected ddcci backlight devices:"
declare -A BACKLIGHT_BUSES
for dev in /sys/class/backlight/ddcci*; do
    [ -d "$dev" ] || continue
    name=$(basename "$dev")
    real=$(readlink -f "$dev")
    bus=$(echo "$real" | grep -oE 'i2c-[0-9]+' | head -1 || true)
    cur=$(cat "$dev/brightness" 2>/dev/null || echo "?")
    echo "  $name -> $bus (brightness: $cur%)"
    BACKLIGHT_BUSES[${bus#i2c-}]=1
done

# Show stale clients (I2C client at 0x37 without a bound backlight device).
stale=()
for adapter in /sys/bus/i2c/devices/i2c-*; do
    [ -d "$adapter" ] || continue
    bus=$(basename "$adapter" | sed 's/i2c-//')
    if has_stale_client "$bus"; then
        stale+=("i2c-${bus}")
    fi
done

if [ ${#stale[@]} -gt 0 ]; then
    echo ""
    echo "Stale I2C clients found (no bound backlight device):"
    for s in "${stale[@]}"; do
        echo "  - ${s}/0x37"
    done
fi

# Show DRM mapping.
echo ""
echo "DRM mapping from ddcutil:"
if command -v ddcutil >/dev/null 2>&1; then
    ddcutil detect 2>/dev/null | grep -E '^(Display|I2C bus:|DRM_connector:)' || true
else
    echo "  (ddcutil not installed)"
fi

# Current config mapping.
echo ""
echo "Waybar config mapping:"
monitor1_dev=$(config_dev monitor1)
monitor2_dev=$(config_dev monitor2)
echo "  M1 -> $monitor1_dev"
echo "  M2 -> $monitor2_dev"

# Determine detected mapping.
declare -A DETECTED
while IFS='=' read -r role dev; do
    [ -n "$role" ] || continue
    DETECTED[$role]="$dev"
done < <(detect_mapping)

missing=()
[ -d "/sys/class/backlight/$monitor1_dev" ] || missing+=("$monitor1_dev")
[ -d "/sys/class/backlight/$monitor2_dev" ] || missing+=("$monitor2_dev")

mismatch=0
for role in M1 M2; do
    case "$role" in
        M1) expected="$monitor1_dev" ;;
        M2) expected="$monitor2_dev" ;;
    esac
    detected="${DETECTED[$role]:-}"
    if [ -n "$detected" ] && [ "$expected" != "$detected" ]; then
        mismatch=1
        echo ""
        echo "MISMATCH: $role is configured as '$expected' but detected as '$detected'."
    fi
done

if [ ${#missing[@]} -gt 0 ]; then
    echo ""
    echo "WARNING: the following devices from the Waybar config are missing:"
    for dev in "${missing[@]}"; do
        echo "  - $dev"
    done
fi

if [ ${#stale[@]} -gt 0 ] || [ ${#missing[@]} -gt 0 ] || [ "$mismatch" -ne 0 ]; then
    : # problems found
else
    echo ""
    echo "Mapping looks consistent."
    exit 0
fi

# If not fixing, print instructions and exit.
if [ "$FIX" -ne 1 ]; then
    echo ""
    echo "Run with --fix to recreate missing devices and update the Waybar config:"
    echo "  $0 --fix"
    exit 1
fi

# Apply fixes.
echo ""
echo "Applying fixes..."

# Recreate missing backlight devices.
SETUP_SCRIPT="/usr/local/bin/ddcci-setup"
if [ ! -x "$SETUP_SCRIPT" ]; then
    SETUP_SCRIPT="$SCRIPT_DIR/ddcci-setup.sh"
fi

if [ ${#missing[@]} -gt 0 ] || [ ${#stale[@]} -gt 0 ]; then
    echo "Recreating ddcci backlight devices with $SETUP_SCRIPT ..."
    if ! sudo "$SETUP_SCRIPT"; then
        echo "ERROR: ddcci-setup failed. Fix the issue and rerun."
        exit 1
    fi
fi

# Re-detect mapping after setup.
declare -A DETECTED_AFTER
while IFS='=' read -r role dev; do
    [ -n "$role" ] || continue
    DETECTED_AFTER[$role]="$dev"
done < <(detect_mapping)

# Update config if mapping changed.
echo ""
echo "Updating $CONFIG ..."
for role in M1 M2; do
    case "$role" in
        M1) expected="$monitor1_dev" ;;
        M2) expected="$monitor2_dev" ;;
    esac
    detected="${DETECTED_AFTER[$role]:-}"
    [ -n "$detected" ] || continue
    if [ "$expected" != "$detected" ]; then
        module="monitor${role#M}"
        sed -i "s/waybar-ddcci get ${expected}/waybar-ddcci get ${detected}/g; s/waybar-ddcci cycle ${expected}/waybar-ddcci cycle ${detected}/g; s/waybar-ddcci up ${expected}/waybar-ddcci up ${detected}/g; s/waybar-ddcci down ${expected}/waybar-ddcci down ${detected}/g" "$CONFIG"
        echo "  $role: $expected -> $detected"
    fi
done

echo ""
echo "Reloading Waybar..."
pkill -USR2 waybar 2>/dev/null || true

echo "Done."
