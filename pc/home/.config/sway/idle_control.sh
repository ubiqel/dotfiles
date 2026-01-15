#!/bin/sh

is_playing() {
    playerctl status -a 2>/dev/null | grep -q Playing
}

case "$1" in
    lock)
        exec swaylock -f -k --color 000000 --indicator-idle-visible
        ;;

    lock-if-idle)
        if ! is_playing; then
            exec swaylock -f -k --color 000000 --indicator-idle-visible
        fi
        ;;

    dpms-off-if-idle)
        if ! is_playing; then
            exec swaymsg "output * dpms off"
        fi
        ;;

    dpms-on)
        exec swaymsg "output * dpms on"
        ;;

    suspend-if-idle)
        if ! is_playing; then
            exec systemctl suspend
        fi
        ;;

    *)
        exit 1
        ;;
esac
