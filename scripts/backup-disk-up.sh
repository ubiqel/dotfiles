#!/usr/bin/env bash
set -euo pipefail

PART="/dev/sda1"

if findmnt -rn -S "$PART" >/dev/null; then
    exit 0
fi

udisksctl mount -b "$PART" --no-user-interaction
