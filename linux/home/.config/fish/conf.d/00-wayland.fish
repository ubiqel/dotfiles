# Portable Wayland session environment, shared by the host and the guest.
# The 00- prefix matters: fish sources conf.d in filename order and
# pc/conf.d/sway.fish ends with a tty1 `exec sway`, so anything sorting after
# it is never read in the login shell.
#
# These are the host-shell copy of the guest session environment in vmbox's
# share/profile.d/10-vmbox-session.sh. The values are duplicated on purpose
# (one is a fish conf.d, the other a POSIX /etc/profile drop-in, and the guest
# has no fish at login), so change both together.
set -x XDG_CURRENT_DESKTOP sway

# Performance / Direct Scanout
set -x WLR_SCENE_DISABLE_DIRECT_SCANOUT 1

# App integrations
set -x MOZ_ENABLE_WAYLAND 1
set -x ELECTRON_OZONE_PLATFORM_HINT auto

# Terminal metadata: every session (fish here, the greetd drop-in in the guest)
# must answer the same for $TERMINAL and $COLORTERM, so interactive shells and
# launched apps agree regardless of which one started them.
set -x COLORTERM truecolor
set -x TERMINAL ghostty
