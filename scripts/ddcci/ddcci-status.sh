#!/bin/bash
# Show the current ddcci backlight mapping.
set -euo pipefail

echo "ddcci backlight devices:"
for dev in /sys/class/backlight/ddcci*; do
    [ -d "$dev" ] || continue
    name=$(basename "$dev")
    real=$(readlink -f "$dev")
    bus=$(echo "$real" | grep -oE 'i2c-[0-9]+' | head -1 || true)
    drm=$(ddcutil detect 2>/dev/null | grep -B1 "$bus" | head -1 | sed 's/.*DRM_connector:[[:space:]]*//' || true)
    pct=$(cat "$dev/brightness")
    echo "  $name -> $bus -> ${drm:-unknown DRM connector} (brightness: $pct%)"
done
