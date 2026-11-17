# Portable Wayland session environment, shared by the host and the guest.
# The 00- prefix matters: fish sources conf.d in filename order and
# pc/conf.d/sway.fish ends with a tty1 `exec sway`, so anything sorting after
# it is never read in the login shell.
set -x XDG_CURRENT_DESKTOP sway

# Performance / Direct Scanout
set -x WLR_SCENE_DISABLE_DIRECT_SCANOUT 1

# App integrations
set -x MOZ_ENABLE_WAYLAND 1
set -x ELECTRON_OZONE_PLATFORM_HINT auto

# Terminal metadata (moved here from the later-sorting conf.d/term.fish)
set -x COLORTERM truecolor
set -x TERMINAL ghostty
