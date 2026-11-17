if status is-interactive
    set -g fish_greeting
    fish_vi_key_bindings
    # fish_vi_key_bindings resets bindings when it runs after the automatic
    # hook; call the shared custom bindings explicitly afterwards.
    fish_user_key_bindings
end

# macOS-only setup. It lives here, not in the macbook profile, because stow
# cannot own .config/fish/config.fish from two profiles: scripts/stow_mac.sh
# stows common first and the second package's config.fish aborts the whole
# stow (and with it gitconfig, ghostty, orbstack and the brew shell setup).
if test (uname) = Darwin
    if status is-interactive
        eval "$(/opt/homebrew/bin/brew shellenv)"
    end

    if test -z "$SSH_ENV"
        set -xg SSH_ENV $HOME/.ssh/environment
    end

    if not __ssh_agent_is_started
        __ssh_agent_start
    end

    # Added by OrbStack: command-line tools and integration
    # This won't be added again if you remove it.
    source ~/.orbstack/shell/init2.fish 2>/dev/null || :
end
