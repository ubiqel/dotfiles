if true
    set -x XDG_CURRENT_DESKTOP sway
    set -x SSH_AUTH_SOCK $XDG_RUNTIME_DIR/keyring/ssh

    # REQUIRED FOR NVIDIA WAYLAND
    set -x __GLX_VENDOR_LIBRARY_NAME nvidia
    set -x LIBVA_DRIVER_NAME nvidia

    # Set custom renderer
    # set -x WLR_RENDERER gles2

    # Performance / Direct Scanout
    set -x WLR_SCENE_DISABLE_DIRECT_SCANOUT 1

    # App integrations
    set -x MOZ_ENABLE_WAYLAND 1
    set -x ELECTRON_OZONE_PLATFORM_HINT auto

    set TTY1 (tty)
    [ "$TTY1" = /dev/tty1 ] && exec sway --unsupported-gpu
end
