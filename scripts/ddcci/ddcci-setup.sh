#!/bin/bash
set -euo pipefail

# Load ddcci kernel modules and manually probe display I2C buses.
# On kernel >= 6.8 the driver cannot auto-probe displays, so we instantiate
# a DDC/CI client at address 0x37 on adapters that have connected monitors.
#
# Some monitors leave behind a stale I2C client at 0x37 without a bound
# backlight device (e.g. after an aborted probe). The script detects and
# removes those stale clients before re-probing.

log() { echo "[ddcci-setup] $*"; }

# Load modules. Ignore errors if already loaded.
modprobe ddcci 2>/dev/null || true
modprobe ddcci-backlight 2>/dev/null || true

# Give the driver a moment to register.
sleep 0.5

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

# Delete a stale client at 0x37.
delete_stale_client() {
    local bus="$1"
    log "Deleting stale I2C client at i2c-${bus}/0x37"
    printf '0x37\n' > "/sys/bus/i2c/devices/i2c-${bus}/delete_device" 2>/dev/null || true
    sleep 0.5
}

# Clean up stale clients on all adapters before probing.
for adapter in /sys/bus/i2c/devices/i2c-*; do
    [ -d "$adapter" ] || continue
    bus=$(basename "$adapter" | sed 's/i2c-//')
    if has_stale_client "$bus"; then
        delete_stale_client "$bus"
    fi
done

# Build a list of I2C buses that have connected monitors.
# Prefer ddcutil if available; otherwise fall back to all display adapters.
declare -a BUSES=()

if command -v ddcutil >/dev/null 2>&1; then
    while IFS= read -r line; do
        if [[ "$line" =~ I2C[[:space:]]bus:[[:space:]]+/dev/i2c-([0-9]+) ]]; then
            BUSES+=("${BASH_REMATCH[1]}")
        fi
    done < <(ddcutil detect 2>/dev/null || true)
else
    log "ddcutil not found; probing all display I2C adapters."
    for adapter in /sys/bus/i2c/devices/i2c-*; do
        [ -d "$adapter" ] || continue
        name=$(cat "$adapter/name" 2>/dev/null || true)
        case "$name" in
            *"i2c adapter"*)
                BUSES+=("$(basename "$adapter" | sed 's/i2c-//')")
                ;;
        esac
    done
fi

if [ ${#BUSES[@]} -eq 0 ]; then
    log "No connected display I2C buses found."
    exit 0
fi

log "Connected display buses: ${BUSES[*]}"

# Probe a DDC/CI client at 0x37.
probe_bus() {
    local bus="$1"
    log "Probing i2c-${bus}"
    printf 'ddcci 0x37\n' > "/sys/bus/i2c/devices/i2c-${bus}/new_device" 2>/dev/null || true
}

max_attempts=10
delay=2

for ((attempt=1; attempt<=max_attempts; attempt++)); do
    remaining=0
    for bus in "${BUSES[@]}"; do
        if has_backlight "$bus"; then
            continue
        fi
        remaining=$((remaining + 1))

        if has_stale_client "$bus"; then
            delete_stale_client "$bus"
        fi

        probe_bus "$bus"
    done

    if [ "$remaining" -eq 0 ]; then
        log "All connected adapters bound successfully."
        exit 0
    fi

    log "Waiting ${delay}s for ${remaining} adapter(s) to bind (attempt ${attempt}/${max_attempts})..."
    sleep "$delay"
done

log "Warning: ${remaining} connected adapter(s) still not bound after ${max_attempts} attempts."
exit 0
