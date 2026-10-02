#!/bin/bash
set -euo pipefail

# Verify that the Waybar ddcci brightness modules resolve to live backlight
# devices. Prints a warning if they do not. With --fix, recreates missing ddcci
# backlight devices (and stale I2C clients) and re-checks the mapping.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/waybar/config.jsonc"
MAPPING="${XDG_CONFIG_HOME:-$HOME/.config}/waybar/ddcci-monitors.conf"
FIX=0

if [ "${1:-}" = "--fix" ]; then
    FIX=1
fi

# Locate waybar-ddcci even when ~/.local/bin is not on PATH.
WAYBAR_DDCCI="$(command -v waybar-ddcci 2>/dev/null || true)"
if [ -z "$WAYBAR_DDCCI" ] && [ -x "$HOME/.local/bin/waybar-ddcci" ]; then
    WAYBAR_DDCCI="$HOME/.local/bin/waybar-ddcci"
fi

# Always do a fresh resolution when checking, bypassing the miss throttle.
export DDCCI_MISS_TTL=0

# Extract the role (or legacy device) used by a Waybar module.
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

# Resolve a Waybar reference (role or legacy ddcciN) to a live device name.
# Always returns 0; prints the device name, or nothing if unresolvable.
resolve_ref() {
    local ref="$1"
    if [ -z "$ref" ]; then
        return 0
    fi
    if [[ "$ref" =~ ^ddcci[0-9]+$ ]]; then
        if [ -d "/sys/class/backlight/$ref" ]; then
            echo "$ref"
        fi
        return 0
    fi
    if [ -n "$WAYBAR_DDCCI" ]; then
        "$WAYBAR_DDCCI" resolve "$ref" 2>/dev/null || true
    fi
    return 0
}

# Show current ddcci backlight devices.
echo "Detected ddcci backlight devices:"
found_dev=0
for dev in /sys/class/backlight/ddcci*; do
    [ -d "$dev" ] || continue
    found_dev=1
    name=$(basename "$dev")
    real=$(readlink -f "$dev")
    bus=$(echo "$real" | grep -oE 'i2c-[0-9]+' | head -1 || true)
    cur=$(cat "$dev/brightness" 2>/dev/null || echo "?")
    echo "  $name -> $bus (brightness: $cur%)"
done
if [ "$found_dev" -eq 0 ]; then
    echo "  (none)"
fi

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
    ddcutil detect --brief 2>/dev/null | grep -E '^(Display|[[:space:]]+(I2C bus:|DRM connector:|Monitor:))' || true
else
    echo "  (ddcutil not installed)"
fi

# Check each Waybar module.
echo ""
echo "Waybar module mapping:"
problems=0
fallback_used=0
for role in M1 M2; do
    case "$role" in
        M1) module=monitor1 ;;
        M2) module=monitor2 ;;
    esac
    ref="$(config_dev "$module")"
    if [ -z "$ref" ]; then
        echo "  $role: no 'waybar-ddcci get' reference found in $CONFIG"
        problems=1
        continue
    fi
    dev="$(resolve_ref "$ref")"
    if [ -n "$dev" ]; then
        case "$dev" in
            bus:*)
                fallback_used=1
                echo "  $role: $ref -> $dev (ddcutil fallback; kernel device ddcci${dev#bus:} missing)"
                ;;
            *)
                echo "  $role: $ref -> $dev (kernel device)"
                ;;
        esac
    else
        echo "  $role: $ref -> NOT RESOLVED (monitor not detected or backlight missing)"
        problems=1
    fi
done

# Brightness works through the fallback, so only unresolved roles are errors.
need_fix=0
if [ "$fallback_used" -eq 1 ] || [ ${#stale[@]} -gt 0 ]; then
    need_fix=1
fi

if [ "$problems" -eq 0 ]; then
    echo ""
    if [ "$need_fix" -eq 1 ]; then
        echo "Brightness works, but some monitors use the ddcutil fallback"
        echo "(kernel ddcci devices are missing or have stale I2C clients)."
    else
        echo "Mapping looks consistent."
    fi
    # An explicit --fix still tries to restore the kernel devices.
    if [ "$FIX" -ne 1 ] || [ "$need_fix" -eq 0 ]; then
        exit 0
    fi
fi

if [ "$FIX" -ne 1 ]; then
    echo ""
    echo "Run with --fix to recreate missing devices and re-check:"
    echo "  $0 --fix"
    exit 1
fi

# --- Apply fixes -----------------------------------------------------------

echo ""
echo "Applying fixes..."

# Prefer the repo copy so fixes are applied even before bootstrap installs it.
SETUP_SCRIPT="$SCRIPT_DIR/ddcci-setup.sh"
if [ ! -x "$SETUP_SCRIPT" ]; then
    SETUP_SCRIPT="/usr/local/bin/ddcci-setup"
fi

echo "Recreating ddcci backlight devices with $SETUP_SCRIPT ..."
if ! sudo "$SETUP_SCRIPT"; then
    echo "ERROR: ddcci-setup failed. Fix the issue and rerun."
    exit 1
fi

# Re-check the mapping after setup.
echo ""
echo "Re-checking mapping..."
problems=0
for role in M1 M2; do
    case "$role" in
        M1) module=monitor1 ;;
        M2) module=monitor2 ;;
    esac
    ref="$(config_dev "$module")"
    dev="$(resolve_ref "$ref")"
    if [ -n "$dev" ]; then
        case "$dev" in
            bus:*) echo "  $role: $ref -> $dev (ddcutil fallback)" ;;
            *)     echo "  $role: $ref -> $dev (kernel device)" ;;
        esac
    else
        echo "  $role: $ref -> STILL NOT RESOLVED"
        problems=1
    fi
done

if [ "$problems" -ne 0 ]; then
    echo ""
    echo "Mapping still inconsistent. Check 'ddcutil detect' and $MAPPING."
    exit 1
fi

echo ""
echo "Reloading Waybar..."
pkill -USR2 waybar 2>/dev/null || true

echo "Done."
