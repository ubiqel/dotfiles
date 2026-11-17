if status is-interactive
    set -g fish_greeting
    fish_vi_key_bindings
    # fish_vi_key_bindings resets bindings when it runs after the automatic
    # hook; call the shared custom bindings explicitly afterwards.
    fish_user_key_bindings
end
