#!/bin/bash
set -euo pipefail

# Load ddcci kernel modules and manually probe display I2C buses.
# On kernel >= 6.8 the driver cannot auto-probe displays, so we instantiate
# a DDC/CI client at address 0x37 on adapters that have connected monitors.
#
# Displays are not always DDC/CI-ready when the service first runs (especially
# during early boot or right after resume), so this script waits for ddcutil to
# report at least one connected display before probing, and exits non-zero if it
# ultimately fails to create the backlight devices.
#
# Some monitors (e.g. Gigabyte M27Q P) return a malformed DDC/CI capability
# string. The ddcci driver then creates an internal device reference but fails
# to register the backlight device. Subsequent probes fail with EEXIST because
# the stale internal reference is still present. When normal probing fails,
# this script unloads and reloads the ddcci modules to clear that state.

log() { echo "[ddcci-setup] $*"; }

# How long to wait for connected displays to appear before giving up (seconds).
DDCCI_WAIT_SECONDS="${DDCCI_WAIT_SECONDS:-90}"
# How long to wait for a probed device to bind (attempts * delay seconds).
DDCCI_PROBE_ATTEMPTS="${DDCCI_PROBE_ATTEMPTS:-10}"
DDCCI_PROBE_DELAY="${DDCCI_PROBE_DELAY:-2}"
# Delay after bus writes, in ms (ddcci module parameter; default 60). A larger
# value helps monitors that return malformed capability strings on short delays.
DDCCI_DELAY="${DDCCI_DELAY:-150}"

# Set the driver's writable delay parameter (best effort).
set_delay() {
    local param="/sys/module/ddcci/parameters/delay"
    if [ -w "$param" ]; then
        echo "$DDCCI_DELAY" > "$param" 2>/dev/null || true
    fi
}

# Load modules. Ignore errors if already loaded.
load_modules() {
    modprobe ddcci 2>/dev/null || true
    modprobe ddcci-backlight 2>/dev/null || true
    sleep 0.5
    set_delay
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

# Delete every 0x37 client on every adapter, including bound ones. Needed before
# unloading the modules so that a stale core ddcci device (left behind when a
# malformed capability string makes the backlight probe fail with EEXIST) is
# actually cleared on reload.
delete_all_clients() {
    for adapter in /sys/bus/i2c/devices/i2c-*; do
        [ -d "$adapter" ] || continue
        local bus
        bus=$(basename "$adapter" | sed 's/i2c-//')
        if [ -e "$adapter/${bus}-0037" ]; then
            delete_client "$bus"
        fi
    done
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

# Cached output of `ddcutil detect --brief`.
DDCUTIL_OUTPUT=""

# Run ddcutil and cache its output. Returns 0 if a display was found.
detect_displays() {
    if ! command -v ddcutil >/dev/null 2>&1; then
        return 1
    fi
    # --disable-dynamic-sleep avoids ddcutil's dynamic-sleep stats cache, which
    # requires HOME/XDG and otherwise aborts initialization under systemd.
    DDCUTIL_OUTPUT="$(ddcutil detect --brief --disable-dynamic-sleep 2>/dev/null || true)"
    grep -q '^Display[[:space:]]' <<<"$DDCUTIL_OUTPUT"
}

# Wait until ddcutil reports at least one connected display.
wait_for_displays() {
    local waited=0
    while :; do
        if detect_displays; then
            return 0
        fi
        if [ "$waited" -ge "$DDCCI_WAIT_SECONDS" ]; then
            return 1
        fi
        log "No connected displays yet; retrying in 2s (waited ${waited}s/${DDCCI_WAIT_SECONDS}s)..."
        sleep 2
        waited=$((waited + 2))
    done
}

# Parse connected display I2C buses from the cached ddcutil output.
detect_buses() {
    while IFS= read -r line; do
        if [[ "$line" =~ I2C[[:space:]]bus:[[:space:]]+/dev/i2c-([0-9]+) ]]; then
            echo "${BASH_REMATCH[1]}"
        fi
    done <<<"$DDCUTIL_OUTPUT"
}

# Try to probe connected buses and wait for backlight devices to bind.
# Returns 0 if all connected buses are bound, 1 otherwise.
try_probe() {
    local buses=("$@")

    for ((attempt=1; attempt<=DDCCI_PROBE_ATTEMPTS; attempt++)); do
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

        log "Waiting ${DDCCI_PROBE_DELAY}s for ${remaining} adapter(s) to bind (attempt ${attempt}/${DDCCI_PROBE_ATTEMPTS})..."
        sleep "$DDCCI_PROBE_DELAY"
    done

    return 1
}

# Main logic.

# Serialize concurrent triggers (boot timer, DRM hotplug, resume) so two probes
# cannot delete each other's I2C clients.
exec 9>"/run/ddcci-setup.lock"
if ! flock -n 9; then
    log "Another ddcci-setup instance is already running; skipping."
    exit 0
fi

load_modules
cleanup_all_stale_clients

if ! wait_for_displays; then
    log "No connected displays detected after ${DDCCI_WAIT_SECONDS}s."
    exit 1
fi

mapfile -t BUSES < <(detect_buses)

if [ ${#BUSES[@]} -eq 0 ]; then
    log "No connected display I2C buses found."
    exit 1
fi

log "Connected display buses: ${BUSES[*]}"

if try_probe "${BUSES[@]}"; then
    exit 0
fi

log "Normal probing failed. Resetting ddcci driver state..."
delete_all_clients
unload_modules
load_modules
cleanup_all_stale_clients

if try_probe "${BUSES[@]}"; then
    exit 0
fi

log "Warning: connected adapter(s) still not bound after driver reset."
# Do not leave the failed probes' I2C clients behind: a stale client keeps the
# bus locked and prevents the next (retried) run from detecting/probing it.
cleanup_all_stale_clients
exit 1
