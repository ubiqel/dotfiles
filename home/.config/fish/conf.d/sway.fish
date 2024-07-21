# get pci card num (because it may change on restart)
# set val $(ls -l /dev/dri/by-path/ | grep 'pci.*card' | rev | cut -c 1)

# using right videocard
set -x WLR_DRM_DEVICES "/dev/dri/card1"

# making nvidia drivers work...
# set -x WLR_RENDERER vulkan # remove screen flickering for Wayland apps
set -x WLR_RENDERER gles2 # remove screen flickering for Wayland apps
set -x WLR_NO_HARDWARE_CURSORS 1 # get back cursor!
set -x XWAYLAND_NO_GLAMOR 1 # remove screen flickering for XWayland apps

# for electron
set -x ELECTRON_OZONE_PLATFORM_HINT wayland

set TTY1 (tty)
[ "$TTY1" = "/dev/tty1" ] && exec sway --unsupported-gpu
