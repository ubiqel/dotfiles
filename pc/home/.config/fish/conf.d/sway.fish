if true # if neeed to disable sway
# get pci card num (because it may change on restart)
# set val $(ls -l /dev/dri/by-path/ | grep 'pci.*card' | rev | cut -c 1)

    set -x XDG_CURRENT_DESKTOP sway

    set -x SSH_AUTH_SOCK $XDG_RUNTIME_DIR/keyring/ssh

    # Using right videocard
    set -x WLR_DRM_DEVICES /dev/dri/card1:/dev/dri/card0

    # https://github.com/swaywm/sway/issues/8854
    # set -x WLR_SCENE_DISABLE_DIRECT_SCANOUT 1
    # set -x WLR_DRM_NO_ATOMIC 1

    # Making nvidia drivers work...
    set -x WLR_RENDERER vulkan
    # set -x WLR_RENDERER gles2
    # set -x WLR_NO_HARDWARE_CURSORS 1 # get back cursor!

    # Firefox
    set -x MOZ_ENABLE_WAYLAND 1 # not required anymore (should default to wayland), but sometimes my firefox launches via xwayland (no idea why)
    set -x MOZ_USE_XINPUT2 1

    # General wayland environment variables
    # set -x XDG_SESSION_TYPE wayland
    # set -x QT_QPA_PLATFORM wayland
    # set -x QT_WAYLAND_DISABLE_WINDOWDECORATION 2

    # OpenGL Variables
    # set -x GBM_BACKEND nvidia-drm
    # set -x __GL_GSYNC_ALLOWED 0
    # set -x __GL_VRR_ALLOWED 0
    # set -x __GLX_VENDOR_LIBRARY_NAME nvidia

    # for electron
    # set -x ELECTRON_OZONE_PLATFORM_HINT auto

    set TTY1 (tty)
    [ "$TTY1" = /dev/tty1 ] && exec sway --unsupported-gpu
end
