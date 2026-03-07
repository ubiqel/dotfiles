#!/usr/bin/env bash
set -euo pipefail

PART="/dev/sda1"
DISK="/dev/sda"

# Если смонтирован — размонтируем
if findmnt -rn -S "$PART" >/dev/null; then
    udisksctl unmount -b "$PART" --no-user-interaction
fi

# Усыпляем диск
sudo -n /usr/bin/hdparm -y "$DISK" >/dev/null
