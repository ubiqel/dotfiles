if true
    # REQUIRED FOR NVIDIA WAYLAND
    set -x __GLX_VENDOR_LIBRARY_NAME nvidia
    set -x LIBVA_DRIVER_NAME nvidia

    # Set custom renderer
    # set -x WLR_RENDERER gles2

    # Ignore simpledrm (boot framebuffer) so sway doesn't build a multi-GPU renderer.
    # by-path keeps the NVIDIA card pinned even if card numbering changes.
    set -x WLR_DRM_DEVICES (realpath /dev/dri/by-path/pci-0000:01:00.0-card)

    set TTY1 (tty)
    [ "$TTY1" = /dev/tty1 ] && exec sway --unsupported-gpu
end
