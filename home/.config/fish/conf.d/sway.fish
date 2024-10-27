# get pci card num (because it may change on restart)
# set val $(ls -l /dev/dri/by-path/ | grep 'pci.*card' | rev | cut -c 1)

# Using right videocard
set -x WLR_DRM_DEVICES /dev/dri/card0

# Making nvidia drivers work...
# set -x WLR_RENDERER vulkan # remove screen flickering for Wayland apps
set -x WLR_RENDERER gles2 # remove screen flickering for Wayland apps
set -x WLR_NO_HARDWARE_CURSORS 1 # get back cursor!

# Firefox
set -x MOZ_ENABLE_WAYLAND 1 # not required anymore (should default to wayland), but sometimes my firefox launches via xwayland (no idea why)

# for electron
set -x ELECTRON_OZONE_PLATFORM_HINT auto

# xwayland
set -x XWAYLAND_NO_GLAMOR 1 # remove screen flickering

set TTY1 (tty)
[ "$TTY1" = /dev/tty1 ] && exec sway --unsupported-gpu
