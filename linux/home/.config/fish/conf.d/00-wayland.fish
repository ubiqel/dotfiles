if true
    set -x XDG_CURRENT_DESKTOP sway
    set -x SSH_AUTH_SOCK $XDG_RUNTIME_DIR/keyring/ssh

    # Performance / Direct Scanout
    set -x WLR_SCENE_DISABLE_DIRECT_SCANOUT 1

    # App integrations
    set -x MOZ_ENABLE_WAYLAND 1
    set -x ELECTRON_OZONE_PLATFORM_HINT auto
end
