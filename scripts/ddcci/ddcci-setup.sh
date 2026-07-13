#!/bin/bash
set -euo pipefail

# Load ddcci kernel modules and manually probe display I2C buses.
# On kernel >= 6.8 the driver cannot auto-probe displays, so we instantiate
# a DDC/CI client at address 0x37 on adapters that have connected monitors.
#
# Some monitors (e.g. Gigabyte M27Q P) return a malformed DDC/CI capability
# string. The ddcci driver then creates an internal device reference but fails
# to register the backlight device. Subsequent probes fail with EEXIST because
# the stale internal reference is still present. When normal probing fails,
# this script unloads and reloads the ddcci modules to clear that state.

log() { echo "[ddcci-setup] $*"; }

# Load modules. Ignore errors if already loaded.
load_modules() {
    modprobe ddcci 2>/dev/null || true
    modprobe ddcci-backlight 2>/dev/null || true
    sleep 0.5
}

# Unload modules to clear stale internal driver state.
unload_modules() {
    log "Unloading ddcci modules to reset driver state..."
    modprobe -r ddcci-backlight 2>/dev/null || true
    modprobe -r ddcci 2>/dev/null || true
    sleep 1
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

# Delete a stale client at 0x37.
delete_client() {
    local bus="$1"
    log "Deleting I2C client at i2c-${bus}/0x37"
    printf '0x37\n' > "/sys/bus/i2c/devices/i2c-${bus}/delete_device" 2>/dev/null || true
    sleep 0.5
}

# Probe a DDC/CI client at 0x37.
probe_bus() {
    local bus="$1"
    log "Probing i2c-${bus}"
    printf 'ddcci 0x37\n' > "/sys/bus/i2c/devices/i2c-${bus}/new_device" 2>/dev/null || true
}

# Clean up stale clients on all adapters before probing.
cleanup_all_stale_clients() {
    for adapter in /sys/bus/i2c/devices/i2c-*; do
        [ -d "$adapter" ] || continue
        local bus
        bus=$(basename "$adapter" | sed 's/i2c-//')
        if has_stale_client "$bus"; then
            delete_client "$bus"
        fi
    done
}

# Detect connected display I2C buses using ddcutil.
detect_buses() {
    if ! command -v ddcutil >/dev/null 2>&1; then
        return
    fi
    while IFS= read -r line; do
        if [[ "$line" =~ I2C[[:space:]]bus:[[:space:]]+/dev/i2c-([0-9]+) ]]; then
            echo "${BASH_REMATCH[1]}"
        fi
    done < <(ddcutil detect 2>/dev/null || true)
}

# Try to probe connected buses and wait for backlight devices to bind.
# Returns 0 if all connected buses are bound, 1 otherwise.
try_probe() {
    local buses=("$@")
    local max_attempts=10
    local delay=2

    for ((attempt=1; attempt<=max_attempts; attempt++)); do
        local remaining=0
        for bus in "${buses[@]}"; do
            if has_backlight "$bus"; then
                continue
            fi
            remaining=$((remaining + 1))

            if has_stale_client "$bus"; then
                delete_client "$bus"
            fi

            probe_bus "$bus"
        done

        if [ "$remaining" -eq 0 ]; then
            log "All connected adapters bound successfully."
            return 0
        fi

        log "Waiting ${delay}s for ${remaining} adapter(s) to bind (attempt ${attempt}/${max_attempts})..."
        sleep "$delay"
    done

    return 1
}

# Main logic.
load_modules
cleanup_all_stale_clients

mapfile -t BUSES < <(detect_buses)

if [ ${#BUSES[@]} -eq 0 ]; then
    log "No connected display I2C buses found."
    exit 0
fi

log "Connected display buses: ${BUSES[*]}"

if try_probe "${BUSES[@]}"; then
    exit 0
fi

log "Normal probing failed. Resetting ddcci driver state..."
unload_modules
load_modules
cleanup_all_stale_clients

if try_probe "${BUSES[@]}"; then
    exit 0
fi

log "Warning: connected adapter(s) still not bound after driver reset."
exit 0
